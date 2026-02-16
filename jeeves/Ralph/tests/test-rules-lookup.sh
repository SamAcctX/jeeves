#!/bin/bash
set -Eeuo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$TEST_DIR/../../.." && pwd -P)"

SCRIPT_UNDER_TEST="$PROJECT_ROOT/jeeves/bin/find-rules-files.sh"

source "$SCRIPT_UNDER_TEST"

TESTS_PASSED=0
TESTS_FAILED=0

cleanup_tmpdir() {
    if [[ -n "${tmpdir:-}" && -d "$tmpdir" ]]; then
        rm -rf -- "$tmpdir"
    fi
}

test_find_rules_files_upward_traversal() {
    local test_name="test_find_rules_files_upward_traversal"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/level1/level2/level3"
    echo "# Rules Level 3" > "$tmpdir/level1/level2/level3/RULES.md"
    echo "# Rules Level 2" > "$tmpdir/level1/level2/RULES.md"
    echo "# Rules Level 1" > "$tmpdir/level1/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/level1/level2/level3")
    
    local expected="$tmpdir/level1/level2/level3/RULES.md $tmpdir/level1/level2/RULES.md $tmpdir/level1/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_ignore_parent_rules() {
    local test_name="test_ignore_parent_rules"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/child/grandchild"
    echo "# Rules Child" > "$tmpdir/child/RULES.md"
    echo -e "# Rules Grandchild\nIGNORE_PARENT_RULES" > "$tmpdir/child/grandchild/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/child/grandchild")
    
    local expected="$tmpdir/child/grandchild/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_no_rules_md_found() {
    local test_name="test_no_rules_md_found"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/subdir"
    
    local result
    result=$(find_rules_files "$tmpdir/subdir")
    
    local expected=""
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: '$expected'"
        echo "  Got:      '$result'"
        ((TESTS_FAILED++)) || true
    fi
}

test_project_root_detection_ralph() {
    local test_name="test_project_root_detection_ralph"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/project/.ralph"
    mkdir -p "$tmpdir/project/inner"
    echo "# Project Rules" > "$tmpdir/project/RULES.md"
    echo "# Inner Rules" > "$tmpdir/project/inner/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/project/inner")
    
    local expected="$tmpdir/project/inner/RULES.md $tmpdir/project/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_project_root_detection_git() {
    local test_name="test_project_root_detection_git"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/project/.git"
    mkdir -p "$tmpdir/project/inner"
    echo "# Project Rules" > "$tmpdir/project/RULES.md"
    echo "# Inner Rules" > "$tmpdir/project/inner/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/project/inner")
    
    local expected="$tmpdir/project/inner/RULES.md $tmpdir/project/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_default_to_pwd() {
    local test_name="test_default_to_pwd"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/subdir"
    echo "# Root Rules" > "$tmpdir/RULES.md"
    
    local result
    result=$(cd "$tmpdir/subdir" && find_rules_files)
    
    local expected="$tmpdir/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_multiple_rules_at_same_level() {
    local test_name="test_multiple_rules_at_same_level"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/subdir"
    echo "# Root Rules" > "$tmpdir/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/subdir")
    
    local expected="$tmpdir/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_filesystem_root() {
    local test_name="test_filesystem_root"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir"
    
    local result
    result=$(find_rules_files "$tmpdir")
    
    cleanup_tmpdir
    
    if [[ -z "$result" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: empty"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_ignore_parent_rules_with_leading_whitespace() {
    local test_name="test_ignore_parent_rules_with_leading_whitespace"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/child/grandchild"
    echo "# Rules Child" > "$tmpdir/child/RULES.md"
    echo -e "# Rules Grandchild\n  IGNORE_PARENT_RULES" > "$tmpdir/child/grandchild/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/child/grandchild")
    
    local expected="$tmpdir/child/grandchild/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_ignore_parent_rules_with_trailing_whitespace() {
    local test_name="test_ignore_parent_rules_with_trailing_whitespace"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/child/grandchild"
    echo "# Rules Child" > "$tmpdir/child/RULES.md"
    echo -e "# Rules Grandchild\nIGNORE_PARENT_RULES  " > "$tmpdir/child/grandchild/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/child/grandchild")
    
    local expected="$tmpdir/child/grandchild/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_ignore_parent_rules_commented_should_not_stop() {
    local test_name="test_ignore_parent_rules_commented_should_not_stop"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/child/grandchild"
    echo "# Rules Child" > "$tmpdir/child/RULES.md"
    echo -e "# Rules Grandchild\n# IGNORE_PARENT_RULES" > "$tmpdir/child/grandchild/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/child/grandchild")
    
    local expected="$tmpdir/child/grandchild/RULES.md $tmpdir/child/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_ignore_parent_rules_multiple_whitespace_variations() {
    local test_name="test_ignore_parent_rules_multiple_whitespace_variations"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/child/grandchild"
    echo "# Rules Child" > "$tmpdir/child/RULES.md"
    echo -e "# Rules Grandchild\n  \tIGNORE_PARENT_RULES\t  " > "$tmpdir/child/grandchild/RULES.md"
    
    local result
    result=$(find_rules_files "$tmpdir/child/grandchild")
    
    local expected="$tmpdir/child/grandchild/RULES.md"
    
    cleanup_tmpdir
    
    if [[ "$result" == "$expected" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: $expected"
        echo "  Got:      $result"
        ((TESTS_FAILED++)) || true
    fi
}

echo "Running RULES.md lookup algorithm tests..."
echo "=========================================="

test_find_rules_files_upward_traversal
test_ignore_parent_rules
test_no_rules_md_found
test_project_root_detection_ralph
test_project_root_detection_git
test_default_to_pwd
test_multiple_rules_at_same_level
test_filesystem_root
test_ignore_parent_rules_with_leading_whitespace
test_ignore_parent_rules_with_trailing_whitespace
test_ignore_parent_rules_commented_should_not_stop
test_ignore_parent_rules_multiple_whitespace_variations

echo "=========================================="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
