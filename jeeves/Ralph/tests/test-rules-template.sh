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

test_template_exists() {
    local -r template_path="$1"
    
    if [[ -f "$template_path" ]]; then
        log_info "Test PASSED: Template exists at $template_path"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Template not found at $template_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

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

test_token_exists() {
    local -r template_path="$1"
    local -r token="$2"
    
    if grep -q "$token" "$template_path"; then
        log_info "Test PASSED: Token '$token' exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Token '$token' not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_example_exists() {
    local -r template_path="$1"
    local -r section="$2"
    
    local section_start
    section_start=$(grep -n "^## $section" "$template_path" | head -1 | cut -d: -f1)
    
    if [[ -z "$section_start" ]]; then
        log_error "Test FAILED: Section '$section' not found for example check"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    local remaining_lines
    remaining_lines=$(($(wc -l < "$template_path") - section_start + 1))
    
    if tail -n +"$section_start" "$template_path" | head -n "$remaining_lines" | grep -qE "^### [A-Za-z]"; then
        log_info "Test PASSED: Example exists in section '$section'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: No example found in section '$section'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

main() {
    log_info "Starting RULES.md template tests..."
    
    local -r TEMPLATE_PATH="/proj/jeeves/Ralph/templates/RULES.md.template"
    
    test_template_exists "$TEMPLATE_PATH"
    
    test_section_exists "$TEMPLATE_PATH" "Code Patterns"
    test_section_exists "$TEMPLATE_PATH" "Common Pitfalls"
    test_section_exists "$TEMPLATE_PATH" "Standard Approaches"
    test_section_exists "$TEMPLATE_PATH" "Auto-Discovered Patterns"
    
    test_token_exists "$TEMPLATE_PATH" "IGNORE_PARENT_RULES"
    
    test_example_exists "$TEMPLATE_PATH" "Code Patterns"
    test_example_exists "$TEMPLATE_PATH" "Common Pitfalls"
    test_example_exists "$TEMPLATE_PATH" "Standard Approaches"
    
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
