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
./install-agents.sh --global
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
- Installs 5 MCP servers: sequentialthinking, fetch, crawl4ai, searxng, playwright

### install-agents.sh
- Installs PRD and Deepest-Thinking agents to both OpenCode and Claude platforms
- Supports `--global`, `--deepest`, and `--all` flags
- Creates directories if they don't exist
- Templates: PRD Creator, PRD Researcher, PRD Advisors (5), Deepest-Thinking
- Installation paths: Project scope (/proj/.opencode/ and /proj/.claude/), Global scope (~/.opencode/ and ~/.claude/)

### install-skill-deps.sh
- Discovers skills, parses dependencies from SKILL.md files, and installs required packages
- Docker-safe (never exits with non-zero status)
- Supports `--dry-run` and `--verbose` flags
- Installs apt, pip, and npm packages
- Uses parse_skill_deps.py for parsing
- Handles package name transformations and deduplication

### parse_skill_deps.py
- Python 3 script for parsing SKILL.md dependencies
- Accepts `--skill-path` (file or directory) and `--output` (JSON file path)
- Outputs JSON with categorized dependencies (apt, pip, npm, brew, cargo, gem)
- Handles special cases like pip extras and editable installs
- Called by install-skill-deps.sh

### install-skills.sh
- Installs Agent Skills for both Claude Code and OpenCode platforms
- Supports `--doc-skills`, `--n8n-skills`, `--all`, and `--global` flags
- Installs document creation skills (docx, pdf, xlsx, pptx, markitdown)
- Installs n8n automation skills (7 skills for workflow development)
- Handles system and package dependencies

### sync-agents.sh
- Synchronizes agent model configurations from agents.yaml to agent files
- Syncs both OpenCode and Claude platforms by default; use `--tool` to target one
- Uses yq for proper YAML parsing and manipulation
- Supports `--tool` (opencode/claude), `--config`, `--show`, and `--dry-run` flags
- Detects platform from file path and applies the correct model per-platform
- Handles search path prioritization (project > user > global)

### apply-rules.sh
- Applies RULES.md to project files by extracting and merging sections
- Extracts sections: Code Patterns, Common Pitfalls, Standard Approaches
- Handles nested directory structures
- Uses find-rules-files.sh to locate rule files

### find-rules-files.sh
- Locates RULES.md files in project structure
- Traverses directory hierarchy from current directory
- Collects RULES.md files
- Stops at .ralph or .git directories
- Handles IGNORE_PARENT_RULES directive

### ralph-init.sh
- Initializes Ralph project scaffolding in a current directory
- Validates required tools (yq, jq, git)
- Detects project root
- Creates .ralph directory structure
- Copies templates (agents, skills, configs)
- Handles RULES.md creation
- Integrates with git
- Runs installation scripts (install-agents.sh, install-mcp-servers.sh, install-skill-deps.sh)
- Supports `--force` and `--rules` flags

### ralph-loop.sh
- Main Ralph Loop orchestration script for autonomous AI task execution
- Supports OpenCode and Claude Code tools
- Configurable iteration limits
- Backoff delay with jitter
- Agent synchronization
- Git conflict detection
- Task signal parsing (TASK_COMPLETE, TASK_INCOMPLETE, TASK_FAILED, TASK_BLOCKED)
- Logging with timestamps
- Supports `--tool`, `--max-iterations`, `--skip-sync`, `--no-delay`, `--dry-run`, and `--verbose` flags

### ralph-peek.sh
- Monitors active AI processing sessions during Ralph Loop execution
- Companion tool to ralph-loop.sh for real-time monitoring
- Finds the newest OpenCode session and attaches interactively or prints its web URL
- Dependencies: opencode, jq
- Supports `-t`/`--tui` (attach via TUI, default) and `-w`/`--web` (print Web UI URL) flags
- Testing: `ralph-peek.sh --web` (prints URL without attaching, safe for non-interactive use)

### ralph-paths.sh
- Centralized path detection and expansion utilities
- Key functions: find_project_root, find_ralph_dir, find_task_dir, find_agent_file, expand_path, expand_relative_path
- Used by other Ralph scripts

### ralph-filter-output.sh
- Filters OpenCode JSON output to show only essential information
- Filter by text responses, tokens, tools, cost, signals
- Compact or detailed output formats
- Signal extraction (TASK_COMPLETE, etc.)
- Token statistics formatting
- Tool usage reporting
- Supports `--text`, `--no-text`, `--tokens`, `--no-tokens`, `--tools`, `--no-tools`, `--cost`, `--no-cost`, `--signals`, `--no-signals`, and `--compact` flags

### ralph-validate.sh
- Sourceable validation utilities library for Ralph operations
- Key functions: validate_task_id, validate_yaml, validate_file_exists, validate_dir_exists, validate_git_repo

### fetch-opencode-models.sh
- Fetches free models from OpenCode Zen API
- Assigns models to agents by tier (complex reasoning, coding, general-purpose)
- Supports `--free`, `--output`, `--dry-run`, `--list`, `--model`, and `--include` flags
- Reads from agents.yaml template, writes to project agents.yaml

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
