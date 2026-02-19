#!/bin/bash
set -e

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

SHOW_TEXT=${SHOW_TEXT:-true}
SHOW_TOKENS=${SHOW_TOKENS:-true}
SHOW_TOOLS=${SHOW_TOOLS:-true}
SHOW_COST=${SHOW_COST:-true}
SHOW_SIGNALS=${SHOW_SIGNALS:-true}
COMPACT=${COMPACT:-false}

show_usage() {
    cat << 'USAGE'
Usage: ralph-filter-output.sh [OPTIONS] [FILE]

Filter OpenCode JSON output to show only essential information.

Options:
    --text          Show text responses (default: true)
    --no-text       Hide text responses
    --tokens        Show token statistics (default: true)
    --no-tokens     Hide token statistics
    --tools         Show tool usage (default: true)
    --no-tools      Hide tool usage
    --cost          Show cost information (default: true)
    --no-cost       Hide cost information
    --signals       Show task signals (default: true)
    --no-signals    Hide task signals
    --compact       Use compact output format
    --help          Show this help message

Environment Variables:
    SHOW_TEXT       Show text responses (true/false)
    SHOW_TOKENS     Show token statistics (true/false)
    SHOW_TOOLS      Show tool usage (true/false)
    SHOW_COST       Show cost information (true/false)
    SHOW_SIGNALS    Show task signals (true/false)
    COMPACT         Use compact output format (true/false)

Examples:
    cat output.json | ralph-filter-output.sh
    ralph-filter-output.sh output.json
    ralph-filter-output.sh --compact --no-text output.json

USAGE
}

parse_arguments() {
    local file=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --text) SHOW_TEXT="true"; shift ;;
            --no-text) SHOW_TEXT="false"; shift ;;
            --tokens) SHOW_TOKENS="true"; shift ;;
            --no-tokens) SHOW_TOKENS="false"; shift ;;
            --tools) SHOW_TOOLS="true"; shift ;;
            --no-tools) SHOW_TOOLS="false"; shift ;;
            --cost) SHOW_COST="true"; shift ;;
            --no-cost) SHOW_COST="false"; shift ;;
            --signals) SHOW_SIGNALS="true"; shift ;;
            --no-signals) SHOW_SIGNALS="false"; shift ;;
            --compact) COMPACT="true"; shift ;;
            --help|-h) show_usage; exit 0 ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$file" ]; then
                    file="$1"
                fi
                shift
                ;;
        esac
    done
    
    INPUT_FILE="$file"
}

format_tokens() {
    local total="$1"
    local input="$2"
    local output="$3"
    local reasoning="$4"
    local cache_read="$5"
    local cache_write="$6"
    
    if [ "$COMPACT" = "true" ]; then
        echo "Tokens: total=$total, in=$input, out=$output"
    else
        echo "Token Statistics:"
        echo "  Total: $total"
        echo "  Input: $input"
        echo "  Output: $output"
        if [ "$reasoning" != "0" ]; then
            echo "  Reasoning: $reasoning"
        fi
        if [ "$cache_read" != "0" ] || [ "$cache_write" != "0" ]; then
            echo "  Cache: read=$cache_read, write=$cache_write"
        fi
    fi
}

format_tool_use() {
    local tool="$1"
    local call_id="$2"
    local status="$3"
    local input="$4"
    local output="$5"
    local model="$6"
    local duration="$7"
    
    if [ "$COMPACT" = "true" ]; then
        echo "Tool: $tool ($status)"
    else
        echo "Tool: $tool"
        echo "  Call ID: $call_id"
        echo "  Status: $status"
        if [ -n "$model" ]; then
            echo "  Model: $model"
        fi
        if [ -n "$duration" ]; then
            local start_time=$(echo "$duration" | jq -r '.start // empty')
            local end_time=$(echo "$duration" | jq -r '.end // empty')
            if [ -n "$start_time" ] && [ -n "$end_time" ]; then
                local diff=$((end_time - start_time))
                echo "  Duration: ${diff}s"
            fi
        fi
        if [ "$SHOW_TEXT" = "true" ] && [ -n "$input" ]; then
            local input_preview=$(echo "$input" | jq -r '.prompt // .description // empty' 2>/dev/null | head -c 200)
            if [ -n "$input_preview" ]; then
                echo "  Input Preview: ${input_preview}..."
            fi
        fi
        if [ "$SHOW_TEXT" = "true" ] && [ -n "$output" ]; then
            local output_preview=$(echo "$output" | head -c 300)
            if [ -n "$output_preview" ]; then
                echo "  Output Preview: ${output_preview}..."
            fi
        fi
    fi
}

