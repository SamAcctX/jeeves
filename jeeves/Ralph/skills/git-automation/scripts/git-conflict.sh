#!/bin/bash
# git-conflict.sh - Git conflict detection library
# Task: 0071
#
# This script detects git merge conflicts for the Ralph Loop git-automation skill.
# It provides both fast (O(1)) and rich conflict detection mechanisms.
#
# Repository contexts:
#   - REPO_ROOT: Full detection capabilities, can abort operations
#   - SUBFOLDER: Limited detection (path-filtered), information only
#   - NO_REPO: N/A (no git operations)
#
# Usage (as library):
#   source /proj/.ralph/skills/git-automation/scripts/git-conflict.sh
#   check_conflicts || echo "Conflicts detected"
#
# Usage (standalone):
#   /proj/.ralph/skills/git-automation/scripts/git-conflict.sh [--check-critical]

set -euo pipefail

# Source git-context.sh for context detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/git-context.sh"

# Configuration
readonly RALPH_TASKS_DIR="${PROJ_ROOT}/.ralph/tasks"
readonly CRITICAL_FILES=("TODO.md" "deps-tracker.yaml")

# Exit codes
readonly EXIT_NO_CONFLICTS=0
readonly EXIT_CONFLICTS=1
readonly EXIT_NOT_A_REPO=2
readonly EXIT_ERROR=3

#######################################
# Fast Detection Functions (O(1))
#######################################

# Check if a merge or rebase is in progress
# Returns: 0 if merge/rebase in progress, 1 otherwise
is_merge_in_progress() {
    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        return 1
    fi

    # Check for merge/rebase indicators
    if [[ -f "${PROJ_ROOT}/.git/MERGE_HEAD" ]] || \
       [[ -d "${PROJ_ROOT}/.git/rebase-merge" ]] || \
       [[ -d "${PROJ_ROOT}/.git/rebase-apply" ]]; then
        return 0
    fi

    # Also check via git status (works for worktrees and submodules)
    if git -C "${PROJ_ROOT}" rev-parse --verify MERGE_HEAD >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Check if a cherry-pick or revert is in progress
is_cherry_pick_in_progress() {
    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        return 1
    fi

    if [[ -f "${PROJ_ROOT}/.git/CHERRY_PICK_HEAD" ]] || \
       [[ -f "${PROJ_ROOT}/.git/REVERT_HEAD" ]]; then
        return 0
    fi

    return 1
}

#######################################
# Rich Detection Functions
#######################################

# Get list of all conflicted files with their conflict codes
# Output: Lines of "CONFLICT_CODE:filepath"
# Conflict codes (porcelain v1):
#   UU - Both modified (conflict)
#   AA - Both added (conflict)
#   DD - Both deleted (conflict)
#   AU - Added by us, modified by them
#   UA - Modified by us, added by them
#   DU - Deleted by us, modified by them
#   UD - Modified by us, deleted by them
get_conflicted_files() {
    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        return
    fi

    # Use git status --porcelain=v1 to get conflict codes
    # Parse lines starting with conflict codes
    git -C "${PROJ_ROOT}" status --porcelain=v1 2>/dev/null | \
        grep -E "^(UU|AA|DD|AU|UA|DU|UD)" || true
}

# Get human-readable description of conflict code
# Arguments:
#   $1 - Conflict code (UU, AA, DD, AU, UA, DU, UD)
get_conflict_description() {
    local code="${1:-}"

    case "${code}" in
        UU) echo "both modified" ;;
        AA) echo "both added" ;;
        DD) echo "both deleted" ;;
        AU) echo "added by us, modified by them" ;;
        UA) echo "modified by us, added by them" ;;
        DU) echo "deleted by us, modified by them" ;;
        UD) echo "modified by us, deleted by them" ;;
        *) echo "unknown conflict" ;;
    esac
}

