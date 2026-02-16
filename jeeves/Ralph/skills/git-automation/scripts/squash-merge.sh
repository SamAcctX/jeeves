#!/bin/bash
# squash-merge.sh - Squash merge task branch
# Task: 0068
#
# Usage: ./squash-merge.sh --task-id NNNN [--agent-type developer]
#
# Integrates with:
#   - git-context.sh (context detection)
#   - git-commit-msg.sh (commit message generation)
#   - git-conflict.sh (conflict detection - for 0071)

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Git automation directory
readonly GIT_AUTOMATION_DIR="${SCRIPT_DIR}"

# Configuration paths (these will be set after sourcing git-context.sh)
TASKS_DIR=""

# Arguments
TASK_ID=""
AGENT_TYPE="developer"

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --task-id)
                TASK_ID="$2"
                shift 2
                ;;
            --agent-type)
                AGENT_TYPE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "[ERROR] Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${TASK_ID}" ]]; then
        echo "[ERROR] Missing required argument: --task-id" >&2
        show_help
        exit 1
    fi
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") --task-id NNNN [--agent-type TYPE]

Squash merge a task branch to the primary branch.

Arguments:
  --task-id NNNN       The task ID to merge (required)
  --agent-type TYPE    Agent type for commit message (default: developer)
                       Options: developer, tester, architect, writer, researcher, ui-designer
  --help, -h           Show this help message

Examples:
  $(basename "$0") --task-id 0068
  $(basename "$0") --task-id 0068 --agent-type tester
EOF
}

# Extract task title from TASK.md
get_task_title() {
    local task_id="$1"
    local task_file="${TASKS_DIR}/${task_id}/TASK.md"

    if [[ -f "${task_file}" ]]; then
        # Extract the first line that looks like a title (starts with # Task)
        grep -m 1 "^# Task " "${task_file}" 2>/dev/null | sed 's/^# Task [0-9]*: //' || echo ""
    else
        echo ""
    fi
}

# Source the git-context library
source_git_context() {
    local context_script="${GIT_AUTOMATION_DIR}/git-context.sh"

    if [[ -f "${context_script}" ]]; then
        # shellcheck source=/dev/null
        source "${context_script}"
        # Set TASKS_DIR after sourcing (PROJ_ROOT is now available from git-context.sh)
        TASKS_DIR="${PROJ_ROOT}/.ralph/tasks"
    else
        log_error "git-context.sh not found at ${context_script}"
        exit 1
    fi
}

# Generate commit message using git-commit-msg.sh
generate_commit_message() {
    local task_id="$1"
    local agent_type="$2"
    local task_title="$3"

    local commit_msg_script="${GIT_AUTOMATION_DIR}/git-commit-msg.sh"

    if [[ -f "${commit_msg_script}" ]]; then
        "${commit_msg_script}" \
            --task-id "${task_id}" \
            --agent-type "${agent_type}" \
            --task-title "${task_title}"
    else
        # Fallback if commit message generator not available
        echo "feat: implement task ${task_id}"
    fi
}

# Check for merge conflicts (placeholder for 0071 integration)
check_conflicts() {
    local task_branch="$1"

    # Check if we can merge without conflicts
    if ! git merge-tree "$(git merge-base HEAD "${task_branch}")" HEAD "${task_branch}" >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# Check if working directory is clean
is_working_directory_clean() {
    local status_output
    status_output=$(git -C "${PROJ_ROOT}" status --porcelain 2>&1)
    if [[ -n "${status_output}" ]]; then
        echo "[DEBUG] git status --porcelain: ${status_output}" >&2
        return 1
    fi
    return 0
}

# Verify task branch exists
branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null
}

