#!/bin/bash
# task-branch-create.sh - Create task branch
# Task: 0067
#
# Usage: ./task-branch-create.sh --task-id NNNN [--description "short-desc"]
#
# The description defaults to task title from .ralph/tasks/NNNN/TASK.md

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# Source git-context.sh for repository context detection
# shellcheck source=./git-context.sh
source "${SCRIPT_DIR}/git-context.sh"

# Configuration paths
# PROJ_ROOT is already defined in git-context.sh
readonly RALPH_TASKS_DIR="${PROJ_ROOT}/.ralph/tasks"

# Script variables
TASK_ID=""
DESCRIPTION=""
DRY_RUN=false

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
# Utility Functions
#######################################

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --task-id)
                TASK_ID="$2"
                shift 2
                ;;
            --description)
                DESCRIPTION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${TASK_ID}" ]]; then
        log_error "Missing required argument: --task-id"
        show_usage
        exit 1
    fi

    # Validate task ID format (4-digit number)
    if [[ ! "${TASK_ID}" =~ ^[0-9]{4}$ ]]; then
        log_error "Invalid task ID format: ${TASK_ID}. Must be 4 digits (e.g., 0067)"
        exit 1
    fi
}

# Show usage information
show_usage() {
    cat <<EOF
Usage: $(basename "$0") --task-id NNNN [--description "short-desc"]

Create a task branch with proper naming convention.

Options:
    --task-id NNNN          Task ID (4 digits, zero-padded, e.g., 0067)
    --description "desc"    Short description (defaults to task title from TASK.md)
    --dry-run               Show what would be done without making changes
    --help, -h              Show this help message

Examples:
    $(basename "$0") --task-id 0067
    $(basename "$0") --task-id 0067 --description "implement-branch-creation"
    $(basename "$0") --task-id 0070 --description "conventional-commits"

Branch Naming:
    Format: task/NNNN-description
    Examples:
        task/0067-implement-branch-creation
        task/0070-conventional-commits

Repository Contexts:
    REPO_ROOT   - Full git integration, creates branches automatically
    SUBFOLDER   - Shows manual command for user to execute
    NO_REPO     - Skips silently
EOF
}

# Extract task title from TASK.md file
get_task_title() {
    local task_id="$1"
    local task_file="${RALPH_TASKS_DIR}/${task_id}/TASK.md"

    if [[ -f "${task_file}" ]]; then
        # Extract title from first line (format: # Task NNNN: Title)
        local title
        title=$(head -1 "${task_file}" | sed -E 's/^# Task [0-9]+: *//' | tr '[:upper:]' '[:lower:]')
        # Sanitize for branch name (remove special chars, replace spaces with hyphens)
        title=$(echo "${title}" | sed 's/[^a-z0-9 _-]//g; s/ /-/g')
        echo "${title}"
    else
        echo ""
    fi
}

# Generate branch name from task ID and description
generate_branch_name() {
    local task_id="$1"
    local description="$2"

    if [[ -n "${description}" ]]; then
        echo "task/${task_id}-${description}"
    else
        # Try to get from TASK.md
        local task_title
        task_title=$(get_task_title "${task_id}")
        if [[ -n "${task_title}" ]]; then
            echo "task/${task_id}-${task_title}"
        else
            echo "task/${task_id}"
        fi
    fi
}

# Check for uncommitted changes
check_uncommitted_changes() {
    if ! git -C "${PROJ_ROOT}" diff-index --quiet HEAD -- 2>/dev/null; then
        return 0  # Has uncommitted changes
    fi
    return 1  # Clean working directory
}

# Check if branch exists locally
branch_exists_local() {
    local branch_name="$1"
    git -C "${PROJ_ROOT}" show-ref --verify --quiet "refs/heads/${branch_name}" 2>/dev/null
}

# Check if branch exists on remote
branch_exists_remote() {
    local branch_name="$1"
    git -C "${PROJ_ROOT}" ls-remote --heads origin "${branch_name}" 2>/dev/null | grep -q "refs/heads/${branch_name}"
}

#######################################
# Core Functions
#######################################

