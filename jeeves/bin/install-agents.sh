#!/bin/bash

# PRD Agents Installation Script
# Installs PRD agents for OpenCode platform

set -e  # Exit on error

# Default values
GLOBAL_SCOPE=false
DEEPEST_ONLY=false
INSTALL_ALL=false

# Function to display usage instructions
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install PRD agents for OpenCode platform."
    echo ""
    echo "OPTIONS:"
    echo "  -g, --global    Install agents globally (user home directory)"
    echo "  -d, --deepest   Install Deepest-Thinking agent only"
    echo "  -a, --all       Install all agents (PRD Creator and Deepest-Thinking)"
    echo "  -h, --help      Display this help message"
    echo ""
    echo "SCOPE:"
    echo "  By default: Project scope (/proj/.opencode/)"
    echo "  With --global: User scope (~/.opencode/)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Install to project scope"
    echo "  $0 -g                 # Install to user scope"
    echo "  $0 -d                 # Install Deepest-Thinking agent only"
    echo "  $0 -a                 # Install all agents explicitly"
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
        --global|-g)
            GLOBAL_SCOPE=true
            shift
            ;;
        --deepest|-d)
            DEEPEST_ONLY=true
            shift
            ;;
        --all|-a)
            INSTALL_ALL=true
            shift
            ;;
        --help|-h)
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
    SCOPE_DESCRIPTION="global (user home directory)"
else
    # Project scope (workspace directory)
    OPENCODE_DIR="/proj/.opencode/agents"
    SCOPE_DESCRIPTION="project (/proj)"
fi

# PRD Creator OpenCode template path
OPENCODE_TEMPLATE="/opt/jeeves/PRD/prd-creator-opencode-template.md"

# PRD Researcher template path
PRD_RESEARCHER_OPENCODE_TEMPLATE="/opt/jeeves/PRD/prd-researcher-opencode-template.md"

# PRD Advisor OpenCode template paths
PRD_ADVISOR_API_TEMPLATE="/opt/jeeves/PRD/prd-advisor-api-opencode-template.md"
PRD_ADVISOR_CLI_TEMPLATE="/opt/jeeves/PRD/prd-advisor-cli-opencode-template.md"
PRD_ADVISOR_DATA_TEMPLATE="/opt/jeeves/PRD/prd-advisor-data-opencode-template.md"
PRD_ADVISOR_LIBRARY_TEMPLATE="/opt/jeeves/PRD/prd-advisor-library-opencode-template.md"
PRD_ADVISOR_UI_TEMPLATE="/opt/jeeves/PRD/prd-advisor-ui-opencode-template.md"

# Deepest-Thinking template path
DEEPEST_OPENCODE_TEMPLATE="/opt/jeeves/Deepest-Thinking/deepest-thinking-opencode-template.md"

# Main installation function
install_agents() {
    info_msg "Installing PRD agents in $SCOPE_DESCRIPTION..."
    
    # Check if template files exist
    if [ ! -f "$OPENCODE_TEMPLATE" ]; then
        error_exit "OpenCode template not found at: $OPENCODE_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_RESEARCHER_OPENCODE_TEMPLATE" ]; then
        error_exit "PRD Researcher OpenCode template not found at: $PRD_RESEARCHER_OPENCODE_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_ADVISOR_API_TEMPLATE" ]; then
        error_exit "PRD Advisor API template not found at: $PRD_ADVISOR_API_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_ADVISOR_CLI_TEMPLATE" ]; then
        error_exit "PRD Advisor CLI template not found at: $PRD_ADVISOR_CLI_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_ADVISOR_DATA_TEMPLATE" ]; then
        error_exit "PRD Advisor Data template not found at: $PRD_ADVISOR_DATA_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_ADVISOR_LIBRARY_TEMPLATE" ]; then
        error_exit "PRD Advisor Library template not found at: $PRD_ADVISOR_LIBRARY_TEMPLATE"
    fi
    
    if [ ! -f "$PRD_ADVISOR_UI_TEMPLATE" ]; then
        error_exit "PRD Advisor UI template not found at: $PRD_ADVISOR_UI_TEMPLATE"
    fi
    
    # Create directories if they don't exist
    info_msg "Creating directories..."
    
    if [ ! -d "$OPENCODE_DIR" ]; then
        mkdir -p "$OPENCODE_DIR" || error_exit "Failed to create directory: $OPENCODE_DIR"
        success_msg "Created directory: $OPENCODE_DIR"
    else
        info_msg "Directory already exists: $OPENCODE_DIR"
    fi
    
    # Install OpenCode PRD agent
    info_msg "Installing OpenCode PRD agent..."
    if cp "$OPENCODE_TEMPLATE" "$OPENCODE_DIR/prd-creator.md"; then
        success_msg "OpenCode PRD agent installed to: $OPENCODE_DIR/prd-creator.md"
    else
        error_exit "Failed to install OpenCode PRD agent"
    fi
    
    # Install PRD Researcher OpenCode agent
    info_msg "Installing PRD Researcher OpenCode agent..."
    if cp "$PRD_RESEARCHER_OPENCODE_TEMPLATE" "$OPENCODE_DIR/prd-researcher.md"; then
        success_msg "PRD Researcher OpenCode agent installed to: $OPENCODE_DIR/prd-researcher.md"
    else
        error_exit "Failed to install PRD Researcher OpenCode agent"
    fi
    
    # Install PRD Advisor API OpenCode agent
    info_msg "Installing PRD Advisor API OpenCode agent..."
    if cp "$PRD_ADVISOR_API_TEMPLATE" "$OPENCODE_DIR/prd-advisor-api.md"; then
        success_msg "PRD Advisor API OpenCode agent installed to: $OPENCODE_DIR/prd-advisor-api.md"
    else
        error_exit "Failed to install PRD Advisor API OpenCode agent"
    fi
    
    # Install PRD Advisor CLI OpenCode agent
    info_msg "Installing PRD Advisor CLI OpenCode agent..."
    if cp "$PRD_ADVISOR_CLI_TEMPLATE" "$OPENCODE_DIR/prd-advisor-cli.md"; then
        success_msg "PRD Advisor CLI OpenCode agent installed to: $OPENCODE_DIR/prd-advisor-cli.md"
    else
        error_exit "Failed to install PRD Advisor CLI OpenCode agent"
    fi
    
    # Install PRD Advisor Data OpenCode agent
    info_msg "Installing PRD Advisor Data OpenCode agent..."
    if cp "$PRD_ADVISOR_DATA_TEMPLATE" "$OPENCODE_DIR/prd-advisor-data.md"; then
        success_msg "PRD Advisor Data OpenCode agent installed to: $OPENCODE_DIR/prd-advisor-data.md"
    else
        error_exit "Failed to install PRD Advisor Data OpenCode agent"
    fi
    
    # Install PRD Advisor Library OpenCode agent
    info_msg "Installing PRD Advisor Library OpenCode agent..."
    if cp "$PRD_ADVISOR_LIBRARY_TEMPLATE" "$OPENCODE_DIR/prd-advisor-library.md"; then
        success_msg "PRD Advisor Library OpenCode agent installed to: $OPENCODE_DIR/prd-advisor-library.md"
    else
        error_exit "Failed to install PRD Advisor Library OpenCode agent"
    fi
    
    # Install PRD Advisor UI OpenCode agent
    info_msg "Installing PRD Advisor UI OpenCode agent..."
    if cp "$PRD_ADVISOR_UI_TEMPLATE" "$OPENCODE_DIR/prd-advisor-ui.md"; then
        success_msg "PRD Advisor UI OpenCode agent installed to: $OPENCODE_DIR/prd-advisor-ui.md"
    else
        error_exit "Failed to install PRD Advisor UI OpenCode agent"
    fi
    
    # Verify installations
    info_msg "Verifying installations..."
    
    if [ -f "$OPENCODE_DIR/prd-creator.md" ]; then
        success_msg "OpenCode PRD agent verification: PASSED"
    else
        warning_msg "OpenCode PRD agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-researcher.md" ]; then
        success_msg "PRD Researcher OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Researcher OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-advisor-api.md" ]; then
        success_msg "PRD Advisor API OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Advisor API OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-advisor-cli.md" ]; then
        success_msg "PRD Advisor CLI OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Advisor CLI OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-advisor-data.md" ]; then
        success_msg "PRD Advisor Data OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Advisor Data OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-advisor-library.md" ]; then
        success_msg "PRD Advisor Library OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Advisor Library OpenCode agent verification: FAILED"
    fi
    
    if [ -f "$OPENCODE_DIR/prd-advisor-ui.md" ]; then
        success_msg "PRD Advisor UI OpenCode agent verification: PASSED"
    else
        warning_msg "PRD Advisor UI OpenCode agent verification: FAILED"
    fi
    
    info_msg "PRD agents installation completed successfully!"
    
    # Install Deepest-Thinking OpenCode agent
    info_msg "Installing Deepest-Thinking OpenCode agent..."
    if cp "$DEEPEST_OPENCODE_TEMPLATE" "$OPENCODE_DIR/deepest-thinking.md"; then
        success_msg "Deepest-Thinking OpenCode agent installed to: $OPENCODE_DIR/deepest-thinking.md"
    else
        error_exit "Failed to install Deepest-Thinking OpenCode agent"
    fi
    
    # Verify Deepest-Thinking installation
    info_msg "Verifying Deepest-Thinking installation..."
    
    if [ -f "$OPENCODE_DIR/deepest-thinking.md" ]; then
        success_msg "Deepest-Thinking OpenCode agent verification: PASSED"
    else
        warning_msg "Deepest-Thinking OpenCode agent verification: FAILED"
    fi
}

# Function to install Deepest-Thinking agents only
install_deepest_agents() {
    info_msg "Installing Deepest-Thinking agents in $SCOPE_DESCRIPTION..."
    
    # Check if template files exist
    if [ ! -f "$DEEPEST_OPENCODE_TEMPLATE" ]; then
        error_exit "Deepest-Thinking OpenCode template not found at: $DEEPEST_OPENCODE_TEMPLATE"
    fi
    
    # Create directories if they don't exist
    info_msg "Creating directories..."
    
    if [ ! -d "$OPENCODE_DIR" ]; then
        mkdir -p "$OPENCODE_DIR" || error_exit "Failed to create directory: $OPENCODE_DIR"
        success_msg "Created directory: $OPENCODE_DIR"
    else
        info_msg "Directory already exists: $OPENCODE_DIR"
    fi
    
    # Install Deepest-Thinking OpenCode agent
    info_msg "Installing Deepest-Thinking OpenCode agent..."
    if cp "$DEEPEST_OPENCODE_TEMPLATE" "$OPENCODE_DIR/deepest-thinking.md"; then
        success_msg "Deepest-Thinking OpenCode agent installed to: $OPENCODE_DIR/deepest-thinking.md"
    else
        error_exit "Failed to install Deepest-Thinking OpenCode agent"
    fi
    
    # Verify installation
    info_msg "Verifying Deepest-Thinking installation..."
    
    if [ -f "$OPENCODE_DIR/deepest-thinking.md" ]; then
        success_msg "Deepest-Thinking OpenCode agent verification: PASSED"
    else
        warning_msg "Deepest-Thinking OpenCode agent verification: FAILED"
    fi
    
    info_msg "Deepest-Thinking agent installation completed successfully!"
}

# Check if running as root (for global installations)
if [ "$GLOBAL_SCOPE" = true ] && [ "$(id -u)" -ne 0 ]; then
    warning_msg "Installing globally without root privileges. Some operations may fail."
fi

# Handle --all flag (install all agents)
if [ "$INSTALL_ALL" = true ]; then
    DEEPEST_ONLY=false
fi

# Check if Deepest-Thinking only installation
if [ "$DEEPEST_ONLY" = true ]; then
    install_deepest_agents
    exit 0
fi

# Run installation
install_agents