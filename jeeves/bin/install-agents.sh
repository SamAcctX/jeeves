#!/bin/bash

set -e

GLOBAL_SCOPE=false
DEEPEST_ONLY=false
INSTALL_ALL=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install PRD and Deepest-Thinking agents for OpenCode and Claude platforms."
    echo ""
    echo "OPTIONS:"
    echo "  -g, --global    Install agents globally (user home directory)"
    echo "  -d, --deepest   Install Deepest-Thinking agent only"
    echo "  -a, --all       Install all agents (PRD Creator and Deepest-Thinking)"
    echo "  -h, --help      Display this help message"
    echo ""
    echo "SCOPE:"
    echo "  By default: Project scope (/proj/.opencode/ and /proj/.claude/)"
    echo "  With --global: User scope (~/.opencode/ and ~/.claude/)"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                    # Install to project scope"
    echo "  $0 -g                 # Install to user scope"
    echo "  $0 -d                 # Install Deepest-Thinking agent only"
    echo "  $0 -a                 # Install all agents explicitly"
    echo ""
}

error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

success_msg() {
    echo "✓ $1"
}

info_msg() {
    echo "ℹ  $1"
}

warning_msg() {
    echo "⚠  $1" >&2
}

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

if [ "$GLOBAL_SCOPE" = true ]; then
    OPENCODE_DIR="$HOME/.opencode/agents"
    CLAUDE_DIR="$HOME/.claude/agents"
    SCOPE_DESCRIPTION="global (user home directory)"
else
    OPENCODE_DIR="/proj/.opencode/agents"
    CLAUDE_DIR="/proj/.claude/agents"
    SCOPE_DESCRIPTION="project (/proj)"
fi

TEMPLATE_BASE="/opt/jeeves"

declare -A OPENCODE_TEMPLATES=(
    ["prd-creator"]="$TEMPLATE_BASE/PRD/prd-creator-opencode-template.md"
    ["prd-researcher"]="$TEMPLATE_BASE/PRD/prd-researcher-opencode-template.md"
    ["prd-advisor-api"]="$TEMPLATE_BASE/PRD/prd-advisor-api-opencode-template.md"
    ["prd-advisor-cli"]="$TEMPLATE_BASE/PRD/prd-advisor-cli-opencode-template.md"
    ["prd-advisor-data"]="$TEMPLATE_BASE/PRD/prd-advisor-data-opencode-template.md"
    ["prd-advisor-library"]="$TEMPLATE_BASE/PRD/prd-advisor-library-opencode-template.md"
    ["prd-advisor-ui"]="$TEMPLATE_BASE/PRD/prd-advisor-ui-opencode-template.md"
    ["deepest-thinking"]="$TEMPLATE_BASE/Deepest-Thinking/deepest-thinking-opencode-template.md"
)

declare -A CLAUDE_TEMPLATES=(
    ["prd-creator"]="$TEMPLATE_BASE/PRD/prd-creator-claude-template.md"
    ["prd-researcher"]="$TEMPLATE_BASE/PRD/prd-researcher-claude-template.md"
    ["prd-advisor-api"]="$TEMPLATE_BASE/PRD/prd-advisor-api-claude-template.md"
    ["prd-advisor-cli"]="$TEMPLATE_BASE/PRD/prd-advisor-cli-claude-template.md"
    ["prd-advisor-data"]="$TEMPLATE_BASE/PRD/prd-advisor-data-claude-template.md"
    ["prd-advisor-library"]="$TEMPLATE_BASE/PRD/prd-advisor-library-claude-template.md"
    ["prd-advisor-ui"]="$TEMPLATE_BASE/PRD/prd-advisor-ui-claude-template.md"
    ["deepest-thinking"]="$TEMPLATE_BASE/Deepest-Thinking/deepest-thinking-claude-template.md"
)

PRD_AGENTS=("prd-creator" "prd-researcher" "prd-advisor-api" "prd-advisor-cli" "prd-advisor-data" "prd-advisor-library" "prd-advisor-ui")
DEEPEST_AGENTS=("deepest-thinking")
ALL_AGENTS=("${PRD_AGENTS[@]}" "${DEEPEST_AGENTS[@]}")

ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
        success_msg "Created directory: $dir"
    fi
}

install_agent() {
    local name="$1"
    local template="$2"
    local dest_dir="$3"
    local platform="$4"

    if [ ! -f "$template" ]; then
        warning_msg "$platform template not found for $name: $template"
        return 1
    fi

    if cp "$template" "$dest_dir/${name}.md"; then
        success_msg "$platform $name installed to: $dest_dir/${name}.md"
    else
        error_exit "Failed to install $platform $name agent"
    fi
}

verify_agent() {
    local name="$1"
    local dest_dir="$2"
    local platform="$3"

    if [ -f "$dest_dir/${name}.md" ]; then
        success_msg "$platform $name verification: PASSED"
    else
        warning_msg "$platform $name verification: FAILED"
    fi
}

install_agent_set() {
    local -n agent_list=$1
    info_msg "Installing agents in $SCOPE_DESCRIPTION..."

    ensure_dir "$OPENCODE_DIR"
    ensure_dir "$CLAUDE_DIR"

    for name in "${agent_list[@]}"; do
        info_msg "Installing $name..."
        install_agent "$name" "${OPENCODE_TEMPLATES[$name]}" "$OPENCODE_DIR" "OpenCode"
        install_agent "$name" "${CLAUDE_TEMPLATES[$name]}" "$CLAUDE_DIR" "Claude"
    done

    info_msg "Verifying installations..."
    for name in "${agent_list[@]}"; do
        verify_agent "$name" "$OPENCODE_DIR" "OpenCode"
        verify_agent "$name" "$CLAUDE_DIR" "Claude"
    done

    info_msg "Agent installation completed successfully!"
}

if [ "$GLOBAL_SCOPE" = true ] && [ "$(id -u)" -ne 0 ]; then
    warning_msg "Installing globally without root privileges. Some operations may fail."
fi

if [ "$INSTALL_ALL" = true ]; then
    DEEPEST_ONLY=false
fi

if [ "$DEEPEST_ONLY" = true ]; then
    install_agent_set DEEPEST_AGENTS
    exit 0
fi

install_agent_set ALL_AGENTS
