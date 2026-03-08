#!/bin/bash
set -e
set -o pipefail

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local log_line="[$timestamp] [$level] $message"
    
    case "$level" in
        INFO) print_info "$message" ;;
        SUCCESS) print_success "$message" ;;
        WARNING) print_warning "$message" ;;
        ERROR) print_error "$message" ;;
    esac
    
    if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
        echo "$log_line" >> "$LOG_FILE"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_SAVE_ARGS=("$@")
set --
source "$SCRIPT_DIR/ralph-paths.sh" 2>/dev/null || true
source "$SCRIPT_DIR/ralph-validate.sh" 2>/dev/null || true
set -- "${_SAVE_ARGS[@]}"
unset _SAVE_ARGS

ITERATION=0
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-100}
SELECTED_TOOL="opencode"
CLI_TOOL=""
SHOULD_TERMINATE=0
NO_DELAY=0
SKIP_SYNC=0
DRY_RUN=false
VERBOSE=0

RALPH_BACKOFF_BASE=${RALPH_BACKOFF_BASE:-2}
RALPH_BACKOFF_MAX=${RALPH_BACKOFF_MAX:-60}
RALPH_DIR=".ralph"
PROJECT_ROOT=""

LOG_FILE=""
LOG_DIR="logs"

PROMPT_FILE="/opt/jeeves/Ralph/templates/prompts/ralph-prompt.md.template"
MANAGER_OUTPUT=""
MANAGER_EXIT_CODE=0

cleanup_on_error() {
    local line_num=$1
    print_error "Error occurred on line $line_num"
}

cleanup() {
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        print_warning "Ralph Loop exiting with code: $exit_code"
    else
        print_success "Ralph Loop completed successfully"
    fi
}

handle_interrupt() {
    print_warning "Received interrupt signal - shutting down gracefully..."
    SHOULD_TERMINATE=1
    exit 130
}

validate_max_iterations() {
    if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
        print_warning "Invalid RALPH_MAX_ITERATIONS: '$MAX_ITERATIONS' - defaulting to unlimited"
        MAX_ITERATIONS=0
    elif [ "$MAX_ITERATIONS" -lt 0 ]; then
        print_warning "Negative RALPH_MAX_ITERATIONS: '$MAX_ITERATIONS' - defaulting to unlimited"
        MAX_ITERATIONS=0
    fi
}

check_iteration_limit() {
    if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -ge "$MAX_ITERATIONS" ]; then
        print_warning "GLOBAL_ITERATION_LIMIT_REACHED: $MAX_ITERATIONS iterations"
        return 1
    fi
    return 0
}

calculate_delay() {
    local iteration="$1"
    
    if [ "$NO_DELAY" -eq 1 ]; then
        echo "0"
        return
    fi
    
    local base="${RALPH_BACKOFF_BASE:-2}"
    local max="${RALPH_BACKOFF_MAX:-60}"
    
    local delay=$((base * (2 ** iteration)))
    if [ "$delay" -gt "$max" ]; then
        delay=$max
    fi
    
    local jitter=$(awk "BEGIN {printf \"%.2f\", ($RANDOM % 100) / 100}")
    awk "BEGIN {printf \"%.2f\", $delay + $jitter}"
}

sleep_with_backoff() {
    local iteration="$1"
    
    if [ "$NO_DELAY" -eq 1 ]; then
        return
    fi
    
    local delay=$(calculate_delay "$iteration")
    
    if awk "BEGIN {exit !($delay > 0)}"; then
        return
    fi
    
    print_info "Sleeping for ${delay}s before next iteration..."
    sleep "$delay"
}

verify_sync_agents() {
    if ! command -v sync-agents.sh &> /dev/null; then
        print_warning "sync-agents not found in PATH"
        return 1
    fi
    return 0
}

run_sync_agents() {
    if [ "$SKIP_SYNC" -eq 1 ]; then
        print_info "Skipping agent sync (--skip-sync)"
        return 0
    fi
    
    if ! verify_sync_agents; then
        print_warning "Agent sync skipped (tool not found)"
        return 0
    fi
    
    print_info "Running agent synchronization..."
    export RALPH_TOOL="$SELECTED_TOOL"
    
    local start_time=$(date +%s)
    
    if sync-agents.sh; then
        local duration=$(($(date +%s) - start_time))
        print_success "Agent sync completed in ${duration}s"
    else
        local duration=$(($(date +%s) - start_time))
        print_warning "Agent sync failed after ${duration}s (continuing anyway)"
    fi

    print_info "Restarting opencode web service to reload updated agents..."
    if opencode-web restart; then
        print_success "Opencode web service restarted"
    else
        print_warning "Opencode web service restart failed"
        print_warning "Opencode CLI may use outdated agent models, and may error, but will try anyways"
    fi

}

