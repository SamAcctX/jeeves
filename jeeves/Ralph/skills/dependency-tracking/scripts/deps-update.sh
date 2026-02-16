#!/bin/bash
#
# deps-update.sh - Runtime dependency updates
#
# Functions:
#   deps_add_dependency(from_task, to_task) - Add dependency relationship
#   deps_remove_dependency(from_task, to_task) - Remove dependency
#
# Usage:
#   source deps-update.sh
#   deps_add_dependency 0001 0002
#
# CLI:
#   ./deps-update.sh --add-dependency 0001 0002
#   ./deps-update.sh --remove-dependency 0001 0002
#
# Exit codes:
#   0 - Success
#   1 - General error
#   4 - Invalid task ID format
#   5 - Task not found
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deps-parse.sh"

DEPS_FILE="${DEPS_FILE:-.ralph/tasks/deps-tracker.yaml}"

# Check if task exists in deps file
_task_exists_in_deps() {
    local task_id="$1"
    local task_num
    task_num=$(echo "$task_id" | sed 's/^0*//')
    [[ -z "$task_num" ]] && task_num="0"
    
    local exists
    exists=$(yq -r ".tasks | to_entries[] | select(.key == \"$task_id\" or .key == \"$task_num\") | .key" "$DEPS_FILE" 2>/dev/null)
    [[ -n "$exists" ]]
}

# Add dependency relationship
# Args:
#   $1 - from_task (task that depends on $2)
#   $2 - to_task (task being depended on)
# Returns:
#   Exit 0 on success, 4 for invalid format, 5 for task not found
deps_add_dependency() {
    local from_task="$1" to_task="$2"
    local backup_file="${DEPS_FILE}.bak"
    
    # Validate task IDs - exit code 4 for invalid format
    if [[ ! "$from_task" =~ ^[0-9]{4}$ ]]; then
        echo "Invalid from_task: $from_task" >&2
        return 4
    fi
    if [[ ! "$to_task" =~ ^[0-9]{4}$ ]]; then
        echo "Invalid to_task: $to_task" >&2
        return 4
    fi
    
    # Check file exists
    if [[ ! -f "$DEPS_FILE" ]]; then
        echo "deps file not found: $DEPS_FILE" >&2
        return 1
    fi
    
    # Check if tasks exist - exit code 5 for not found
    if ! _task_exists_in_deps "$from_task"; then
        echo "Task not found: $from_task" >&2
        return 5
    fi
    if ! _task_exists_in_deps "$to_task"; then
        echo "Task not found: $to_task" >&2
        return 5
    fi
    
    # Create backup
    cp "$DEPS_FILE" "$backup_file"
    
    # Check if already exists (exactly matches to_task)
    local current_deps
    current_deps=$(yq -r ".tasks.\"$from_task\".depends_on // []" "$DEPS_FILE" 2>/dev/null)
    
    if [[ "$current_deps" == "[$to_task]" ]]; then
        rm -f "$backup_file"
        return 0
    fi
    
    # Set depends_on to exactly [to_task] (replace)
    yq -i ".tasks.\"$from_task\".depends_on = [\"$to_task\"]" "$DEPS_FILE" 2>/dev/null
    
    # Add to blocks (bidirectional)
    local blocks_array
    blocks_array=$(yq -r ".tasks.\"$to_task\".blocks // []" "$DEPS_FILE" 2>/dev/null)
    if [[ "$blocks_array" == "[]" ]] || [[ -z "$blocks_array" ]]; then
        yq -i ".tasks.\"$to_task\".blocks = [\"$from_task\"]" "$DEPS_FILE" 2>/dev/null
    else
        yq -i ".tasks.\"$to_task\".blocks += [\"$from_task\"]" "$DEPS_FILE" 2>/dev/null
    fi
    
    rm -f "$backup_file"
    return 0
}

# Remove dependency relationship
# Args:
#   $1 - from_task
#   $2 - to_task
deps_remove_dependency() {
    local from_task="$1" to_task="$2"
    local backup_file="${DEPS_FILE}.bak"
    
    [[ "$from_task" =~ ^[0-9]{4}$ ]] || return 1
    [[ "$to_task" =~ ^[0-9]{4}$ ]] || return 1
    [[ -f "$DEPS_FILE" ]] || return 1
    
    cp "$DEPS_FILE" "$backup_file"
    
    # Remove from depends_on
    yq -i ".tasks.\"$from_task\".depends_on -= [\"$to_task\"]" "$DEPS_FILE" 2>/dev/null
    
    # Remove from blocks
    yq -i ".tasks.\"$to_task\".blocks -= [\"$from_task\"]" "$DEPS_FILE" 2>/dev/null
    
    rm -f "$backup_file"
    return 0
}

# CLI
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --add-dependency)
            deps_add_dependency "$2" "$3"
            ;;
        --remove-dependency)
            deps_remove_dependency "$2" "$3"
            ;;
        *)
            echo "Usage: $0 --add-dependency <from> <to>"
            echo "       $0 --remove-dependency <from> <to>"
            exit 1
            ;;
    esac
fi