# Handle REPO_ROOT context - full branch creation
handle_repo_root() {
    local branch_name="$1"
    local primary_branch
    primary_branch=$(load_primary_branch)

    if [[ -z "${primary_branch}" ]]; then
        primary_branch=$(get_primary_branch)
        if [[ -z "${primary_branch}" ]]; then
            log_error "Could not detect primary branch"
            exit 1
        fi
    fi

    log_info "Primary branch: ${primary_branch}"

    # Check for uncommitted changes
    if check_uncommitted_changes; then
        # Check if we're on a branch with no commits yet
        if ! git -C "${PROJ_ROOT}" rev-parse HEAD >/dev/null 2>&1 || git -C "${PROJ_ROOT}" rev-list -n 1 HEAD 2>/dev/null | grep -q "^$"; then
            log_warning "Uncommitted changes on empty branch - cannot stash"
            log_info "Creating initial commit first..."
            touch "${PROJ_ROOT}/.gitignore"
            git -C "${PROJ_ROOT}" add .gitignore
            git -C "${PROJ_ROOT}" commit -m "chore: initial commit"
        else
            log_warning "Uncommitted changes detected in working directory"
            log_info "Stashing changes before branch creation..."
            if [[ "${DRY_RUN}" == "false" ]]; then
                git -C "${PROJ_ROOT}" stash push -m "task-branch-create: ${branch_name}"
                log_success "Changes stashed"
            else
                log_info "[DRY RUN] Would stash changes"
            fi
        fi
    fi

    # Check if branch already exists locally
    if branch_exists_local "${branch_name}"; then
        log_warning "Branch '${branch_name}' already exists locally"
        log_info "Checking out existing branch..."
        if [[ "${DRY_RUN}" == "false" ]]; then
            git -C "${PROJ_ROOT}" checkout "${branch_name}"
            log_success "Checked out existing branch: ${branch_name}"
        else
            log_info "[DRY RUN] Would checkout existing branch: ${branch_name}"
        fi
        return 0
    fi

    # Check if branch exists on remote
    if branch_exists_remote "${branch_name}"; then
        log_warning "Branch '${branch_name}' exists on remote"
        log_info "Fetching and checking out remote branch..."
        if [[ "${DRY_RUN}" == "false" ]]; then
            git -C "${PROJ_ROOT}" fetch origin "${branch_name}" || true
            git -C "${PROJ_ROOT}" checkout -b "${branch_name}" "origin/${branch_name}"
            log_success "Checked out remote branch: ${branch_name}"
        else
            log_info "[DRY RUN] Would fetch and checkout remote branch: ${branch_name}"
        fi
        return 0
    fi

    # Branch doesn't exist - create from primary branch
    log_info "Creating new branch from ${primary_branch}..."

    if [[ "${DRY_RUN}" == "false" ]]; then
        # Checkout primary branch and pull latest changes
        git -C "${PROJ_ROOT}" checkout "${primary_branch}"
        git -C "${PROJ_ROOT}" pull origin "${primary_branch}" || true

        # Check if primary branch has commits, if not create initial commit
        if ! git -C "${PROJ_ROOT}" rev-parse "${primary_branch}" >/dev/null 2>&1 || git -C "${PROJ_ROOT}" rev-list -n 1 "${primary_branch}" 2>/dev/null | grep -q "^$"; then
            log_info "Primary branch has no commits, creating initial commit..."
            touch "${PROJ_ROOT}/.gitignore"
            git -C "${PROJ_ROOT}" add .gitignore
            git -C "${PROJ_ROOT}" commit -m "chore: initial commit"
        fi

        # Create new branch
        git -C "${PROJ_ROOT}" checkout -b "${branch_name}"

        # Push to remote with tracking
        git -C "${PROJ_ROOT}" push -u origin "${branch_name}"

        log_success "Created and pushed branch: ${branch_name}"
    else
        log_info "[DRY RUN] Would:"
        log_info "  - Checkout ${primary_branch}"
        log_info "  - Pull latest changes"
        log_info "  - Create branch: ${branch_name}"
        log_info "  - Push to origin with tracking"
    fi
}

# Handle SUBFOLDER context - provide manual command
handle_subfolder() {
    local branch_name="$1"
    local repo_root
    repo_root=$(get_repo_root)

    echo ""
    echo "========================================"
    echo "  Branch Creation - Manual Action Required"
    echo "========================================"
    echo ""
    log_warning "Working in subdirectory of repository"
    if [[ -n "${repo_root}" ]]; then
        echo "  Repository root: ${repo_root}"
    fi
    echo ""
    echo "  Branch creation skipped - user manages branches"
    echo ""
    echo "  To create the task branch manually, run:"
    echo ""
    echo "    git checkout -b ${branch_name}"
    echo ""
    echo "  Then push to remote:"
    echo ""
    echo "    git push -u origin ${branch_name}"
    echo ""
    echo "========================================"
}

# Handle NO_REPO context - skip silently
handle_no_repo() {
    log_info "No git repository detected - branch creation skipped"
}

#######################################
# Main Function
#######################################

main() {
    parse_args "$@"

    # Generate branch name
    local branch_name
    branch_name=$(generate_branch_name "${TASK_ID}" "${DESCRIPTION}")

    log_info "Task ID: ${TASK_ID}"
    log_info "Branch name: ${branch_name}"

    # Detect repository context
    local context
    context=$(detect_repo_context)

    log_info "Repository context: ${context}"

    # Handle based on context
    case "${context}" in
        REPO_ROOT)
            handle_repo_root "${branch_name}"
            ;;
        SUBFOLDER)
            handle_subfolder "${branch_name}"
            ;;
        NO_REPO)
            handle_no_repo
            ;;
        *)
            log_error "Unknown repository context: ${context}"
            exit 1
            ;;
    esac

    # Log to activity.md if task directory exists
    local activity_file="${RALPH_TASKS_DIR}/${TASK_ID}/activity.md"
    if [[ -f "${activity_file}" ]] && [[ "${DRY_RUN}" == "false" ]]; then
        echo "" >> "${activity_file}"
        echo "## Branch Creation [$(date -u +"%Y-%m-%dT%H:%M:%SZ")]" >> "${activity_file}"
        echo "" >> "${activity_file}"
        echo "Created task branch: ${branch_name}" >> "${activity_file}"
        echo "" >> "${activity_file}"
        echo "Context: ${context}" >> "${activity_file}"
        log_info "Logged branch creation to activity.md"
    fi

    log_success "Task branch creation complete"
}

main "$@"
