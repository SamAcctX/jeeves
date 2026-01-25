#!/bin/bash

# MCP Installation Script
# Pre-installs and configures MCP (Model Context Protocol) servers for OpenCode and Claude Code
# Supports both project-local and user/global scope installations

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

# MCP Server Configurations
declare -A MCP_SERVERS=(
    ["sequentialthinking"]="@modelcontextprotocol/server-sequential-thinking"
    ["fetch"]="python -m mcp_server_fetch"
    ["searxng"]="mcp-searxng"
)

# Environment Variables for MCP Servers
declare -A MCP_ENV_VARS=(
    ["searxng"]="SEARXNG_URL"
)

# Default Paths
declare -A OPENCODE_PATHS=(
    ["project"]="opencode.json"
    ["global"]="~/.config/opencode/opencode.json"
)

declare -A CLAUDE_PATHS=(
    ["project"]=".mcp.json"
    ["global"]="~/.claude.json"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Print colored output
print_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Get current timestamp for backup filenames
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate JSON syntax
validate_json() {
    local json_file="$1"
    
    if command_exists jq; then
        if jq empty "$json_file" 2>/dev/null; then
            return 0
        else
            print_error "Invalid JSON in file: $json_file"
            return 1
        fi
    elif command_exists python3; then
        if python3 -m json.tool "$json_file" >/dev/null 2>&1; then
            return 0
        else
            print_error "Invalid JSON in file: $json_file"
            return 1
        fi
    else
        print_error "Neither jq nor python3 is available for JSON validation"
        return 1
    fi
}

# Parse JSON file
parse_json() {
    local json_file="$1"
    
    if command_exists jq; then
        jq '.' "$json_file"
    elif command_exists python3; then
        python3 -c "import json; print(json.dumps(json.load(open('$json_file'))))"
    else
        print_error "Neither jq nor python3 is available for JSON parsing"
        return 1
    fi
}

# Create timestamped backup
create_backup() {
    local file_path="$1"
    local timestamp=$(get_timestamp)
    local backup_path="${file_path}.backup_${timestamp}"
    
    if [ -f "$file_path" ]; then
        if cp "$file_path" "$backup_path" 2>/dev/null; then
            print_success "Backup created: $backup_path"
            return 0
        else
            print_error "Failed to create backup: $backup_path"
            return 1
        fi
    else
        return 1
    fi
}

# Check if file is writable
is_writable() {
    local file_path="$1"
    
    if [ -w "$file_path" ]; then
        return 0
    else
        print_error "File is not writable: $file_path"
        return 1
    fi
}

# Check if MCP server already exists in config
mcp_server_exists() {
    local config="$1"
    local server_name="$2"
    
    if command_exists jq; then
        jq -e ".mcpServers.\"$server_name\"" "$config" >/dev/null 2>&1 || jq -e ".mcp.\"$server_name\"" "$config" >/dev/null 2>&1
    else
        # Fallback: grep for server name
        grep -q "\"$server_name\"" "$config"
    fi
}

# Check if a specific MCP server exists in config file
mcp_server_exists_in_config() {
    local config_file="$1"
    local server_name="$2"
    local is_opencode="$3"
    
    if command_exists jq; then
        if [ "$is_opencode" = true ]; then
            jq -e ".mcp.\"$server_name\"" "$config_file" >/dev/null 2>&1
        else
            jq -e ".mcpServers.\"$server_name\"" "$config_file" >/dev/null 2>&1
        fi
    else
        # Fallback: grep for server name
        grep -q "\"$server_name\"" "$config_file"
    fi
}

# Merge MCP configuration into existing config
merge_mcp_config() {
    local config_file="$1"
    local mcp_config="$2"
    local is_opencode="$3"
    
    if [ "$is_opencode" = true ]; then
        # Merge into mcp object
        if command_exists jq; then
            jq --argjson mcp "$mcp_config" '.mcp += $mcp' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
        else
            print_error "jq is required for OpenCode config merging"
            return 1
        fi
    else
        # Merge into mcpServers object
        if command_exists jq; then
            jq --argjson mcp "$mcp_config" '.mcpServers += $mcp' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
        else
            print_error "jq is required for Claude Code config merging"
            return 1
        fi
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if ! command_exists python3; then
        missing_deps+=("python3")
    fi
    
    if ! command_exists npx; then
        missing_deps+=("npx")
    fi
    
    if ! command_exists node; then
        missing_deps+=("node")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install: ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Process OpenCode configuration
process_opencode_config() {
    local scope="$1"
    local dry_run="$2"
    
    local config_file="${OPENCODE_PATHS[$scope]}"
    local mcp_config=""
    local mcp_json=""
    
    print_info "Processing OpenCode configuration (${scope} scope)..."
    
    # Build MCP configuration
    for server_name in "${!MCP_SERVERS[@]}"; do
        local server_config=""
        
        if [ "$server_name" = "searxng" ]; then
            # Prompt for SEARXNG_URL
            if [ "$dry_run" = true ]; then
                print_info "[DRY-RUN] Would prompt for SEARXNG_URL for $server_name"
                searxng_url="https://searxng.example.com"
            else
                read -p "Enter SEARXNG_URL for $server_name: " searxng_url
            fi
            server_config=$(cat <<EOF
    "$server_name": {
        "type": "local",
        "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}"],
        "environment": {
            "SEARXNG_URL": "$searxng_url"
        }
    }
EOF
)
        else
            server_config=$(cat <<EOF
    "$server_name": {
        "type": "local",
        "command": ["${MCP_SERVERS[$server_name]}"]
    }
EOF
)
        fi
        
        mcp_config+="$server_config"
    done
    
    # Build proper JSON object for mcp section
    mcp_json="{"
    local first=true
    for server_name in "${!MCP_SERVERS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            mcp_json+=","
        fi
        mcp_json+="$server_config"
    done
    mcp_json+="}"
    
    # Check if config file exists
    if [ -f "$config_file" ]; then
        print_info "Config file exists: $config_file"
        
        # Validate existing JSON
        if ! validate_json "$config_file"; then
            print_error "Existing config file is not valid JSON: $config_file"
            exit 1
        fi
        
        # Create backup
        if [ "$dry_run" = false ]; then
            create_backup "$config_file" || print_warning "Could not create backup"
        fi
        
        # Check if MCP section exists
        if command_exists jq; then
            if ! jq -e '.mcp' "$config_file" >/dev/null 2>&1; then
                # Add mcp section
                if [ "$dry_run" = false ]; then
                    # Create temporary file with mcp section
                    cat > "${config_file}.tmp" <<EOF
{
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
$mcp_config
    }
}
EOF
                    # Merge with existing config
                    jq -s '.[0] * .[1]' "$config_file" "${config_file}.tmp" > "${config_file}.new" && mv "${config_file}.new" "$config_file"
                    rm -f "${config_file}.tmp"
                    print_success "Added mcp section to OpenCode config"
                else
                    print_info "[DRY-RUN] Would add mcp section to OpenCode config"
                    display_dry_run_preview "$config_file" true
                fi
            else
                # Merge into existing mcp section
                if [ "$dry_run" = false ]; then
                    # Build proper JSON object for mcp section
                    local mcp_json="{"
                    local first=true
                    local added_servers=0
                    for server_name in "${!MCP_SERVERS[@]}"; do
                        # Check if server already exists
                        if ! mcp_server_exists_in_config "$config_file" "$server_name" true; then
                            if [ "$first" = true ]; then
                                first=false
                            else
                                mcp_json+=","
                            fi
                            mcp_json+="$server_config"
                            added_servers=$((added_servers + 1))
                        fi
                    done
                    mcp_json+="}"
                    
                    if [ $added_servers -gt 0 ]; then
                        # Merge into existing mcp section
                        jq --argjson mcp "$mcp_json" '.mcp += $mcp' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
                        print_success "Merged $added_servers MCP configurations into OpenCode config"
                    else
                        print_info "All MCP servers already exist in OpenCode config"
                    fi
                else
                    print_info "[DRY-RUN] Would merge MCP configurations into OpenCode config"
                fi
            fi
        else
            print_error "jq is required for OpenCode config processing"
            exit 1
        fi
    else
        print_info "Config file does not exist, creating new one..."
        
        if [ "$dry_run" = false ]; then
            # Create directory if needed
            if [ "$scope" = "global" ]; then
                mkdir -p "$(dirname "$config_file")" || {
                    print_error "Failed to create directory: $(dirname "$config_file")"
                    exit 1
                }
            fi
            
            # Check if file is writable
            if ! is_writable "$config_file"; then
                exit 1
            fi
            
            # Create new config file
            if cat > "$config_file" <<EOF
{
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
$mcp_config
    }
}
EOF
            then
                print_success "Created new OpenCode config file: $config_file"
            else
                print_error "Failed to create OpenCode config file: $config_file"
                exit 1
            fi
        else
            print_info "[DRY-RUN] Would create new OpenCode config file: $config_file"
        fi
    fi
}

# Process Claude Code configuration
process_claude_config() {
    local scope="$1"
    local dry_run="$2"
    
    local config_file="${CLAUDE_PATHS[$scope]}"
    local mcp_config=""
    local mcp_json=""
    
    print_info "Processing Claude Code configuration (${scope} scope)..."
    
    # Build MCP configuration
    for server_name in "${!MCP_SERVERS[@]}"; do
        local server_config=""
        
        if [ "$server_name" = "searxng" ]; then
            # Prompt for SEARXNG_URL
            if [ "$dry_run" = true ]; then
                print_info "[DRY-RUN] Would prompt for SEARXNG_URL for $server_name"
                searxng_url="https://searxng.example.com"
            else
                read -p "Enter SEARXNG_URL for $server_name: " searxng_url
            fi
            server_config=$(cat <<EOF
    "$server_name": {
        "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}"],
        "env": {
            "SEARXNG_URL": "$searxng_url"
        }
    }
EOF
)
        else
            server_config=$(cat <<EOF
    "$server_name": {
        "command": ["${MCP_SERVERS[$server_name]}"]
    }
EOF
)
        fi
        
        mcp_config+="$server_config"
    done
    
    # Build proper JSON object for mcpServers section
    mcp_json="{"
    local first=true
    for server_name in "${!MCP_SERVERS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            mcp_json+=","
        fi
        mcp_json+="$server_config"
    done
    mcp_json+="}"
    
    # Check if config file exists
    if [ -f "$config_file" ]; then
        print_info "Config file exists: $config_file"
        
        # Create backup
        if [ "$dry_run" = false ]; then
            create_backup "$config_file" || print_warning "Could not create backup"
        fi
        
        # Validate existing JSON
        if ! validate_json "$config_file"; then
            print_error "Existing config file is not valid JSON"
            exit 1
        fi
        
        # Check if mcpServers section exists
        if command_exists jq; then
            if ! jq -e '.mcpServers' "$config_file" >/dev/null 2>&1; then
                # Add mcpServers section
                if [ "$dry_run" = false ]; then
                    # Create temporary file with mcpServers section
                    cat > "${config_file}.tmp" <<EOF
{
    "mcpServers": {
$mcp_config
    }
}
EOF
                    # Merge with existing config
                    jq -s '.[0] * .[1]' "$config_file" "${config_file}.tmp" > "${config_file}.new" && mv "${config_file}.new" "$config_file"
                    rm -f "${config_file}.tmp"
                    print_success "Added mcpServers section to Claude Code config"
                else
                    print_info "[DRY-RUN] Would add mcpServers section to Claude Code config"
                    display_dry_run_preview "$config_file" false
                fi
            else
                # Merge into existing mcpServers section
                if [ "$dry_run" = false ]; then
                    # Build proper JSON object for mcpServers section
                    local mcp_json="{"
                    local first=true
                    local added_servers=0
                    for server_name in "${!MCP_SERVERS[@]}"; do
                        # Check if server already exists
                        if ! mcp_server_exists_in_config "$config_file" "$server_name" false; then
                            if [ "$first" = true ]; then
                                first=false
                            else
                                mcp_json+=","
                            fi
                            mcp_json+="$server_config"
                            added_servers=$((added_servers + 1))
                        fi
                    done
                    mcp_json+="}"
                    
                    if [ $added_servers -gt 0 ]; then
                        # Merge into existing mcpServers section
                        jq --argjson mcp "$mcp_json" '.mcpServers += $mcp' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
                        print_success "Merged $added_servers MCP configurations into Claude Code config"
                    else
                        print_info "All MCP servers already exist in Claude Code config"
                    fi
                else
                    print_info "[DRY-RUN] Would merge MCP configurations into Claude Code config"
                fi
            fi
        else
            print_error "jq is required for Claude Code config processing"
            exit 1
        fi
    else
        print_info "Config file does not exist, creating new one..."
        
        if [ "$dry_run" = false ]; then
            # Create directory if needed
            if [ "$scope" = "global" ]; then
                mkdir -p "$(dirname "$config_file")" || {
                    print_error "Failed to create directory: $(dirname "$config_file")"
                    exit 1
                }
            fi
            
            # Check if file is writable
            if ! is_writable "$config_file"; then
                exit 1
            fi
            
            # Create new config file
            if cat > "$config_file" <<EOF
{
    "mcpServers": {
$mcp_config
    }
}
EOF
            then
                print_success "Created new Claude Code config file: $config_file"
            else
                print_error "Failed to create Claude Code config file: $config_file"
                exit 1
            fi
        else
            print_info "[DRY-RUN] Would create new Claude Code config file: $config_file"
        fi
    fi
}

