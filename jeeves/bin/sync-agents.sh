#!/bin/bash
set -e

# sync-agents: Synchronize agent model configurations from agents.yaml to agent files
# Uses yq for proper YAML parsing and manipulation

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="${RALPH_DIR:-.ralph}"
AGENTS_YAML="${AGENTS_YAML:-$RALPH_DIR/config/agents.yaml}"
TOOL="${RALPH_TOOL:-opencode}"
VALID_TOOLS=("opencode" "claude")

# Agent search paths (priority: project-specific > user-global)
AGENT_SEARCH_PATHS=(
    ".ralph/agents"
    ".opencode/agents"
    ".claude/agents"
    "$HOME/.config/opencode/agents"
    "$HOME/.claude/agents"
)

# Agent types loaded from agents.yaml
AGENT_TYPES=()

# Statistics
STATS_UPDATED=0
STATS_SKIPPED=0
STATS_FAILED=0

# Logging functions
print_info() { echo -e "\033[1;34m[INFO]\033[0m $1" >&2; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1" >&2; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1" >&2; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

# Validate tool value
validate_tool() {
    local tool="$1"
    local valid=0
    
    for valid_tool in "${VALID_TOOLS[@]}"; do
        if [ "$tool" = "$valid_tool" ]; then
            valid=1
            break
        fi
    done
    
    if [ $valid -eq 0 ]; then
        print_error "Invalid tool: '$tool'. Valid options: ${VALID_TOOLS[*]}"
        exit 1
    fi
    
    print_info "Using tool: $tool"
}

# Check if yq is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        print_error "yq is not installed. Please install yq to use sync-agents."
        print_info "Installation: https://github.com/mikefarah/yq#install"
        exit 1
    fi
}

# Validate agents.yaml exists and is readable
validate_agents_yaml() {
    if [ ! -f "$AGENTS_YAML" ]; then
        print_error "agents.yaml not found: $AGENTS_YAML"
        exit 1
    fi
    
    if [ ! -r "$AGENTS_YAML" ]; then
        print_error "agents.yaml is not readable: $AGENTS_YAML"
        exit 1
    fi
    
    # Validate YAML syntax
    if ! yq eval '.' "$AGENTS_YAML" > /dev/null 2>&1; then
        print_error "agents.yaml contains invalid YAML syntax"
        exit 1
    fi
    
    print_success "agents.yaml validated"
}

# Extract list of agent types from agents.yaml
extract_agent_types() {
    local agents
    agents=$(yq eval '.agents | keys | .[]' "$AGENTS_YAML" 2>/dev/null)
    
    if [ -z "$agents" ]; then
        print_error "No agents found in agents.yaml"
        exit 1
    fi
    
    echo "$agents"
}

# Load agent types into AGENT_TYPES array
load_agent_types() {
    if [ -f "$AGENTS_YAML" ]; then
        mapfile -t AGENT_TYPES < <(extract_agent_types)
        print_info "Loaded ${#AGENT_TYPES[@]} agent type(s) from agents.yaml"
    else
        # Default agent types if no agents.yaml
        AGENT_TYPES=(manager architect developer tester ui-designer researcher writer decomposer)
        print_warning "No agents.yaml found, using default agent types"
    fi
}

# Get model for an agent type from agents.yaml
get_agent_model() {
    local agent_type="$1"
    local tool="${2:-$TOOL}"
    local model
    
    # Try preferred model first
    model=$(yq eval ".agents.${agent_type}.preferred.${tool}" "$AGENTS_YAML" 2>/dev/null)
    
    if [ "$model" = "null" ] || [ -z "$model" ]; then
        # Try fallback model
        model=$(yq eval ".agents.${agent_type}.fallback.${tool}" "$AGENTS_YAML" 2>/dev/null)
    fi
    
    if [ "$model" = "null" ] || [ -z "$model" ]; then
        return 1
    fi
    
    echo "$model"
}

