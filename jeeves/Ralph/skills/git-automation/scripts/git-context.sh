#!/bin/bash
# git-context.sh - Repository context detection library
# Task: 0066
#
# This script detects the repository context and primary branch for the Ralph Loop
# git-automation skill. It handles three contexts:
#   - REPO_ROOT: /proj/.git exists (full capabilities)
#   - SUBFOLDER: Git works but /proj is not root (limited capabilities)
#   - NO_REPO: No git repository detected (file-only operations)
#
# Usage:
#   Source this file to use the functions:
#     source /proj/.ralph/skills/git-automation/scripts/git-context.sh
#
#   Or run directly to detect and display context:
#     /proj/.ralph/skills/git-automation/scripts/git-context.sh

set -euo pipefail

# Configuration paths
# Allow override via environment variable (useful for testing)
: "${PROJ_ROOT:="/proj"}"
export PROJ_ROOT
export CONFIG_DIR="${PROJ_ROOT}/.ralph/config"
export CONTEXT_FILE="${CONFIG_DIR}/repo-context"
export PRIMARY_BRANCH_FILE="${CONFIG_DIR}/primary-branch"

# Colors for output (disable if not terminal)
if [[ -t 1 ]]; then
    export COLOR_RESET='\033[0m'
    export COLOR_GREEN='\033[0;32m'
    export COLOR_YELLOW='\033[1;33m'
    export COLOR_RED='\033[0;31m'
    export COLOR_BLUE='\033[0;34m'
else
    export COLOR_RESET=''
    export COLOR_GREEN=''
    export COLOR_YELLOW=''
    export COLOR_RED=''
    export COLOR_BLUE=''
fi

#######################################
# Logging Functions
#######################################

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*" >&2
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

#######################################
# Core Detection Functions
#######################################

