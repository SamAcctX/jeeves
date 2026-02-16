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

    if "$@" >/dev/null 2>&1; then
        local actual=0
    else
        local actual=$?
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

# Setup - creates various test scenarios
setup() {
    export TEST_DIR="$(mktemp -d)"
    export DEPS_FILE="$TEST_DIR/deps-tracker.yaml"
    cd "$TEST_DIR"
}

# Create valid graph (no cycles)
setup_valid_graph() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: [0002, 0003]
  0002:
    depends_on: [0001]
    blocks: [0004]
  0003:
    depends_on: [0001]
    blocks: [0004]
  0004:
    depends_on: [0002, 0003]
    blocks: []
EOF
}

# Create graph with self-reference cycle
setup_self_reference_cycle() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: [0001]
    blocks: []
EOF
}

# Create graph with two-node cycle
setup_two_node_cycle() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: [0002]
    blocks: [0002]
  0002:
    depends_on: [0001]
    blocks: [0001]
EOF
}

# Create graph with three-node cycle
setup_three_node_cycle() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: [0003]
    blocks: [0002]
  0002:
    depends_on: [0001]
    blocks: [0003]
  0003:
    depends_on: [0002]
    blocks: [0001]
EOF
}

# Create graph with diamond + cycle
setup_complex_cycle() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: [0002, 0003]
  0002:
    depends_on: [0001]
    blocks: [0004]
  0003:
    depends_on: [0001]
    blocks: [0004]
  0004:
    depends_on: [0002, 0003, 0005]
    blocks: [0005]
  0005:
    depends_on: [0004]
    blocks: [0004]
EOF
}

# Create empty graph
setup_empty_graph() {
    cat > "$DEPS_FILE" << 'EOF'
tasks: {}
EOF
}

# Create single task no deps
setup_single_task() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: []
EOF
}

# Create graph with task that leads to cycle elsewhere
setup_partial_cycle() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: []
    blocks: []
  0002:
    depends_on: [0001, 0004]
    blocks: [0003]
  0003:
    depends_on: [0002]
    blocks: [0004]
  0004:
    depends_on: [0003]
    blocks: []
EOF
}

# Create multiple independent cycles
setup_multiple_cycles() {
    cat > "$DEPS_FILE" << 'EOF'
tasks:
  0001:
    depends_on: [0002]
    blocks: [0002]
  0002:
    depends_on: [0001]
    blocks: [0001]
  0003:
    depends_on: [0004]
    blocks: [0004]
  0004:
    depends_on: [0003]
    blocks: [0003]
  0005:
    depends_on: []
    blocks: []
EOF
}

teardown() {
    rm -rf "$TEST_DIR"
}

source_deps_cycle() {
    if [ -f "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh" ]; then
        source "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-parse.sh"
    fi
    if [ -f "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh" ]; then
        source "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh"
    fi
}

# === TEST CASES ===

# deps_detect_cycle() function tests

# Test 1: Valid graph - task 0001 has no cycle → exit 1 (no cycle)
test_detect_cycle_valid_graph_0001() {
    setup_valid_graph
    test_assert_exit_code 1 "detect_cycle for task 0001 in valid graph returns exit code 1" \
        deps_detect_cycle 0001
}

# Test 2: Valid graph - task 0004 (deep in graph) has no cycle → exit 1
test_detect_cycle_valid_graph_0004() {
    setup_valid_graph
    test_assert_exit_code 1 "detect_cycle for task 0004 in valid graph returns exit code 1" \
        deps_detect_cycle 0004
}

# Test 3: Self-reference - task 0001 depends on itself → exit 0 (cycle found)
test_detect_cycle_self_reference() {
    setup_self_reference_cycle
    test_assert_exit_code 0 "detect_cycle for self-referencing task returns exit code 0" \
        deps_detect_cycle 0001
}

# Test 4: Two-node cycle - 0001→0002→0001 → exit 0
test_detect_cycle_two_node() {
    setup_two_node_cycle
    test_assert_exit_code 0 "detect_cycle for two-node cycle returns exit code 0" \
        deps_detect_cycle 0001
}

