#!/bin/bash
set -Eeuo pipefail

has_ignore_parent_rules() {
    local rules_file="$1"
    
    if [[ ! -f "$rules_file" ]]; then
        return 1
    fi
    
    grep -v "^[[:space:]]*#" "$rules_file" 2>/dev/null | grep -q "^[[:space:]]*IGNORE_PARENT_RULES[[:space:]]*$"
    return $?
}

find_rules_files() {
    local current_dir="${1:-$(pwd)}"
    local rules_files=""
    local first=true
    
    while true; do
        if [[ -f "$current_dir/RULES.md" ]]; then
            if [[ "$first" == "true" ]]; then
                rules_files="$current_dir/RULES.md"
                first=false
            else
                rules_files="$rules_files $current_dir/RULES.md"
            fi
            
            if has_ignore_parent_rules "$current_dir/RULES.md"; then
                break
            fi
        fi
        
        if [[ -d "$current_dir/.ralph" ]] || [[ -d "$current_dir/.git" ]]; then
            break
        fi
        
        local parent
        parent=$(dirname "$current_dir")
        if [[ "$parent" == "$current_dir" ]]; then
            break
        fi
        current_dir="$parent"
    done
    
    echo "$rules_files"
}