extract_signal() {
    local text="$1"
    
    if echo "$text" | grep -qE "TASK_COMPLETE_[0-9]{4}"; then
        echo "$text" | grep -oE "TASK_COMPLETE_[0-9]{4}(:.*)?" | head -1
        return 0
    fi
    if echo "$text" | grep -qE "TASK_INCOMPLETE_[0-9]{4}"; then
        echo "$text" | grep -oE "TASK_INCOMPLETE_[0-9]{4}(:.*)?" | head -1
        return 0
    fi
    if echo "$text" | grep -qE "TASK_FAILED_[0-9]{4}"; then
        echo "$text" | grep -oE "TASK_FAILED_[0-9]{4}(:.*)?" | head -1
        return 0
    fi
    if echo "$text" | grep -qE "TASK_BLOCKED_[0-9]{4}"; then
        echo "$text" | grep -oE "TASK_BLOCKED_[0-9]{4}(:.*)?" | head -1
        return 0
    fi
    return 1
}

filter_output() {
    local input="$1"
    local total_tokens=0
    local total_input=0
    local total_output=0
    local total_cost=0
    local step_count=0
    local tool_count=0
    
    if [ "$COMPACT" = "true" ]; then
        echo "=== Ralph Output Summary ==="
    else
        echo ""
        echo "========================================"
        echo "       Ralph Output Summary"
        echo "========================================"
        echo ""
    fi
    
    echo "$input" | while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
        
        if [ -z "$type" ]; then
            continue
        fi
        
        case "$type" in
            text)
                if [ "$SHOW_TEXT" = "true" ]; then
                    local text=$(echo "$line" | jq -r '.part.text // empty' 2>/dev/null)
                    if [ -n "$text" ]; then
                        if [ "$SHOW_SIGNALS" = "true" ]; then
                            local signal=$(extract_signal "$text")
                            if [ -n "$signal" ]; then
                                if [ "$COMPACT" = "true" ]; then
                                    echo "SIGNAL: $signal"
                                else
                                    echo ""
                                    echo "*** TASK SIGNAL: $signal ***"
                                    echo ""
                                fi
                            fi
                        fi
                        
                        if [ "$COMPACT" = "true" ]; then
                            echo "Text: ${text:0:100}..."
                        else
                            echo ""
                            echo "--- AI Response ---"
                            echo "$text"
                            echo "---"
                        fi
                    fi
                fi
                ;;
            
            tool_use)
                if [ "$SHOW_TOOLS" = "true" ]; then
                    local tool=$(echo "$line" | jq -r '.part.tool // empty' 2>/dev/null)
                    local call_id=$(echo "$line" | jq -r '.part.callID // empty' 2>/dev/null)
                    local status=$(echo "$line" | jq -r '.part.state.status // empty' 2>/dev/null)
                    local input=$(echo "$line" | jq -r '.part.state.input // empty' 2>/dev/null)
                    local output=$(echo "$line" | jq -r '.part.state.output // empty' 2>/dev/null)
                    local model=$(echo "$line" | jq -r '.part.metadata.model.modelID // empty' 2>/dev/null)
                    local duration=$(echo "$line" | jq -r '.part.time // empty' 2>/dev/null)
                    
                    if [ -n "$tool" ]; then
                        format_tool_use "$tool" "$call_id" "$status" "$input" "$output" "$model" "$duration"
                    fi
                fi
                ;;
            
            step_finish)
                step_count=$((step_count + 1))
                
                if [ "$SHOW_TOKENS" = "true" ]; then
                    local tokens=$(echo "$line" | jq -r '.part.tokens // empty' 2>/dev/null)
                    if [ -n "$tokens" ] && [ "$tokens" != "null" ]; then
                        local total=$(echo "$tokens" | jq -r '.total // 0')
                        local input_t=$(echo "$tokens" | jq -r '.input // 0')
                        local output_t=$(echo "$tokens" | jq -r '.output // 0')
                        local reasoning=$(echo "$tokens" | jq -r '.reasoning // 0')
                        local cache_read=$(echo "$tokens" | jq -r '.cache.read // 0')
                        local cache_write=$(echo "$tokens" | jq -r '.cache.write // 0')
                        
                        if [ "$total" != "0" ]; then
                            format_tokens "$total" "$input_t" "$output_t" "$reasoning" "$cache_read" "$cache_write"
                        fi
                    fi
                fi
                
                if [ "$SHOW_COST" = "true" ]; then
                    local cost=$(echo "$line" | jq -r '.part.cost // empty' 2>/dev/null)
                    if [ -n "$cost" ] && [ "$cost" != "null" ] && [ "$cost" != "0" ]; then
                        if [ "$COMPACT" = "true" ]; then
                            echo "Cost: \$${cost}"
                        else
                            echo "Cost: \$${cost}"
                        fi
                    fi
                fi
                ;;
        esac
    done
    
    if [ "$COMPACT" = "true" ]; then
        echo "=== End Summary ==="
    else
        echo ""
        echo "========================================"
        echo "       End of Summary"
        echo "========================================"
    fi
}

main() {
    parse_arguments "$@"
    
    local input
    
    if [ -n "$INPUT_FILE" ]; then
        if [ ! -f "$INPUT_FILE" ]; then
            print_error "File not found: $INPUT_FILE"
            exit 1
        fi
        input=$(cat "$INPUT_FILE")
    else
        input=$(cat)
    fi
    
    if [ -z "$input" ]; then
        print_error "No input provided"
        exit 1
    fi
    
    filter_output "$input"
}

main "$@"