# Execute REPO_ROOT mode workflow
execute_repo_root_mode() {
    local primary_branch="$1"
    local task_branch="$2"
    local commit_message="$3"

    log_info "Executing squash merge in REPO_ROOT mode"

    # Safety check: verify task branch exists
    if ! branch_exists "${task_branch}"; then
        log_error "Task branch '${task_branch}' does not exist"
        exit 1
    fi

    # Safety check: verify working directory is clean
    if ! is_working_directory_clean; then
        log_error "Working directory is not clean. Please commit or stash changes."
        log_info "Run 'git status' to see uncommitted changes"
        exit 1
    fi

    # Checkout primary branch
    log_info "Checking out primary branch: ${primary_branch}"
    if ! git checkout "${primary_branch}"; then
        log_error "Failed to checkout primary branch: ${primary_branch}"
        exit 1
    fi

    # Pull latest changes
    log_info "Pulling latest changes from remote"
    if ! git pull; then
        log_warning "Failed to pull latest changes - continuing with local state"
    fi

    # Check for conflicts before merge
    log_info "Checking for merge conflicts"
    if ! check_conflicts "${task_branch}"; then
        log_error "Merge conflicts detected between '${primary_branch}' and '${task_branch}'"
        log_error "TASK_BLOCKED: Merge conflict requires human resolution"
        echo ""
        echo "To resolve manually:"
        echo "  1. git checkout ${task_branch}"
        echo "  2. git rebase ${primary_branch}"
        echo "  3. Resolve conflicts"
        echo "  4. git checkout ${primary_branch}"
        echo "  5. Re-run this script"
        exit 1
    fi

    # Perform squash merge
    log_info "Performing squash merge of '${task_branch}'"
    if ! git merge --squash "${task_branch}"; then
        log_error "Squash merge failed"
        exit 1
    fi

    # Check if there are changes staged
    if [[ -z "$(git diff --cached --name-only)" ]]; then
        log_warning "No changes to commit - task branch may be empty or already merged"
        exit 0
    fi

    # Create commit with generated message
    log_info "Creating commit with message: ${commit_message}"
    if ! git commit -m "${commit_message}"; then
        log_error "Failed to create commit"
        exit 1
    fi

    # Push to remote (optional - may fail if no remote configured)
    log_info "Pushing to remote"
    git push || true

    log_success "Squash merge completed successfully"
    log_info "Task branch '${task_branch}' merged to '${primary_branch}'"
}

# Execute SUBFOLDER mode workflow
execute_subfolder_mode() {
    local repo_root="$1"
    local primary_branch="$2"
    local task_branch="$3"
    local commit_message="$4"

    log_info "Executing squash merge in SUBFOLDER mode"
    log_warning "Limited mode: Repository root is at ${repo_root}"
    log_warning "Please execute the following steps manually:"

    echo ""
    echo "========================================"
    echo "  Generated commit message:"
    echo "  \"${commit_message}\""
    echo "========================================"
    echo ""
    echo "Manual merge steps:"
    echo ""
    echo "  1. cd ${repo_root}"
    echo "  2. git checkout ${primary_branch}"
    echo "  3. git pull"
    echo "  4. git merge --squash ${task_branch}"
    echo "  5. git commit -m \"${commit_message}\""
    echo "  6. git push"
    echo ""
    echo "========================================"
}

# Execute NO_REPO mode workflow
execute_no_repo_mode() {
    log_warning "No git repository detected"
    log_info "Skipping squash merge - file operations only"
    log_info "Task ${TASK_ID} marked as complete in file system"
}

# Main execution
main() {
    parse_args "$@"

    # Source git-context library first (provides logging functions)
    source_git_context

    log_info "Starting squash merge for task ${TASK_ID}"

    # Detect repository context
    local context
    context=$(detect_repo_context)

    # Get primary branch
    local primary_branch
    echo "[DEBUG] get_primary_branch: Checking branches..." >&2
    echo "[DEBUG] get_primary_branch: git show-ref --heads..." >&2
    git -C "${PROJ_ROOT}" show-ref --heads >&2
    primary_branch=$(get_primary_branch)

    # Get task title
    local task_title
    task_title=$(get_task_title "${TASK_ID}")

    # Generate commit message
    local commit_message
    commit_message=$(generate_commit_message "${TASK_ID}" "${AGENT_TYPE}" "${task_title}")

    # Determine task branch name
    local task_branch="task/${TASK_ID}"

    # Execute based on context
    case "${context}" in
        REPO_ROOT)
            if [[ -z "${primary_branch}" ]]; then
                log_error "Could not detect primary branch"
                exit 1
            fi
            execute_repo_root_mode "${primary_branch}" "${task_branch}" "${commit_message}"
            ;;

        SUBFOLDER)
            local repo_root
            repo_root=$(get_repo_root)
            if [[ -z "${primary_branch}" ]]; then
                log_error "Could not detect primary branch"
                exit 1
            fi
            execute_subfolder_mode "${repo_root}" "${primary_branch}" "${task_branch}" "${commit_message}"
            ;;

        NO_REPO)
            execute_no_repo_mode
            ;;

        *)
            log_error "Unknown context: ${context}"
            exit 1
            ;;
    esac
}

main "$@"
