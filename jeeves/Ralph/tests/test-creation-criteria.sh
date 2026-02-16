#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_success() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $*" >&2
}

TESTS_PASSED=0
TESTS_FAILED=0

test_section_exists() {
    local -r template_path="$1"
    local -r section_name="$2"
    
    if grep -q "^## $section_name" "$template_path"; then
        log_info "Test PASSED: Section '$section_name' exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Section '$section_name' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_threshold_exists() {
    local -r template_path="$1"
    local -r threshold_name="$2"
    local -r threshold_value="$3"
    
    if grep -qi "$threshold_value" "$template_path"; then
        log_info "Test PASSED: Threshold '$threshold_name' with value '$threshold_value' exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Threshold '$threshold_name' with value '$threshold_value' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_decision_tree_exists() {
    local -r template_path="$1"
    
    if grep -qE "Working in subdirectory\?" "$template_path"; then
        log_info "Test PASSED: Decision tree exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Decision tree not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_granularity_guidance_exists() {
    local -r template_path="$1"
    
    if grep -qE "module/package boundaries|Don't create RULES.md for every subdirectory" "$template_path"; then
        log_info "Test PASSED: Granularity guidance exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Granularity guidance not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_example_count() {
    local -r template_path="$1"
    local -r section="$2"
    local -r min_count="$3"
    
    local section_start
    section_start=$(grep -n "^## $section" "$template_path" | head -1 | cut -d: -f1)
    
    if [[ -z "$section_start" ]]; then
        log_error "Test FAILED: Section '$section' not found for example count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    local remaining_lines
    remaining_lines=$(($(wc -l < "$template_path") - section_start + 1))
    
    local example_count
    example_count=$(tail -n +"$section_start" "$template_path" | head -n "$remaining_lines" | grep -cE "^#### .+|^### .+\(.+\)|^#### .+\(.+\)")
    
    if [[ $example_count -ge $min_count ]]; then
        log_info "Test PASSED: At least $min_count examples in '$section'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Only $example_count examples found, expected at least $min_count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_child_override_document() {
    local -r template_path="$1"
    
    if grep -qE "child.*override|override.*parent|deepest.*precedence" "$template_path"; then
        log_info "Test PASSED: Child rules override documentation exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Child rules override documentation not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_ignore_parent_usage() {
    local -r template_path="$1"
    
    if grep -qE "IGNORE_PARENT_RULES.*isolated|isolated.*IGNORE_PARENT_RULES" "$template_path"; then
        log_info "Test PASSED: IGNORE_PARENT_RULES usage guidance exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: IGNORE_PARENT_RULES usage guidance not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

main() {
    log_info "Starting RULES.md creation criteria tests..."
    
    local -r TEMPLATE_PATH="/proj/jeeves/Ralph/templates/RULES.md.template"
    
    test_section_exists "$TEMPLATE_PATH" "RULES.md Creation Guidelines"
    
    test_threshold_exists "$TEMPLATE_PATH" "Unique Patterns" "2+ unique patterns"
    test_threshold_exists "$TEMPLATE_PATH" "Parent Overrides" "3+ parent overrides"
    test_threshold_exists "$TEMPLATE_PATH" "File Count" "10+ files"
    test_threshold_exists "$TEMPLATE_PATH" "Cross-Task Occurrences" "3+ cross-task"
    
    test_decision_tree_exists "$TEMPLATE_PATH"
    
    test_granularity_guidance_exists "$TEMPLATE_PATH"
    
    test_child_override_document "$TEMPLATE_PATH"
    
    test_ignore_parent_usage "$TEMPLATE_PATH"
    
    test_example_count "$TEMPLATE_PATH" "RULES.md Creation Guidelines" 2
    
    echo "" >&2
    log_info "========================================="
    log_info "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    log_info "========================================="
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
    
    exit 0
}

main "$@"
