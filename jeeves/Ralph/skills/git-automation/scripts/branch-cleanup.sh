#!/bin/bash
# branch-cleanup.sh - Clean up task branches after completion
# Task: 0069
#
# Usage: ./branch-cleanup.sh --task-id NNNN [--force]
#
# Options:
#   --task-id NNNN   Task ID for branch to clean up (required)
#   --force          Skip confirmation prompt

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Source git-context library
source "${SCRIPT_DIR}/git-context.sh"

# Configuration (PROJ_ROOT and CONFIG_DIR already defined in git-context.sh)

# Command line arguments
TASK_ID=""
FORCE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --task-id)
            TASK_ID="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 --task-id NNNN [--force]" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "${TASK_ID}" ]]; then
    log_error "--task-id is required"
    echo "Usage: $0 --task-id NNNN [--force]" >&2
    exit 1
fi

# Format task ID with leading zeros (ensure 4 digits)
# Handle both numeric input (69) and already-formatted input (0069)
if [[ "${TASK_ID}" =~ ^[0-9]+$ ]]; then
    # Numeric input - format with leading zeros (force base 10 to avoid octal interpretation)
    FORMATTED_TASK_ID=$(printf "%04d" "$((10#${TASK_ID}))")
elif [[ "${TASK_ID}" =~ ^[0-9]{4}$ ]]; then
    # Already 4-digit formatted - use as-is
    FORMATTED_TASK_ID="${TASK_ID}"
else
    # Other format - use as-is
    FORMATTED_TASK_ID="${TASK_ID}"
fi
BRANCH_NAME="task/${FORMATTED_TASK_ID}"

# Detect repository context
    CONTEXT=$(detect_repo_context)
    echo "[DEBUG] CONTEXT=${CONTEXT}" >&2
    echo "[DEBUG] PROJ_ROOT=${PROJ_ROOT}" >&2
    echo "[DEBUG] .git exists: $([ -d "${PROJ_ROOT}/.git" ] && echo yes || echo no)" >&2
    echo "[DEBUG] Branches before branch_exists check:" >&2
    echo "[DEBUG] Current dir: $(pwd)" >&2
    echo "[DEBUG] ls .git/refs/heads:" >&2
    ls -la .git/refs/heads >&2 || echo "ls failed" >&2
    echo "[DEBUG] ls PROJ_ROOT/.git/refs/heads:" >&2
    ls -la "${PROJ_ROOT}/.git/refs/heads" >&2 || echo "ls failed" >&2
    git -C "${PROJ_ROOT}" show-ref --heads >&2
PRIMARY_BRANCH=$(get_primary_branch)

#######################################
# Safety Check Functions
#######################################

# Check if the task branch exists locally
branch_exists_local() {
    git -C "${PROJ_ROOT}" show-ref --verify --quiet "refs/heads/${BRANCH_NAME}" 2>/dev/null
}

# Check if the task branch exists remotely
branch_exists_remote() {
    git -C "${PROJ_ROOT}" ls-remote --heads origin "${BRANCH_NAME}" 2>/dev/null | grep -q "${BRANCH_NAME}"
}

# Check if branch is fully merged into primary branch
is_branch_merged() {
    local branch="$1"
    local primary="${2:-${PRIMARY_BRANCH}}"

    if [[ -z "${primary}" ]]; then
        log_error "Cannot determine primary branch for merge check"
        return 1
    fi

    # Check if all commits in branch are reachable from primary
    git -C "${PROJ_ROOT}" merge-base --is-ancestor "${branch}" "${primary}" 2>/dev/null
}

# Check for uncommitted changes on the task branch
check_uncommitted_changes() {
    local branch="$1"

    # Check if there are uncommitted changes when on that branch
    # We need to check the worktree status
    git -C "${PROJ_ROOT}" status --porcelain 2>/dev/null | grep -q .
}

# Get the current branch
current_branch=$(get_current_branch)

#######################################
# User Confirmation
#######################################

