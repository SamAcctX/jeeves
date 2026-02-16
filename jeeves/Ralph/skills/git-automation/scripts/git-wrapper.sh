#!/bin/bash
# git-wrapper.sh - Safe git operations wrapper with error categorization and retry logic
# Task: 0074
#
# This script provides a safe wrapper for git operations that categorizes errors
# and handles them appropriately according to the "Git enhances but does not block"
# philosophy.
#
# Error Categories:
#   TRANSIENT    - Network issues, timeouts (3x retry with backoff)
#   USER_ERROR   - Auth failures, permission denied (TASK_BLOCKED with instructions)
#   CRITICAL     - Repository corruption, disk full (TASK_BLOCKED immediately)
#   NON-CRITICAL - Push failed, already up-to-date (log warning, continue)
#
# Usage (as library):
#   source /proj/.ralph/skills/git-automation/scripts/git-wrapper.sh
#   git_safe push origin task/0074
#   git_safe checkout main
#
# Usage (standalone):
#   ./git-wrapper.sh <git-command> [args...]

set -euo pipefail

# Configuration
readonly PROJ_ROOT="/proj"
readonly MAX_RETRIES=3
readonly BASE_RETRY_DELAY=2

# Colors for output (disable if not terminal)
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[1;33m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_BLUE='\033[0;34m'
else
    readonly COLOR_RESET=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_RED=''
    readonly COLOR_BLUE=''
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
# Error Categorization
#######################################

# Categorize error from stderr output
# Arguments:
#   $1 - Error message (stderr from git command)
#   $2 - Exit code from git command
# Returns: One of: TRANSIENT, USER_ERROR, CRITICAL, NON-CRITICAL, UNKNOWN
categorize_error() {
    local error_msg="${1:-}"
    local exit_code="${2:-1}"
    local error_lower
    error_lower=$(echo "$error_msg" | tr '[:upper:]' '[:lower:]')

    # CRITICAL: Repository corruption or system-level failures
    if echo "$error_lower" | grep -qE "(fatal:.*corrupt|fatal:.*broken|fatal:.*damaged)"; then
        echo "CRITICAL"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(no space left on device|disk full|write error)"; then
        echo "CRITICAL"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(unable to create|cannot create|permission denied.*create)"; then
        echo "CRITICAL"
        return 0
    fi

    # USER_ERROR: Authentication and permission issues
    if echo "$error_lower" | grep -qE "(permission denied|access denied|unauthorized)"; then
        echo "USER_ERROR"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(authentication failed|invalid username|invalid password|bad credentials)"; then
        echo "USER_ERROR"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(could not read|could not write|could not access)"; then
        echo "USER_ERROR"
        return 0
    fi

    # TRANSIENT: Network and connection issues
    if echo "$error_lower" | grep -qE "(could not resolve host|unknown host|host not found)"; then
        echo "TRANSIENT"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(connection timed out|timeout|timed out)"; then
        echo "TRANSIENT"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(network is unreachable|network unreachable)"; then
        echo "TRANSIENT"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(temporary failure|temporarily unavailable|service unavailable)"; then
        echo "TRANSIENT"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(connection refused|could not connect)"; then
        echo "TRANSIENT"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(ssl|tls|certificate)"; then
        echo "TRANSIENT"
        return 0
    fi

    # NON-CRITICAL: Expected git states that aren't failures
    if echo "$error_lower" | grep -qE "(everything up-to-date|already up to date|already up-to-date)"; then
        echo "NON-CRITICAL"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(nothing to commit|nothing added to commit|working tree clean)"; then
        echo "NON-CRITICAL"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(already exists|already on)"; then
        echo "NON-CRITICAL"
        return 0
    fi

    if echo "$error_lower" | grep -qE "(did not match any|pathspec.*did not match)"; then
        echo "NON-CRITICAL"
        return 0
    fi

    # Check exit code for additional hints
    # Exit code 128 often indicates critical git errors
    if [[ "$exit_code" -eq 128 ]]; then
        echo "CRITICAL"
        return 0
    fi

    # Default to UNKNOWN (treated as non-critical per philosophy)
    echo "UNKNOWN"
    return 0
}

# Get human-readable message for error category
# Arguments:
#   $1 - Error category
# Returns: Human-readable description
get_category_description() {
    case "${1:-UNKNOWN}" in
        TRANSIENT)
            echo "Transient network issue"
            ;;
        USER_ERROR)
            echo "Authentication or permission problem"
            ;;
        CRITICAL)
            echo "Critical repository or system error"
            ;;
        NON-CRITICAL)
            echo "Non-critical git state"
            ;;
        *)
            echo "Unknown error"
            ;;
    esac
}

#######################################
# Retry Logic
#######################################

