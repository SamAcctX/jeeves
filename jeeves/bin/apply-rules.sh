#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ -f "$SCRIPT_DIR/find-rules-files.sh" ]]; then
    source "$SCRIPT_DIR/find-rules-files.sh"
fi

extract_section() {
    local -r file="$1"
    local -r section_name="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    local in_section=false
    local content=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "## $section_name" ]]; then
            in_section=true
            continue
        fi
        
        if [[ "$in_section" == true ]]; then
            if [[ "$line" =~ ^##\  ]]; then
                break
            fi
            if [[ -n "$line" ]]; then
                content+="$line"$'\n'
            fi
        fi
    done < "$file"
    
    echo "$content"
}

merge_patterns() {
    local -r existing="$1"
    local -r new="$2"
    
    if [[ -z "$new" ]]; then
        echo "$existing"
        return
    fi
    
    echo "$new"
}

merge_pitfalls() {
    local -r existing="$1"
    local -r new="$2"
    
    if [[ -z "$new" ]]; then
        echo "$existing"
        return
    fi
    
    echo "$new"
}

merge_approaches() {
    local -r existing="$1"
    local -r new="$2"
    
    if [[ -z "$new" ]]; then
        echo "$existing"
        return
    fi
    
    echo "$new"
}

apply_rules() {
    local -r rules_files="$1"
    local merged_patterns=""
    local merged_pitfalls=""
    local merged_approaches=""
    
    local -a files_array=()
    while IFS= read -r file; do
        files_array+=("$file")
    done < <(echo "$rules_files" | tr ' ' '\n' | grep -v '^$')
    
    for ((i=${#files_array[@]}-1; i>=0; i--)); do
        local rules_file="${files_array[$i]}"
        
        if [[ -f "$rules_file" ]]; then
            echo "Loading rules from: $rules_file"
            
            local patterns
            patterns=$(extract_section "$rules_file" "Code Patterns")
            local pitfalls
            pitfalls=$(extract_section "$rules_file" "Common Pitfalls")
            local approaches
            approaches=$(extract_section "$rules_file" "Standard Approaches")
            
            merged_patterns=$(merge_patterns "$merged_patterns" "$patterns")
            merged_pitfalls=$(merge_pitfalls "$merged_pitfalls" "$pitfalls")
            merged_approaches=$(merge_approaches "$merged_approaches" "$approaches")
        fi
    done
    
    echo ""
    echo "CODE_PATTERNS:"
    if [[ -n "$merged_patterns" ]]; then
        echo "$merged_patterns"
    else
        echo "(none)"
    fi
    echo ""
    echo "COMMON_PITFALLS:"
    if [[ -n "$merged_pitfalls" ]]; then
        echo "$merged_pitfalls"
    else
        echo "(none)"
    fi
    echo ""
    echo "STANDARD_APPROACHES:"
    if [[ -n "$merged_approaches" ]]; then
        echo "$merged_approaches"
    else
        echo "(none)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -gt 0 ]]; then
        apply_rules "$1"
    else
        echo "Usage: $0 <space-separated-rules-files>"
        exit 1
    fi
fi
