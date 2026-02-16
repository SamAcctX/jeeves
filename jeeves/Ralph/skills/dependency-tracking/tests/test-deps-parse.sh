#!/bin/bash
set -e

# Test framework
PASSED=0
FAILED=0

test_assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" = "$actual" ]; then
        echo "✓ PASS: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        FAILED=$((FAILED + 1))
    fi
}

test_assert_exit_code() {
    local expected="$1"
    local test_name="$2"
    shift 2

    local actual=""
    if [ $# -gt 0 ]; then
        # If exit code was passed as argument
        actual="$1"
    else
        # Run the command and capture exit code
        if "$@" >/dev/null 2>&1; then
            actual=0
        else
            actual=$?
        fi
    fi

    if [ "$expected" = "$actual" ]; then
        echo "✓ PASS: $test_name"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code: $actual"
        FAILED=$((FAILED + 1))
    fi
}

# Setup test environment
setup() {
    export TEST_DIR="$(mktemp -d)"
    export DEPS_FILE="$TEST_DIR/deps-tracker.yaml"
    export TODO_FILE="$TEST_DIR/TODO.md"

    # Create deps-parse.sh script
    cp "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh" "$TEST_DIR/deps-parse.sh"
    chmod +x "$TEST_DIR/deps-parse.sh"

    # Create sample deps-tracker.yaml
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: [0003, 0004]
  0002:
    depends_on: []
    blocks: [0003]
  0003:
    depends_on: [0001, 0002]
    blocks: [0005]
  0004:
    depends_on: [0001]
    blocks: [0005]
  0005:
    depends_on: [0003, 0004]
    blocks: []
  0006:
    depends_on: []
    blocks: []
EOF

    cd "$TEST_DIR"
}

# Cleanup
teardown() {
    rm -rf "$TEST_DIR"
}

# Source the script being tested
source_deps_parse() {
    if [ -f "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh" ]; then
        source "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh"
    else
        echo "WARNING: deps-parse.sh not found (expected for TDD)"
    fi
}

# === TEST CASES ===

# deps_get_dependencies tests
test_deps_get_dependencies_empty() {
    source_deps_parse
    local result=$(deps_get_dependencies 0006)
    test_assert_equals "" "$result" "deps_get_dependencies for task with no dependencies returns empty"
}

test_deps_get_dependencies_one() {
    source_deps_parse
    local result=$(deps_get_dependencies 0004)
    test_assert_equals "0001" "$result" "deps_get_dependencies for task with one dependency returns '0001'"
}

test_deps_get_dependencies_multiple() {
    source_deps_parse
    local result=$(deps_get_dependencies 0003)
    test_assert_equals "0001 0002" "$result" "deps_get_dependencies for task with multiple dependencies returns both"
}

test_deps_get_dependencies_nonexistent() {
    source_deps_parse
    local result=$(deps_get_dependencies 9999)
    test_assert_equals "" "$result" "deps_get_dependencies for non-existent task returns empty"
}

test_deps_get_dependencies_missing_file() {
    source_deps_parse
    local original_deps_file="$DEPS_FILE"
    export DEPS_FILE="$TEST_DIR/nonexistent.yaml"
    local result=$(deps_get_dependencies 0001)
    export DEPS_FILE="$original_deps_file"
    test_assert_equals "" "$result" "deps_get_dependencies handles missing deps file gracefully"
}

# deps_get_blocked tests
test_deps_get_blocked_empty() {
    source_deps_parse
    local result=$(deps_get_blocked 0005)
    test_assert_equals "" "$result" "deps_get_blocked for task with no blocked returns empty"
}

test_deps_get_blocked_one() {
    source_deps_parse
    local result=$(deps_get_blocked 0002)
    test_assert_equals "0003" "$result" "deps_get_blocked for task with one blocked returns '0003'"
}

test_deps_get_blocked_multiple() {
    source_deps_parse
    local result=$(deps_get_blocked 0001)
    test_assert_equals "0003 0004" "$result" "deps_get_blocked for task with multiple blocked returns both"
}

test_deps_get_blocked_nonexistent() {
    source_deps_parse
    local result=$(deps_get_blocked 9999)
    test_assert_equals "" "$result" "deps_get_blocked for non-existent task returns empty"
}

# deps_is_unblocked tests
test_deps_is_unblocked_no_deps() {
    source_deps_parse
    deps_is_unblocked 0001
    test_assert_exit_code 0 "deps_is_unblocked for task with no dependencies returns exit code 0"
}

test_deps_is_unblocked_all_complete() {
    source_deps_parse
    deps_is_unblocked 0003 "0001 0002"
    test_assert_exit_code 0 "deps_is_unblocked with all dependencies completed returns exit code 0"
}

test_deps_is_unblocked_partial_complete() {
    source_deps_parse
    if deps_is_unblocked 0003 "0001"; then
        local actual=0
    else
        local actual=1
    fi
    test_assert_exit_code 1 "deps_is_unblocked with partial dependencies returns exit code 1" "$actual"
}

test_deps_is_unblocked_none_complete() {
    source_deps_parse
    if deps_is_unblocked 0003 ""; then
        local actual=0
    else
        local actual=1
    fi
    test_assert_exit_code 1 "deps_is_unblocked with no dependencies completed returns exit code 1" "$actual"
}

test_deps_is_unblocked_nonexistent() {
    source_deps_parse
    if deps_is_unblocked 9999 "0001"; then
        local actual=0
    else
        local actual=1
    fi
    test_assert_exit_code 1 "deps_is_unblocked for non-existent task handles gracefully" "$actual"
}

# CLI interface tests
test_cli_get_dependencies() {
    source_deps_parse
    ./deps-parse.sh --get-dependencies 0003 | grep -q "0001"
    test_assert_exit_code 0 "CLI --get-dependencies 0003 outputs dependencies"
}

test_cli_get_blocker() {
    source_deps_parse
    ./deps-parse.sh --get-blocked 0001 | grep -q "0003"
    test_assert_exit_code 0 "CLI --get-blocked 0001 outputs blocked tasks"
}

test_cli_is_unblocked_true() {
    source_deps_parse
    ./deps-parse.sh --is-unblocked 0001
    test_assert_exit_code 0 "CLI --is-unblocked 0001 returns exit code 0"
}

test_cli_is_unblocked_false() {
    source_deps_parse
    set +e
    ./deps-parse.sh --is-unblocked 0003 "0001" >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 1 "CLI --is-unblocked 0003 '0001' returns exit code 1" "$actual"
    set -e
}

test_cli_is_unblocked_true_with_all() {
    source_deps_parse
    set +e
    ./deps-parse.sh --is-unblocked 0003 "0001 0002" >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 0 "CLI --is-unblocked 0003 '0001 0002' returns exit code 0" "$actual"
    set -e
}

test_cli_invalid_args() {
    source_deps_parse
    set +e
    ./deps-parse.sh 0001 >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 1 "CLI with invalid arguments shows usage/error" "$actual"
    set -e
}

# Error handling tests
test_malformed_yaml() {
    source_deps_parse
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: [invalid
EOF
    local result=$(deps_get_dependencies 0001)
    test_assert_equals "" "$result" "deps_get_dependencies handles malformed YAML gracefully"
}

test_missing_deps_file() {
    source_deps_parse
    export DEPS_FILE="$TEST_DIR/nonexistent.yaml"
    local result=$(deps_get_dependencies 0001)
    test_assert_equals "" "$result" "deps_get_dependencies handles missing deps-tracker.yaml gracefully"
}

test_invalid_task_id() {
    source_deps_parse
    local result=$(deps_get_dependencies invalid)
    test_assert_equals "" "$result" "deps_get_dependencies handles invalid task ID gracefully"
}

# Run all tests
main() {
    setup
    source_deps_parse

    echo "Running deps-parse.sh tests..."
    echo ""

    # deps_get_dependencies tests
    test_deps_get_dependencies_empty
    test_deps_get_dependencies_one
    test_deps_get_dependencies_multiple
    test_deps_get_dependencies_nonexistent
    test_deps_get_dependencies_missing_file

    # deps_get_blocked tests
    test_deps_get_blocked_empty
    test_deps_get_blocked_one
    test_deps_get_blocked_multiple
    test_deps_get_blocked_nonexistent

    # deps_is_unblocked tests
    test_deps_is_unblocked_no_deps
    test_deps_is_unblocked_all_complete
    test_deps_is_unblocked_partial_complete
    test_deps_is_unblocked_none_complete
    test_deps_is_unblocked_nonexistent

    # CLI interface tests
    test_cli_get_dependencies
    test_cli_get_blocker
    test_cli_is_unblocked_true
    test_cli_is_unblocked_false
    test_cli_is_unblocked_true_with_all
    test_cli_invalid_args

    # Error handling tests
    test_malformed_yaml
    test_missing_deps_file
    test_invalid_task_id

    teardown

    echo ""
    echo "=== Test Results ==="
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    echo "Total: $((PASSED + FAILED))"

    if [ $FAILED -gt 0 ]; then
        exit 1
    fi
}

main "$@"