# Detect the repository context
# Returns: REPO_ROOT, SUBFOLDER, or NO_REPO
detect_repo_context() {
    local current_dir
    current_dir=$(pwd)
    
    # Convert to absolute path for comparison
    if [[ "${current_dir}" != /* ]]; then
        current_dir="${PROJ_ROOT}/${current_dir}"
    fi
    
    # Normalize paths (remove trailing slashes, resolve ..)
    current_dir=$(cd "${current_dir}" 2>/dev/null && pwd -P) || current_dir=$(cd "${current_dir}" && pwd -P)
    
    # Normalize PROJ_ROOT for comparison
    local proj_root_normalized
    proj_root_normalized=$(cd "${PROJ_ROOT}" 2>/dev/null && pwd -P) || {
        # PROJ_ROOT doesn't exist or isn't accessible
        echo "NO_REPO"
        return 0
    }
    
    
    
    # Check if PROJ_ROOT has a git repository
    if ! git -C "${proj_root_normalized}" rev-parse --git-dir >/dev/null 2>&1; then
        echo "NO_REPO"
        return 0
    fi
    
    # REPO_ROOT: Current directory IS the project root
    if [[ "${current_dir}" == "${proj_root_normalized}" ]]; then
        echo "REPO_ROOT"
        return 0
    fi
    
    # SUBFOLDER: Current directory is within project root's git repo
    # Verify we're in the same git repository as PROJ_ROOT
    if [[ "${current_dir}" == "${proj_root_normalized}"* ]]; then
        # Get the actual repo root from current_dir
        local repo_root_from_current
        repo_root_from_current=$(git -C "${current_dir}" rev-parse --show-toplevel 2>/dev/null) || {
            echo "NO_REPO"
            return 0
        }
        
        # Verify it's the same repo as PROJ_ROOT
        if [[ "${repo_root_from_current}" == "${proj_root_normalized}" ]]; then
            echo "SUBFOLDER"
            return 0
        fi
    fi
    
    # NO_REPO: Not in the project's git repo
    echo "NO_REPO"
}

# Get the actual repository root path (for SUBFOLDER mode)
# Returns: Absolute path to repository root, or empty string if not in a repo
get_repo_root() {
    local git_dir
    if git -C "${PROJ_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
        git_dir=$(git -C "${PROJ_ROOT}" rev-parse --git-dir 2>/dev/null)
        if [[ -n "${git_dir}" ]]; then
            # Convert relative path to absolute
            if [[ "${git_dir}" == /* ]]; then
                # Already absolute, but git-dir might be .git file for submodules
                if [[ -f "${git_dir}" ]]; then
                    # Worktree or submodule - get parent of the .git file's directory
                    dirname "$(dirname "${git_dir}")"
                else
                    # Regular .git directory
                    dirname "${git_dir}"
                fi
            else
                # Relative path - resolve relative to PROJ_ROOT
                cd "${PROJ_ROOT}" && cd "${git_dir}" && cd .. && pwd
            fi
        fi
    fi
}

# Get the current branch name
# Returns: Branch name, or empty string if detached HEAD or not in repo
get_current_branch() {
    if git -C "${PROJ_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
        git -C "${PROJ_ROOT}" branch --show-current 2>/dev/null || true
    fi
}

# Detect the primary branch using 4-tier fallback strategy
# 1. Try 'main' first
# 2. Try 'master' second
# 3. Try 'trunk' third
# 4. Fall back to current branch name
# Returns: Primary branch name, or empty string if detection fails
get_primary_branch() {
    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        return 0
    fi

    # Tier 1: Check if 'main' exists
    if git -C "${PROJ_ROOT}" show-ref --verify --quiet refs/heads/main 2>/dev/null; then
        echo "main"
        return 0
    fi

    # Tier 2: Check if 'master' exists
    if git -C "${PROJ_ROOT}" show-ref --verify --quiet refs/heads/master 2>/dev/null; then
        echo "master"
        return 0
    fi

    # Tier 3: Check if 'trunk' exists
    if git -C "${PROJ_ROOT}" show-ref --verify --quiet refs/heads/trunk 2>/dev/null; then
        echo "trunk"
        return 0
    fi

    # Tier 4: Fall back to current branch
    local current_branch
    current_branch=$(get_current_branch)
    if [[ -n "${current_branch}" ]]; then
        echo "${current_branch}"
        return 0
    fi

    # If we get here, we're likely in a detached HEAD state
    return 0
}

# Detect the primary branch using 4-tier fallback strategy
# 1. Try 'main' first
# 2. Try 'master' second
# 3. Try 'trunk' third
# 4. Fall back to current branch name
# Returns: Primary branch name, or empty string if detection fails

#######################################
# Persistence Functions
#######################################

# Ensure the config directory exists
ensure_config_dir() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        mkdir -p "${CONFIG_DIR}" || {
            log_error "Failed to create config directory: ${CONFIG_DIR}"
            return 1
        }
    fi
}

# Persist the repository context to config file
# Arguments:
#   $1 - Context (REPO_ROOT, SUBFOLDER, or NO_REPO)
#   $2 - Primary branch name (optional, only for REPO_ROOT context)
persist_context() {
    local context="${1:-}"
    local primary_branch="${2:-}"

    ensure_config_dir || return 1

    # Write context file
    {
        echo "CONTEXT=${context}"
        echo "DETECTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "PROJ_ROOT=${PROJ_ROOT}"

        if [[ "${context}" == "REPO_ROOT" ]]; then
            echo "REPO_ROOT=${PROJ_ROOT}"
        elif [[ "${context}" == "SUBFOLDER" ]]; then
            local repo_root
            repo_root=$(get_repo_root)
            echo "REPO_ROOT=${repo_root}"
        fi
    } > "${CONTEXT_FILE}"

    # Write primary branch file if applicable
    if [[ -n "${primary_branch}" ]]; then
        echo "${primary_branch}" > "${PRIMARY_BRANCH_FILE}"
    else
        # Clear primary branch file if no repo
        rm -f "${PRIMARY_BRANCH_FILE}"
    fi

    log_success "Context persisted to ${CONTEXT_FILE}"
}

# Load persisted context (for other scripts to use)
# Returns: Context value, or NO_REPO if not persisted
load_context() {
    if [[ -f "${CONTEXT_FILE}" ]]; then
        grep "^CONTEXT=" "${CONTEXT_FILE}" | cut -d'=' -f2 || echo "NO_REPO"
    else
        echo "NO_REPO"
    fi
}

# Load persisted primary branch
# Returns: Primary branch name, or empty string
load_primary_branch() {
    if [[ -f "${PRIMARY_BRANCH_FILE}" ]]; then
        cat "${PRIMARY_BRANCH_FILE}"
    fi
}

#######################################
# User Messaging Functions
#######################################

# Show context message with clear responsibility contract
# Arguments:
#   $1 - Context (REPO_ROOT, SUBFOLDER, or NO_REPO)
#   $2 - Primary branch name (optional)
#   $3 - Current branch name (optional)
show_context_message() {
    local context="${1:-NO_REPO}"
    local primary_branch="${2:-}"
    local current_branch="${3:-}"

    echo ""
    echo "========================================"
    echo "  Git Integration Status"
    echo "========================================"
    echo ""

    case "${context}" in
        REPO_ROOT)
            echo -e "${COLOR_GREEN}✓ Git Integration: FULL MODE${COLOR_RESET}"
            echo "  Repository root detected at ${PROJ_ROOT}"
            echo ""
            if [[ -n "${primary_branch}" ]]; then
                echo "  Primary branch: ${COLOR_BLUE}${primary_branch}${COLOR_RESET}"
            fi
            if [[ -n "${current_branch}" ]]; then
                echo "  Current branch: ${current_branch}"
            fi
            echo ""
            echo "  Capabilities:"
            echo "    • Full branch management"
            echo "    • Automatic workflow integration"
            echo "    • Primary branch tracking"
            echo ""
            ;;

        SUBFOLDER)
            local repo_root
            repo_root=$(get_repo_root)
            echo -e "${COLOR_YELLOW}⚠ Git Integration: LIMITED MODE${COLOR_RESET}"
            echo "  Working in subdirectory of repository"
            if [[ -n "${repo_root}" ]]; then
                echo "  Repository root: ${repo_root}"
            fi
            echo ""
            echo "  Limitations:"
            echo "    • Git branch operations are disabled"
            echo "    • File operations only"
            echo ""
            echo -e "${COLOR_YELLOW}  Your Responsibility:${COLOR_RESET}"
            echo "    You must manage branches manually."
            echo "    Create and switch branches outside of Ralph Loop."
            echo ""
            ;;

        NO_REPO)
            echo -e "${COLOR_RED}✗ Git Integration: NOT AVAILABLE${COLOR_RESET}"
            echo "  No git repository detected"
            echo ""
            echo "  Mode:"
            echo "    • File-based task management only"
            echo "    • No git operations will be performed"
            echo ""
            echo -e "${COLOR_YELLOW}  Note:${COLOR_RESET}"
            echo "    Initialize a git repository to enable full features:"
            echo "      git init"
            echo ""
            ;;

        *)
            log_error "Unknown context: ${context}"
            return 1
            ;;
    esac

    echo "========================================"
    echo ""
}

#######################################
# Main Function (when run directly)
#######################################

main() {
    log_info "Detecting repository context..."

    # Detect context
    local context
    context=$(detect_repo_context)

    # Get branch information
    local primary_branch=""
    local current_branch=""

    if [[ "${context}" != "NO_REPO" ]]; then
        primary_branch=$(get_primary_branch)
        current_branch=$(get_current_branch)
    fi

    # Show message to user
    show_context_message "${context}" "${primary_branch}" "${current_branch}"

    # Persist context for other tasks
    persist_context "${context}" "${primary_branch}"

    # Return context as exit code for scripting
    # 0 = REPO_ROOT, 1 = SUBFOLDER, 2 = NO_REPO
    case "${context}" in
        REPO_ROOT)  return 0 ;;
        SUBFOLDER)  return 1 ;;
        NO_REPO)    return 2 ;;
        *)          return 3 ;;
    esac
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
