#!/bin/bash
set -Eeuo pipefail

DOCS_FILE="/proj/jeeves/Ralph/docs/rules-system.md"
ERRORS=0

print_error() {
    echo "ERROR: $1" >&2
    ERRORS=$((ERRORS + 1))
}

print_success() {
    echo "SUCCESS: $1"
}

print_info() {
    echo "INFO: $1"
}

echo "=== RULES.md System Documentation Validation ==="
echo ""

if [[ ! -f "$DOCS_FILE" ]]; then
    print_error "Documentation file not found: $DOCS_FILE"
    exit 1
fi

print_success "Documentation file exists: $DOCS_FILE"

REQUIRED_SECTIONS=(
    "Overview"
    "File Format"
    "Lookup Algorithm"
    "Hierarchical Application"
    "IGNORE_PARENT_RULES"
    "Auto-Discovery"
    "Auto-Rule Format"
    "Creation Criteria"
    "Examples"
    "Best Practices"
    "Troubleshooting"
)

print_info "Checking required sections..."
for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "^## $section" "$DOCS_FILE"; then
        print_success "Section found: $section"
    else
        print_error "Section missing: $section"
    fi
done

print_info "Checking for workflow diagram..."
if grep -q "┌\|└\|│" "$DOCS_FILE" || grep -q "ASCII\|text diagram" "$DOCS_FILE"; then
    print_success "Workflow diagram present"
else
    print_error "Workflow diagram not found"
fi

print_info "Checking for troubleshooting section content..."
TROUBLESHOOTING_CONTENT=$(sed -n '/^## Troubleshooting$/,/^## /p' "$DOCS_FILE" 2>/dev/null || echo "")
if [[ ${#TROUBLESHOOTING_CONTENT} -gt 200 ]]; then
    print_success "Troubleshooting section has substantial content"
else
    print_error "Troubleshooting section appears empty or too short"
fi

print_info "Checking for utility links..."
if grep -q "find-rules-files.sh" "$DOCS_FILE" && grep -q "apply-rules.sh" "$DOCS_FILE"; then
    print_success "Utility links present"
else
    print_error "Missing utility links"
fi

print_info "Checking for template reference..."
if grep -q "RULES.md.template" "$DOCS_FILE"; then
    print_success "Template reference present"
else
    print_error "Template reference missing"
fi

print_info "Checking for test file references..."
if grep -q "test-rules" "$DOCS_FILE"; then
    print_success "Test file references present"
else
    print_error "Test file references missing"
fi

print_info "Checking for auto-rule format example..."
if grep -q "AUTO \[YYYY-MM-DD\]\[task-XXXX\]:" "$DOCS_FILE"; then
    print_success "Auto-rule format example present"
else
    print_error "Auto-rule format example missing"
fi

print_info "Checking for IGNORE_PARENT_RULES documentation..."
if grep -q "IGNORE_PARENT_RULES" "$DOCS_FILE"; then
    print_success "IGNORE_PARENT_RULES documented"
else
    print_error "IGNORE_PARENT_RULES not documented"
fi

print_info "Checking for creation criteria..."
if grep -q "2+ Unique Patterns\|3+ Parent Overrides\|10+ Files\|3+ Cross-Task" "$DOCS_FILE"; then
    print_success "Creation criteria documented"
else
    print_error "Creation criteria missing"
fi

echo ""
echo "=== Validation Summary ==="
if [[ $ERRORS -eq 0 ]]; then
    print_success "All validation checks passed!"
    exit 0
else
    print_error "Validation failed with $ERRORS error(s)"
    exit 1
fi