# Test 5: Three-node cycle - 0001→0002→0003→0001 → exit 0
test_detect_cycle_three_node() {
    setup_three_node_cycle
    test_assert_exit_code 0 "detect_cycle for three-node cycle returns exit code 0" \
        deps_detect_cycle 0001
}

# Test 6: Complex cycle - diamond pattern with cycle at end → exit 0
test_detect_cycle_complex() {
    setup_complex_cycle
    test_assert_exit_code 0 "detect_cycle for complex cycle returns exit code 0" \
        deps_detect_cycle 0004
}

# Test 7: Non-existent task → exit 1 or graceful error
test_detect_cycle_nonexistent_task() {
    setup_valid_graph
    test_assert_exit_code 1 "detect_cycle for non-existent task returns exit code 1" \
        deps_detect_cycle 9999
}

# Test 8: Task in valid graph that leads to cycle elsewhere → exit 0
test_detect_cycle_partial() {
    setup_partial_cycle
    test_assert_exit_code 0 "detect_cycle for task in partial cycle returns exit code 0" \
        deps_detect_cycle 0002
}

# Test 9: Empty graph → exit 1 (no cycles)
test_detect_cycle_empty_graph() {
    setup_empty_graph
    test_assert_exit_code 1 "detect_cycle in empty graph returns exit code 1" \
        deps_detect_cycle 0001
}

# Test 10: Missing deps file → exit 1 or graceful error
test_detect_cycle_missing_file() {
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    local saved_deps_file="$DEPS_FILE"
    unset DEPS_FILE
    test_assert_exit_code 1 "detect_cycle with missing deps file returns exit code 1" \
        deps_detect_cycle 0001
    DEPS_FILE="$saved_deps_file"
}

# deps_validate_graph() function tests

# Test 11: Valid graph (no cycles anywhere) → exit 1 (valid, no cycles found)
test_validate_graph_valid() {
    setup_valid_graph
    test_assert_exit_code 1 "validate_graph on valid graph returns exit code 1 (valid)" \
        deps_validate_graph
}

# Test 12: Self-reference cycle → exit 0 (cycle found)
test_validate_graph_self_reference() {
    setup_self_reference_cycle
    test_assert_exit_code 0 "validate_graph on self-reference cycle returns exit code 0" \
        deps_validate_graph
}

# Test 13: Two-node cycle → exit 0
test_validate_graph_two_node() {
    setup_two_node_cycle
    test_assert_exit_code 0 "validate_graph on two-node cycle returns exit code 0" \
        deps_validate_graph
}

# Test 14: Three-node cycle → exit 0
test_validate_graph_three_node() {
    setup_three_node_cycle
    test_assert_exit_code 0 "validate_graph on three-node cycle returns exit code 0" \
        deps_validate_graph
}

# Test 15: Complex cycle → exit 0
test_validate_graph_complex() {
    setup_complex_cycle
    test_assert_exit_code 0 "validate_graph on complex cycle returns exit code 0" \
        deps_validate_graph
}

# Test 16: Multiple independent cycles → exit 0
test_validate_graph_multiple_cycles() {
    setup_multiple_cycles
    test_assert_exit_code 0 "validate_graph on multiple independent cycles returns exit code 0" \
        deps_validate_graph
}

# Test 17: Empty graph → exit 1 (valid)
test_validate_graph_empty() {
    setup_empty_graph
    test_assert_exit_code 1 "validate_graph on empty graph returns exit code 1 (valid)" \
        deps_validate_graph
}

# Test 18: Single task no deps → exit 1 (valid)
test_validate_graph_single_task() {
    setup_single_task
    test_assert_exit_code 1 "validate_graph on single task returns exit code 1 (valid)" \
        deps_validate_graph
}

# CLI interface tests

