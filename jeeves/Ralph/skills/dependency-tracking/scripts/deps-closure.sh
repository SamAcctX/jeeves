#!/bin/bash
#
# deps-closure.sh - Transitive dependency resolution
#
# Functions:
#   deps_get_all_dependencies(task_id) - Get transitive closure
#   deps_is_fully_unblocked(task_id) - Check transitive dependencies
#   deps_get_dependency_depth(task_id) - Get max depth
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deps-parse.sh"

# Get all dependencies including transitive
# Args:
#   $1 - Task ID
# Returns:
#   List of all dependency IDs (transitive closure)
deps_get_all_dependencies() {
    local task_id="$1"
    local all_deps=""
    local to_process="$task_id"
    local processed=""
    
    while [ -n "$to_process" ]; do
        local current
        current=$(echo "$to_process" | cut -d' ' -f1)
        to_process=$(echo "$to_process" | cut -d' ' -f2-)
        
        if echo "$processed" | grep -qw "$current"; then
            continue
        fi
        processed="$processed $current"
        
        local direct_deps
        direct_deps=$(deps_get_dependencies "$current")
        for dep in $direct_deps; do
            all_deps="$all_deps $dep"
            if ! echo "$processed" | grep -qw "$dep"; then
                to_process="$to_process $dep"
            fi
        done
    done
    
    echo "$all_deps" | tr ' ' '\n' | sort -u | grep -v '^$'
}

# Check if task is fully unblocked (considering transitive deps)
# Args:
#   $1 - Task ID
#   $2 - Completed tasks (space-separated)
deps_is_fully_unblocked() {
    local task_id="$1"
    local completed_tasks="$2"
    local all_deps
    
    all_deps=$(deps_get_all_dependencies "$task_id")
    
    for dep in $all_deps; do
        if ! echo "$completed_tasks" | grep -qw "$dep"; then
            return 1
        fi
    done
    return 0
}

# Get maximum dependency depth
deps_get_dependency_depth() {
    local task_id="$1"
    local max_depth=0
    local all_deps
    
    all_deps=$(deps_get_all_dependencies "$task_id")
    
    # Simple depth calculation - count unique deps
    echo "$all_deps" | wc -l | tr -d ' '
}

# CLI
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --all-dependencies)
            deps_get_all_dependencies "$2"
            ;;
        --is-fully-unblocked)
            deps_is_fully_unblocked "$2" "$3"
            ;;
        --depth)
            deps_get_dependency_depth "$2"
            ;;
        *)
            echo "Usage: $0 --all-dependencies <task>"
            echo "       $0 --is-fully-unblocked <task> <completed>"
            ;;
    esac
fi
