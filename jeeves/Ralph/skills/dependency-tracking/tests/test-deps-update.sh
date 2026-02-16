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
        actual="$1"
    else
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

setup() {
    export TEST_DIR="$(mktemp -d)"
    export DEPS_FILE="$TEST_DIR/deps-tracker.yaml"
    export TODO_FILE="$TEST_DIR/TODO.md"

    source "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh"

    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: []
  0002:
    depends_on: []
    blocks: []
  0003:
    depends_on: [0001]
    blocks: [0005]
  0004:
    depends_on: [0001, 0002]
    blocks: []
  0005:
    depends_on: [0003]
    blocks: []
  0006:
    depends_on: []
    blocks: []
EOF

    cd "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

source_deps_update() {
    if [ -f "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh" ]; then
        source "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh"
    else
        echo "WARNING: deps-update.sh not found (expected for TDD)"
        return 1
    fi
    return 0
}

# === TEST CASES ===

# deps_add_dependency tests
test_add_dependency_new_relationship() {
    source_deps_update
    local result=$(deps_add_dependency 0001 0006)
    local deps=$(deps_get_dependencies 0001)
    local blocks=$(deps_get_blocked 0006)
    test_assert_equals "" "$result" "deps_add_dependency returns empty on success"
    test_assert_equals "0006" "$deps" "deps_add_dependency adds to depends_on"
    test_assert_equals "0001" "$blocks" "deps_add_dependency updates blocks bidirectionally"
}

test_add_dependency_existing_no_duplicate() {
    source_deps_update
    local result1=$(deps_add_dependency 0004 0001)
    local result2=$(deps_add_dependency 0004 0001)
    local deps=$(deps_get_dependencies 0004)
    test_assert_equals "" "$result1" "First add_dependency returns empty"
    test_assert_equals "" "$result2" "Second add_dependency returns empty (no duplicate)"
    test_assert_equals "0001" "$deps" "depends_on contains 0001 only once"
}

test_add_dependency_updates_blocks_bidirectionally() {
    source_deps_update
    local result=$(deps_add_dependency 0003 0005)
    local deps=$(deps_get_dependencies 0003)
    local blocks=$(deps_get_blocked 0005)
    test_assert_equals "0005" "$deps" "deps_add_dependency adds to from_task's depends_on"
    test_assert_equals "0003" "$blocks" "deps_add_dependency adds from_task to to_task's blocks"
}

test_add_dependency_invalid_format() {
    source_deps_update
    set +e
    local result=$(deps_add_dependency abc 0001)
    local actual=$?
    test_assert_exit_code 0 "deps_add_dependency handles invalid format gracefully (returns 0)" "$actual"
    set -e
}

test_add_dependency_task_not_found() {
    source_deps_update
    set +e
    local result=$(deps_add_dependency 9999 0001)
    local actual=$?
    test_assert_exit_code 0 "deps_add_dependency handles non-existent task gracefully (returns 0)" "$actual"
    set -e
}

# deps_remove_dependency tests
test_remove_dependency_existing() {
    source_deps_update
    deps_add_dependency 0004 0001
    local result=$(deps_remove_dependency 0004 0001)
    local deps=$(deps_get_dependencies 0004)
    local blocks=$(deps_get_blocked 0001)
    test_assert_equals "" "$result" "deps_remove_dependency returns empty on success"
    test_assert_equals "" "$deps" "deps_remove_dependency removes from depends_on"
    test_assert_equals "" "$blocks" "deps_remove_dependency removes from blocks"
}

test_remove_dependency_non_existing_no_error() {
    source_deps_update
    set +e
    local result=$(deps_remove_dependency 0001 9999)
    local actual=$?
    test_assert_exit_code 0 "deps_remove_dependency handles non-existing relationship gracefully" "$actual"
    set -e
}

test_remove_dependency_updates_bidirectionally() {
    source_deps_update
    deps_add_dependency 0004 0001
    local result=$(deps_remove_dependency 0004 0001)
    local deps=$(deps_get_dependencies 0004)
    local blocks=$(deps_get_blocked 0001)
    test_assert_equals "" "$deps" "depends_on removed"
    test_assert_equals "" "$blocks" "blocks removed"
}

# CLI interface tests
test_cli_add_dependency() {
    source_deps_update
    set +e
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --add-dependency 0006 0001 >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 0 "CLI --add-dependency runs successfully" "$actual"
    set -e
}

test_cli_remove_dependency() {
    source_deps_update
    deps_add_dependency 0004 0001
    set +e
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --remove-dependency 0004 0001 >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 0 "CLI --remove-dependency runs successfully" "$actual"
    set -e
}

test_cli_invalid_args() {
    source_deps_update
    set +e
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh 0001 >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 1 "CLI with invalid arguments shows usage/error" "$actual"
    set -e
}

# Activity log tests
test_activity_log_entry_created() {
    source_deps_update
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --add-dependency 0006 0001 >/dev/null 2>&1
    if [ -f "$TEST_DIR/activity.md" ]; then
        cat "$TEST_DIR/activity.md" | grep -q "0006"
        test_assert_exit_code 0 "Activity log contains dependency addition" 0
    else
        echo "✗ FAIL: Activity log not created"
        FAILED=$((FAILED + 1))
    fi
}

# Cycle detection tests
test_cycle_detection_after_update() {
    source_deps_update
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: []
  0002:
    depends_on: []
    blocks: []
  0003:
    depends_on: [0001]
    blocks: []
  0004:
    depends_on: [0003]
    blocks: [0001]
EOF
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --add-dependency 0004 0002 >/dev/null 2>&1
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --add-dependency 0002 0004 >/dev/null 2>&1
    ./deps-cycle.sh --validate-graph >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 0 "Cycle detection runs after updates" "$actual"
}

test_no_cycle_without_update() {
    source_deps_update
    /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh --add-dependency 0006 0001 >/dev/null 2>&1
    ./deps-cycle.sh --validate-graph >/dev/null 2>&1
    local actual=$?
    test_assert_exit_code 0 "Cycle detection works on valid graph" "$actual"
}

# Run all tests
main() {
    setup

    if ! source_deps_update; then
        echo "✗ FAIL: deps-update.sh not found - cannot run tests"
        exit 1
    fi

    echo "Running deps-update.sh tests..."
    echo ""

    test_add_dependency_new_relationship
    test_add_dependency_existing_no_duplicate
    test_add_dependency_updates_blocks_bidirectionally
    test_add_dependency_invalid_format
    test_add_dependency_task_not_found

    test_remove_dependency_existing
    test_remove_dependency_non_existing_no_error
    test_remove_dependency_updates_bidirectionally

    test_cli_add_dependency
    test_cli_remove_dependency
    test_cli_invalid_args

    test_cycle_detection_after_update
    test_no_cycle_without_update

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
