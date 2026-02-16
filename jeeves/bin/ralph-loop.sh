#!/bin/bash
set -e
set -o pipefail

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

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

RALPH_BACKOFF_BASE=${RALPH_BACKOFF_BASE:-2}
RALPH_BACKOFF_MAX=${RALPH_BACKOFF_MAX:-60}
RALPH_DIR=".ralph"
PROJECT_ROOT=""

PROMPT_FILE=".ralph/prompts/ralph-prompt.md"
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
    if ! command -v sync-agents &> /dev/null; then
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
    
    if sync-agents; then
        local duration=$(($(date +%s) - start_time))
        print_success "Agent sync completed in ${duration}s"
    else
        local duration=$(($(date +%s) - start_time))
        print_warning "Agent sync failed after ${duration}s (continuing anyway)"
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
    
    local prompt_path="$PROJECT_ROOT/$PROMPT_FILE"
    
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
    
    [ -n "$RALPH_MANAGER_MODEL" ] && model_arg="--model $RALPH_MANAGER_MODEL"
    
    print_info "Invoking OpenCode Manager..."
    
    MANAGER_OUTPUT=$(mktemp)
    
    if opencode --agent manager $model_arg < "$prompt_path" 2>&1 | tee "$MANAGER_OUTPUT"; then
        return 0
    else
        print_warning "OpenCode Manager invocation returned non-zero exit code"
        return 1
    fi
}

invoke_claude_manager() {
    local prompt_path="$1"
    local model="${RALPH_MANAGER_MODEL:-opus}"
    
    print_info "Invoking Claude Manager (model: $model)..."
    
    MANAGER_OUTPUT=$(mktemp)
    
    if claude -p --dangerously-skip-permissions --model "$model" < "$prompt_path" 2>&1 | tee "$MANAGER_OUTPUT"; then
        return 0
    else
        print_warning "Claude Manager invocation returned non-zero exit code"
        return 1
    fi
}

SIGNAL_COMPLETE="TASK_COMPLETE_[0-9]{4}"
SIGNAL_INCOMPLETE="TASK_INCOMPLETE_[0-9]{4}"
SIGNAL_FAILED="TASK_FAILED_[0-9]{4}"
SIGNAL_BLOCKED="TASK_BLOCKED_[0-9]{4}"

extract_task_id() {
    local signal="$1"
    echo "$signal" | grep -oE "[0-9]{4}" | head -1
}

extract_signal_message() {
    local output="$1"
    local signal="$2"
    
    if echo "$output" | grep -qE "${signal}.*:"; then
        echo "$output" | grep -oE "${signal}:.*" | head -1 | sed 's/[^:]*: //'
    else
        echo ""
    fi
}

handle_complete_signal() {
    local task_id="$1"
    print_success "Task $task_id completed"
    SHOULD_TERMINATE=1
}

handle_incomplete_signal() {
    local task_id="$1"
    print_info "Task $task_id incomplete - continuing loop"
}

handle_failed_signal() {
    local task_id="$1"
    local message="$2"
    print_warning "Task $task_id failed: $message"
}

handle_blocked_signal() {
    local task_id="$1"
    local message="$2"
    print_error "Task $task_id blocked: $message"
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
    
    if grep -qE "^ALL TASKS COMPLETE, EXIT LOOP" "$todo_file"; then
        print_info "ALL TASKS COMPLETE, EXIT LOOP sentinel detected"
        SHOULD_TERMINATE=1
        return 0
    fi
    
    return 1
}

parse_signals() {
    local output_file="$1"
    
    if [ ! -f "$output_file" ]; then
        print_warning "No output file to parse"
        return 1
    fi
    
    local signal_count=$(grep -c -oE "(^|[[:space:]])(TASK_COMPLETE|TASK_INCOMPLETE|TASK_FAILED|TASK_BLOCKED)_[0-9]{4}" "$output_file" 2>/dev/null || echo "0")
    
    if [ "$signal_count" -gt 1 ]; then
        print_warning "Multiple signals detected ($signal_count) - using first valid signal"
    fi
    
    local line
    line=$(grep -oE "(^|[[:space:]])(TASK_COMPLETE|TASK_INCOMPLETE|TASK_FAILED|TASK_BLOCKED)_[0-9]{4}(:.*)?($|[[:space:]])" "$output_file" 2>/dev/null | head -1)
    
    if [ -z "$line" ]; then
        print_info "No signal found in output"
        return 1
    fi
    
    line=$(echo "$line" | sed 's/^[[:space:]]*//')
    
    if echo "$line" | grep -qE "^$SIGNAL_COMPLETE($|[[:space:]]|$)"; then
        local task_id
        task_id=$(extract_task_id "$line")
        handle_complete_signal "$task_id"
        return 0
    fi
    
    if echo "$line" | grep -qE "^$SIGNAL_BLOCKED"; then
        local task_id message
        task_id=$(extract_task_id "$line")
        message=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]*$//')
        handle_blocked_signal "$task_id" "$message"
        return 0
    fi
    
    if echo "$line" | grep -qE "^$SIGNAL_FAILED"; then
        local task_id message
        task_id=$(extract_task_id "$line")
        message=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]*$//')
        handle_failed_signal "$task_id" "$message"
        return 0
    fi
    
    if echo "$line" | grep -qE "^$SIGNAL_INCOMPLETE($|[[:space:]]|$)"; then
        local task_id
        task_id=$(extract_task_id "$line")
        handle_incomplete_signal "$task_id"
        return 0
    fi
    
    print_warning "Unrecognized signal format: $line"
    return 1
}

