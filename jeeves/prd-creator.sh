#!/usr/bin/env bash
# PRD Creator - A helper tool for PRD creation with AI coding assistants
# Compatible with opencode and Claude

set -e

PRD_AGENT_FILE="/opt/jeeves/prd-creator/prd-creator-prompt.md"
PRD_PROMPT_FILE="$PRD_AGENT_FILE"
PRD_README="/opt/jeeves/prd-creator/README.md"
WORKSPACE="${WORKSPACE:-/workspace}"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_AGENTS_DIR="$OPENCODE_CONFIG_DIR/agent"
PROJECT_AGENTS_DIR=".opencode/agent"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warning() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✗ ${NC}$1"; }
header() { echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

show_usage() {
    cat << EOF
PRD Creator - Create Product Requirements Documents with AI assistance

Usage: prd-creator [COMMAND] [OPTIONS]

COMMANDS:
    init           Show initialization instructions
    copy-prompt    Copy PRD creator prompt to clipboard (if clipboard available)
    save-prompt    Save the PRD creator agent to your workspace
    install         Install PRD Creator as an opencode agent
    help           Show this help message

OPTIONS FOR 'install' COMMAND:
    --global        Install to global config (~/.config/opencode/agent/)
    --project       Install to project config (.opencode/agent/) [default if in project root]
    --skip-mcp      Skip automatic MCP server configuration

EXAMPLES:
    prd-creator init                    # Show how to get started
    prd-creator install                    # Install as global agent with MCP configuration
    prd-creator install --project           # Install as project-level agent with MCP configuration
    prd-creator install --skip-mcp          # Install without configuring MCP servers
    prd-creator save-prompt               # Save agent to workspace
    prd-creator show-readme               # Show full README with detailed instructions
    prd-creator check-mcp                # Check MCP server configuration

For more information, run: prd-creator show-readme

EOF
}

check_files() {
    if [ ! -f "$PRD_PROMPT_FILE" ]; then
        error "PRD agent file not found at: $PRD_PROMPT_FILE"
        return 1
    fi
    if [ ! -f "$PRD_README" ]; then
        error "PRD README not found at: $PRD_README"
        return 1
    fi
    return 0
}

cmd_init() {
    header "PRD Creator - Quick Start Guide"
    
    printf "\n"
    printf "The PRD Creator helps you create comprehensive Product Requirements Documents\n"
    printf "using AI coding assistants (opencode or Claude).\n"
    printf "\n"
    printf "QUICK START (Choose one method):\n"
    printf "\n"
    printf "${CYAN}Method 1: Install as OpenCode Agent (Recommended)${NC}\n"
    printf "  1. Run: ${GREEN}prd-creator install${NC}\n"
    printf "  2. Restart opencode\n"
    printf "  3. Select 'PRD Creator' from agents menu\n"
    printf "  4. Start describing your app idea!\n"
    printf "\n"
    printf "${CYAN}Method 2: Direct Prompt Copy${NC}\n"
    printf "  1. Run: ${GREEN}prd-creator save-prompt${NC}\n"
    printf "  2. Copy the agent content from the generated file\n"
    printf "  3. In opencode/claude, paste it into your conversation\n"
    printf "  4. Start describing your app idea!\n"
    printf "\n"
    printf "${CYAN}For enhanced functionality (MCP tools):${NC}\n"
    printf "  Run: ${GREEN}prd-creator check-mcp${NC} to see which MCP servers are recommended\n"
    printf "  and how to configure them for enhanced research capabilities.\n"
    printf "\n"
    printf "FULL DOCUMENTATION:\n"
    printf "  Run: ${GREEN}prd-creator show-readme${NC} for complete usage instructions.\n"
    printf "\n"
}

cmd_save_prompt() {
    header "Saving PRD Creator Agent"
    
    if [ ! -f "$PRD_PROMPT_FILE" ]; then
        error "PRD agent file not found at: $PRD_PROMPT_FILE"
        info "Make sure the Docker image has been built with the files"
        return 1
    fi
    
    OUTPUT_FILE="$WORKSPACE/prd-creator.md"
    
    if [ -f "$OUTPUT_FILE" ]; then
        warning "File already exists: $OUTPUT_FILE"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Aborted"
            exit 0
        fi
    fi
    
    cp "$PRD_PROMPT_FILE" "$OUTPUT_FILE"
    success "PRD Creator agent saved to: $OUTPUT_FILE"
    info "You can now:"
    info "  - Copy the content and paste it into your opencode/claude conversation"
    info "  - Use it to create a custom mode/agent in your AI tool"
    info ""
    info "After pasting the agent, simply describe your app idea to begin!"
}

configure_opencode_mcp() {
    local config_file="$OPENCODE_CONFIG_DIR/opencode.json"
    local config_bak="$config_file.prd-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ ! -f "$config_file" ]; then
        # Create default config if it doesn't exist
        info "Creating OpenCode configuration file..."
        mkdir -p "$OPENCODE_CONFIG_DIR"
        cat > "$config_file" << 'EOF'
{
  "mcpServers": {}
}
EOF
    fi
    
    # Backup original config
    cp "$config_file" "$config_bak"
    info "Configuration backed up to: $config_bak"
    
    # Update MCP configuration
    local temp_config=$(mktemp)
    
    # Use jq to safely update JSON, or fallback to simple text manipulation
    if command -v jq >/dev/null 2>&1; then
        # Use jq for proper JSON handling
        jq --arg workspace "$WORKSPACE" '
            .mcpServers."sequential-thinking" = {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
            } |
            .mcpServers."filesystem" = {
                "command": "npx", 
                "args": ["-y", "@modelcontextprotocol/server-filesystem", $workspace]
            }
        ' "$config_file" > "$temp_config"
        
        mv "$temp_config" "$config_file"
        success "MCP servers configured using jq"
    else
        # Fallback: simple text-based JSON manipulation
        warning "jq not found, using basic JSON manipulation"
        
        # Read existing config and add MCP servers
        python3 -c "
import json
import sys

config_file = '$config_file'
workspace = '$WORKSPACE'

try:
    with open(config_file, 'r') as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    config = {'mcpServers': {}}

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['sequential-thinking'] = {
    'command': 'npx',
    'args': ['-y', '@modelcontextprotocol/server-sequential-thinking']
}

config['mcpServers']['filesystem'] = {
    'command': 'npx',
    'args': ['-y', '@modelcontextprotocol/server-filesystem', workspace]
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
"
        
        if [ $? -eq 0 ]; then
            success "MCP servers configured using Python"
        else
            error "Failed to configure MCP servers"
            rm -f "$config_bak"
            return 1
        fi
    fi
    
    # Clean up temp file if it exists
    rm -f "$temp_config"
    
    success "MCP servers configured:"
    info "• Sequential Thinking - For systematic problem analysis"
    info "• File System - For saving PRD files to your workspace"
    info ""
    info "Note: These MCP servers will auto-install when first used via npx"
}

cmd_install() {
    local install_global=false
    local install_project=false
    local skip_mcp=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --global)
                install_global=true
                shift
                ;;
            --project)
                install_project=true
                shift
                ;;
            --skip-mcp)
                skip_mcp=true
                shift
                ;;
            *)
                # Auto-detect: if in workspace with git repo, use project
                if [ -d "$WORKSPACE/.git" ] || [ -f "$WORKSPACE/package.json" ] || [ -f "$WORKSPACE/pyproject.toml" ] || [ -f "$WORKSPACE/Cargo.toml" ]; then
                    install_project=true
                else
                    install_global=true
                fi
                shift
                ;;
        esac
    done
    
    # If both flags specified, use project
    if [ "$install_global" = true ] && [ "$install_project" = true ]; then
        warning "Both --global and --project specified, using project installation"
        install_global=false
    fi
    
    # Configure MCP servers unless explicitly skipped
    if [ "$skip_mcp" != "true" ]; then
        printf "\n"
        header "Configuring MCP Servers"
        configure_opencode_mcp
        if [ $? -ne 0 ]; then
            error "MCP configuration failed"
            return 1
        fi
    fi
    
    if [ "$install_global" = true ]; then
        local target_dir="$OPENCODE_AGENTS_DIR"
        printf "\n"
        info "Installing PRD Creator as global agent..."
        printf "\n"
        info "Target: $target_dir"
        
        # Create agents directory if it doesn't exist
        if [ ! -d "$OPENCODE_AGENTS_DIR" ]; then
            mkdir -p "$OPENCODE_AGENTS_DIR"
            info "Created global agents directory: $OPENCODE_AGENTS_DIR"
        fi
        
        # Copy agent configuration
        cp "$PRD_PROMPT_FILE" "$OPENCODE_AGENTS_DIR/prd-creator.md"
        
        if [ $? -eq 0 ]; then
            success "PRD Creator agent installed to: $OPENCODE_AGENTS_DIR/prd-creator.md"
            printf "\n"
            info "To use PRD Creator agent:"
            info "  1. Restart opencode if it's currently running"
            info "  2. Select 'PRD Creator' from agents menu (or use @prd-creator)"
            info "  3. Start describing your app idea!"
            if [ "$skip_mcp" != "true" ]; then
                info ""
                info "MCP servers have been automatically configured and will be available"
                info "when opencode restarts."
            fi
        else
            error "Failed to copy agent configuration to global directory"
            return 1
        fi
    fi
    
    if [ "$install_project" = true ]; then
        local target_dir="$WORKSPACE/$PROJECT_AGENTS_DIR"
        printf "\n"
        info "Installing PRD Creator as project-level agent..."
        printf "\n"
        info "Target: $target_dir"
        info "Workspace: $WORKSPACE"
        
        # Create project agents directory if it doesn't exist
        if [ ! -d "$target_dir" ]; then
            mkdir -p "$target_dir"
            info "Created project agents directory: $target_dir"
        fi
        
        # Copy agent configuration
        cp "$PRD_PROMPT_FILE" "$target_dir/prd-creator.md"
        
        if [ $? -eq 0 ]; then
            success "PRD Creator agent installed to: $target_dir/prd-creator.md"
            printf "\n"
            info "To use PRD Creator agent:"
            info "  1. Restart opencode or reload as project"
            info "  2. Select 'PRD Creator' from agents menu (or use @prd-creator)"
            info "  3. Start describing your app idea!"
            if [ "$skip_mcp" != "true" ]; then
                info ""
                info "MCP servers have been automatically configured and will be available"
                info "when opencode restarts."
            fi
        else
            error "Failed to copy agent configuration to project directory"
            return 1
        fi
    fi
}

