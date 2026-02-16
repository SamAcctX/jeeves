#!/bin/bash
set -Eeuo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd -- "$TEST_DIR/../../.." && pwd -P)"

SCRIPT_UNDER_TEST="$PROJECT_ROOT/jeeves/bin/apply-rules.sh"

if [[ ! -f "$SCRIPT_UNDER_TEST" ]]; then
    echo "ERROR: Script under test not found: $SCRIPT_UNDER_TEST"
    exit 1
fi

source "$SCRIPT_UNDER_TEST"

TESTS_PASSED=0
TESTS_FAILED=0

cleanup_tmpdir() {
    if [[ -n "${tmpdir:-}" && -d "$tmpdir" ]]; then
        rm -rf -- "$tmpdir"
    fi
}

test_extract_section_code_patterns() {
    local test_name="test_extract_section_code_patterns"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    cat > "$tmpdir/RULES.md" << 'EOF'
# Project Rules

## Code Patterns
- Pattern 1: Use snake_case for functions
- Pattern 2: Always quote variables

## Common Pitfalls
- Pitfall 1: Forgetting to quote variables

## Standard Approaches
- Approach 1: Use set -e for error handling
EOF
    
    local result
    result=$(extract_section "$tmpdir/RULES.md" "Code Patterns")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"- Pattern 1: Use snake_case for functions"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected to contain: - Pattern 1: Use snake_case for functions"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_extract_section_common_pitfalls() {
    local test_name="test_extract_section_common_pitfalls"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    cat > "$tmpdir/RULES.md" << 'EOF'
# Project Rules

## Code Patterns
- Pattern 1: Use snake_case

## Common Pitfalls
- Pitfall 1: Forgetting to quote variables
- Pitfall 2: Not using set -e

## Standard Approaches
- Approach 1: Use error handling
EOF
    
    local result
    result=$(extract_section "$tmpdir/RULES.md" "Common Pitfalls")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"- Pitfall 1: Forgetting to quote variables"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected to contain: - Pitfall 1: Forgetting to quote variables"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_extract_section_standard_approaches() {
    local test_name="test_extract_section_standard_approaches"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    cat > "$tmpdir/RULES.md" << 'EOF'
# Project Rules

## Code Patterns
- Pattern 1: Use snake_case

## Common Pitfalls
- Pitfall 1: Forgetting to quote

## Standard Approaches
- Approach 1: Use set -e
- Approach 2: Use trap for cleanup
EOF
    
    local result
    result=$(extract_section "$tmpdir/RULES.md" "Standard Approaches")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"- Approach 2: Use trap for cleanup"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected to contain: - Approach 2: Use trap for cleanup"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_extract_section_not_found() {
    local test_name="test_extract_section_not_found"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    cat > "$tmpdir/RULES.md" << 'EOF'
# Project Rules

## Code Patterns
- Pattern 1: Use snake_case
EOF
    
    local result
    result=$(extract_section "$tmpdir/RULES.md" "NonExistent Section")
    
    cleanup_tmpdir
    
    if [[ -z "$result" ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected: empty"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_deeper_rules_override_parent() {
    local test_name="test_deeper_rules_override_parent"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/parent/child"
    
    cat > "$tmpdir/parent/RULES.md" << 'EOF'
# Parent Rules

## Code Patterns
- Pattern A: Parent pattern (should be overridden)
EOF
    
    cat > "$tmpdir/parent/child/RULES.md" << 'EOF'
# Child Rules

## Code Patterns
- Pattern B: Child pattern (should win)
EOF
    
    local rules_files="$tmpdir/parent/child/RULES.md $tmpdir/parent/RULES.md"
    local result
    result=$(apply_rules "$rules_files")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"Pattern B: Child pattern"* ]] && [[ "$result" != *"Pattern A: Parent pattern"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected child pattern to override parent"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_merge_non_conflicting_rules() {
    local test_name="test_merge_non_conflicting_rules"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/parent/child"
    
    cat > "$tmpdir/parent/RULES.md" << 'EOF'
# Parent Rules

## Code Patterns
- Pattern A: Parent pattern

## Common Pitfalls
- Pitfall A: Parent pitfall

## Standard Approaches
- Approach A: Parent approach
EOF
    
    cat > "$tmpdir/parent/child/RULES.md" << 'EOF'
# Child Rules

## Code Patterns
- Pattern B: Child pattern

## Common Pitfalls
- Pitfall B: Child pitfall

## Standard Approaches
- Approach B: Child approach
EOF
    
    local rules_files="$tmpdir/parent/child/RULES.md $tmpdir/parent/RULES.md"
    local result
    result=$(apply_rules "$rules_files")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"Pattern B: Child pattern"* ]] && [[ "$result" != *"Pattern A: Parent pattern"* ]] && [[ "$result" == *"Pitfall B: Child pitfall"* ]] && [[ "$result" == *"Approach B: Child approach"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected child rules to override parent rules in all sections"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_logging_which_files_applied() {
    local test_name="test_logging_which_files_applied"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/parent/child"
    
    cat > "$tmpdir/parent/RULES.md" << 'EOF'
# Parent Rules

## Code Patterns
- Pattern A: From parent
EOF
    
    cat > "$tmpdir/parent/child/RULES.md" << 'EOF'
# Child Rules

## Code Patterns
- Pattern B: From child
EOF
    
    local rules_files="$tmpdir/parent/child/RULES.md $tmpdir/parent/RULES.md"
    local result
    result=$(apply_rules "$rules_files")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"Loading rules from: $tmpdir/parent/child/RULES.md"* ]] && [[ "$result" == *"Loading rules from: $tmpdir/parent/RULES.md"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected to log which files were loaded"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_output_format() {
    local test_name="test_output_format"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    cat > "$tmpdir/RULES.md" << 'EOF'
# Rules

## Code Patterns
- Test pattern

## Common Pitfalls
- Test pitfall

## Standard Approaches
- Test approach
EOF
    
    local rules_files="$tmpdir/RULES.md"
    local result
    result=$(apply_rules "$rules_files")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"CODE_PATTERNS:"* ]] && [[ "$result" == *"COMMON_PITFALLS:"* ]] && [[ "$result" == *"STANDARD_APPROACHES:"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected proper output format with all three sections"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

test_three_level_hierarchy() {
    local test_name="test_three_level_hierarchy"
    local tmpdir=""
    
    tmpdir=$(mktemp -d) || { echo "FAILED: $test_name - could not create temp dir"; ((TESTS_FAILED++)) || true; return 1; }
    
    mkdir -p "$tmpdir/level1/level2/level3"
    
    cat > "$tmpdir/level1/RULES.md" << 'EOF'
# Level 1 Rules

## Code Patterns
- Pattern Level 1 (should be overridden)
EOF
    
    cat > "$tmpdir/level1/level2/RULES.md" << 'EOF'
# Level 2 Rules

## Code Patterns
- Pattern Level 2 (should be overridden)
EOF
    
    cat > "$tmpdir/level1/level2/level3/RULES.md" << 'EOF'
# Level 3 Rules

## Code Patterns
- Pattern Level 3 (should win)
EOF
    
    local rules_files="$tmpdir/level1/level2/level3/RULES.md $tmpdir/level1/level2/RULES.md $tmpdir/level1/RULES.md"
    local result
    result=$(apply_rules "$rules_files")
    
    cleanup_tmpdir
    
    if [[ "$result" == *"Pattern Level 3"* ]] && [[ "$result" != *"Pattern Level 1"* ]] && [[ "$result" != *"Pattern Level 2"* ]]; then
        echo "PASSED: $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "FAILED: $test_name"
        echo "  Expected Level 3 pattern to override others"
        echo "  Got: $result"
        ((TESTS_FAILED++)) || true
    fi
}

echo "Running Hierarchical Rule Application tests..."
echo "=============================================="

test_extract_section_code_patterns
test_extract_section_common_pitfalls
test_extract_section_standard_approaches
test_extract_section_not_found
test_deeper_rules_override_parent
test_merge_non_conflicting_rules
test_logging_which_files_applied
test_output_format
test_three_level_hierarchy

echo "=============================================="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi

exit 0
