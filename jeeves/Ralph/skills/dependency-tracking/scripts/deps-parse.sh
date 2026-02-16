#!/bin/bash
#
# deps-parse.sh - Dependency graph parsing utilities
#
# Description: Parses deps-tracker.yaml and provides dependency query functions
#
# Functions:
#   deps_get_dependencies(task_id) - Get direct dependencies
#   deps_get_blocked(task_id) - Get blocked tasks  
#   deps_is_unblocked(task_id, completed_tasks) - Check if unblocked
#
# Usage:
#   source deps-parse.sh                    # Use functions in other scripts
#   ./deps-parse.sh --get-dependencies 0001 # CLI mode
#
# Environment:
#   DEPS_FILE - Path to deps-tracker.yaml (default: .ralph/tasks/deps-tracker.yaml)
#
# Dependencies: yq
#

DEPS_FILE="${DEPS_FILE:-.ralph/tasks/deps-tracker.yaml}"

# Validate task ID format (must be 4 digits)
# Args:
#   $1 - Task ID to validate
# Returns:
#   0 if valid, 1 if invalid
deps_ensure_valid_task_id() {
    local task_id="$1"
    if [[ ! "$task_id" =~ ^[0-9]{4}$ ]]; then
        echo "Error: Invalid task ID format '$task_id'. Expected 4-digit format (e.g., '0001')" >&2
        return 1
    fi
    return 0
}

# Check if deps file exists
# Returns:
#   0 if file exists, 1 if not
deps_ensure_deps_file_exists() {
    if [[ ! -f "$DEPS_FILE" ]]; then
        echo "Error: Dependencies file '$DEPS_FILE' not found" >&2
        return 1
    fi
    return 0
}

# Convert task ID to numeric value (removes leading zeros)
# Args:
#   $1 - Task ID (4-digit format)
# Returns:
#   Numeric value of task ID
deps_task_id_to_number() {
    local task_id="$1"
    echo $((10#$task_id))
}

# Get direct dependencies for a task
# Args:
#   $1 - Task ID (4-digit format, e.g., "0001")
# Returns:
#   List of dependency task IDs (space-separated), or empty if none
# Exit codes:
#   0 - Success (even if no dependencies)
deps_get_dependencies() {
    local task_id="$1"
    
    deps_ensure_valid_task_id "$task_id" || return 0
    deps_ensure_deps_file_exists || return 0
    
    local task_num
    task_num=$(deps_task_id_to_number "$task_id")
    
    local result
    result=$(yq -r ".tasks | to_entries[] | select(.key == \"$task_id\" or .key == \"$task_num\") | .value.depends_on // [] | .[]" "$DEPS_FILE" 2>/dev/null | while read -r dep; do
        if [[ -n "$dep" ]]; then
            printf "%04d " "$dep"
        fi
    done)
    
    result="${result% }"
    [[ -n "$result" ]] && echo "$result"
    return 0
}

# Get tasks blocked by a given task
# Args:
#   $1 - Task ID (4-digit format, e.g., "0001")
# Returns:
#   List of blocked task IDs (space-separated), or empty if none
# Exit codes:
#   0 - Success (even if no blocked tasks)
deps_get_blocked() {
    local task_id="$1"
    
    deps_ensure_valid_task_id "$task_id" || return 0
    deps_ensure_deps_file_exists || return 0
    
    local task_num
    task_num=$(deps_task_id_to_number "$task_id")
    
    local result
    result=$(yq -r ".tasks | to_entries[] | select(.key == \"$task_id\" or .key == \"$task_num\") | .value.blocks // [] | .[]" "$DEPS_FILE" 2>/dev/null | while read -r blocked; do
        if [[ -n "$blocked" ]]; then
            printf "%04d " "$blocked"
        fi
    done)
    
    result="${result% }"
    [[ -n "$result" ]] && echo "$result"
    return 0
}

# Check if a task is unblocked (all dependencies completed)
# Args:
#   $1 - Task ID (4-digit format, e.g., "0001")
#   $2 - Space-separated list of completed task IDs (optional)
# Returns:
#   0 if task is unblocked, 1 otherwise
deps_is_unblocked() {
    local task_id="$1"
    local completed_tasks="${2:-}"
    local dependencies=""
    local dep=""
    
    deps_ensure_valid_task_id "$task_id" || return 1
    deps_ensure_deps_file_exists || return 1
    
    local task_num
    task_num=$(deps_task_id_to_number "$task_id")
    
    # Check if task exists
    local task_exists
    task_exists=$(yq -r ".tasks | to_entries[] | select(.key == \"$task_id\" or .key == \"$task_num\") | .value.depends_on // [] | length" "$DEPS_FILE" 2>/dev/null)
    
    if [[ -z "$task_exists" ]]; then
        return 1
    fi
    
    dependencies=$(deps_get_dependencies "$task_id")
    
    if [[ -z "$dependencies" ]]; then
        return 0
    fi
    
    for dep in $dependencies; do
        if [[ ! " $completed_tasks " =~ " $dep " ]]; then
            return 1
        fi
    done
    
    return 0
}

# Display usage information
deps_print_usage() {
    echo "Usage: $0 --get-dependencies <task_id> | --get-blocked <task_id> | --is-unblocked <task_id> [completed_tasks]"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --get-dependencies)
            deps_get_dependencies "${2:-}"
            ;;
        --get-blocked)
            deps_get_blocked "${2:-}"
            ;;
        --is-unblocked)
            deps_is_unblocked "${2:-}" "${3:-}"
            exit $?
            ;;
        *)
            deps_print_usage
            exit 1
            ;;
    esac
fi