# Display summary
display_summary() {
    local scope="$1"
    local dry_run="$2"
    
    echo ""
    print_success "MCP Installation Summary"
    echo "========================"
    echo "Scope: ${scope} scope"
    echo "Dry-run: ${dry_run}"
    echo ""
    echo "Installed MCP Servers:"
    for server_name in "${!MCP_SERVERS[@]}"; do
        echo "  - $server_name"
    done
    echo ""
    
    if [ "$dry_run" = true ]; then
        print_warning "This was a dry-run. No changes were made to configuration files."
    fi
}

# Display dry-run preview
display_dry_run_preview() {
    local config_file="$1"
    local is_opencode="$2"
    local added_servers=0
    local existing_servers=0
    
    echo ""
    print_info "Dry-Run Preview for $config_file:"
    echo "-----------------------------------"
    
    for server_name in "${!MCP_SERVERS[@]}"; do
        if mcp_server_exists_in_config "$config_file" "$server_name" "$is_opencode"; then
            echo "  [EXISTING] $server_name"
            existing_servers=$((existing_servers + 1))
        else
            echo "  [TO ADD]   $server_name"
            added_servers=$((added_servers + 1))
        fi
    done
    
    echo ""
    print_info "Summary: $added_servers servers to add, $existing_servers servers already exist"
    echo ""
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Parse command-line arguments
SCOPE="project"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            SCOPE="global"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: $0 [--global] [--dry-run]"
            exit 1
            ;;
    esac
done

# Main execution
print_info "MCP Installation Script"
echo "======================="
echo ""

# Check dependencies
check_dependencies

# Process configurations
process_opencode_config "$SCOPE" "$DRY_RUN"
process_claude_config "$SCOPE" "$DRY_RUN"

# Display summary
display_summary "$SCOPE" "$DRY_RUN"

exit 0
