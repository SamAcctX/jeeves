#!/bin/bash

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# print_info: Print informational message
# Args: Message to display
# expand_path: Expand tilde (~) and environment variables in a path
# Args: Path containing tilde and/or environment variables
# Returns: Fully expanded path
expand_path() {
    local path="$1"

    if [[ "$path" == \~* ]]; then
        path="${path#\~}"
        path="${HOME}${path}"
    fi

    while [[ "$path" =~ \$([A-Za-z_][A-Za-z0-9_]*) ]]; do
        local var_name="${BASH_REMATCH[1]}"
        if [[ -v "${var_name}" ]]; then
            path="${path/\$${var_name}/${!var_name}}"
        else
            path="${path/\$${var_name}/}"
        fi
    done

    echo "$path"
}

# expand_path_all: Expand tilde (~) and all environment variables in a path
# Args: Path containing environment variables and/or tilde
# Returns: Fully expanded path
expand_path_all() {
    local path="$1"
    local result="${path}"

    while [[ "$result" =~ \$([A-Za-z_][A-Za-z0-9_]*) ]]; do
        local var_name="${BASH_REMATCH[1]}"
        if [[ -v "${var_name}" ]]; then
            result="${result//\$${var_name}/${!var_name}}"
        else
            result="${result//\$${var_name}/}"
        fi
    done

    echo "$result"
}

# expand_relative_path: Convert relative path to absolute path
# Args:
#   - path: Relative path to expand
#   - base: Base directory for relative path (optional, defaults to pwd)
# Returns: Absolute path
expand_relative_path() {
    local path="$1"
    local base="$2"

    if [[ ! "$path" =~ ^/ ]]; then
        if [[ -n "$base" ]]; then
            path="${base}/${path}"
        else
            path="$(pwd)/${path}"
        fi
    fi

    echo "$path"
}

# find_project_root: Detect git repository root or return current directory
# Returns: Path to git root or current directory if not in git repo
find_project_root() {
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$git_root" ]; then
        git_root=$(pwd)
    fi
    echo "$git_root"
}

# find_ralph_dir: Find .ralph directory in current directory tree
# Args: None
# Returns: Path to .ralph directory or error if not found
find_ralph_dir() {
    local dir
    dir=$(pwd)
    while [ "$dir" != "/" ]; do
        if [ -d "${dir}/.ralph" ]; then
            echo "${dir}/.ralph"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    print_error "Error: .ralph directory not found" >&2
    return 1
}

# find_task_dir: Find task directory for given task ID
# Args:
#   - task_id: Task ID to locate (e.g., "0001")
# Returns: Path to task directory or error if not found
find_task_dir() {
    local task_id="$1"
    local ralph_dir
    ralph_dir=$(find_ralph_dir) || return 1
    echo "${ralph_dir}/tasks/${task_id}"
}

# find_agent_file: Find agent file in project or global location
# Args:
#   - agent_name: Name of agent to find (e.g., "tester")
# Returns: Path to agent file or error if not found
find_agent_file() {
    local agent_name="$1"
    local search_paths=(
        "/proj/.ralph/agents/${agent_name}.md"
        "/proj/.opencode/agents/${agent_name}.md"
        "${HOME}/.config/opencode/agents/${agent_name}.md"
    )
    
    for search_path in "${search_paths[@]}"; do
        if [ -f "$search_path" ]; then
            echo "$search_path"
            return 0
        fi
    done
    
    return 1
}

# usage: Display usage information for ralph-paths.sh
# Args: None
# Returns: Usage information to stdout
usage() {
    cat <<EOF
Ralph Path Detection Utilities

Usage: source ralph-paths.sh

Functions:

    find_project_root
        Detects git repository root or falls back to current directory
        
        Example:
            # In a git repository
            source $(dirname "$0")/ralph-paths.sh
            root=$(find_project_root)
            echo "Project root: $root"

    find_ralph_dir
        Finds .ralph directory in current directory tree
        
        Example:
            # In a project with .ralph directory
            source $(dirname "$0")/ralph-paths.sh
            ralph_dir=$(find_ralph_dir)
            echo "Ralph directory: $ralph_dir"

    find_task_dir TASK_ID
        Finds task directory given a task ID
        
        Example:
            # Get directory for task 0001
            source $(dirname "$0")/ralph-paths.sh
            task_dir=$(find_task_dir "0001")
            echo "Task directory: $task_dir"

    find_agent_file AGENT_NAME
        Finds agent file in project or global location
        
        Example:
            # Find tester agent file
            source $(dirname "$0")/ralph-paths.sh
            agent_file=$(find_agent_file "tester")
            echo "Agent file: $agent_file"

    expand_path PATH
        Expands tilde (~) and environment variables in a path
        
        Example:
            # Expand tilde
            source $(dirname "$0")/ralph-paths.sh
            path=$(expand_path "~/.config")
            echo "Expanded: $path"
            
            # Expand environment variable
            source $(dirname "$0")/ralph-paths.sh
            path=$(expand_path "\$HOME")
            echo "Expanded: $path"

    expand_relative_path PATH BASE
        Expands relative path to absolute path relative to base
        
        Example:
            # Expand relative path
            source $(dirname "$0")/ralph-paths.sh
            path=$(expand_relative_path "tasks/0001" "/proj")
            echo "Expanded: $path"

EOF
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
    exit 0
fi