confirm_deletion() {
    local branch="$1"
    local merged="$2"

    if [[ "${FORCE}" == "true" ]]; then
        return 0
    fi

    echo ""
    echo "========================================"
    echo "  Branch Cleanup Confirmation"
    echo "========================================"
    echo ""
    echo "Branch to delete: ${branch}"
    echo "Primary branch: ${PRIMARY_BRANCH:-unknown}"

    if [[ "${merged}" == "true" ]]; then
        echo -e "${COLOR_GREEN}✓ Branch is merged${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}⚠ Branch is NOT merged${COLOR_RESET}"
        echo "  Unmerged commits will be lost!"
    fi

    if [[ "${current_branch}" == "${branch}" ]]; then
        echo -e "${COLOR_YELLOW}⚠ You are currently on this branch${COLOR_RESET}"
        echo "  Will switch to ${PRIMARY_BRANCH:-primary} before deletion"
    fi

    echo ""
    echo -n "Proceed with deletion? (y/N): "
    read -r response

    if [[ "${response,,}" == "y" || "${response,,}" == "yes" ]]; then
        return 0
    else
        log_info "Deletion cancelled by user"
        return 1
    fi
}

#######################################
# Deletion Functions
#######################################

delete_local_branch() {
    local branch="$1"
    local merged="$2"

    if ! branch_exists_local; then
        log_warning "Local branch '${branch}' does not exist"
        return 0
    fi

    # If currently on the branch, switch to primary first
    if [[ "${current_branch}" == "${branch}" ]]; then
        if [[ -n "${PRIMARY_BRANCH}" ]]; then
            log_info "Switching from '${branch}' to '${PRIMARY_BRANCH}'"
            git -C "${PROJ_ROOT}" checkout "${PRIMARY_BRANCH}" || {
                log_error "Failed to switch to primary branch"
                return 1
            }
        else
            log_error "Cannot switch branches - primary branch unknown"
            return 1
        fi
    fi

    # Delete local branch
    if [[ "${merged}" == "true" ]]; then
        # Safe delete (only if merged)
        log_info "Deleting local branch '${branch}' (safe delete)"
        if git -C "${PROJ_ROOT}" branch -d "${branch}" 2>/dev/null; then
            log_success "Deleted local branch: ${branch}"
            return 0
        else
            log_error "Failed to delete local branch (may have unmerged commits)"
            return 1
        fi
    else
        # Force delete (unmerged)
        log_warning "Force deleting unmerged branch '${branch}'"
        if git -C "${PROJ_ROOT}" branch -D "${branch}" 2>/dev/null; then
            log_success "Force deleted local branch: ${branch}"
            return 0
        else
            log_error "Failed to force delete local branch"
            return 1
        fi
    fi
}

delete_remote_branch() {
    local branch="$1"

    if ! branch_exists_remote; then
        log_warning "Remote branch 'origin/${branch}' does not exist"
        return 0
    fi

    log_info "Deleting remote branch 'origin/${branch}'"
    if git -C "${PROJ_ROOT}" push origin --delete "${branch}" 2>/dev/null; then
        log_success "Deleted remote branch: origin/${branch}"
        return 0
    else
        log_error "Failed to delete remote branch"
        return 1
    fi
}

prune_remote_refs() {
    log_info "Pruning remote references"
    if git -C "${PROJ_ROOT}" remote prune origin 2>/dev/null; then
        log_success "Pruned remote references"
        return 0
    else
        log_warning "Failed to prune remote references"
        return 1
    fi
}

#######################################
# Context Handlers
#######################################

