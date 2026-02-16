#!/bin/bash
set -e

# Test suite for deps-select.sh
# Tests for dependency-tracking skill task selection functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_SOURCE="${SCRIPT_DIR}/../scripts/deps-select.sh"
TEST_DIR="${SCRIPT_DIR}/fixtures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${YELLOW}[TEST $TOTAL_TESTS]${NC} $test_name"
    
    if eval "$test_command"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ PASSED${NC}"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Setup test fixtures
setup_incomplete_all() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [ ] 0001: Task 0001
- [ ] 0002: Task 0002
- [ ] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_some_complete() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [x] 0001: Task 0001
- [ ] 0002: Task 0002
- [ ] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_all_complete() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [x] 0001: Task 0001
- [x] 0002: Task 0002
- [x] 0003: Task 0003
- [x] 0004: Task 0004
- [x] 0005: Task 0005
EOF
}

setup_no_complete() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [ ] 0001: Task 0001
- [ ] 0002: Task 0002
- [ ] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_some_complete_1_2() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [x] 0001: Task 0001
- [x] 0002: Task 0002
- [ ] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_all_complete_1_2_3() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [x] 0001: Task 0001
- [x] 0002: Task 0002
- [x] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_all_complete_1_2_3_4() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [x] 0001: Task 0001
- [x] 0002: Task 0002
- [x] 0003: Task 0003
- [x] 0004: Task 0004
- [ ] 0005: Task 0005
EOF
}

setup_empty_todo() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
EOF
}

setup_invalid_todo() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
This is not a valid TODO file format
EOF
}

setup_malformed_todo() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [ ] 0001: Task 0001
- [ ] 0002: Task 0002
- [INVALID FORMAT HERE]
EOF
}

setup_no_todo_file() {
    rm -f "${TEST_DIR}/TODO.md"
}

setup_task_0006() {
    cat > "${TEST_DIR}/TODO.md" << 'EOF'
- [ ] 0001: Task 0001
- [ ] 0002: Task 0002
- [ ] 0003: Task 0003
- [ ] 0004: Task 0004
- [ ] 0005: Task 0005
- [ ] 0006: Task 0006
EOF
}

# Test 1: Get incomplete tasks - all incomplete → returns all 5
run_test "Get incomplete tasks - all incomplete returns all 5" \
    "setup_incomplete_all && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$'"

# Test 2: Get incomplete tasks - some complete → returns incomplete only
run_test "Get incomplete tasks - some complete returns incomplete only" \
    "setup_some_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$'"

# Test 3: Get incomplete tasks - all complete → returns empty
run_test "Get incomplete tasks - all complete returns empty" \
    "setup_all_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '^$' || \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | wc -l | grep -q '^0$'"

# Test 4: Get completed tasks - none complete → returns empty
run_test "Get completed tasks - none complete returns empty" \
    "setup_no_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '^$' || \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | wc -l | grep -q '^0$'"

# Test 5: Get completed tasks - some complete → returns completed only
run_test "Get completed tasks - some complete returns completed only" \
    "setup_some_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$'"

# Test 6: Get completed tasks - all complete → returns all
run_test "Get completed tasks - all complete returns all" \
    "setup_all_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_completed_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$'"

# Test 7: Find unblocked - none complete → 0001, 0005 unblocked
run_test "Find unblocked - no tasks complete returns 0001 and 0005" \
    "setup_no_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$'"

# Test 8: Find unblocked - 0001 complete → 0002, 0003, 0005 unblocked
run_test "Find unblocked - 0001 complete returns 0002, 0003, 0005" \
    "setup_some_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$'"

# Test 9: Find unblocked - 0001,0002 complete → 0003,0005 unblocked
run_test "Find unblocked - 0001,0002 complete returns 0003, 0005" \
    "setup_some_complete_1_2 && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$'"

# Test 10: Find unblocked - 0001,0002,0003 complete → 0004,0005 unblocked
run_test "Find unblocked - 0001,0002,0003 complete returns 0004, 0005" \
    "setup_all_complete_1_2_3 && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0004$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0005$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '0003$'"

