#!/bin/bash

# PRD Agents Installation Script
# Installs PRD agents for both Claude Code and OpenCode platforms

set -e  # Exit on error

# Default values
GLOBAL_SCOPE=false

# Function to display usage instructions
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install PRD agents for Claude Code and OpenCode platforms."
    echo ""
    echo "OPTIONS:"
    echo "  --global    Install agents globally (user home directory)"
    echo "  --help      Display this help message"
    echo ""
    echo "SCOPE:"
    echo "  By default: Project scope (/proj/.claude/ and /proj/.opencode/)"
    echo "  With --global: User scope (~/.claude/ and ~/.opencode/)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Install to project scope"
    echo "  $0 --global           # Install to user scope"
    echo ""
}

# Function to print error message and exit
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to print success message
success_msg() {
    echo "✓ $1"
}

# Function to print info message
info_msg() {
    echo "ℹ  $1"
}

# Function to print warning message
warning_msg() {
    echo "⚠  $1" >&2
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            GLOBAL_SCOPE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            error_exit "Unknown option: $1. Use --help for usage instructions."
            ;;
    esac
done

# Determine installation paths based on scope
if [ "$GLOBAL_SCOPE" = true ]; then
    # Global scope (user home directory)
    OPENCODE_DIR="$HOME/.opencode/agents"
    CLAUDE_DIR="$HOME/.claude/agents"
    SCOPE_DESCRIPTION="global (user home directory)"
else
    # Project scope (workspace directory)
    OPENCODE_DIR="/proj/.opencode/agents"
    CLAUDE_DIR="/proj/.claude/agents"
    SCOPE_DESCRIPTION="project (/proj)"
fi

# Template source paths
OPENCODE_TEMPLATE="/opt/jeeves/prd-creator-opencode-template.md"
CLAUDE_TEMPLATE="/opt/jeeves/prd-creator-claude-template.md"

# Main installation function
install_agents() {
    info_msg "Installing PRD agents in $SCOPE_DESCRIPTION..."
    
    # Check if template files exist
    if [ ! -f "$OPENCODE_TEMPLATE" ]; then
        error_exit "OpenCode template not found at: $OPENCODE_TEMPLATE"
    fi
    
    if [ ! -f "$CLAUDE_TEMPLATE" ]; then
        error_exit "Claude Code template not found at: $CLAUDE_TEMPLATE"
    fi
    
    # Create directories if they don't exist
    info_msg "Creating directories..."
    
    if [ ! -d "$OPENCODE_DIR" ]; then
        mkdir -p "$OPENCODE_DIR" || error_exit "Failed to create directory: $OPENCODE_DIR"
        success_msg "Created directory: $OPENCODE_DIR"
    else
        info_msg "Directory already exists: $OPENCODE_DIR"
    fi
    
    if [ ! -d "$CLAUDE_DIR" ]; then
        mkdir -p "$CLAUDE_DIR" || error_exit "Failed to create directory: $CLAUDE_DIR"
        success_msg "Created directory: $CLAUDE_DIR"
    else
        info_msg "Directory already exists: $CLAUDE_DIR"
    fi
    
    # Install OpenCode agent
    info_msg "Installing OpenCode PRD agent..."
    if cp "$OPENCODE_TEMPLATE" "$OPENCODE_DIR/prd-creator.md"; then
        success_msg "OpenCode PRD agent installed to: $OPENCODE_DIR/prd-creator.md"
    else
        error_exit "Failed to install OpenCode PRD agent"
    fi
    
    # Install Claude Code agent
    info_msg "Installing Claude Code PRD agent..."
    if cp "$CLAUDE_TEMPLATE" "$CLAUDE_DIR/prd-creator.md"; then
        success_msg "Claude Code PRD agent installed to: $CLAUDE_DIR/prd-creator.md"
    else
        error_exit "Failed to install Claude Code PRD agent"
    fi
    
    # Verify installations
    info_msg "Verifying installations..."
    
    if [ -f "$OPENCODE_DIR/prd-creator.md" ]; then
        success_msg "OpenCode agent verification: PASSED"
    else
        warning_msg "OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$CLAUDE_DIR/prd-creator.md" ]; then
        success_msg "Claude Code agent verification: PASSED"
    else
        warning_msg "Claude Code agent verification: FAILED"
    fi
    
    info_msg "PRD agents installation completed successfully!"
}

# Check if running as root (for global installations)
if [ "$GLOBAL_SCOPE" = true ] && [ "$(id -u)" -ne 0 ]; then
    warning_msg "Installing globally without root privileges. Some operations may fail."
fi

# Run installation
install_agents