parse_manager_signal() {
    local output="$1"
    
    if echo "$output" | grep -qE "TASK_COMPLETE_[0-9]{4}"; then
        echo "COMPLETE"
        return 0
    fi
    
    if echo "$output" | grep -qE "TASK_INCOMPLETE_[0-9]{4}"; then
        echo "INCOMPLETE"
        return 0
    fi
    
    if echo "$output" | grep -qE "TASK_FAILED_[0-9]{4}"; then
        echo "FAILED"
        return 0
    fi
    
    if echo "$output" | grep -qE "TASK_BLOCKED_[0-9]{4}"; then
        echo "BLOCKED"
        return 0
    fi
    
    echo "UNKNOWN"
    return 1
}

main_loop() {
    if [ "$MAX_ITERATIONS" -gt 0 ]; then
        print_info "Starting Ralph Loop (iteration $ITERATION, max: $MAX_ITERATIONS)"
    else
        print_info "Starting Ralph Loop (iteration $ITERATION, max: unlimited)"
    fi
    
    while true; do
        check_for_conflicts
        if [ $? -eq 1 ]; then
            print_error "Conflict detected - terminating loop"
            break
        fi
        
        if should_terminate; then
            print_info "Termination conditions met - exiting loop"
            break
        fi
        
        print_info "=== Iteration $ITERATION ==="
        
        invoke_manager
        MANAGER_EXIT_CODE=$?
        
        if [ -n "$MANAGER_OUTPUT" ] && [ -f "$MANAGER_OUTPUT" ]; then
            if parse_signals "$MANAGER_OUTPUT"; then
                print_info "Signal processed successfully"
            else
                print_warning "No valid signal found in Manager output"
            fi
        else
            print_warning "No Manager output file available"
        fi
        
        if [ "$SHOULD_TERMINATE" -eq 1 ]; then
            print_info "Termination flag set - exiting loop"
            break
        fi
        
        ITERATION=$((ITERATION + 1))
        
        sleep_with_backoff "$ITERATION"
    done
    
    print_success "Ralph Loop finished after $ITERATION iterations"
}

parse_arguments() {
    CLI_TOOL=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool)
                CLI_TOOL="$2"
                shift 2
                ;;
            --max-iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            --skip-sync)
                SKIP_SYNC=1
                shift
                ;;
            --no-delay)
                NO_DELAY=1
                shift
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
    --tool {opencode|claude}    Select AI tool (default: opencode)
    --max-iterations N          Maximum iterations (default: 100, 0=unlimited)
    --skip-sync                 Skip pre-loop agent synchronization
    --no-delay                  Disable backoff delays
    --dry-run                   Print commands without executing
    --help, -h                  Show this help message

Environment Variables:
    RALPH_TOOL                  Default tool selection
    RALPH_MAX_ITERATIONS        Maximum loop iterations
    RALPH_BACKOFF_BASE          Backoff base delay (default: 2)
    RALPH_BACKOFF_MAX           Backoff max delay (default: 60)
    RALPH_MANAGER_MODEL         Override Manager model

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
    
    print_info "Ralph Loop initialized"
    print_info "  Tool: $SELECTED_TOOL"
    if [ "$MAX_ITERATIONS" -gt 0 ]; then
        print_info "  Max iterations: $MAX_ITERATIONS"
    else
        print_info "  Max iterations: unlimited"
    fi
    print_info "  Project root: $PROJECT_ROOT"
}

main() {
    parse_arguments "$@"
    initialize
    run_sync_agents
    main_loop
}

main "$@"
