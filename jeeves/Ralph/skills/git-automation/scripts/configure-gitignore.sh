#!/bin/bash
# configure-gitignore.sh - Configure gitignore for Ralph Loop
# Task: 0073
#
# This script configures .gitignore with Ralph Loop entries, handling
# three repository contexts: REPO_ROOT, SUBFOLDER, and NO_REPO.
#
# Usage: ./configure-gitignore.sh [--preserve-done]
#
# Options:
#   --preserve-done  Uncomment the !.ralph/tasks/done/ pattern

set -euo pipefail

# Get script directory and source git-context.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=git-context.sh
source "${SCRIPT_DIR}/git-context.sh"

# Section markers for idempotency
readonly START_MARKER="# === RALPH LOOP GITIGNORE ENTRIES START ==="
readonly END_MARKER="# === RALPH LOOP GITIGNORE ENTRIES END ==="

# Gitignore content template
generate_gitignore_content() {
    local preserve_done="${1:-false}"
    local done_entry

    if [[ "${preserve_done}" == "true" ]]; then
        done_entry="!.ralph/tasks/done/     # Preserve completed task history"
    else
        done_entry="# !.ralph/tasks/done/     # Uncomment to preserve completed task history"
    fi

    cat <<EOF
${START_MARKER}
# Ralph Loop - ephemeral task data
.ralph/tasks/*          # Active task data
${done_entry}

# Ralph Loop - log files and temporary files
.ralph/*.log            # Log files
.ralph/.tmp/            # Temporary files
${END_MARKER}
EOF
}

# Determine the correct .gitignore path based on repository context
get_gitignore_path() {
    local context
    context=$(detect_repo_context)

    case "${context}" in
        REPO_ROOT|NO_REPO)
            echo "${PROJ_ROOT}/.gitignore"
            ;;
        SUBFOLDER)
            local repo_root
            repo_root=$(get_repo_root)
            if [[ -n "${repo_root}" ]]; then
                echo "${repo_root}/.gitignore"
            else
                log_error "Failed to determine repository root for SUBFOLDER context"
                return 1
            fi
            ;;
        *)
            log_error "Unknown repository context: ${context}"
            return 1
            ;;
    esac
}

# Check if the Ralph Loop section already exists in the file
has_existing_section() {
    local gitignore_path="${1}"

    if [[ ! -f "${gitignore_path}" ]]; then
        return 1
    fi

    if grep -q "^${START_MARKER}$" "${gitignore_path}" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Update existing section with new content
update_existing_section() {
    local gitignore_path="${1}"
    local new_content="${2}"
    local temp_file
    local start_line
    local end_line

    temp_file=$(mktemp)

    # Find line numbers of markers
    start_line=$(grep -n "^${START_MARKER}$" "${gitignore_path}" | head -1 | cut -d':' -f1)
    end_line=$(grep -n "^${END_MARKER}$" "${gitignore_path}" | head -1 | cut -d':' -f1)

    # Extract content before START_MARKER (if any)
    if [[ ${start_line} -gt 1 ]]; then
        head -n $((start_line - 1)) "${gitignore_path}" > "${temp_file}"
    else
        > "${temp_file}"
    fi

    # Add new content
    echo "${new_content}" >> "${temp_file}"

    # Extract content after END_MARKER (if any)
    local total_lines
    total_lines=$(wc -l < "${gitignore_path}")
    if [[ ${end_line} -lt ${total_lines} ]]; then
        tail -n +$((end_line + 1)) "${gitignore_path}" >> "${temp_file}"
    fi

    # Replace original file
    mv "${temp_file}" "${gitignore_path}"
}

# Append new section to the file
append_new_section() {
    local gitignore_path="${1}"
    local new_content="${2}"

    # Add blank line if file exists and doesn't end with newline
    if [[ -f "${gitignore_path}" ]] && [[ -s "${gitignore_path}" ]]; then
        # Check if file ends with newline
        if [[ -n $(tail -c1 "${gitignore_path}") ]]; then
            echo "" >> "${gitignore_path}"
        fi
        # Add another blank line for separation
        echo "" >> "${gitignore_path}"
    fi

    echo "${new_content}" >> "${gitignore_path}"
}

# Main configuration function
configure_gitignore() {
    local preserve_done="${1:-false}"
    local gitignore_path
    local context

    # Detect repository context
    context=$(detect_repo_context)
    log_info "Detected repository context: ${context}"

    # Get the correct .gitignore path
    gitignore_path=$(get_gitignore_path)
    log_info "Target .gitignore: ${gitignore_path}"

    # Generate content
    local content
    content=$(generate_gitignore_content "${preserve_done}")

    # Check if file exists and has existing section
    if has_existing_section "${gitignore_path}"; then
        log_info "Updating existing Ralph Loop section in ${gitignore_path}"
        update_existing_section "${gitignore_path}" "${content}"
        log_success "Updated Ralph Loop gitignore entries"
    else
        log_info "Adding Ralph Loop section to ${gitignore_path}"
        append_new_section "${gitignore_path}" "${content}"
        log_success "Added Ralph Loop gitignore entries"
    fi

    # Show context-specific message
    if [[ "${context}" == "SUBFOLDER" ]]; then
        log_warning "Note: .gitignore updated at repository root (outside /proj)"
        log_info "Ralph Loop entries will apply to the entire repository"
    fi
}

# Display usage information
show_usage() {
    cat <<EOF
Usage: ${0##*/} [--preserve-done]

Configure .gitignore with Ralph Loop entries for ephemeral task data.

Options:
  --preserve-done    Uncomment the !.ralph/tasks/done/ pattern to preserve
                     completed task history in version control
  -h, --help         Show this help message

Repository Contexts:
  REPO_ROOT   - Adds entries to /proj/.gitignore
  SUBFOLDER   - Finds repo root and adds entries to <repo-root>/.gitignore
  NO_REPO     - Creates /proj/.gitignore (local file only)

The script is idempotent and can be safely run multiple times.
EOF
}

# Main entry point
main() {
    local preserve_done="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --preserve-done)
                preserve_done="true"
                shift
                ;;
            -h|--help)
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

    # Configure gitignore
    configure_gitignore "${preserve_done}"
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
