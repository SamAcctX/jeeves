#!/bin/bash
#
# deps-select.sh - Unblocked task selection utilities
#
# Description: Provides functions for selecting unblocked tasks from TODO.md
#              based on dependency relationships in deps-tracker.yaml
#
# Functions:
#   deps_get_incomplete_tasks([todo_file]) - Get incomplete task IDs
#   deps_get_completed_tasks([todo_file]) - Get completed task IDs
#   deps_find_unblocked_tasks([todo_file]) - Find unblocked tasks
#   deps_select_next_task([todo_file]) - Select next task
#
# Usage:
#   source deps-select.sh
#   deps_select_next_task
#   deps_find_unblocked_tasks
#
# CLI:
#   ./deps-select.sh --get-incomplete
#   ./deps-select.sh --get-completed
#   ./deps-select.sh --find-unblocked
#   ./deps-select.sh --select-next
#
# Environment:
#   TODO_FILE - Path to TODO.md (default: .ralph/tasks/TODO.md)
#
# Dependencies: deps-parse.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deps-parse.sh"

# Get incomplete tasks from TODO.md
# Args:
#   $1 - Optional: TODO file path (default: .ralph/tasks/TODO.md)
# Returns:
#   List of incomplete task IDs (one per line)
deps_get_incomplete_tasks() {
    local todo_file="${1:-.ralph/tasks/TODO.md}"
    grep -E '^- \[ \]' "$todo_file" 2>/dev/null | sed -E 's/^- \[ \]  *([0-9]{4})  *:.*/\1/' | sort
}

# Get completed tasks from TODO.md
# Args:
#   $1 - Optional: TODO file path (default: .ralph/tasks/TODO.md)
# Returns:
#   List of completed task IDs (one per line)
deps_get_completed_tasks() {
    local todo_file="${1:-.ralph/tasks/TODO.md}"
    grep -E '^- \[x\]' "$todo_file" 2>/dev/null | sed -E 's/^- \[x\]  *([0-9]{4})  *:.*/\1/' | sort
}

# Find unblocked tasks (tasks with all dependencies completed)
# Args:
#   $1 - Optional: TODO file path (default: .ralph/tasks/TODO.md)
# Returns:
#   List of unblocked task IDs (one per line)
deps_find_unblocked_tasks() {
    local todo_file="${1:-.ralph/tasks/TODO.md}"
    local completed_tasks
    completed_tasks=$(deps_get_completed_tasks "$todo_file" | tr '\n' ' ')
    
    for task in $(deps_get_incomplete_tasks "$todo_file"); do
        if _deps_is_unblocked "$task" "$completed_tasks" "$todo_file"; then
            echo "$task"
        fi
    done
}

_deps_is_unblocked() {
    local task_id="$1"
    local completed_tasks="${2:-}"
    local todo_file="${3:-.ralph/tasks/TODO.md}"
    local dependencies=""
    local dep=""
    local local_deps_file=""
    local old_deps_file=""
    local task_exists=""
    
    deps_ensure_valid_task_id "$task_id" || return 1
    
    # Try to find local deps-tracker.yaml in same directory as TODO_FILE
    local todo_dir
    todo_dir="$(dirname "$todo_file")"
    local local_deps="$todo_dir/deps-tracker.yaml"
    
    if [[ -f "$local_deps" ]]; then
        local_deps_file="$local_deps"
    elif [[ -f "${DEPS_FILE:-.ralph/tasks/deps-tracker.yaml}" ]]; then
        local_deps_file="${DEPS_FILE:-.ralph/tasks/deps-tracker.yaml}"
    else
        # No deps file - all tasks are unblocked
        return 0
    fi
    
    old_deps_file="$DEPS_FILE"
    DEPS_FILE="$local_deps_file"
    
    local task_num
    task_num=$(deps_task_id_to_number "$task_id")
    
    task_exists=$(yq -r ".tasks | to_entries[] | select(.key == \"$task_id\" or .key == \"$task_num\") | .value.depends_on // [] | length" "$local_deps_file" 2>/dev/null)
    
    if [[ -z "$task_exists" ]]; then
        # Task not found in deps file - assume unblocked
        DEPS_FILE="$old_deps_file"
        return 0
    fi
    
    dependencies=$(deps_get_dependencies "$task_id")
    
    DEPS_FILE="$old_deps_file"
    
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

# Select next task (first unblocked task)
# Args:
#   $1 - Optional: TODO file path (default: .ralph/tasks/TODO.md)
# Returns:
#   Single task ID of first unblocked task, or empty if none
deps_select_next_task() {
    local todo_file="${1:-.ralph/tasks/TODO.md}"
    deps_find_unblocked_tasks "$todo_file" | head -1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --get-incomplete)
            shift
            deps_get_incomplete_tasks "$@"
            ;;
        --get-completed)
            shift
            deps_get_completed_tasks "$@"
            ;;
        --find-unblocked)
            shift
            deps_find_unblocked_tasks "$@"
            ;;
        --select-next)
            shift
            deps_select_next_task "$@"
            ;;
        *)
            echo "Usage: $0 --get-incomplete|--get-completed|--find-unblocked|--select-next"
            ;;
    esac
fi