# Test 11: Find unblocked - all complete → returns empty
run_test "Find unblocked - all complete returns empty" \
    "setup_all_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | grep -q '^$' || \
    bash -c 'source ${SCRIPT_SOURCE} && deps_find_unblocked_tasks ${TEST_DIR}/TODO.md' | wc -l | grep -q '^0$'"

# Test 12: Select next task - first unblocked task
run_test "Select next task returns first unblocked task" \
    "setup_some_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_select_next_task ${TEST_DIR}/TODO.md' | grep -q '0002$'"

# Test 13: Select next task - respects priority order
run_test "Select next task respects priority order (0002 before 0003)" \
    "setup_some_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_select_next_task ${TEST_DIR}/TODO.md' | grep -q '0002$' && \
    ! bash -c 'source ${SCRIPT_SOURCE} && deps_select_next_task ${TEST_DIR}/TODO.md' | grep -q '0003$'"

# Test 14: Select next task - no unblocked → empty
run_test "Select next task - no unblocked returns empty" \
    "setup_all_complete && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_select_next_task ${TEST_DIR}/TODO.md' | grep -q '^$' || \
    bash -c 'source ${SCRIPT_SOURCE} && deps_select_next_task ${TEST_DIR}/TODO.md' | wc -l | grep -q '^0$'"

# Test 15: CLI: --get-incomplete
run_test "CLI --get-incomplete option exists" \
    "bash -c 'source ${SCRIPT_SOURCE} && echo \"Usage: $0 --get-incomplete\"' > /dev/null 2>&1"

# Test 16: CLI: --get-completed
run_test "CLI --get-completed option exists" \
    "bash -c 'source ${SCRIPT_SOURCE} && echo \"Usage: $0 --get-completed\"' > /dev/null 2>&1"

# Test 17: CLI: --find-unblocked
run_test "CLI --find-unblocked option exists" \
    "bash -c 'source ${SCRIPT_SOURCE} && echo \"Usage: $0 --find-unblocked\"' > /dev/null 2>&1"

# Test 18: CLI: --select-next
run_test "CLI --select-next option exists" \
    "bash -c 'source ${SCRIPT_SOURCE} && echo \"Usage: $0 --select-next\"' > /dev/null 2>&1"

# Test 19: Error: Missing TODO file
run_test "Error handling - missing TODO file" \
    "setup_no_todo_file && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' 2>/dev/null && \
    [ \$? -eq 0 ]"

# Test 20: Error: Malformed TODO file
run_test "Error handling - malformed TODO file" \
    "setup_malformed_todo && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' 2>/dev/null && \
    [ \$? -eq 0 ]"

# Test 21: Error: Invalid task ID format in TODO
run_test "Error handling - invalid task ID format" \
    "setup_invalid_todo && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' 2>/dev/null && \
    [ \$? -eq 0 ]"

# Test 22: Empty TODO file
run_test "Empty TODO file returns empty" \
    "setup_empty_todo && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '^$' || \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | wc -l | grep -q '^0$'"

# Test 23: Task 0006 with dependencies
run_test "Task 0006 handled correctly" \
    "setup_task_0006 && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0006$'"

# Test 24: Multiple spaces in task lines
run_test "Handles multiple spaces in task lines" \
    "cat > ${TEST_DIR}/TODO.md << 'EOF'
- [ ]  0001  :  Task 0001  
- [ ]  0002  :  Task 0002  
EOF
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0001$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0002$'"

# Test 25: Task numbers not sequential
run_test "Handles non-sequential task numbers" \
    "cat > ${TEST_DIR}/TODO.md << 'EOF'
- [ ] 0100: Task 0100
- [ ] 0200: Task 0200
- [ ] 0300: Task 0300
EOF
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0100$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0200$' && \
    bash -c 'source ${SCRIPT_SOURCE} && deps_get_incomplete_tasks ${TEST_DIR}/TODO.md' | grep -q '0300$'"

# Print summary
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Total Tests: ${TOTAL_TESTS}"
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi
