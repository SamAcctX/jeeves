#!/usr/bin/env bash
# PRD Creator Uninstall Script

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_AGENTS_DIR="$OPENCODE_CONFIG_DIR/agent"
PROJECT_AGENTS_DIR=".opencode/agent"
OPENCODE_CONFIG_FILE="$OPENCODE_CONFIG_DIR/opencode.json"

info() { echo -e "${BLUE}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warning() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✗ ${NC}$1"; }
header() { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

show_usage() {
    cat << EOF
PRD Creator - Uninstall PRD Creator agent

Usage: prd-creator-uninstall [OPTIONS]

COMMANDS:
    global          Remove global agent
    project         Remove project agent
    all             Remove both global and project agents
    help            Show this help message

EXAMPLES:
    prd-creator-uninstall global              # Remove global agent
    prd-creator-uninstall project             # Remove project agent
    prd-creator-uninstall all                 # Remove both agents
    prd-creator-uninstall all --include-mcp   # Remove agents and deconfigure MCP servers

OPTIONS:
    --dry-run       Show what would be removed without actually removing
    --force         Skip confirmation prompts
    --include-mcp   Also remove PRD Creator's MCP servers from OpenCode config

For more information, see 'prd-creator help'.

EOF
}

confirm_removal() {
    local file_path="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = "true" ]; then
        info "Would remove: $description"
        return 0
    fi
    
    warning "About to remove: $description"
    warning "File: $file_path"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Cancelled"
        return 1
    fi
    return 0
}

remove_mcp_servers() {
    local config_file="$OPENCODE_CONFIG_FILE"
    
    if [ ! -f "$config_file" ]; then
        info "OpenCode configuration file not found: $config_file"
        return 0
    fi
    
    header "Removing MCP Servers from OpenCode Configuration"
    
    if [ "$DRY_RUN" = "true" ]; then
        info "Would remove MCP servers from: $config_file"
        info "• sequential-thinking"
        info "• filesystem"
        return 0
    fi
    
    # Backup the config before modification
    local config_bak="$config_file.prd-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
    cp "$config_file" "$config_bak"
    info "Configuration backed up to: $config_bak"
    
    # Remove MCP servers using jq if available
    if command -v jq >/dev/null 2>&1; then
        local temp_config=$(mktemp)
        jq 'del(.mcpServers."sequential-thinking") | del(.mcpServers."filesystem")' "$config_file" > "$temp_config"
        mv "$temp_config" "$config_file"
        success "MCP servers removed using jq"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json

config_file = '$config_file'

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print('Error reading configuration file')
    exit(1)

if 'mcpServers' in config:
    removed = []
    if 'sequential-thinking' in config['mcpServers']:
        del config['mcpServers']['sequential-thinking']
        removed.append('sequential-thinking')
    if 'filesystem' in config['mcpServers']:
        del config['mcpServers']['filesystem']
        removed.append('filesystem')
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print('Removed MCP servers:', ', '.join(removed) if removed else 'None found')
else:
    print('No mcpServers section found in configuration')
"
        success "MCP servers removed using Python"
    else
        error "Neither jq nor python3 found for JSON manipulation"
        warning "Please manually remove 'sequential-thinking' and 'filesystem' from $config_file"
        return 1
    fi
    
    # Clean up temp file if it exists
    rm -f "$temp_config"
    
    success "PRD Creator MCP servers removed from OpenCode configuration"
    info ""
    warning "Note: Other agents may still use these MCP servers."
    warning "Only remove them if you're sure they're no longer needed."
}

cmd_remove_global() {
    header "Uninstalling Global PRD Creator Agent"
    
    local agent_file="$OPENCODE_AGENTS_DIR/prd-creator.md"
    if [ -f "$agent_file" ]; then
        if ! confirm_removal "$agent_file" "Global PRD Creator agent"; then
            return 1
        fi
        
        rm -f "$agent_file"
        success "Global PRD Creator agent removed from: $agent_file"
    else
        info "Global PRD Creator agent not found at: $agent_file"
    fi
}

cmd_remove_project() {
    header "Uninstalling Project PRD Creator Agent"
    
    local agent_file="$WORKSPACE/$PROJECT_AGENTS_DIR/prd-creator.md"
    if [ -f "$agent_file" ]; then
        if ! confirm_removal "$agent_file" "Project PRD Creator agent"; then
            return 1
        fi
        
        rm -f "$agent_file"
        success "Project PRD Creator agent removed from: $agent_file"
    else
        info "Project PRD Creator agent not found at: $agent_file"
    fi
}

cmd_remove_all() {
    header "Uninstalling All PRD Creator Agents"
    
    local removed_any=false
    
    # Remove global agent
    local global_agent="$OPENCODE_AGENTS_DIR/prd-creator.md"
    if [ -f "$global_agent" ]; then
        if ! confirm_removal "$global_agent" "Global PRD Creator agent"; then
            return 1
        fi
        
        rm -f "$global_agent"
        success "Global PRD Creator agent removed from: $global_agent"
        removed_any=true
    else
        info "Global PRD Creator agent not found at: $global_agent"
    fi
    
    # Remove project agent
    local project_agent="$WORKSPACE/$PROJECT_AGENTS_DIR/prd-creator.md"
    if [ -f "$project_agent" ]; then
        if ! confirm_removal "$project_agent" "Project PRD Creator agent"; then
            return 1
        fi
        
        rm -f "$project_agent"
        success "Project PRD Creator agent removed from: $project_agent"
        removed_any=true
    else
        info "Project PRD Creator agent not found at: $project_agent"
    fi
    
    if [ "$removed_any" = true ]; then
        success "PRD Creator agents uninstalled successfully"
        info "You may need to restart OpenCode to refresh the agent list"
        
        # Note about MCP servers if not being removed
        if [ "$remove_mcp" != true ]; then
            info ""
            warning "Note: MCP servers configured for PRD Creator remain in OpenCode configuration."
            warning "To remove them, run: prd-creator-uninstall all --include-mcp"
        fi
    else
        warning "No PRD Creator agents found to uninstall"
    fi
}

main() {
    local remove_mcp=false
    local command=""
    
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    # Parse all arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            --force)
                export FORCE=true
                shift
                ;;
            --include-mcp)
                remove_mcp=true
                shift
                ;;
            global|project|all)
                command="$1"
                shift
                ;;
            help|--help|-h)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo ""
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Execute the command
    case "$command" in
        global)
            cmd_remove_global
            ;;
        project)
            cmd_remove_project
            ;;
        all)
            cmd_remove_all
            ;;
        "")
            error "No command specified"
            echo ""
            show_usage
            exit 1
            ;;
    esac
    
    # Remove MCP servers if requested
    if [ "$remove_mcp" = true ]; then
        remove_mcp_servers
    fi
}

main "$@"