# Test 19: --detect-cycle 0001 on valid graph → exit 1
test_cli_detect_cycle_valid() {
    setup_valid_graph
    test_assert_exit_code 1 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle 0001 returns exit code 1 on valid graph" \
        /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle 0001
}

# Test 20: --detect-cycle 0001 on cyclic graph → exit 0
test_cli_detect_cycle_cyclic() {
    setup_self_reference_cycle
    test_assert_exit_code 0 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle 0001 returns exit code 0 on cyclic graph" \
        bash /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle 0001
}

# Test 21: --validate-graph on valid graph → exit 1
test_cli_validate_graph_valid() {
    setup_valid_graph
    test_assert_exit_code 1 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --validate-graph returns exit code 1 on valid graph" \
        bash /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --validate-graph
}

# Test 22: --validate-graph on cyclic graph → exit 0
test_cli_validate_graph_cyclic() {
    setup_two_node_cycle
    test_assert_exit_code 0 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --validate-graph returns exit code 0 on cyclic graph" \
        bash /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --validate-graph
}

# Test 23: Invalid arguments → usage message, exit 1
test_cli_invalid_arguments() {
    setup_valid_graph
    test_assert_exit_code 1 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh invalid_arg returns exit code 1" \
        /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh invalid_arg
}

# Test 24: Missing task ID with --detect-cycle → error, exit 1
test_cli_missing_task_id() {
    setup_valid_graph
    test_assert_exit_code 1 "/proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle returns exit code 1" \
        bash /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh --detect-cycle
}

# Cycle output format tests

# Test 25: Cycle detection outputs cycle path (pattern, not exact order)
test_cycle_output_format() {
    setup_three_node_cycle
    local output
    output=$(deps_detect_cycle 0001 2>&1)
    echo "$output"
    if echo "$output" | grep -q "0001 -> 000[23]"; then
        echo "✓ PASS: Cycle detection outputs cycle path"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: Cycle detection does not output expected cycle path"
        echo "  Expected: cycle pattern including 0001 and 0002/0003"
        echo "  Actual: $output"
        FAILED=$((FAILED + 1))
    fi
}

# Test 26: Self-reference outputs "0001 -> 0001"
test_self_reference_output_format() {
    setup_self_reference_cycle
    local output
    output=$(deps_detect_cycle 0001 2>&1)
    echo "$output"
    if echo "$output" | grep -q "0001 -> 0001"; then
        echo "✓ PASS: Self-reference outputs correct cycle path"
        PASSED=$((PASSED + 1))
    else
        echo "✗ FAIL: Self-reference does not output expected cycle path"
        echo "  Expected: 0001 -> 0001"
        echo "  Actual: $output"
        FAILED=$((FAILED + 1))
    fi
}

main() {
    setup
    source_deps_cycle

    # Run all tests

    # deps_detect_cycle() function tests
    test_detect_cycle_valid_graph_0001
    test_detect_cycle_valid_graph_0004
    test_detect_cycle_self_reference
    test_detect_cycle_two_node
    test_detect_cycle_three_node
    test_detect_cycle_complex
    test_detect_cycle_nonexistent_task
    test_detect_cycle_partial
    test_detect_cycle_empty_graph
    test_detect_cycle_missing_file

    # deps_validate_graph() function tests
    test_validate_graph_valid
    test_validate_graph_self_reference
    test_validate_graph_two_node
    test_validate_graph_three_node
    test_validate_graph_complex
    test_validate_graph_multiple_cycles
    test_validate_graph_empty
    test_validate_graph_single_task

    # CLI interface tests
    test_cli_detect_cycle_valid
    test_cli_detect_cycle_cyclic
    test_cli_validate_graph_valid
    test_cli_validate_graph_cyclic
    test_cli_invalid_arguments
    test_cli_missing_task_id

    # Cycle output format tests
    test_cycle_output_format
    test_self_reference_output_format

    teardown

    echo ""
    echo "=== Test Results ==="
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"

    if [ $FAILED -gt 0 ]; then
        exit 1
    fi
}

main "$@"