CRITICAL_FILES=(
    ".ralph/tasks/TODO.md"
    ".ralph/tasks/deps-tracker.yaml"
)

check_for_conflicts() {
    local has_conflict=0
    local conflict_files=""
    
    if ! git rev-parse --git-dir &> /dev/null; then
        return 0
    fi
    
    print_info "Checking for git conflicts..."
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi
        
        if git status --porcelain "$file" 2>/dev/null | grep -q "^UU"; then
            has_conflict=1
            conflict_files="$conflict_files $file"
            print_error "Git conflict detected: $file"
        fi
        
        if grep -q "^<<<<<<<" "$file" 2>/dev/null || \
           grep -q "^=======$" "$file" 2>/dev/null || \
           grep -q "^>>>>>>>" "$file" 2>/dev/null; then
            has_conflict=1
            conflict_files="$conflict_files $file"
            print_error "Conflict markers in: $file"
        fi
    done
    
    if [ $has_conflict -eq 1 ]; then
        print_error "TASK_BLOCKED_0000: Git merge conflict requires resolution in:$conflict_files"
        SHOULD_TERMINATE=1
        return 1
    fi
    
    return 0
}

should_terminate() {
    local todo_file="$PROJECT_ROOT/$RALPH_DIR/tasks/TODO.md"
    
    if [ "$SHOULD_TERMINATE" -eq 1 ]; then
        return 0
    fi
    
    check_iteration_limit
    if [ $? -eq 1 ]; then
        return 0
    fi
    
    if parse_todo_md "$todo_file"; then
        return 0
    fi
    
    return 1
}

invoke_manager() {
    print_info "Invoking Manager agent (iteration $ITERATION, tool: $SELECTED_TOOL)..."

    local prompt_path="$PROMPT_FILE"
    if [[ ! "$PROMPT_FILE" =~ ^/ ]]; then
        prompt_path="$PROJECT_ROOT/$PROMPT_FILE"
    fi

    if [ ! -f "$prompt_path" ]; then
        print_error "Prompt file not found: $prompt_path"
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would invoke: $SELECTED_TOOL"
        echo "TASK_COMPLETE_0001"
        return 0
    fi
    
    case "$SELECTED_TOOL" in
        opencode)
            invoke_opencode_manager "$prompt_path"
            ;;
        claude)
            invoke_claude_manager "$prompt_path"
            ;;
        *)
            print_error "Unknown tool: $SELECTED_TOOL"
            return 1
            ;;
    esac
    
    MANAGER_EXIT_CODE=$?
    return $MANAGER_EXIT_CODE
}

invoke_opencode_manager() {
    local prompt_path="$1"
    local model_arg=""
    local format_arg=""
    
    if [ -n "$RALPH_MANAGER_MODEL" ]; then
        model_arg="--model $RALPH_MANAGER_MODEL"
    fi
    
    if [ "$VERBOSE" -eq 1 ]; then
        format_arg="--format json"
    fi
    
    log_message INFO "Invoking OpenCode Manager (iteration: $ITERATION, max: $MAX_ITERATIONS, tool: $SELECTED_TOOL)"
    
    MANAGER_OUTPUT=$(mktemp)
    local start_time=$(date +%s)
    
    if opencode run --agent manager --attach http://localhost:3333 $model_arg $format_arg < "$prompt_path" | tee "$MANAGER_OUTPUT"; then
        local duration=$(($(date +%s) - start_time))
        strip_ansi "$MANAGER_OUTPUT"
        log_message INFO "OpenCode Manager completed (iteration: $ITERATION, duration: ${duration}s, exit_code: 0)"
        return 0
    else
        local exit_code=$?
        local duration=$(($(date +%s) - start_time))
        strip_ansi "$MANAGER_OUTPUT"
        log_message WARNING "OpenCode Manager invocation returned non-zero exit code (iteration: $ITERATION, duration: ${duration}s, exit_code: $exit_code)"
        return 1
    fi
}