# Get agent description from agents.yaml
get_agent_description() {
    local agent_type="$1"
    local description
    
    description=$(yq eval ".agents.${agent_type}.description" "$AGENTS_YAML" 2>/dev/null)
    
    if [ "$description" = "null" ]; then
        description=""
    fi
    
    echo "$description"
}

# Discover agent files for a given agent type
discover_agent_files() {
    local agent_type="$1"
    local found_files=""
    
    for search_path in "${AGENT_SEARCH_PATHS[@]}"; do
        if [ -d "$search_path" ]; then
            local agent_file="$search_path/${agent_type}.md"
            if [ -f "$agent_file" ]; then
                if [ -n "$found_files" ]; then
                    found_files="$found_files $agent_file"
                else
                    found_files="$agent_file"
                fi
            fi
        fi
    done
    
    echo "$found_files"
}

# List all search paths and their status
list_search_paths() {
    print_info "Agent file search paths:"
    for path in "${AGENT_SEARCH_PATHS[@]}"; do
        local status="not found"
        if [ -d "$path" ]; then
            local count
            count=$(find "$path" -name "*.md" -type f 2>/dev/null | wc -l)
            status="found ($count files)"
        fi
        echo "  $path - $status"
    done
}

# Scan for all agent files
scan_all_agents() {
    local total_found=0
    local agent_mappings=""
    
    for agent_type in "${AGENT_TYPES[@]}"; do
        local files
        files=$(discover_agent_files "$agent_type")
        
        if [ -n "$files" ]; then
            agent_mappings="${agent_mappings}${agent_type}:${files}
"
            local count
            count=$(echo "$files" | wc -w)
            total_found=$((total_found + count))
            print_info "Found $count file(s) for agent: $agent_type"
        fi
    done
    
    print_success "Found $total_found agent file(s) total"
    echo "$agent_mappings"
}

# Check if a file has YAML frontmatter
has_frontmatter() {
    local file="$1"
    head -1 "$file" | grep -q "^---"
}

# Extract frontmatter from a markdown file using yq
extract_frontmatter() {
    local file="$1"
    
    if ! has_frontmatter "$file"; then
        echo "{}"
        return
    fi
    
    # Read file and extract content between --- markers
    local in_frontmatter=0
    local frontmatter=""
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" -eq 0 ]; then
                in_frontmatter=1
                continue
            else
                break
            fi
        fi
        
        if [ "$in_frontmatter" -eq 1 ]; then
            frontmatter="${frontmatter}${line}"$'\n'
        fi
    done < "$file"
    
    if [ -n "$frontmatter" ]; then
        # Validate it's proper YAML
        if echo "$frontmatter" | yq eval '.' - > /dev/null 2>&1; then
            echo "$frontmatter" | yq eval '.' -
        else
            echo "{}"
        fi
    else
        echo "{}"
    fi
}

# Extract content (everything after frontmatter) from a markdown file
extract_content() {
    local file="$1"
    
    if ! has_frontmatter "$file"; then
        cat "$file"
        return
    fi
    
    local in_frontmatter=0
    local frontmatter_ended=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [ "$frontmatter_ended" -eq 1 ]; then
            echo "$line"
            continue
        fi
        
        if [ "$line" = "---" ]; then
            if [ "$in_frontmatter" -eq 0 ]; then
                in_frontmatter=1
            else
                in_frontmatter=0
                frontmatter_ended=1
            fi
            continue
        fi
    done < "$file"
}

# Get current model from file using yq
get_current_model() {
    local file="$1"
    
    if ! has_frontmatter "$file"; then
        echo ""
        return
    fi
    
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    
    local model
    model=$(echo "$frontmatter" | yq eval '.model // ""' -)
    
    if [ "$model" = "null" ]; then
        model=""
    fi
    
    echo "$model"
}