handle_repo_root_mode() {
    log_info "Running in REPO_ROOT mode - full cleanup available"

    # Check if branch exists locally
    if ! branch_exists_local; then
        log_warning "Local branch '${BRANCH_NAME}' does not exist"
    fi

    # Check merge status
    local merged="false"
    if is_branch_merged "${BRANCH_NAME}"; then
        merged="true"
        log_info "Branch '${BRANCH_NAME}' is merged into '${PRIMARY_BRANCH}'"
    else
        log_warning "Branch '${BRANCH_NAME}' is NOT merged into '${PRIMARY_BRANCH}'"
    fi

    # Get user confirmation
    if ! confirm_deletion "${BRANCH_NAME}" "${merged}"; then
        echo ""
        echo "Branch cleanup cancelled"
        return 1
    fi

    # Track results
    local local_deleted=false
    local remote_deleted=false
    local prune_done=false

    # Delete local branch
    if branch_exists_local; then
        if delete_local_branch "${BRANCH_NAME}" "${merged}"; then
            local_deleted=true
        fi
    fi

    # Delete remote branch
    if branch_exists_remote; then
        if delete_remote_branch "${BRANCH_NAME}"; then
            remote_deleted=true
        fi
    fi

    # Prune remote refs
    if prune_remote_refs; then
        prune_done=true
    fi

    # Print summary
    echo ""
    echo "========================================"
    echo "  Branch Cleanup Summary"
    echo "========================================"
    echo ""
    if [[ "${local_deleted}" == "true" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} Local branch deleted: ${BRANCH_NAME}"
    else
        echo -e "${COLOR_YELLOW}○${COLOR_RESET} Local branch: no action or failed"
    fi

    if [[ "${remote_deleted}" == "true" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} Remote branch deleted: origin/${BRANCH_NAME}"
    else
        echo -e "${COLOR_YELLOW}○${COLOR_RESET} Remote branch: no action or failed"
    fi

    if [[ "${prune_done}" == "true" ]]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} Remote refs pruned"
    fi

    echo ""
    log_success "Branch cleanup complete for task ${FORMATTED_TASK_ID}"

    # Log to activity.md if task directory exists
    local activity_file="${PROJ_ROOT}/.ralph/tasks/${FORMATTED_TASK_ID}/activity.md"
    if [[ -f "${activity_file}" ]]; then
        echo "" >> "${activity_file}"
        echo "## Branch Cleanup [$(date -u +"%Y-%m-%dT%H:%M:%SZ")]" >> "${activity_file}"
        echo "" >> "${activity_file}"
        if [[ "${local_deleted}" == "true" ]]; then
            echo "Deleted local branch: ${BRANCH_NAME}" >> "${activity_file}"
        fi
        if [[ "${remote_deleted}" == "true" ]]; then
            echo "Deleted remote branch: origin/${BRANCH_NAME}" >> "${activity_file}"
        fi
        if [[ "${prune_done}" == "true" ]]; then
            echo "Pruned remote references" >> "${activity_file}"
        fi
        if [[ "${local_deleted}" != "true" && "${remote_deleted}" != "true" ]]; then
            echo "No branches deleted (did not exist)" >> "${activity_file}"
        fi
        echo "" >> "${activity_file}"
        echo "Primary branch: ${PRIMARY_BRANCH}" >> "${activity_file}"
        echo "Merge status: $([[ "${merged}" == "true" ]] && echo "merged" || echo "not merged")" >> "${activity_file}"
        log_info "Logged branch cleanup to activity.md"
    fi

    return 0
}

handle_subfolder_mode() {
    log_info "Running in SUBFOLDER mode - limited cleanup available"

    local repo_root
    repo_root=$(get_repo_root)

    echo ""
    echo "========================================"
    echo -e "${COLOR_YELLOW}  Branch Cleanup: Limited Mode${COLOR_RESET}"
    echo "========================================"
    echo ""
    echo "Branch cleanup skipped - user manages branches manually"
    echo ""
    echo "Repository root: ${repo_root}"
    echo ""

    # Check merge status (informational only)
    if is_branch_merged "${BRANCH_NAME}"; then
        echo -e "${COLOR_GREEN}✓ Branch '${BRANCH_NAME}' is merged${COLOR_RESET}"
    else
        echo -e "${COLOR_YELLOW}⚠ Branch '${BRANCH_NAME}' is not merged${COLOR_RESET}"
    fi

    echo ""
    echo "Manual cleanup steps:"
    echo "  1. cd ${repo_root}"
    echo "  2. git branch -d ${BRANCH_NAME}     # Delete local (only if merged)"
    echo "     # OR: git branch -D ${BRANCH_NAME}  # Force delete if unmerged"
    echo "  3. git push origin --delete ${BRANCH_NAME}  # Delete remote"
    echo "  4. git remote prune origin          # Clean up refs"
    echo ""

    return 0
}

handle_no_repo_mode() {
    log_info "Running in NO_REPO mode - skipping branch cleanup"

    echo ""
    echo "========================================"
    echo -e "${COLOR_YELLOW}  Branch Cleanup: Not Available${COLOR_RESET}"
    echo "========================================"
    echo ""
    echo "No git repository detected."
    echo "Branch cleanup is not applicable in this mode."
    echo ""

    return 0
}

#######################################
# Main
#######################################

main() {
    log_info "Starting branch cleanup for task ${FORMATTED_TASK_ID}"

    # Handle based on context
    case "${CONTEXT}" in
        REPO_ROOT)
            handle_repo_root_mode
            ;;
        SUBFOLDER)
            handle_subfolder_mode
            ;;
        NO_REPO)
            handle_no_repo_mode
            ;;
        *)
            log_error "Unknown context: ${CONTEXT}"
            exit 1
            ;;
    esac
}

main "$@"
