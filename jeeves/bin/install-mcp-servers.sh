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
    ["playwright"]="@playwright/mcp@latest"
)

# Environment Variables for MCP Servers
declare -A MCP_ENV_VARS=(
    ["searxng"]="SEARXNG_URL"
)

# Global variables to store environment values
SEARXNG_URL=""

# Default Paths
declare -A OPENCODE_PATHS=(
    ["project"]="opencode.json"
    ["global"]="$HOME/.config/opencode/opencode.json"
)

declare -A CLAUDE_PATHS=(
    ["project"]=".mcp.json"
    ["global"]="$HOME/.claude.json"
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
    
    if jq empty "$json_file" 2>/dev/null; then
        return 0
    else
        print_error "Invalid JSON in file: $json_file"
        return 1
    fi
}

# Build MCP server entry
build_server_config_entry() {
    local server_name="$1"
    local is_opencode="$2"
    local searxng_url="$SEARXNG_URL"

    if [ "$server_name" = "searxng" ]; then
        if [ "$is_opencode" = true ]; then
            printf '    "%s": {
        "type": "local",
        "command": ["npx", "-y", "%s"],
        "environment": {
            "SEARXNG_URL": "%s"
        }
    }' "$server_name" "${MCP_SERVERS[$server_name]}" "$searxng_url"
        else
            printf '    "%s": {
        "command": "npx",
        "args": ["-y", "%s"],
        "env": {
            "SEARXNG_URL": "%s"
        }
    }' "$server_name" "${MCP_SERVERS[$server_name]}" "$searxng_url"
        fi
    elif [ "$server_name" = "playwright" ]; then
        if [ "$is_opencode" = true ]; then
            printf '    "%s": {
        "type": "local",
        "command": ["npx", "-y", "%s", "--isolated", "--no-sandbox"],
        "environment": {
            "PLAYWRIGHT_MCP_HEADLESS": "true",
            "PLAYWRIGHT_MCP_BROWSER": "chromium"
        }
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
        else
            printf '    "%s": {
        "command": "npx",
        "args": ["-y", "%s", "--isolated", "--no-sandbox"],
        "env": {
            "PLAYWRIGHT_MCP_HEADLESS": "true",
            "PLAYWRIGHT_MCP_BROWSER": "chromium"
        }
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
        fi
    elif [ "$server_name" = "sequentialthinking" ]; then
        if [ "$is_opencode" = true ]; then
            printf '    "%s": {
        "type": "local",
        "command": ["npx", "-y", "%s"]
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
        else
            printf '    "%s": {
        "command": "npx",
        "args": ["-y", "%s"]
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
        fi
    elif [ "$server_name" = "fetch" ]; then
        if [ "$is_opencode" = true ]; then
            printf '    "%s": {
        "type": "local",
        "command": ["python", "-m", "mcp_server_fetch"]
    }' "$server_name"
        else
            printf '    "%s": {
        "command": "python",
        "args": ["-m", "mcp_server_fetch"]
    }' "$server_name"
        fi
    else
        if [ "$is_opencode" = true ]; then
            if [[ "${MCP_SERVERS[$server_name]}" == npx* ]]; then
                printf '    "%s": {
        "type": "local",
        "command": ["npx", "-y", "%s"]
    }' "$server_name" "${MCP_SERVERS[$server_name]#npx -y }"
            else
                printf '    "%s": {
        "type": "local",
        "command": ["%s"]
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
            fi
        else
            if [[ "${MCP_SERVERS[$server_name]}" == npx* ]]; then
                printf '    "%s": {
        "command": "npx",
        "args": ["-y", "%s"]
    }' "$server_name" "${MCP_SERVERS[$server_name]#npx -y }"
            else
                printf '    "%s": {
        "command": "%s"
    }' "$server_name" "${MCP_SERVERS[$server_name]}"
            fi
        fi
    fi
}

# Combine MCP entries with proper comma separators and newlines
join_mcp_entries() {
    local is_opencode="$1"
    shift
    local server_names=($@)
    local entries=()

    for server_name in "${server_names[@]}"; do
        entries+=( "$(build_server_config_entry "$server_name" "$is_opencode")" )
    done

    local combined=""
    for idx in "${!entries[@]}"; do
        if [ "$idx" -gt 0 ]; then
            combined+=$',\n'
        fi
        combined+="${entries[$idx]}"
    done

    printf '%s' "$combined"
}

# Parse JSON file
parse_json() {
    local json_file="$1"
    
    jq '.' "$json_file"
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
    
    jq -e ".mcpServers.\"$server_name\"" "$config" >/dev/null 2>&1 || jq -e ".mcp.\"$server_name\"" "$config" >/dev/null 2>&1
}

# Check if a specific MCP server exists in config file
mcp_server_exists_in_config() {
    local config_file="$1"
    local server_name="$2"
    local is_opencode="$3"
    
    if [ "$is_opencode" = true ]; then
        jq -e ".mcp.\"$server_name\"" "$config_file" >/dev/null 2>&1
    else
        jq -e ".mcpServers.\"$server_name\"" "$config_file" >/dev/null 2>&1
    fi
}

# Merge MCP configuration into existing config
merge_mcp_config() {
    local config_file="$1"
    local mcp_config="$2"
    local is_opencode="$3"
    
    if [ "$is_opencode" = true ]; then
        # Merge into mcp object, creating it if it doesn't exist
        if command_exists jq; then
            jq --argjson mcp "$mcp_config" 'if .mcp then .mcp += $mcp else . + {"mcp": $mcp} end' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
        else
            print_error "jq is required for OpenCode config merging"
            return 1
        fi
    else
        # Merge into mcpServers object
        if command_exists jq; then
            jq --argjson mcp "$mcp_config" 'if .mcpServers then .mcpServers += $mcp else . + {"mcpServers": $mcp} end' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
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
    local -a mcp_entries=()
    for server_name in "${!MCP_SERVERS[@]}"; do
        if [ "$dry_run" = true ] && [ "$server_name" = "searxng" ]; then
            print_info "[DRY-RUN] Using SEARXNG_URL for $server_name"
        fi
        
        mcp_entries+=("$(build_server_config_entry "$server_name" true)")
    done
    
    mcp_config=""
    for idx in "${!mcp_entries[@]}"; do
        if [ "$idx" -gt 0 ]; then
            mcp_config+=$',\n'
        fi
        mcp_config+="${mcp_entries[$idx]}"
    done
    
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
                    # Build mcp section content
                    local mcp_section_content=""
                    for idx in "${!mcp_entries[@]}"; do
                        if [ "$idx" -gt 0 ]; then
                            mcp_section_content+=$',\n'
                        fi
                        mcp_section_content+="${mcp_entries[$idx]}"
                    done
                    
                    # Create temporary file with mcp section
                    cat > "${config_file}.tmp" <<EOF
{
    "mcp": {
$mcp_section_content
    }
}
EOF
                    # Merge with existing config
                    jq -s '.[0] * .[1]' "$config_file" "${config_file}.tmp" > "${config_file}.new" && mv "${config_file}.new" "$config_file"
                    rm -f "${config_file}.tmp"
                    print_success "Created mcp section in OpenCode config"
                else
                    print_info "[DRY-RUN] Would create mcp section in OpenCode config"
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
                            # Build config for this server
                            local server_config=""
                            if [ "$server_name" = "searxng" ]; then
                                server_config=$(cat <<EOF
     "$server_name": {
         "type": "local",
         "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}"],
         "environment": {
             "SEARXNG_URL": "$SEARXNG_URL"
         }
     }
EOF
)
                            elif [ "$server_name" = "playwright" ]; then
                                server_config=$(cat <<EOF
      "$server_name": {
          "type": "local",
          "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}", "--isolated", "--no-sandbox"],
          "environment": {
              "PLAYWRIGHT_MCP_HEADLESS": "true",
              "PLAYWRIGHT_MCP_BROWSER": "chromium"
          }
      }
EOF
)
                            elif [ "$server_name" = "sequentialthinking" ]; then
                                server_config=$(cat <<EOF
     "$server_name": {
         "type": "local",
         "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}"]
     }
EOF
)
                            elif [ "$server_name" = "fetch" ]; then
                                server_config=$(cat <<EOF
     "$server_name": {
         "type": "local",
         "command": ["python", "-m", "mcp_server_fetch"]
     }
EOF
)
                            else
                                if [[ "${MCP_SERVERS[$server_name]}" == python* ]]; then
                                    server_config=$(cat <<EOF
     "$server_name": {
         "type": "local",
         "command": ["python", "-m", "mcp_server_fetch"]
     }
EOF
)
                                else
                                    server_config=$(cat <<EOF
     "$server_name": {
         "type": "local",
         "command": ["npx", "-y", "${MCP_SERVERS[$server_name]}"]
     }
EOF
)
                                fi
                            fi
                            
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
                    display_dry_run_preview "$config_file" true
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
            
            # Create temporary directory for file creation
            local temp_dir=$(mktemp -d /tmp/mcp-config-XXXXXX)
            
            # Create temporary config file
            local temp_config_file="${temp_dir}/config.json"
            
            if cat > "$temp_config_file" <<EOF
{
    "\$schema": "https://opencode.ai/config.json",
    "mcp": {
$mcp_config
    }
}
EOF
            then
                # Move config file to target location
                if mv "$temp_config_file" "$config_file"; then
                    print_success "Created new OpenCode config file: $config_file"
                    # Clean up temporary directory
                    rm -rf "$temp_dir"
                else
                    print_error "Failed to move OpenCode config file to target location"
                    rm -rf "$temp_dir"
                    exit 1
                fi
            else
                print_error "Failed to create temporary OpenCode config file"
                rm -rf "$temp_dir"
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
    local -a mcp_entries=()
    for server_name in "${!MCP_SERVERS[@]}"; do
        local server_config=""
        
        if [ "$server_name" = "searxng" ]; then
            if [ "$dry_run" = true ]; then
                print_info "[DRY-RUN] Using SEARXNG_URL for $server_name"
            fi
            searxng_url="$SEARXNG_URL"
            server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]#npx -y }"],
        "env": {
            "SEARXNG_URL": "$searxng_url"
        }
    }
EOF
)
        elif [ "$server_name" = "playwright" ]; then
            server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}", "--isolated", "--no-sandbox"],
        "env": {
            "PLAYWRIGHT_MCP_HEADLESS": "true",
            "PLAYWRIGHT_MCP_BROWSER": "chromium"
        }
    }
EOF
)
        elif [ "$server_name" = "sequentialthinking" ]; then
            server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}"]
    }
EOF
)
        else
            if [[ "${MCP_SERVERS[$server_name]}" == npx* ]]; then
                server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]#npx -y }"]
    }
EOF
)
            elif [[ "${MCP_SERVERS[$server_name]}" == python* ]]; then
                server_config=$(cat <<EOF
    "$server_name": {
        "command": "python",
        "args": ["-m", "mcp_server_fetch"]
    }
EOF
)
            else
                server_config=$(cat <<EOF
    "$server_name": {
        "command": "${MCP_SERVERS[$server_name]}"
    }
EOF
)
            fi
        fi
        
        mcp_entries+=("$server_config")
    done
    
    mcp_config=""
    for idx in "${!mcp_entries[@]}"; do
        if [ "$idx" -gt 0 ]; then
            mcp_config+=$',\n'
        fi
        mcp_config+="${mcp_entries[$idx]}"
    done
    
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
                    print_success "Created mcpServers section in Claude Code config"
                else
                    print_info "[DRY-RUN] Would create mcpServers section in Claude Code config"
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
                            # Build config for this server
                            local server_config=""
                            if [ "$server_name" = "searxng" ]; then
                                server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}"],
        "env": {
            "SEARXNG_URL": "$SEARXNG_URL"
        }
    }
EOF
)
                            elif [ "$server_name" = "playwright" ]; then
server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}", "--isolated", "--no-sandbox"],
        "env": {
            "PLAYWRIGHT_MCP_HEADLESS": "true",
            "PLAYWRIGHT_MCP_BROWSER": "chromium"
        }
    }
EOF
)
                            elif [ "$server_name" = "sequentialthinking" ]; then
                                server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}"]
    }
EOF
)
                            elif [ "$server_name" = "fetch" ]; then
                                server_config=$(cat <<EOF
    "$server_name": {
        "command": "python",
        "args": ["-m", "mcp_server_fetch"]
    }
EOF
)
                            else
                                if [[ "${MCP_SERVERS[$server_name]}" == python* ]]; then
                                    server_config=$(cat <<EOF
    "$server_name": {
        "command": "python",
        "args": ["-m", "mcp_server_fetch"]
    }
EOF
)
                                else
                                    server_config=$(cat <<EOF
    "$server_name": {
        "command": "npx",
        "args": ["-y", "${MCP_SERVERS[$server_name]}"]
    }
EOF
)
                                fi
                            fi
                            
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
            
            # Create temporary directory for file creation
            local temp_dir=$(mktemp -d /tmp/mcp-config-XXXXXX)
            
            # Create temporary config file
            local temp_config_file="${temp_dir}/config.json"
            
            if cat > "$temp_config_file" <<EOF
{
    "mcpServers": {
$mcp_config
    }
}
EOF
            then
                # Move config file to target location
                if mv "$temp_config_file" "$config_file"; then
                    print_success "Created new Claude Code config file: $config_file"
                    # Clean up temporary directory
                    rm -rf "$temp_dir"
                else
                    print_error "Failed to move Claude Code config file to target location"
                    rm -rf "$temp_dir"
                    exit 1
                fi
            else
                print_error "Failed to create temporary Claude Code config file"
                rm -rf "$temp_dir"
                exit 1
            fi
        else
            print_info "[DRY-RUN] Would create new Claude Code config file: $config_file"
        fi
    fi
}

# Display dry run preview
display_dry_run_preview() {
    local config_file="$1"
    local is_opencode="$2"
    
    echo ""
    print_info "Dry-run preview for $config_file:"
    echo "---------------------------------------"
    
    # Show what the MCP section would look like
    local -a mcp_entries=()
    for server_name in "${!MCP_SERVERS[@]}"; do
        if [ "$is_opencode" = true ]; then
            mcp_entries+=("$(build_server_config_entry "$server_name" true)")
        else
            mcp_entries+=("$(build_server_config_entry "$server_name" false)")
        fi
    done
    
    local mcp_config=""
    for idx in "${!mcp_entries[@]}"; do
        if [ "$idx" -gt 0 ]; then
            mcp_config+=$',\n'
        fi
        mcp_config+="${mcp_entries[$idx]}"
    done
    
    if [ "$is_opencode" = true ]; then
        echo "Would add/merge into mcp section:"
    else
        echo "Would add/merge into mcpServers section:"
    fi
    
    echo -e "$mcp_config"
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

# Prompt for SEARXNG_URL once at the beginning
if [ "$DRY_RUN" = true ]; then
    print_info "[DRY-RUN] Using placeholder SEARXNG_URL"
    SEARXNG_URL="https://searxng.example.com"
elif [ -z "$SEARXNG_URL" ]; then
    read -p "Enter SEARXNG_URL: " SEARXNG_URL
fi


# Process configurations
process_opencode_config "$SCOPE" "$DRY_RUN"
process_claude_config "$SCOPE" "$DRY_RUN"

# Display summary
display_summary "$SCOPE" "$DRY_RUN"

exit 0
