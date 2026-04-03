#!/bin/bash
# state-file-conflicts.sh - Detect conflicts in Ralph state files
# Task: 0072
#
# Usage: ./state-file-conflicts.sh [--fix]
#
# Exit codes:
#   0 - No conflicts detected
#   1 - Conflicts detected (TASK_BLOCKED emitted)
#
# Note: --fix is reserved for future use, currently detection only

set -e

# State files to check
readonly STATE_FILES=(
    "/proj/.ralph/tasks/TODO.md"
    "/proj/.ralph/deps-tracker.yaml"
)

# Colors for output (disable if not terminal)
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_YELLOW='\033[1;33m'
    readonly COLOR_BLUE='\033[0;34m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
fi

#######################################
# Output Functions
#######################################

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

print_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

print_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

show_help() {
    echo "Usage: $(basename "$0") [--fix]"
    echo ""
    echo "Detect conflicts in Ralph state files (TODO.md, deps-tracker.yaml)"
    echo ""
    echo "Options:"
    echo "  --fix    Attempt to fix conflicts (not implemented)"
    echo "  --help, -h  Show this help message"
    echo ""
    echo "Exit codes:"
    echo "  0 - No conflicts detected"
    echo "  1 - Conflicts detected"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                # Reserved for future use
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

parse_args "$@"

#######################################
# Conflict Detection Functions
#######################################

# Check a file for conflict markers
# Arguments:
#   $1 - File path to check
# Returns:
#   0 - No conflicts found
#   1 - Conflicts found
check_file_for_conflicts() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    if grep -q "<<<<<<< " "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Count conflict markers in a file
# Arguments:
#   $1 - File path
# Outputs:
#   Number of conflict marker blocks (each block starts with <<<<<<< )
count_conflicts() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return
    fi
    grep -c "<<<<<<< " "$file" 2>/dev/null || echo "0"
}

#######################################
# Main Logic
#######################################

main() {
    local fix_mode=false
    local has_conflicts=false
    local conflict_files=()
    local conflict_counts=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                fix_mode=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Warn about --fix being reserved
    if [[ "$fix_mode" == true ]]; then
        print_warning "--fix flag provided but auto-fix is not yet implemented. Detection only."
    fi

    # Check each state file for conflicts
    for file in "${STATE_FILES[@]}"; do
        if ! check_file_for_conflicts "$file"; then
            has_conflicts=true
            local count
            count=$(count_conflicts "$file")
            conflict_files+=("$file")
            conflict_counts+=("$count")
        fi
    done

    # Handle detection results
    if [[ "$has_conflicts" == true ]]; then
        # Emit TASK_BLOCKED signal
        echo "TASK_BLOCKED_0000: Conflicts detected in Ralph state files"
        echo ""
        echo "Conflicted files:"

        local i
        for i in "${!conflict_files[@]}"; do
            local file="${conflict_files[$i]}"
            local count="${conflict_counts[$i]}"
            local display_file
            display_file=$(basename "$file")
            echo "  - .ralph/${display_file} (${count} conflict marker$([[ $count -eq 1 ]] || echo s))"
        done

        echo ""
        echo "Resolution: Manually resolve conflicts before continuing."
        echo ""
        echo "Action Required:"
        echo "  1. Review both versions of each conflicted file"
        echo "  2. Decide which changes to keep"
        echo "  3. Remove all conflict markers (<<<<<<<, =======, >>>>>>>)"
        echo "  4. Mark resolved: git add .ralph/tasks/TODO.md .ralph/deps-tracker.yaml"
        echo "  5. Restart loop: ./ralph-loop.sh"
        echo ""

        exit 1
    else
        print_info "No conflicts detected in Ralph state files"
        exit 0
    fi
}

main "$@"
