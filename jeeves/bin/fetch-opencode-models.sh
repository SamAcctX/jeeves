#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="https://opencode.ai/zen/v1/models"
RALPH_DIR="${RALPH_DIR:-.ralph}"
DEFAULT_OUTPUT="$RALPH_DIR/config/agents.yaml"
TEMPLATE_PATH="$SCRIPT_DIR/../Ralph/templates/config/agents.yaml.template"

KNOWN_FREE_MODELS="big-pickle gpt-5-nano"

TIER_COMPLEX_PREFS="big-pickle glm-5-free kimi-k2.5-free trinity-large-preview-free gpt-5-nano minimax-m2.5-free"
TIER_CODING_PREFS="gpt-5-nano big-pickle glm-5-free kimi-k2.5-free minimax-m2.5-free trinity-large-preview-free"
TIER_GENERAL_PREFS="minimax-m2.5-free kimi-k2.5-free glm-5-free minimax-m2.1-free trinity-large-preview-free big-pickle gpt-5-nano"

AGENT_TIERS_COMPLEX="manager architect decomposer decomposer-architect decomposer-researcher"
AGENT_TIERS_CODING="developer tester"
AGENT_TIERS_GENERAL="writer researcher ui-designer"

FREE_ONLY=false
DRY_RUN=false
LIST_ONLY=false
OVERRIDE_MODEL=""
OUTPUT_FILE=""
EXTRA_FREE=""

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Fetch current models from OpenCode Zen API and populate agents.yaml with
free model configurations for Ralph agent types.

OPTIONS:
  --free              Filter to free models only (default behavior)
  --output FILE       Output file path (default: $DEFAULT_OUTPUT)
  --dry-run           Preview changes without writing files
  --list              List available free models and exit
  --model MODEL       Use a specific model for all agent types
  --include MODELS    Comma-separated additional model IDs to treat as free
  -h, --help          Show this help message

EXAMPLES:
  $(basename "$0") --free
  $(basename "$0") --free --dry-run
  $(basename "$0") --free --output ./my-agents.yaml
  $(basename "$0") --list
  $(basename "$0") --model big-pickle

ENVIRONMENT:
  RALPH_DIR           Ralph directory (default: .ralph)
  OPENCODE_API_URL    Override API endpoint

EOF
}

check_dependencies() {
    local missing=0

    for cmd in curl jq yq; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "$cmd is not installed"
            missing=1
        fi
    done

    if [ "$missing" -eq 1 ]; then
        print_error "Install missing dependencies before continuing"
        exit 1
    fi
}

fetch_models() {
    local url="${OPENCODE_API_URL:-$API_URL}"
    local response

    print_info "Fetching models from OpenCode Zen API..."

    if ! response=$(curl -s -f --connect-timeout 10 --max-time 30 "$url" 2>&1); then
        print_error "Failed to fetch models from $url"
        print_error "Check your network connection and try again"
        exit 1
    fi

    if [ -z "$response" ]; then
        print_error "Empty response from API"
        exit 1
    fi

    if ! echo "$response" | jq -e '.data' > /dev/null 2>&1; then
        print_error "Invalid API response: missing 'data' field"
        exit 1
    fi

    local count
    count=$(echo "$response" | jq '.data | length')
    print_info "Found $count models from API"

    echo "$response"
}

is_free_model() {
    local model_id="$1"

    if [[ "$model_id" == *-free ]]; then
        return 0
    fi

    for known in $KNOWN_FREE_MODELS; do
        if [ "$model_id" = "$known" ]; then
            return 0
        fi
    done

    if [ -n "$EXTRA_FREE" ]; then
        local IFS=','
        for extra in $EXTRA_FREE; do
            extra=$(echo "$extra" | xargs)
            if [ "$model_id" = "$extra" ]; then
                return 0
            fi
        done
    fi

    return 1
}