# Check if file needs update (idempotency)
needs_update() {
    local agent_file="$1"
    local new_model="$2"
    
    if [ ! -f "$agent_file" ]; then
        return 0
    fi
    
    local current_model
    current_model=$(get_current_model "$agent_file")
    
    # Trim whitespace for comparison
    current_model=$(echo "$current_model" | sed 's/[[:space:]]*$//')
    new_model=$(echo "$new_model" | sed 's/[[:space:]]*$//')
    
    if [ "$current_model" = "$new_model" ]; then
        return 1
    else
        return 0
    fi
}

# Update frontmatter in agent file using yq
update_agent_frontmatter() {
    local agent_file="$1"
    local agent_type="$2"
    local new_model="$3"
    
    if [ ! -f "$agent_file" ]; then
        print_error "File not found: $agent_file"
        return 1
    fi
    
    # Create backup
    local backup_file="${agent_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$agent_file" "$backup_file"
    
    # Get original permissions
    local orig_perms
    orig_perms=$(stat -c "%a" "$agent_file")
    
    # Create temporary file
    local temp_file="${agent_file}.tmp.$$"
    
    if has_frontmatter "$agent_file"; then
        # File has frontmatter - extract, modify with yq, and recombine
        local frontmatter content
        frontmatter=$(extract_frontmatter "$agent_file")
        content=$(extract_content "$agent_file")
        
        # Update model in frontmatter using yq
        local updated_frontmatter
        updated_frontmatter=$(echo "$frontmatter" | yq eval ".model = \"$new_model\"" -)
        # Remove unnecessary quotes from simple string values (no spaces, no special chars)
        if [[ "$new_model" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
            updated_frontmatter=$(echo "$updated_frontmatter" | sed 's/\(model: \)"\([a-zA-Z0-9_.-]*\)"/\1\2/')
        fi
        
        # Write updated file
        echo "---" > "$temp_file"
        echo "$updated_frontmatter" >> "$temp_file"
        echo "---" >> "$temp_file"
        
        # Add content (with leading newline if content exists)
        if [ -n "$content" ]; then
            echo "" >> "$temp_file"
            echo "$content" >> "$temp_file"
        fi
    else
        # File has no frontmatter - add new one
        local content
        content=$(cat "$agent_file")
        
        cat > "$temp_file" << EOF
---
model: $new_model
---

$content
EOF
    fi
    
    # Replace original with updated
    mv "$temp_file" "$agent_file"
    
    # Restore permissions
    chmod "$orig_perms" "$agent_file"
    
    # Remove backup on success
    rm -f "$backup_file"
    
    return 0
}

# Update agent file (always update for simplicity)
update_agent() {
    local agent_file="$1"
    local agent_type="$2"
    local new_model="$3"
    
    # Perform update
    if update_agent_frontmatter "$agent_file" "$agent_type" "$new_model"; then
        print_success "Updated $agent_file with model: $new_model"
        STATS_UPDATED=$((STATS_UPDATED + 1))
        return 0
    else
        print_error "Failed to update $agent_file"
        STATS_FAILED=$((STATS_FAILED + 1))
        return 1
    fi
}

# Filter search paths based on tool
filter_paths_by_tool() {
    local tool="$1"
    local filtered_paths=()
    
    for path in "${AGENT_SEARCH_PATHS[@]}"; do
        case "$tool" in
            opencode)
                if [[ "$path" == *"opencode"* ]] || [[ "$path" == *".ralph"* ]]; then
                    filtered_paths+=("$path")
                fi
                ;;
            claude)
                if [[ "$path" == *"claude"* ]] || [[ "$path" == *".ralph"* ]]; then
                    filtered_paths+=("$path")
                fi
                ;;
        esac
    done
    
    AGENT_SEARCH_PATHS=("${filtered_paths[@]}")
}

