#!/bin/bash
#
# deps-cycle.sh - Circular dependency detection
#
# Description: Detects circular dependencies in deps-tracker.yaml
#
# Functions:
#   deps_detect_cycle(task_id) - Detect cycles using DFS
#   deps_validate_graph() - Check entire graph for cycles
#
# Usage:
#   source deps-parse.sh
#   source deps-cycle.sh
#   deps_detect_cycle 0001
#   deps_validate_graph
#
# CLI:
#   ./deps-cycle.sh --detect-cycle 0001
#   ./deps-cycle.sh --validate-graph
#
# Exit codes:
#   0 - Cycle(s) found
#   1 - No cycles found / General error
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deps-parse.sh"

# Check if task is in the space-separated list
# Args:
#   $1 - Task to find
#   $2 - List of tasks (space-separated)
# Returns:
#   0 if found, 1 if not found
task_in_list() {
    local task="$1"
    local list="$2"
    echo "$list" | grep -qw "$task"
}

# Detect cycle using Depth First Search
# Args:
#   $1 - Task ID to start from (4-digit format)
#   $2 - (internal) visited tasks (space-separated)
#   $3 - (internal) recursion stack (space-separated)
#   $4 - (internal) current path
# Returns:
#   Outputs cycle path if found to stdout
# Exit codes:
#   0 - Cycle detected
#   1 - No cycle / Error
deps_detect_cycle() {
    local task_id="$1"
    local visited="${2:-}"
    local rec_stack="${3:-}"
    local path="${4:-}"

    # Check if deps file exists
    if ! deps_ensure_deps_file_exists 2>/dev/null; then
        echo "Error: Dependencies file not found: $DEPS_FILE" >&2
        return 1
    fi

    # Check if current task is in recursion stack (cycle detected)
    if task_in_list "$task_id" "$rec_stack"; then
        if [ -n "$path" ]; then
            echo "$path -> $task_id"
        else
            echo "$task_id"
        fi
        return 0
    fi

    # Skip if already fully visited (no cycle from this node)
    if task_in_list "$task_id" "$visited"; then
        return 1
    fi

    # Mark as visited and add to recursion stack
    visited="$visited $task_id"
    rec_stack="$rec_stack $task_id"

    # Get dependencies (dependencies that this task depends on)
    local deps
    deps=$(deps_get_dependencies "$task_id")

    if [ -z "$deps" ]; then
        return 1
    fi

    # Recursively check each dependency
    for dep in $deps; do
        local new_path
        if [ -n "$path" ]; then
            new_path="$path -> $task_id"
        else
            new_path="$task_id"
        fi
        if deps_detect_cycle "$dep" "$visited" "$rec_stack" "$new_path"; then
            return 0
        fi
    done

    return 1
}

# Validate entire graph for cycles
# Checks all tasks in the graph to detect any cycles
# Returns:
#   Exit code 0 if any cycle found, 1 if no cycles
deps_validate_graph() {
    # Check if deps file exists
    if ! deps_ensure_deps_file_exists 2>/dev/null; then
        echo "Error: Dependencies file not found: $DEPS_FILE" >&2
        return 1
    fi

    # Get all task IDs from graph
    local tasks
    tasks=$(yq -r '.tasks | keys | .[]' "$DEPS_FILE" 2>/dev/null)

    if [ -z "$tasks" ]; then
        return 1
    fi

    # Check each task for cycles
    for task in $tasks; do
        local formatted_task
        formatted_task=$(printf "%04d" "$task")
        if deps_detect_cycle "$formatted_task"; then
            return 0
        fi
    done

    return 1
}

# CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --detect-cycle)
            deps_detect_cycle "${2:-}"
            exit $?
            ;;
        --validate-graph)
            deps_validate_graph
            exit $?
            ;;
        *)
            echo "Usage: $0 --detect-cycle <task_id>|--validate-graph" >&2
            exit 1
            ;;
    esac
fi
