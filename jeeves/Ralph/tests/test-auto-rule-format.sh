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

test_auto_rule_format() {
    local -r template_path="$1"
    local -r auto_rule_pattern="$2"
    local -r description="$3"
    
    if grep -q "$auto_rule_pattern" "$template_path"; then
        log_info "Test PASSED: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_auto_rule_not_exists() {
    local -r template_path="$1"
    local -r auto_rule_pattern="$2"
    local -r description="$3"
    
    if ! grep -q "$auto_rule_pattern" "$template_path"; then
        log_info "Test PASSED: $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_context_rule_fields() {
    local -r template_path="$1"
    
    local has_context=0
    local has_rule=0
    local has_example=0
    local has_timestamp=0
    local has_task_id=0
    
    if grep -q "^  Context:" "$template_path"; then
        has_context=1
    fi
    
    if grep -q "^  Rule:" "$template_path"; then
        has_rule=1
    fi
    
    if grep -q "^  Example:" "$template_path"; then
        has_example=1
    fi
    
    if grep -qE "AUTO \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]" "$template_path"; then
        has_timestamp=1
    fi
    
    if grep -qE "AUTO \[.*\]\[task-[0-9]{4}\]:" "$template_path"; then
        has_task_id=1
    fi
    
    local total=0
    local passed=0
    
    total=5
    
    if [[ $has_context -eq 1 ]]; then
        log_info "Test PASSED: Context field exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        passed=$((passed + 1))
    else
        log_error "Test FAILED: Context field not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if [[ $has_rule -eq 1 ]]; then
        log_info "Test PASSED: Rule field exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        passed=$((passed + 1))
    else
        log_error "Test FAILED: Rule field not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if [[ $has_example -eq 1 ]]; then
        log_info "Test PASSED: Example field exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        passed=$((passed + 1))
    else
        log_error "Test FAILED: Example field not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if [[ $has_timestamp -eq 1 ]]; then
        log_info "Test PASSED: Timestamp in YYYY-MM-DD format exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        passed=$((passed + 1))
    else
        log_error "Test FAILED: Timestamp in YYYY-MM-DD format not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    if [[ $has_task_id -eq 1 ]]; then
        log_info "Test PASSED: Task ID reference exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        passed=$((passed + 1))
    else
        log_error "Test FAILED: Task ID reference not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    return 0
}

test_example_count() {
    local -r template_path="$1"
    local -r min_examples="$2"
    
    local example_count
    example_count=$(grep -cE "^AUTO \[.*\]\[task-[0-9]{4}\]:" "$template_path" || true)
    
    if [[ $example_count -ge $min_examples ]]; then
        log_info "Test PASSED: At least $min_examples auto-rules exist (found: $example_count)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "Test FAILED: Expected at least $min_examples auto-rules, found: $example_count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_format_documentation() {
    local -r template_path="$1"
    
    if grep -q "^## Auto-Discovered Patterns" "$template_path"; then
        if grep -q "Format Specification" "$template_path"; then
            if grep -q "AUTO \[YYYY-MM-DD\]\[task-XXXX\]:" "$template_path"; then
                log_info "Test PASSED: Auto-rule format documented in template"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            fi
        fi
    fi
    
    log_error "Test FAILED: Auto-rule format not documented in template"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
}

main() {
    log_info "Starting Auto-Rule Format tests..."
    
    local -r TEMPLATE_PATH="/proj/jeeves/Ralph/templates/RULES.md.template"
    
    if [[ ! -f "$TEMPLATE_PATH" ]]; then
        log_error "Template not found at $TEMPLATE_PATH"
        exit 1
    fi
    
    test_auto_rule_format "$TEMPLATE_PATH" 'AUTO \[' "Auto-rule format is grep-friendly (AUTO [ pattern)"
    
    test_context_rule_fields "$TEMPLATE_PATH"
    
    test_example_count "$TEMPLATE_PATH" 3
    
    test_format_documentation "$TEMPLATE_PATH"
    
    test_auto_rule_format "$TEMPLATE_PATH" "^  Context:" "Context line is properly formatted"
    test_auto_rule_format "$TEMPLATE_PATH" "^  Rule:" "Rule line is properly formatted"
    test_auto_rule_format "$TEMPLATE_PATH" "^  Example:" "Example line is properly formatted"
    
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