invoke_claude_manager() {
    local prompt_path="$1"
    local model_arg=""
    local verbose_arg=""
    
    if [ -n "$RALPH_MANAGER_MODEL" ]; then
        model_arg="--model $RALPH_MANAGER_MODEL"
    fi
    
    if [ "$VERBOSE" -eq 1 ]; then
        verbose_arg="--verbose"
    fi
    
    log_message INFO "Invoking Claude Manager (iteration: $ITERATION, max: $MAX_ITERATIONS, tool: $SELECTED_TOOL)"
    
    MANAGER_OUTPUT=$(mktemp)
    local start_time=$(date +%s)
    
    if claude -p --dangerously-skip-permissions $model_arg $verbose_arg < "$prompt_path"  | tee "$MANAGER_OUTPUT"; then
        local duration=$(($(date +%s) - start_time))
        log_message INFO "Claude Manager completed (iteration: $ITERATION, duration: ${duration}s, exit_code: 0)"
        return 0
    else
        local duration=$(($(date +%s) - start_time))
        log_message WARNING "Claude Manager invocation returned non-zero exit code (iteration: $ITERATION, duration: ${duration}s, exit_code: $?)"
        return 1
    fi
}

SIGNAL_COMPLETE="TASK_COMPLETE_[0-9]{4}"
SIGNAL_INCOMPLETE="TASK_INCOMPLETE_[0-9]{4}"
SIGNAL_FAILED="TASK_FAILED_[0-9]{4}"
SIGNAL_BLOCKED="TASK_BLOCKED_[0-9]{4}"

strip_ansi() {
    local file="$1"
    if [ -f "$file" ]; then
        sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$file"
    fi
}

extract_task_id() {
    local signal="$1"
    echo "$signal" | grep -oE "[0-9]{4}" | head -1
}

extract_signal_message() {
    local output="$1"
    local signal="$2"
    
    if echo "$output" | grep -qE "${signal}.*:"; then
        echo "$output" | grep -oE "${signal}:.*" | head -1 | sed 's/[^:]*: \?//'
    else
        echo ""
    fi
}

handle_complete_signal() {
    local task_id="$1"
    log_message SUCCESS "Task $task_id completed (iteration: $ITERATION)"
}

handle_incomplete_signal() {
    local task_id="$1"
    log_message INFO "Task $task_id incomplete - continuing loop (iteration: $ITERATION)"
}

handle_failed_signal() {
    local task_id="$1"
    local message="$2"
    log_message WARNING "Task $task_id failed: $message (iteration: $ITERATION)"
}

handle_blocked_signal() {
    local task_id="$1"
    local message="$2"
    log_message ERROR "Task $task_id blocked: $message (iteration: $ITERATION)"
    SHOULD_TERMINATE=1
}

parse_todo_md() {
    local todo_file="$PROJECT_ROOT/$RALPH_DIR/tasks/TODO.md"
    
    if [ ! -f "$todo_file" ]; then
        return 1
    fi
    
    if grep -qE "^ABORT: HELP NEEDED" "$todo_file"; then
        print_error "ABORT: HELP NEEDED detected in TODO.md - terminating"
        SHOULD_TERMINATE=1
        return 0
    fi
    
    if grep -qE "^ALL[_ ]TASKS[_ ]COMPLETE, EXIT LOOP" "$todo_file"; then
        print_info "ALL TASKS COMPLETE, EXIT LOOP sentinel detected"
        SHOULD_TERMINATE=1
        return 0
    fi
    
    return 1
}

parse_signals() {
    local output_file="$1"
    
    if [ ! -f "$output_file" ]; then
        print_warning "No output file to parse (iteration: $ITERATION)"
        return 1
    fi
    
    log_message INFO "Parsing signals from output (iteration: $ITERATION, file: $output_file)"
    
    local all_signals
    all_signals=$(grep -E "^(TASK_COMPLETE|TASK_INCOMPLETE|TASK_FAILED|TASK_BLOCKED)_[0-9]{4}" "$output_file" 2>/dev/null || true)
    
    local signal_count=0
    if [ -n "$all_signals" ]; then
        signal_count=$(echo "$all_signals" | wc -l | tr -d ' ')
    fi
    
    if [ "$signal_count" -gt 1 ]; then
        print_warning "Multiple start-of-line signals detected ($signal_count) - using first"
        print_info "Signals found:"
        echo "$all_signals" | head -5 | while read -r sig; do
            print_info "  - $sig"
        done
        if [ "$signal_count" -gt 5 ]; then
            print_info "  ... and $((signal_count - 5)) more"
        fi
    fi
    
    local line
    line=$(echo "$all_signals" | head -1)
    
    if [ -z "$line" ]; then
        print_info "No start-of-line signal found in output (iteration: $ITERATION)"
        print_info "Output file size: $(wc -c < "$output_file" 2>/dev/null || echo 'unknown') bytes"
        local mid_line_signals
        mid_line_signals=$(grep -oE "(TASK_COMPLETE|TASK_INCOMPLETE|TASK_FAILED|TASK_BLOCKED)_[0-9]{4}" "$output_file" 2>/dev/null || true)
        if [ -n "$mid_line_signals" ]; then
            local mid_count
            mid_count=$(echo "$mid_line_signals" | wc -l | tr -d ' ')
            print_warning "Found $mid_count signal(s) embedded mid-line (ignored per SIG-P0-01):"
            echo "$mid_line_signals" | head -3 | while read -r sig; do
                print_info "  - $sig"
            done
        else
            local last_lines
            last_lines=$(tail -20 "$output_file" 2>/dev/null | grep -v '^[[:space:]]*$' | head -10)
            if [ -n "$last_lines" ]; then
                print_info "Last non-empty lines from output:"
                echo "$last_lines" | while read -r l; do
                    print_info "  $l"
                done
            else
                print_info "Output file appears to be empty or contain only whitespace"
            fi
        fi
        return 1
    fi
    
    local signal_token
    signal_token=$(echo "$line" | grep -oE "^(TASK_COMPLETE|TASK_INCOMPLETE|TASK_FAILED|TASK_BLOCKED)_[0-9]{4}")
    
    if echo "$signal_token" | grep -qE "^$SIGNAL_COMPLETE$"; then
        local task_id
        task_id=$(extract_task_id "$signal_token")
        handle_complete_signal "$task_id"
        return 0
    fi
    
    if echo "$signal_token" | grep -qE "^$SIGNAL_BLOCKED$"; then
        local task_id message
        task_id=$(extract_task_id "$signal_token")
        message=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]*$//')
        handle_blocked_signal "$task_id" "$message"
        return 0
    fi
    
    if echo "$signal_token" | grep -qE "^$SIGNAL_FAILED$"; then
        local task_id message
        task_id=$(extract_task_id "$signal_token")
        message=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]*$//')
        handle_failed_signal "$task_id" "$message"
        return 0
    fi
    
    if echo "$signal_token" | grep -qE "^$SIGNAL_INCOMPLETE$"; then
        local task_id
        task_id=$(extract_task_id "$signal_token")
        handle_incomplete_signal "$task_id"
        return 0
    fi
    
    print_warning "Unrecognized signal format: $line"
    return 1
}

parse_manager_signal() {
    local output="$1"
    
    if echo "$output" | grep -qE "^TASK_COMPLETE_[0-9]{4}"; then
        echo "COMPLETE"
        return 0
    fi
    
    if echo "$output" | grep -qE "^TASK_INCOMPLETE_[0-9]{4}"; then
        echo "INCOMPLETE"
        return 0
    fi
    
    if echo "$output" | grep -qE "^TASK_FAILED_[0-9]{4}"; then
        echo "FAILED"
        return 0
    fi
    
    if echo "$output" | grep -qE "^TASK_BLOCKED_[0-9]{4}"; then
        echo "BLOCKED"
        return 0
    fi
    
    echo "UNKNOWN"
    return 1
}

main_loop() {
    local loop_start_time=$(date +%s)
    
    if [ "$MAX_ITERATIONS" -gt 0 ]; then
        log_message INFO "Starting Ralph Loop (iteration: $ITERATION, max: $MAX_ITERATIONS)"
    else
        log_message INFO "Starting Ralph Loop (iteration: $ITERATION, max: unlimited)"
    fi
    
    while true; do
        check_for_conflicts
        if [ $? -eq 1 ]; then
            log_message ERROR "Conflict detected - terminating loop (iteration: $ITERATION)"
            break
        fi
        
        if should_terminate; then
            log_message INFO "Termination conditions met - exiting loop (iteration: $ITERATION)"
            break
        fi
        
        log_message INFO "=== Iteration $ITERATION ==="
        
        invoke_manager
        MANAGER_EXIT_CODE=$?
        
        if [ -n "$MANAGER_OUTPUT" ] && [ -f "$MANAGER_OUTPUT" ]; then
            if parse_signals "$MANAGER_OUTPUT"; then
                log_message INFO "Signal processed successfully (iteration: $ITERATION)"
            else
                log_message WARNING "No valid signal found in Manager output (iteration: $ITERATION, see above for details)"
            fi
        else
            log_message WARNING "No Manager output file available (iteration: $ITERATION)"
            if [ -n "$MANAGER_OUTPUT" ]; then
                log_message WARNING "Output path was: $MANAGER_OUTPUT (file does not exist)"
            fi
        fi
        
        if [ "$SHOULD_TERMINATE" -eq 1 ]; then
            log_message INFO "Termination flag set - exiting loop (iteration: $ITERATION)"
            break
        fi
        
        ITERATION=$((ITERATION + 1))
        
        sleep_with_backoff "$ITERATION"
    done
    
    local total_duration=$(($(date +%s) - loop_start_time))
    log_message SUCCESS "Ralph Loop finished after $ITERATION iterations (total duration: ${total_duration}s)"
}

