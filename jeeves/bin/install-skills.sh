#!/bin/bash

# Skills Installation Script
# Installs Agent Skills for both Claude Code and OpenCode platforms

set -e  # Exit on error

# Default values
GLOBAL_SCOPE=false
DOC_SKILLS=false
N8N_SKILLS=false

# Function to display usage instructions
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install Agent Skills for Claude Code and OpenCode platforms."
    echo ""
    echo "OPTIONS:"
    echo "  --doc-skills    Install document creation skills (docx, pdf, xlsx, pptx, markitdown)"
    echo "  --n8n-skills    Install n8n automation skills (7 skills for workflow development)"
    echo "  --global        Install skills globally (user scope instead of project scope)"
    echo "  --help          Display this help message"
    echo ""
    echo "SCOPE:"
    echo "  By default: Project scope (requires .claude/ and .opencode/ directories)"
    echo "  With --global: User scope (installs to user home directory)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --doc-skills              # Install document skills to project scope"
    echo "  $0 --n8n-skills --global     # Install n8n skills to user scope"
    echo "  $0 --doc-skills --n8n-skills # Install all skills to project scope"
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and install system dependencies
check_dependencies() {
    local needs_npm=false
    local needs_python=false
    local needs_system_deps=false
    
    info_msg "Checking system dependencies..."
    
    # Check for Node.js/npm (required for skills-installer)
    if ! command_exists npx; then
        needs_npm=true
    fi
    
    # Check for Python (required for document skills)
    if [ "$DOC_SKILLS" = true ]; then
        if ! command_exists python3; then
            needs_python=true
        fi
        
        # Check for system packages needed by document skills
        if ! command_exists pandoc || ! command_exists soffice || ! command_exists pdftoppm; then
            needs_system_deps=true
        fi
    fi
    
    # Display dependency requirements
    if [ "$needs_npm" = true ] || [ "$needs_python" = true ]; then
        echo ""
        echo "=========================================="
        echo "DEPENDENCY INSTALLATION REQUIRED"
        echo "=========================================="
        echo ""
        
        if [ "$needs_npm" = true ]; then
            echo "⚠️  Node.js/npm is required but not installed."
            echo "   Please install Node.js (v16 or higher):"
            echo "   - Ubuntu/Debian: sudo apt install nodejs npm"
            echo "   - macOS: brew install node"
            echo "   - Windows: Download from https://nodejs.org"
            echo ""
        fi
        
        if [ "$needs_python" = true ]; then
            echo "⚠️  Python 3 is required for document skills but not installed."
            echo "   Please install Python 3:"
            echo "   - Ubuntu/Debian: sudo apt install python3 python3-pip"
            echo "   - macOS: brew install python3"
            echo "   - Windows: Download from https://python.org"
            echo ""
        fi
        
        echo "Please install the required dependencies and run this script again."
        echo ""
        exit 1
    fi
    
    # Install system packages for document skills if needed
    if [ "$DOC_SKILLS" = true ] && [ "$needs_system_deps" = true ]; then
        info_msg "Installing system packages for document skills..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y pandoc libreoffice poppler-utils qpdf || warning_msg "Failed to install some system packages"
        elif command_exists brew; then
            brew install pandoc libreoffice poppler qpdf || warning_msg "Failed to install some system packages"
        else
            warning_msg "Could not detect package manager. Please install manually."
        fi
    fi
    
    success_msg "Core system dependencies satisfied"
}

# Function to install Python dependencies for document skills
install_doc_python_deps() {
    if [ "$DOC_SKILLS" = false ]; then
        return
    fi
    
    info_msg "Installing Python packages for document skills..."
    
    # Check if we're using a virtual environment (even if not "activated")
    local pip_user_flag="--user"
    local pip3_path
    pip3_path=$(which pip3)
    if [[ "$pip3_path" != "/usr/bin/pip3" ]] && [[ "$pip3_path" != "/bin/pip3" ]]; then
        info_msg "Non-system pip detected at $pip3_path - installing without --user flag"
        pip_user_flag=""
    fi
    
    pip3 install $pip_user_flag defusedxml pypdf pdfplumber reportlab pandas openpyxl || warning_msg "Failed to install some Python packages"
    pip3 install $pip_user_flag "markitdown[all]" || warning_msg "Failed to install markitdown"
    
    success_msg "Python packages installed"
}

# Function to install npm dependencies for document skills
install_doc_npm_deps() {
    if [ "$DOC_SKILLS" = false ]; then
        return
    fi
    
    info_msg "Installing npm packages for document skills..."
    
    # Check if packages are already installed before trying to install
    if ! npm list -g docx >/dev/null 2>&1; then
        sudo npm install -g docx || warning_msg "Failed to install docx npm package"
    else
        info_msg "docx already installed - skipping"
    fi
    
    if ! npm list -g pptxgenjs >/dev/null 2>&1; then
        sudo npm install -g pptxgenjs || warning_msg "Failed to install pptxgenjs"
    else
        info_msg "pptxgenjs already installed - skipping"
    fi
    
    if ! npm list -g playwright >/dev/null 2>&1; then
        sudo npm install -g playwright || warning_msg "Failed to install playwright"
    else
        info_msg "playwright already installed - skipping"
    fi
    
    if ! npm list -g sharp >/dev/null 2>&1; then
        sudo npm install -g sharp || warning_msg "Failed to install sharp"
    else
        info_msg "sharp already installed - skipping"
    fi
    
    success_msg "npm packages installation complete"
}

