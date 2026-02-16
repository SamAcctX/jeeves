# Agent Guide for Jeeves Shell Scripts

## Overview
This directory contains bash installation and utility scripts for the Jeeves container management system.

## Build/Test Commands

### Testing Individual Scripts
```bash
# Test script syntax
bash -n install-mcp-servers.sh
bash -n install-agents.sh
bash -n install-skill-deps.sh
bash -n install-skills.sh

# Run with dry-run to test logic without side effects
./install-mcp-servers.sh --dry-run
./install-agents.sh --global --dry-run
./install-skill-deps.sh --dry-run

# Test with verbose output
./install-skill-deps.sh --verbose
```

### Manual Testing Checklist
- Scripts exit with code 0 on success
- Scripts exit with code 1 on error (with `set -e`)
- `--help` flag displays usage information
- `--dry-run` shows what would happen without making changes
- Color output works correctly (info=blue, success=green, error=red, warning=yellow)

## Code Style Guidelines

### Shebang and Error Handling
```bash
#!/bin/bash
set -e  # Exit on error
trap 'echo "Error on line $LINENO"' ERR  # Optional: show line number on error
```

### Function Naming (snake_case)
```bash
# Good
install_mcp_servers() { }
parse_config_file() { }
command_exists() { }

# Bad
InstallMcpServers() { }  # PascalCase is for PowerShell
installMcpServers() { }  # camelCase not used
```

### Variable Quoting (CRITICAL)
```bash
# Always quote variables
"$VARIABLE"          # Good
$VARIABLE            # Bad - word splitting issues

# Quote command substitutions
output="$(command)"  # Good
output=$(command)    # Risky
```

### Output Functions (Required Pattern)
```bash
print_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }
```

### Dependency Checking
```bash
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Usage
if ! command_exists "docker"; then
    print_error "Docker is not installed"
    exit 1
fi
```

### Associative Arrays (Bash 4+)
```bash
declare -A MCP_SERVERS=(
    ["sequentialthinking"]="@modelcontextprotocol/server-sequential-thinking"
    ["fetch"]="python -m mcp_server_fetch"
)
```

### Argument Parsing
```bash
# Standard pattern
GLOBAL_SCOPE=false

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
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done
```

## Script-Specific Details

### install-mcp-servers.sh
- Configures MCP servers for both OpenCode and Claude Code
- Supports `--global` and `--dry-run` flags
- Modifies JSON files (opencode.json, .mcp.json, ~/.claude.json)
- Prompts for SEARXNG_URL if not set

### install-agents.sh
- Installs agent templates from /opt/jeeves/ to user directories
- Supports `--global` and `--deepest` flags
- Creates directories if they don't exist
- Templates: PRD Creator, Deepest-Thinking

### install-skill-deps.sh
- Parses SKILL.md files for dependencies
- Supports `--dry-run` and `--verbose` flags
- Installs apt, pip, and npm packages
- Uses parse_skill_deps.py for parsing

### parse_skill_deps.py
- Python 3 script for parsing SKILL.md dependencies
- Accepts `--skill-path` (file or directory)
- Outputs JSON with categorized dependencies
- Called by install-skill-deps.sh

## Common Patterns

### File Path Handling
```bash
# Use $HOME for user directories
CONFIG_DIR="$HOME/.config/opencode"

# Use /proj for project directory (mounted from host)
PROJECT_DIR="/proj"
```

### JSON File Manipulation
```bash
# Use jq if available, otherwise use Python
if command_exists jq; then
    jq '.key = "value"' file.json > tmp.json && mv tmp.json file.json
else
    python3 -c "import json; data=json.load(open('file.json')); data['key']='value'; json.dump(data, open('file.json', 'w'), indent=2)"
fi
```

### Backup Before Modification
```bash
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}
```

## Error Handling Best Practices

```bash
# Exit on error
set -e

# Check if command succeeded
if ! command; then
    print_error "Command failed"
    exit 1
fi

# Or with explicit status check
command
if [[ $? -ne 0 ]]; then
    print_error "Command failed"
    exit 1
fi

# Pipefail for pipelines
set -eo pipefail
command1 | command2 | command3  # Fails if any command fails
```

## No Comments Policy
Do not add comments to code unless the user explicitly requests them. Self-documenting code with clear function names is preferred.