parse_arguments() {
    CLI_TOOL=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool|-t)
                CLI_TOOL="$2"
                shift 2
                ;;
            --max-iterations|-m)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            --skip-sync|-s)
                SKIP_SYNC=1
                shift
                ;;
            --no-delay|-n)
                NO_DELAY=1
                shift
                ;;
            --dry-run|-d)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

determine_tool() {
    if [ -n "$CLI_TOOL" ]; then
        SELECTED_TOOL="$CLI_TOOL"
    elif [ -n "$RALPH_TOOL" ]; then
        SELECTED_TOOL="$RALPH_TOOL"
    else
        SELECTED_TOOL="opencode"
    fi
}

validate_tool() {
    case "$SELECTED_TOOL" in
        opencode|claude) return 0 ;;
        *) print_error "Invalid tool: '$SELECTED_TOOL'. Valid tools are: opencode, claude"; exit 1 ;;
    esac
}

show_usage() {
    cat << 'USAGE'
Usage: ralph-loop.sh [OPTIONS]

Ralph Loop - Autonomous AI task execution

Options:
    -t, --tool {opencode|claude}    Select AI tool (default: opencode)
    -m, --max-iterations N          Maximum iterations (default: 100, 0=unlimited)
    -s, --skip-sync                 Skip pre-loop agent synchronization
    -n, --no-delay                  Disable backoff delays
    -d, --dry-run                   Print commands without executing
    -v, --verbose                   Enable JSON format output in OpenCode
    -h, --help                      Show this help message

Environment Variables:
    RALPH_TOOL                  Default tool selection
    RALPH_MAX_ITERATIONS        Maximum loop iterations
    RALPH_BACKOFF_BASE          Backoff base delay (default: 2)
    RALPH_BACKOFF_MAX           Backoff max delay (default: 60)
    RALPH_MANAGER_MODEL         Override Manager model (optional;
                                OpenCode: model="" in frontmatter;
                                Claude: model=inherit from frontmatter)

Logging:
    A log file with timestamps is automatically created at:
    .ralph/logs/ralph-loop-YYYYMMDD-HHMMSS.log

USAGE
}

initialize() {
    trap 'cleanup_on_error $LINENO' ERR
    trap 'cleanup' EXIT
    trap 'handle_interrupt' INT TERM
    
    PROJECT_ROOT=$(find_project_root)
    
    validate_max_iterations
    determine_tool
    validate_tool
    
    if [ ! -d "$PROJECT_ROOT/$RALPH_DIR" ]; then
        print_error "Ralph directory not found: $PROJECT_ROOT/$RALPH_DIR"
        exit 1
    fi
    
    local log_dir="$PROJECT_ROOT/$RALPH_DIR/$LOG_DIR"
    mkdir -p "$log_dir"
    LOG_FILE="$log_dir/ralph-loop-$(date +%Y%m%d-%H%M%S).log"
    touch "$LOG_FILE"
    
    log_message INFO "Ralph Loop initialized"
    log_message INFO "  Tool: $SELECTED_TOOL"
    if [ "$MAX_ITERATIONS" -gt 0 ]; then
        log_message INFO "  Max iterations: $MAX_ITERATIONS"
    else
        log_message INFO "  Max iterations: unlimited"
    fi
    log_message INFO "  Project root: $PROJECT_ROOT"
    log_message INFO "  Log file: $LOG_FILE"
}

main() {
    parse_arguments "$@"
    initialize
    run_sync_agents
    main_loop
}

main "$@"