# Function to install document creation skills
install_doc_skills() {
    local scope_flag=""
    if [ "$GLOBAL_SCOPE" = true ]; then
        scope_flag="--global"
    fi
    
    info_msg "Installing document creation skills..."
    
    # Install document skills for both OpenCode and Claude
    npx skills-installer install @anthropics/skills/docx --client opencode $scope_flag || error_exit "Failed to install docx skill"
    success_msg "Installed: docx (OpenCode)"
    
    npx skills-installer install @anthropics/skills/pdf --client opencode $scope_flag || error_exit "Failed to install pdf skill"
    success_msg "Installed: pdf (OpenCode)"
    
    npx skills-installer install @anthropics/skills/xlsx --client opencode $scope_flag || error_exit "Failed to install xlsx skill"
    success_msg "Installed: xlsx (OpenCode)"
    
    npx skills-installer install @anthropics/skills/pptx --client opencode $scope_flag || error_exit "Failed to install pptx skill"
    success_msg "Installed: pptx (OpenCode)"
    
    npx skills-installer install @K-Dense-AI/claude-scientific-skills/markitdown --client opencode $scope_flag || error_exit "Failed to install markitdown skill"
    success_msg "Installed: markitdown (OpenCode)"
    
    # Install for Claude Code as well
    npx skills-installer install @anthropics/skills/docx --client claude-code $scope_flag || warning_msg "Failed to install docx skill for Claude Code"
    npx skills-installer install @anthropics/skills/pdf --client claude-code $scope_flag || warning_msg "Failed to install pdf skill for Claude Code"
    npx skills-installer install @anthropics/skills/xlsx --client claude-code $scope_flag || warning_msg "Failed to install xlsx skill for Claude Code"
    npx skills-installer install @anthropics/skills/pptx --client claude-code $scope_flag || warning_msg "Failed to install pptx skill for Claude Code"
    npx skills-installer install @K-Dense-AI/claude-scientific-skills/markitdown --client claude-code $scope_flag || warning_msg "Failed to install markitdown skill for Claude Code"
    
    success_msg "Document creation skills installation completed!"
}

# Function to install n8n skills
install_n8n_skills() {
    local scope_flag=""
    if [ "$GLOBAL_SCOPE" = true ]; then
        scope_flag="--global"
    fi
    
    info_msg "Installing n8n automation skills..."
    
    # Install all 7 n8n skills for OpenCode
    npx skills-installer install @czlonkowski/n8n-skills/n8n-workflow-patterns --client opencode $scope_flag || error_exit "Failed to install n8n-workflow-patterns"
    success_msg "Installed: n8n-workflow-patterns (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-mcp-tools-expert --client opencode $scope_flag || error_exit "Failed to install n8n-mcp-tools-expert"
    success_msg "Installed: n8n-mcp-tools-expert (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-expression-syntax --client opencode $scope_flag || error_exit "Failed to install n8n-expression-syntax"
    success_msg "Installed: n8n-expression-syntax (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-node-configuration --client opencode $scope_flag || error_exit "Failed to install n8n-node-configuration"
    success_msg "Installed: n8n-node-configuration (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-code-javascript --client opencode $scope_flag || error_exit "Failed to install n8n-code-javascript"
    success_msg "Installed: n8n-code-javascript (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-validation-expert --client opencode $scope_flag || error_exit "Failed to install n8n-validation-expert"
    success_msg "Installed: n8n-validation-expert (OpenCode)"
    
    npx skills-installer install @czlonkowski/n8n-skills/n8n-code-python --client opencode $scope_flag || error_exit "Failed to install n8n-code-python"
    success_msg "Installed: n8n-code-python (OpenCode)"
    
    # Install for Claude Code as well
    npx skills-installer install @czlonkowski/n8n-skills/n8n-workflow-patterns --client claude-code $scope_flag || warning_msg "Failed to install n8n-workflow-patterns for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-mcp-tools-expert --client claude-code $scope_flag || warning_msg "Failed to install n8n-mcp-tools-expert for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-expression-syntax --client claude-code $scope_flag || warning_msg "Failed to install n8n-expression-syntax for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-node-configuration --client claude-code $scope_flag || warning_msg "Failed to install n8n-node-configuration for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-code-javascript --client claude-code $scope_flag || warning_msg "Failed to install n8n-code-javascript for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-validation-expert --client claude-code $scope_flag || warning_msg "Failed to install n8n-validation-expert for Claude Code"
    npx skills-installer install @czlonkowski/n8n-skills/n8n-code-python --client claude-code $scope_flag || warning_msg "Failed to install n8n-code-python for Claude Code"
    
    success_msg "n8n automation skills installation completed!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --doc-skills)
            DOC_SKILLS=true
            shift
            ;;
        --n8n-skills)
            N8N_SKILLS=true
            shift
            ;;
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

# Validate that at least one skill set is selected
if [ "$DOC_SKILLS" = false ] && [ "$N8N_SKILLS" = false ]; then
    echo "ERROR: No skill set specified." >&2
    echo ""
    usage
    exit 1
fi

# Check system dependencies
check_dependencies

# Install additional dependencies for document skills
install_doc_python_deps
install_doc_npm_deps

# Determine scope description
if [ "$GLOBAL_SCOPE" = true ]; then
    SCOPE_DESCRIPTION="global (user home directory)"
else
    SCOPE_DESCRIPTION="project scope"
fi

# Main installation
info_msg "Installing skills in $SCOPE_DESCRIPTION..."

if [ "$DOC_SKILLS" = true ]; then
    install_doc_skills
fi

if [ "$N8N_SKILLS" = true ]; then
    install_n8n_skills
fi

echo ""
echo "=========================================="
echo "INSTALLATION COMPLETE"
echo "=========================================="
echo ""
success_msg "All requested skills have been installed successfully!"
echo ""
echo "IMPORTANT: You must restart your AI assistant for the"
echo "           newly installed skills to take effect."
echo ""
echo "  - OpenCode: Use /exit to close, then restart with --continue"
echo "  - Claude Code: Restart the application"
echo ""