# Check for conflicts in specific files
# Arguments:
#   $@ - File paths to check (relative to PROJ_ROOT)
# Returns: 0 if no conflicts, 1 if conflicts found
check_files_for_conflicts() {
    local files=("$@")
    local has_conflicts=0

    if [[ ${#files[@]} -eq 0 ]]; then
        return 0
    fi

    local conflicted
    conflicted=$(get_conflicted_files)

    if [[ -z "${conflicted}" ]]; then
        return 0
    fi

    # Check each file
    for file in "${files[@]}"; do
        # Strip leading ./ if present
        file="${file#./}"

        # Check if this file appears in conflict list
        if echo "${conflicted}" | grep -q "${file}$"; then
            has_conflicts=1
        fi
    done

    return ${has_conflicts}
}

#######################################
# Ralph-Specific Conflict Detection
#######################################

# Check for conflicts in Ralph critical state files
# Returns: 0 if no conflicts, 1 if conflicts found
check_critical_files_for_conflicts() {
    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        return 0
    fi

    local has_conflicts=0

    for file in "${CRITICAL_FILES[@]}"; do
        local filepath="${RALPH_TASKS_DIR}/${file}"

        # Check if file exists and has conflicts
        if [[ -f "${filepath}" ]]; then
            # Use the specific check from TASK.md requirements
            if git -C "${PROJ_ROOT}" status --porcelain=v1 2>/dev/null | \
               grep -E "^(UU|AA|DD|AU|UA|DU|UD)" | \
               grep -q "${file}$"; then
                has_conflicts=1
            fi
        fi
    done

    return ${has_conflicts}
}

#######################################
# Main Conflict Check
#######################################

# Check for conflicts and return appropriate status
# Options:
#   --critical-only  Only check Ralph critical files (TODO.md, deps-tracker.yaml)
#   --verbose        Output detailed information
# Returns:
#   0 = No conflicts
#   1 = Conflicts detected
#   2 = Not in a git repository
#   3 = Error
check_conflicts() {
    local critical_only=false
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --critical-only)
                critical_only=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        if [[ "${verbose}" == true ]]; then
            log_warning "Not in a git repository"
        fi
        return ${EXIT_NOT_A_REPO}
    fi

    # Fast check: Is merge/rebase in progress?
    if ! is_merge_in_progress; then
        # No merge in progress, so no conflicts possible
        return ${EXIT_NO_CONFLICTS}
    fi

    if [[ "${verbose}" == true ]]; then
        log_info "Merge/rebase in progress, checking for conflicts..."
    fi

    # Rich check: Get conflicted files
    local conflicted_files
    conflicted_files=$(get_conflicted_files)

    if [[ -z "${conflicted_files}" ]]; then
        # Merge in progress but no conflicts yet
        return ${EXIT_NO_CONFLICTS}
    fi

    # Check if we're only looking at critical files
    if [[ "${critical_only}" == true ]]; then
        if check_critical_files_for_conflicts; then
            return ${EXIT_NO_CONFLICTS}
        else
            return ${EXIT_CONFLICTS}
        fi
    fi

    # Conflicts detected
    return ${EXIT_CONFLICTS}
}

#######################################
# Report Generation
#######################################

# Generate a conflict report for activity.md or stdout
# Options:
#   --format {text|markdown}  Output format (default: text)
#   --include-critical-only   Only include Ralph critical files
generate_conflict_report() {
    local format="text"
    local critical_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                format="${2:-text}"
                shift 2
                ;;
            --critical-only)
                critical_only=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    local context
    context=$(detect_repo_context)

    if [[ "${context}" == "NO_REPO" ]]; then
        echo "No git repository detected."
        return
    fi

    local conflicted_files
    conflicted_files=$(get_conflicted_files)

    if [[ -z "${conflicted_files}" ]]; then
        if [[ "${format}" == "markdown" ]]; then
            echo "No conflicts detected."
        else
            echo "No conflicts detected."
        fi
        return
    fi

    # Generate report header
    if [[ "${format}" == "markdown" ]]; then
        echo "## CONFLICT DETECTED"
        echo ""
        echo "**Status:** Merge/rebase in progress with conflicts"
        echo ""
        echo "### Files with Conflicts"
        echo ""
    else
        echo "CONFLICT DETECTED"
        echo "================="
        echo ""
        echo "Files with conflicts:"
    fi

    # List conflicted files
    while IFS= read -r line; do
        local code="${line:0:2}"
        local file="${line:3}"
        local description
        description=$(get_conflict_description "${code}")

        if [[ "${format}" == "markdown" ]]; then
            echo "- ${file} (${code} - ${description})"
        else
            echo "  - ${file} (${code} - ${description})"
        fi
    done <<< "${conflicted_files}"

    # Filter for critical files if requested
    if [[ "${critical_only}" == true ]]; then
        local critical_conflicts=""
        for critical_file in "${CRITICAL_FILES[@]}"; do
            if echo "${conflicted_files}" | grep -q "${critical_file}$"; then
                critical_conflicts="${critical_conflicts}${critical_file} "
            fi
        done

        if [[ -n "${critical_conflicts}" ]]; then
            if [[ "${format}" == "markdown" ]]; then
                echo ""
                echo "### CRITICAL: Ralph State Files Conflicted"
                echo ""
                echo "The following critical Ralph state files have conflicts:"
                echo "- ${critical_conflicts}"
                echo ""
                echo "**Action Required:** Manual resolution required before proceeding."
            else
                echo ""
                echo "CRITICAL: Ralph State Files Conflicted"
                echo "======================================="
                echo ""
                echo "Files: ${critical_conflicts}"
            fi
        fi
    fi

    if [[ "${format}" == "markdown" ]]; then
        echo ""
        echo "### Resolution Required"
        echo ""
        echo "Manual conflict resolution is required before proceeding."
        echo "Review the conflicting files, resolve the conflicts, and run:"
        echo '```bash'
        echo 'git add <resolved-files>'
        echo 'git commit  # or git rebase --continue'
        echo '```'
    else
        echo ""
        echo "Resolution required before proceeding."
    fi
}

# Emit TASK_BLOCKED signal for Ralph Loop
# This is the specific function called by ralph-loop.sh
emit_task_blocked_signal() {
    local task_id="${1:-}"

    echo "ERROR: Git conflict detected in Ralph state files"

    if [[ -n "${task_id}" ]]; then
        echo "TASK_BLOCKED_${task_id}: Git merge conflict requires human resolution"
    else
        echo "TASK_BLOCKED: Git merge conflict requires human resolution"
    fi

    echo ""
    echo "Conflicting files:"
    for file in "${CRITICAL_FILES[@]}"; do
        echo "  - ${file}"
    done

    echo ""
    echo "Manual resolution steps:"
    echo "  1. Review conflicts in the files above"
    echo "  2. Resolve the conflicts manually"
    echo "  3. Stage resolved files: git add .ralph/tasks/<file>"
    echo "  4. Complete the merge: git commit"
    echo "  5. Restart Ralph Loop"
}

#######################################
# Main Function (when run directly)
#######################################

print_usage() {
    cat << EOF
Usage: ${0##*/} [OPTIONS]

Git conflict detection library for Ralph Loop.

Options:
    --check-critical    Check only Ralph critical files (TODO.md, deps-tracker.yaml)
    --check-all         Check all conflicted files
    --report            Generate conflict report
    --report-markdown   Generate conflict report in markdown format
    --is-merge          Check if merge/rebase is in progress (exit 0 if yes)
    --get-files         List all conflicted files
    --help              Show this help message

Exit codes:
    0 = No conflicts / Merge in progress (for --is-merge)
    1 = Conflicts detected
    2 = Not in a git repository
    3 = Error

Examples:
    # Check for conflicts in Ralph critical files
    ${0##*/} --check-critical

    # Generate a report
    ${0##*/} --report

    # Use as library
    source ${0}
    check_conflicts --critical-only || echo "Conflicts found"
EOF
}

main() {
    local command=""

    # Parse command
    case "${1:-}" in
        --check-critical)
            command="check-critical"
            ;;
        --check-all)
            command="check-all"
            ;;
        --report)
            command="report"
            ;;
        --report-markdown)
            command="report-markdown"
            ;;
        --is-merge)
            command="is-merge"
            ;;
        --get-files)
            command="get-files"
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        "")
            # Default: check all
            command="check-all"
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit ${EXIT_ERROR}
            ;;
    esac

    case "${command}" in
        check-critical)
            if check_conflicts --critical-only; then
                log_success "No conflicts in Ralph critical files"
                exit ${EXIT_NO_CONFLICTS}
            else
                log_error "Conflicts detected in Ralph critical files"
                emit_task_blocked_signal
                exit ${EXIT_CONFLICTS}
            fi
            ;;

        check-all)
            if check_conflicts; then
                log_success "No conflicts detected"
                exit ${EXIT_NO_CONFLICTS}
            else
                log_error "Conflicts detected"
                generate_conflict_report
                exit ${EXIT_CONFLICTS}
            fi
            ;;

        report)
            generate_conflict_report --format text
            ;;

        report-markdown)
            generate_conflict_report --format markdown
            ;;

        is-merge)
            if is_merge_in_progress; then
                echo "Merge/rebase in progress"
                exit 0
            else
                echo "No merge/rebase in progress"
                exit 1
            fi
            ;;

        get-files)
            local files
            files=$(get_conflicted_files)
            if [[ -n "${files}" ]]; then
                echo "${files}"
            else
                echo "No conflicted files"
            fi
            ;;
    esac
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
