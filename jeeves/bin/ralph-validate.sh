#!/bin/bash

# Ralph Validation Utilities Library
# Sourceable bash library for Ralph operations validation

# Exit on error
set -e

# Function: validate_task_id
# Validates that a task ID is in the correct 4-digit format (0001-9999)
# Usage: validate_task_id "0042"
# Returns: 0 on success, 1 on failure
# Output: Error message to stderr on failure
validate_task_id() {
    local id="$1"
    
    # Check if empty
    if [ -z "$id" ]; then
        echo "Error: Task ID cannot be empty" >&2
        return 1
    fi
    
    # Check if numeric
    if ! [[ "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: Task ID must be numeric" >&2
        return 1
    fi
    
    # Check if 4 digits
    if [ ${#id} -ne 4 ]; then
        echo "Error: Task ID must be 4 digits" >&2
        return 1
    fi
    
    # Check if in range 0001-9999
    if [ "$id" -lt 1 ] || [ "$id" -gt 9999 ]; then
        echo "Error: Task ID must be between 0001 and 9999" >&2
        return 1
    fi
    
    return 0
}

# Function: validate_yaml
# Validates YAML syntax using yq or python-yaml
# Usage: validate_yaml "/path/to/file.yaml"
# Returns: 0 on success, 1 on failure
# Output: Error message to stderr on failure
validate_yaml() {
    local file="$1"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        echo "Error: YAML file does not exist: $file" >&2
        return 1
    fi
    
    # Try yq first if available
    if command -v yq >/dev/null 2>&1; then
        if ! yq eval '.' "$file" >/dev/null 2>&1; then
            echo "Error: Invalid YAML syntax in file: $file" >&2
            return 1
        fi
        return 0
    fi
    
    # Fallback to Python if yq is not available
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "Error: Invalid YAML syntax in file: $file" >&2
            return 1
        fi
        return 0
    fi
    
    echo "Error: Neither yq nor python3 available for YAML validation" >&2
    return 1
}

# Function: validate_file_exists
# Checks if a file exists
# Usage: validate_file_exists "/path/to/file"
# Returns: 0 on success, 1 on failure
# Output: Error message to stderr on failure
validate_file_exists() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: File does not exist: $file" >&2
        return 1
    fi
    
    return 0
}

# Function: validate_dir_exists
# Checks if a directory exists
# Usage: validate_dir_exists "/path/to/dir"
# Returns: 0 on success, 1 on failure
# Output: Error message to stderr on failure
validate_dir_exists() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo "Error: Directory does not exist: $dir" >&2
        return 1
    fi
    
    return 0
}

# Function: validate_git_repo
# Confirms that the current directory is a git repository
# Usage: validate_git_repo
# Returns: 0 on success, 1 on failure
# Output: Error message to stderr on failure
validate_git_repo() {
    # Check if .git directory exists
    if [ ! -d ".git" ]; then
        echo "Error: Current directory is not a git repository" >&2
        return 1
    fi
    
    # Verify git is available
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git command not found" >&2
        return 1
    fi
    
    # Try to run git status to confirm it's a repo
    if ! git status >/dev/null 2>&1; then
        echo "Error: Not a valid git repository" >&2
        return 1
    fi
    
    return 0
}