# Synchronize all agents
sync_all_agents() {
    local agent_mappings="$1"
    
    print_info "Synchronizing agents..."
    
    # Reset statistics
    STATS_UPDATED=0
    STATS_FAILED=0
    
    # Process each agent type
    local IFS=$'\n'
    for mapping in $agent_mappings; do
        [ -z "$mapping" ] && continue
        
        local agent_type="${mapping%%:*}"
        local agent_files="${mapping#*:}"
        
        [ -z "$agent_type" ] && continue
        
        local new_model
        new_model=$(get_agent_model "$agent_type")
        
        if [ -z "$new_model" ]; then
            print_warning "No model configured for $agent_type, skipping"
            continue
        fi
        
        # Process each file for this agent
        local file
        for file in $agent_files; do
            [ -z "$file" ] && continue
            if [ -f "$file" ]; then
                update_agent "$file" "$agent_type" "$new_model"
            fi
        done
    done
    
    print_success "Sync complete: $STATS_UPDATED updated, $STATS_FAILED failed"
    
    return 0
}

# Display parsed agents info (for debugging/verification)
show_parsed_agents() {
    print_info "Parsed agents from $AGENTS_YAML:"
    print_info ""
    
    for agent_type in "${AGENT_TYPES[@]}"; do
        local description
        local model
        
        description=$(get_agent_description "$agent_type")
        model=$(get_agent_model "$agent_type" "$TOOL")
        
        print_info "Agent: $agent_type"
        [ -n "$description" ] && print_info "  Description: $description"
        [ -n "$model" ] && print_info "  Model ($TOOL): $model"
        echo ""
    done
}

# Main function
main() {
    # Check for yq
    check_yq
    
    # Validate tool
    validate_tool "$TOOL"
    
    # Validate agents.yaml
    validate_agents_yaml
    
    # Load agent types
    load_agent_types
    
    # Filter paths by tool for multi-tool support
    filter_paths_by_tool "$TOOL"
    
    # List search paths
    list_search_paths
    
    # Scan for agent files
    local agent_mappings
    agent_mappings=$(scan_all_agents)
    
    if [ -z "$agent_mappings" ]; then
        print_warning "No agent files found to synchronize"
        exit 0
    fi
    
    # Sync all agents
    sync_all_agents "$agent_mappings"
    
    print_success "Agent synchronization complete for tool: $TOOL"
}

# Show usage
usage() {
    cat << EOF
Usage: sync-agents [OPTIONS]

Synchronize agent model configurations from agents.yaml to agent definition files.

Options:
  -h, --help          Show this help message
  -t, --tool TOOL     Specify tool (opencode|claude) [default: opencode]
  -c, --config FILE   Specify agents.yaml path [default: .ralph/config/agents.yaml]
  -s, --show          Show parsed agents (don't sync)
  -d, --dry-run       Show what would be updated (don't modify files)

Environment Variables:
  RALPH_TOOL          Tool to use (opencode|claude)
  AGENTS_YAML         Path to agents.yaml file

Examples:
  sync-agents                              # Sync for OpenCode (default)
  RALPH_TOOL=claude sync-agents           # Sync for Claude
  sync-agents -t claude                   # Sync for Claude
  sync-agents -c /path/to/agents.yaml     # Use custom config
  sync-agents -s                          # Show parsed agents
EOF
}

# Parse command-line arguments
DRY_RUN=0
SHOW_ONLY=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--tool)
            TOOL="$2"
            shift 2
            ;;
        -c|--config)
            AGENTS_YAML="$2"
            shift 2
            ;;
        -s|--show)
            SHOW_ONLY=1
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Override with environment variable if set
if [ -n "$RALPH_TOOL" ]; then
    TOOL="$RALPH_TOOL"
fi

# Run main or show only
if [ "$SHOW_ONLY" -eq 1 ]; then
    check_yq
    validate_tool "$TOOL"
    validate_agents_yaml
    load_agent_types
    show_parsed_agents
else
    main
fi