cmd_show_readme() {
    cat "$PRD_README"
}

cmd_check_mcp() {
    header "MCP Server Configuration Check"
    
    printf "\n"
    printf "${CYAN}Recommended MCP Servers for Enhanced PRD Creation${NC}\n"
    printf "\n"
    printf "The PRD Creator works with or without MCP servers. However, following\n"
    printf "MCP servers enhance its capabilities significantly:\n"
    printf "\n"
    printf "${YELLOW}1. Sequential Thinking${NC}\n"
    printf "   Purpose: Break down complex problems step by step\n"
    printf "   GitHub: https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking\n"
    printf "   Config:\n"
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"sequentialthinking\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@modelcontextprotocol/server-sequential-thinking\"]\n"
    printf "       }\n"
    printf "     }\n"
    printf "   }\n"
    printf "\n"
    printf "${YELLOW}2. Brave Search${NC}\n"
    printf "   Purpose: Research current information about technologies, frameworks, best practices\n"
    printf "   GitHub: https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search\n"
    printf "   Note: Requires BRAVE_API_KEY environment variable\n"
    printf "   Config:\n"
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"brave-search\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@modelcontextprotocol/server-brave-search\"],\n"
    printf "         \"env\": {\n"
    printf "           \"BRAVE_API_KEY\": \"your-brave-api-key-here\"\n"
    printf "         }\n"
    printf "       }\n"
    printf "     }\n"
    printf "   }\n"
    printf "\n"
    printf "${YELLOW}3. Tavily Research${NC}\n"
    printf "   Purpose: In-depth technical research and analysis\n"
    printf "   GitHub: https://github.com/tavily-ai/tavily-mcp\n"
    printf "   Note: Requires TAVILY_API_KEY environment variable\n"
    printf "   Config:\n"
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"tavily-research\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@tavily/mcp-server\"],\n"
    printf "         \"env\": {\n"
    printf "           \"TAVILY_API_KEY\": \"your-tavily-api-key-here\"\n"
    printf "         }\n"
    printf "       }\n"
    printf "     }\n"
    printf "   }\n"
    printf "\n"
    printf "${YELLOW}4. File System${NC}\n"
    printf "   Purpose: Save generated PRD files directly to your project\n"
    printf "   GitHub: https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem\n"
    printf "   Config:\n"
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"filesystem\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@modelcontextprotocol/server-filesystem\", \"$WORKSPACE\"]\n"
    printf "       }\n"
    printf "     }\n"
    printf "   }\n"
    printf "\n"
    printf "${YELLOW}5. Fetch${NC} (Optional)\n"
    printf "   Purpose: Fetch web content for research\n"
    printf "   GitHub: https://github.com/modelcontextprotocol/servers/tree/main/src/fetch\n"
    printf "   Config:\n"
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"fetch\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@modelcontextprotocol/server-fetch\"]\n"
    printf "       }\n"
    printf "     }\n"
    printf "   }\n"
    printf "\n"
    printf "${CYAN}Auto-Installation${NC}\n"
    printf "\n"
    printf "${GREEN}The following MCP servers can be auto-installed:${NC}\n"
    printf "• ${YELLOW}Sequential Thinking${NC} - Auto-configured and installs via npx\n"
    printf "• ${YELLOW}File System${NC} - Auto-configured and installs via npx\n"
    printf "\n"
    printf "${CYAN}Manual Configuration Required${NC}\n"
    printf "\n"
    printf "• ${BLUE}Brave Search${NC} - Requires BRAVE_API_KEY environment variable\n"
    printf "• ${BLUE}Tavily Research${NC} - Requires TAVILY_API_KEY environment variable\n"
    printf "• ${BLUE}Fetch${NC} - Optional, no configuration needed\n"
    printf "\n"
    printf "${GREEN}For opencode:${NC}\n"
    printf "1. Open your opencode config directory (~/.config/opencode/)\n"
    printf "2. Edit opencode.json and add to 'mcp' section:\n"
    printf "   %s\n" '```json'
    printf "   {\n"
    printf "     \"mcpServers\": {\n"
    printf "       \"brave-search\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@modelcontextprotocol/server-brave-search\"],\n"
    printf "         \"env\": {\n"
    printf "           \"BRAVE_API_KEY\": \"your-brave-api-key-here\"\n"
    printf "         }\n"
    printf "       },\n"
    printf "       \"tavily-research\": {\n"
    printf "         \"command\": \"npx\",\n"
    printf "         \"args\": [\"-y\", \"@tavily/mcp-server\"],\n"
    printf "         \"env\": {\n"
    printf "           \"TAVILY_API_KEY\": \"your-tavily-api-key-here\"\n"
    printf "         }\n"
    printf "       }\n"
    printf "     }\n"
    printf "   %s\n" '```'
    printf "3. Restart opencode\n"
    printf "\n"
    printf "${GREEN}For Claude Desktop:${NC}\n"
    printf "1. Open Claude Desktop settings\n"
    printf "2. Navigate to Developer > MCP Servers\n"
    printf "3. Add the desired server configurations\n"
    printf "4. Restart Claude\n"
    printf "\n"
    printf "${CYAN}Current Environment Check${NC}\n"
    printf "\n"
    
    # Check environment variables
    if [ -n "$BRAVE_API_KEY" ]; then
        success "BRAVE_API_KEY is set"
    else
        info "BRAVE_API_KEY is not set (required for Brave Search MCP)"
        info "  → Set with: export BRAVE_API_KEY='your-brave-api-key-here'"
    fi
    
    if [ -n "$TAVILY_API_KEY" ]; then
        success "TAVILY_API_KEY is set"
    else
        info "TAVILY_API_KEY is not set (required for Tavily Research MCP)"
        info "  → Set with: export TAVILY_API_KEY='your-tavily-api-key-here'"
    fi
    
    # Auto-install MCP servers that don't require API keys
    info "Automatically configured MCP servers (no API keys needed):"
    info "• Sequential Thinking - Auto-configured and installs via npx"
    info "• File System - Auto-configured and installs via npx"
    
    # Check if API key-dependent MCPs can be installed
    if [ -n "$BRAVE_API_KEY" ] || [ -n "$TAVILY_API_KEY" ]; then
        info "Note: API key-dependent MCPs (Brave Search, Tavily Research) require keys before use"
        info "• Brave Search - Requires BRAVE_API_KEY"
        info "• Tavily Research - Requires TAVILY_API_KEY"
        info "• Fetch - Optional, can be used without API key"
    fi
    
    echo ""
    info "To install additional MCPs manually:"
    info "1. Sequential Thinking: npx @modelcontextprotocol/server-sequential-thinking"
    info "2. File System: npx @modelcontextprotocol/server-filesystem \"$WORKSPACE\""
    info "3. Fetch: npx @modelcontextprotocol/server-fetch"
    info "4. Brave Search: npx @modelcontextprotocol/server-brave-search (requires BRAVE_API_KEY)"
    info "5. Tavily Research: npx @tavily/mcp-server (requires TAVILY_API_KEY)"
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi
    
    case "$1" in
        init)
            cmd_init
            ;;
        copy-prompt)
            if [ -t 1 ]; then
                warning "copy-prompt requires a terminal with clipboard support"
                info "Use 'prd-creator save-prompt' instead to save to a file"
                exit 1
            fi
            ;;
        save-prompt)
            cmd_save_prompt
            ;;
        install|install-agent)
            shift
            cmd_install "$@"
            ;;
        show-readme)
            cmd_show_readme
            ;;
        check-mcp)
            cmd_check_mcp
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"