extract_free_models() {
    local api_response="$1"
    local free_models=()

    local all_ids
    all_ids=$(echo "$api_response" | jq -r '.data[].id' | sort)

    while IFS= read -r model_id; do
        [ -z "$model_id" ] && continue
        if is_free_model "$model_id"; then
            free_models+=("$model_id")
        fi
    done <<< "$all_ids"

    if [ ${#free_models[@]} -eq 0 ]; then
        print_warning "No free models found"
        return 1
    fi

    local model_list
    model_list=$(IFS=', '; echo "${free_models[*]}")
    print_info "Found ${#free_models[@]} free models: $model_list"

    printf '%s\n' "${free_models[@]}"
}

select_model_for_tier() {
    local tier_prefs="$1"
    shift
    local free_models=("$@")

    for pref in $tier_prefs; do
        for model in "${free_models[@]}"; do
            if [ "$pref" = "$model" ]; then
                echo "$pref"
                return 0
            fi
        done
    done

    if [ ${#free_models[@]} -gt 0 ]; then
        echo "${free_models[0]}"
        return 0
    fi

    return 1
}

map_models_to_agents() {
    local -a free_models=()
    while IFS= read -r line; do
        [ -n "$line" ] && free_models+=("$line")
    done

    if [ ${#free_models[@]} -eq 0 ]; then
        print_error "No free models available for mapping"
        return 1
    fi

    local complex_model coding_model general_model

    complex_model=$(select_model_for_tier "$TIER_COMPLEX_PREFS" "${free_models[@]}") || complex_model="${free_models[0]}"
    coding_model=$(select_model_for_tier "$TIER_CODING_PREFS" "${free_models[@]}") || coding_model="${free_models[0]}"
    general_model=$(select_model_for_tier "$TIER_GENERAL_PREFS" "${free_models[@]}") || general_model="${free_models[0]}"

    print_info "Mapping models to agent types..."

    for agent in $AGENT_TIERS_COMPLEX; do
        print_info "  $agent -> opencode/$complex_model"
        echo "$agent=opencode/$complex_model"
    done

    for agent in $AGENT_TIERS_CODING; do
        print_info "  $agent -> opencode/$coding_model"
        echo "$agent=opencode/$coding_model"
    done

    for agent in $AGENT_TIERS_GENERAL; do
        print_info "  $agent -> opencode/$general_model"
        echo "$agent=opencode/$general_model"
    done
}

update_agents_yaml() {
    local output_file="$1"
    shift
    local mappings=("$@")
    local updated_count=0

    if [ -f "$output_file" ]; then
        print_info "Updating existing $output_file"

        if ! yq eval '.' "$output_file" > /dev/null 2>&1; then
            print_error "Existing $output_file contains invalid YAML"
            exit 1
        fi
    elif [ -f "$TEMPLATE_PATH" ]; then
        print_info "Creating $output_file from template"
        local output_dir
        output_dir=$(dirname "$output_file")
        mkdir -p "$output_dir"
        cp "$TEMPLATE_PATH" "$output_file"
    else
        print_info "Generating new $output_file"
        local output_dir
        output_dir=$(dirname "$output_file")
        mkdir -p "$output_dir"
        generate_agents_yaml "$output_file" "${mappings[@]}"
        return $?
    fi

    for mapping in "${mappings[@]}"; do
        local agent_type="${mapping%%=*}"
        local model="${mapping#*=}"

        local exists
        exists=$(yq eval ".agents.${agent_type}" "$output_file" 2>/dev/null)

        if [ "$exists" = "null" ]; then
            yq eval -i ".agents.${agent_type}.description = \"\"" "$output_file"
            yq eval -i ".agents.${agent_type}.preferred.opencode = \"$model\"" "$output_file"
            yq eval -i ".agents.${agent_type}.preferred.claude = \"\"" "$output_file"
        else
            yq eval -i ".agents.${agent_type}.preferred.opencode = \"$model\"" "$output_file"
        fi

        updated_count=$((updated_count + 1))
    done

    print_success "Updated $updated_count agent configurations with free models"
}

generate_agents_yaml() {
    local output_file="$1"
    shift
    local mappings=("$@")
    local updated_count=0

    cat > "$output_file" << 'HEADER'
agents:
HEADER

    for mapping in "${mappings[@]}"; do
        local agent_type="${mapping%%=*}"
        local model="${mapping#*=}"

        cat >> "$output_file" << EOF
  ${agent_type}:
    description: ""
    preferred:
      opencode: ${model}
      claude: ""

EOF
        updated_count=$((updated_count + 1))
    done

    print_success "Generated $output_file with $updated_count agent configurations"
}

preview_changes() {
    local output_file="$1"
    shift
    local mappings=("$@")

    print_info "Dry-run mode: previewing changes for $output_file"
    echo ""

    if [ -f "$output_file" ]; then
        print_info "Would update existing file: $output_file"
        echo ""
        for mapping in "${mappings[@]}"; do
            local agent_type="${mapping%%=*}"
            local model="${mapping#*=}"
            local current
            current=$(yq eval ".agents.${agent_type}.preferred.opencode // \"(not set)\"" "$output_file" 2>/dev/null)
            if [ "$current" = "$model" ]; then
                echo "  $agent_type: $model (unchanged)"
            else
                echo "  $agent_type: $current -> $model"
            fi
        done
    else
        print_info "Would create new file: $output_file"
        echo ""
        for mapping in "${mappings[@]}"; do
            local agent_type="${mapping%%=*}"
            local model="${mapping#*=}"
            echo "  $agent_type: $model"
        done
    fi

    echo ""
    print_info "Run without --dry-run to apply changes"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --free)
            FREE_ONLY=true
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --model)
            OVERRIDE_MODEL="$2"
            shift 2
            ;;
        --include)
            EXTRA_FREE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="$DEFAULT_OUTPUT"
fi

FREE_ONLY=true

check_dependencies

api_response=$(fetch_models)

free_model_list=$(extract_free_models "$api_response") || {
    print_error "No free models available"
    exit 1
}

if [ "$LIST_ONLY" = true ]; then
    echo ""
    print_info "Available free models on OpenCode Zen:"
    echo ""
    while IFS= read -r model; do
        echo "  - $model"
    done <<< "$free_model_list"
    echo ""
    exit 0
fi

if [ -n "$OVERRIDE_MODEL" ]; then
    found=false
    while IFS= read -r model; do
        if [ "$model" = "$OVERRIDE_MODEL" ]; then
            found=true
            break
        fi
    done <<< "$free_model_list"

    if [ "$found" = false ]; then
        all_models=$(echo "$api_response" | jq -r '.data[].id')
        if echo "$all_models" | grep -q "^${OVERRIDE_MODEL}$"; then
            print_warning "$OVERRIDE_MODEL is not a free model"
        else
            print_error "$OVERRIDE_MODEL is not available on OpenCode Zen"
            exit 1
        fi
    fi

    mappings=()
    all_agents="$AGENT_TIERS_COMPLEX $AGENT_TIERS_CODING $AGENT_TIERS_GENERAL"
    local prefixed_model="opencode/$OVERRIDE_MODEL"
    print_info "Mapping all agents to: $prefixed_model"
    for agent in $all_agents; do
        print_info "  $agent -> $prefixed_model"
        mappings+=("$agent=$prefixed_model")
    done
else
    mapfile -t mappings < <(echo "$free_model_list" | map_models_to_agents | grep '=')
fi

if [ ${#mappings[@]} -eq 0 ]; then
    print_error "No model mappings generated"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    preview_changes "$OUTPUT_FILE" "${mappings[@]}"
    exit 0
fi

print_info "Writing configuration to $OUTPUT_FILE"
update_agents_yaml "$OUTPUT_FILE" "${mappings[@]}"

print_success "Done! Run 'sync-agents' to apply models to agent files"