# Execute command with exponential backoff retry
# Arguments:
#   $1 - Current attempt number
#   $2 - Max retries
#   $3 - Base delay (seconds)
#   ${@:4} - Command and arguments to execute
# Returns: Command exit code
retry_with_backoff() {
    local attempt="${1:-1}"
    local max_retries="${2:-3}"
    local base_delay="${3:-2}"
    shift 3

    if [[ $attempt -ge $max_retries ]]; then
        return 1
    fi

    # Calculate exponential backoff: delay * attempt
    local delay=$((base_delay * attempt))
    log_warning "Retry $((attempt + 1))/$max_retries in ${delay}s..."
    sleep "$delay"

    return 0
}

#######################################
# Main Wrapper Function
#######################################

# Execute git command with error handling and retry logic
# Arguments:
#   $@ - Git command and arguments
# Returns: 0 on success, 1 on failure (after retries exhausted)
# Side effects: Logs to stderr, may emit TASK_BLOCKED signal
git_safe() {
    local attempt=1
    local exit_code=0
    local stderr_output
    local category
    local last_error=""

    while [[ $attempt -le $MAX_RETRIES ]]; do
        # Capture both stdout and stderr, but keep stdout for caller
        stderr_output=$(mktemp)
        
        # Run git command, capture stderr to temp file
        set +e
        git "$@" 2>"$stderr_output"
        exit_code=$?
        set -e

        # Read captured stderr
        local error_msg
        error_msg=$(cat "$stderr_output" 2>/dev/null || echo "")
        rm -f "$stderr_output"

        # Success case
        if [[ $exit_code -eq 0 ]]; then
            if [[ $attempt -gt 1 ]]; then
                log_success "Git command succeeded on attempt $attempt"
            fi
            return 0
        fi

        # Store last error for reporting
        last_error="$error_msg"

        # Categorize the error
        category=$(categorize_error "$error_msg" "$exit_code")

        # Log the error details
        if [[ $attempt -eq 1 ]]; then
            log_error "Git command failed: git $*"
            log_error "Error (${category}): $(get_category_description "$category")"
            if [[ -n "$error_msg" ]]; then
                log_error "Details: $error_msg"
            fi
        fi

        # Handle based on category
        case "$category" in
            TRANSIENT)
                if [[ $attempt -lt $MAX_RETRIES ]]; then
                    retry_with_backoff "$attempt" "$MAX_RETRIES" "$BASE_RETRY_DELAY"
                else
                    log_warning "Transient error persisted after $MAX_RETRIES attempts"
                    log_warning "Git operation failed, continuing without git integration"
                    return 1
                fi
                ;;

            USER_ERROR)
                log_error "Authentication or permission error detected"
                log_error "Fix instructions:"
                log_error "  1. Check your credentials are correct"
                log_error "  2. Verify you have access to the repository"
                log_error "  3. Ensure SSH keys or tokens are properly configured"
                log_error "  4. Try manually: git $*"
                
                # Emit TASK_BLOCKED signal
                echo "TASK_BLOCKED: Git authentication/permission failure - manual intervention required"
                return 1
                ;;

            CRITICAL)
                log_error "Critical repository error detected"
                log_error "This may indicate:"
                log_error "  - Repository corruption"
                log_error "  - Disk space issues"
                log_error "  - Severe configuration problems"
                log_error "Please investigate immediately"
                
                # Emit TASK_BLOCKED signal
                echo "TASK_BLOCKED: Critical git failure - immediate attention required"
                return 1
                ;;

            NON-CRITICAL)
                log_warning "Non-critical git state: continuing without git integration"
                if [[ -n "$error_msg" ]]; then
                    log_warning "Details: $error_msg"
                fi
                # Return success for non-critical issues
                return 0
                ;;

            UNKNOWN)
                log_warning "Unknown git error (exit $exit_code)"
                log_warning "Git operation failed, continuing without git integration"
                if [[ -n "$error_msg" ]]; then
                    log_warning "Error output: $error_msg"
                fi
                # Per philosophy: continue on unknown errors
                return 1
                ;;
        esac

        ((attempt++))
    done

    # Exhausted all retries for transient errors
    log_error "Git command failed after $MAX_RETRIES attempts"
    if [[ -n "$last_error" ]]; then
        log_error "Last error: $last_error"
    fi
    return 1
}

#######################################
# Convenience Wrappers
#######################################

# Safe git push with error handling
git_safe_push() {
    git_safe push "$@"
}

# Safe git pull with error handling
git_safe_pull() {
    git_safe pull "$@"
}

# Safe git fetch with error handling
git_safe_fetch() {
    git_safe fetch "$@"
}

# Safe git checkout with error handling
git_safe_checkout() {
    git_safe checkout "$@"
}

# Safe git commit with error handling
git_safe_commit() {
    git_safe commit "$@"
}

#######################################
# Main (when run directly)
#######################################

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <git-command> [args...]" >&2
        echo "Example: $0 push origin main" >&2
        echo "" >&2
        echo "Or source this script to use functions:" >&2
        echo "  source $0" >&2
        echo "  git_safe push origin main" >&2
        exit 1
    fi

    git_safe "$@"
}

# Run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
