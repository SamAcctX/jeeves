# Jeeves Binary Scripts Directory

This directory contains essential bash scripts and Python tools for managing the Jeeves container environment and Ralph Loop workflow. These scripts provide automation for container lifecycle management, agent installation, skill dependency resolution, and Ralph Loop execution.

## Core Management Scripts

### `ralph-init.sh`
**Purpose**: Initialize Ralph project scaffolding in a current directory.
**Key Features**:
- Validates required tools (yq, jq, git)
- Detects project root
- Creates .ralph directory structure
- Copies templates (agents, skills, configs)
- Handles RULES.md creation
- Integrates with git
- Runs installation scripts (install-agents.sh, install-mcp-servers.sh, install-skill-deps.sh)

**Usage**:
```bash
ralph-init.sh                # Interactive setup
ralph-init.sh --force        # Force overwrite existing files
ralph-init.sh --rules        # Force RULES.md creation
ralph-init.sh --help         # Show help
```

### `ralph-loop.sh`
**Purpose**: Main Ralph Loop orchestration script for autonomous AI task execution.
**Key Features**:
- Supports OpenCode and Claude Code tools
- Configurable iteration limits
- Backoff delay with jitter
- Agent synchronization
- Git conflict detection
- Task signal parsing (TASK_COMPLETE, TASK_INCOMPLETE, TASK_FAILED, TASK_BLOCKED)
- Logging with timestamps

**Usage**:
```bash
ralph-loop.sh --tool opencode --max-iterations 100
ralph-loop.sh --tool claude --skip-sync --no-delay
ralph-loop.sh --help         # Show help
```

**Environment Variables**:
- `RALPH_TOOL`: Default AI tool (opencode/claude)
- `RALPH_MAX_ITERATIONS`: Max loop iterations (default: 100)
- `RALPH_BACKOFF_BASE`: Backoff delay base (default: 2)
- `RALPH_BACKOFF_MAX`: Backoff max delay (default: 60)

### `ralph-validate.sh`
**Purpose**: Sourceable validation utilities library for Ralph operations.
**Key Functions**:
- `validate_task_id`: Validates 4-digit task ID format (0001-9999)
- `validate_yaml`: Validates YAML syntax using yq or Python
- `validate_file_exists`: Checks if file exists
- `validate_dir_exists`: Checks if directory exists
- `validate_git_repo`: Confirms current directory is a git repository

### `ralph-paths.sh`
**Purpose**: Centralized path detection and expansion utilities.
**Key Functions**:
- `find_project_root`: Detects git repository root or falls back to current directory
- `find_ralph_dir`: Finds .ralph directory in current tree
- `find_task_dir`: Finds task directory given a task ID
- `find_agent_file`: Finds agent file in project or global locations
- `expand_path`: Expands tilde and environment variables in paths
- `expand_relative_path`: Converts relative paths to absolute

### `ralph-filter-output.sh`
**Purpose**: Filters OpenCode JSON output to show only essential information.
**Key Features**:
- Filter by text responses, tokens, tools, cost, signals
- Compact or detailed output formats
- Signal extraction (TASK_COMPLETE, etc.)
- Token statistics formatting
- Tool usage reporting

**Usage**:
```bash
cat output.json | ralph-filter-output.sh
ralph-filter-output.sh --compact --no-text output.json
ralph-filter-output.sh --help         # Show help
```

### `sync-agents.sh`
**Purpose**: Synchronize agent model configurations from agents.yaml to agent definition files.
**Key Features**:
- Multi-tool support (OpenCode/Claude)
- YAML frontmatter manipulation
- Backup and restore functionality
- Search path prioritization (project > user > global)
- Statistics tracking (updated/skipped/failed)

**Usage**:
```bash
sync-agents                              # Sync for OpenCode (default)
RALPH_TOOL=claude sync-agents           # Sync for Claude
sync-agents -t claude                   # Sync for Claude
sync-agents -c /path/to/agents.yaml     # Use custom config
sync-agents -s                          # Show parsed agents
```

## Installation Scripts

### `install-agents.sh`
**Purpose**: Install PRD agents for both Claude Code and OpenCode platforms.
**Key Features**:
- Supports project and global scopes
- Installs PRD Creator and Deepest-Thinking agents
- Option to install Deepest-Thinking only
- Directory creation and validation
- Template verification
- Installation paths:
  - Project scope: `/proj/.claude/agents/` and `/proj/.opencode/agents/`
  - Global scope: `~/.claude/agents/` and `~/.config/opencode/agents/`

**Usage**:
```bash
install-agents.sh                    # Install to project scope
install-agents.sh -g                 # Install to user scope
install-agents.sh -d                 # Install Deepest-Thinking agent only
install-agents.sh -a                 # Install all agents explicitly
```

### `install-mcp-servers.sh`
**Purpose**: Configures MCP (Model Context Protocol) servers for OpenCode and Claude Code.
**Key Features**:
- Pre-installs and configures MCP servers
- Supports project and global scope installations
- Configures 4 MCP servers:
  - sequentialthinking (@modelcontextprotocol/server-sequential-thinking)
  - fetch (python -m mcp_server_fetch)
  - searxng (mcp-searxng)
  - playwright (@playwright/mcp@latest)
- Handles SEARXNG_URL configuration
- Creates backups of existing config files
- Validates JSON configuration

**Usage**:
```bash
install-mcp-servers.sh              # Project scope installation
install-mcp-servers.sh --global     # Global scope installation
install-mcp-servers.sh --dry-run    # Preview changes
```

### `install-skill-deps.sh`
**Purpose**: Discovers skills, parses dependencies from SKILL.md files, and installs required packages.
**Key Features**:
- Docker-safe (never exits with non-zero status)
- Skill discovery from multiple search paths
- Dependency parsing using Python parser
- Package deduplication
- Installation support for APT, PIP, and NPM packages
- Special case handling for package name transformations
- Detailed reporting with statistics

**Usage**:
```bash
install-skill-deps.sh                      # Run with defaults
install-skill-deps.sh --verbose            # Enable verbose output
install-skill-deps.sh --dry-run            # Preview what would be installed
install-skill-deps.sh -v -d                # Verbose dry-run
```

### `install-skills.sh`
**Purpose**: Installs Agent Skills for both Claude Code and OpenCode platforms.
**Key Features**:
- Installs document creation skills (docx, pdf, xlsx, pptx, markitdown)
- Installs n8n automation skills (7 skills for workflow development)
- Supports project and global scopes
- Checks and installs system dependencies
- Handles Python and npm package installation
- Verifies skill installation

**Usage**:
```bash
install-skills.sh -d                       # Install document skills to project scope
install-skills.sh -n -g                    # Install n8n skills to user scope
install-skills.sh -a                       # Install all skills to project scope
install-skills.sh --doc-skills --n8n-skills # Install all skills to project scope
```

### `parse_skill_deps.py`
**Purpose**: Python script to parse SKILL.md files and extract dependencies.
**Key Features**:
- Discovers SKILL.md files from directories or single file
- Extracts YAML frontmatter
- Parses dependencies from:
  - Dependencies section with bullet points
  - Installation section with code blocks
  - Inline commands in comments or text
- Supports apt, pip, npm, brew, cargo, and gem package managers
- Formats output as JSON with statistics
- Handles special cases like pip extras and editable installs

**Usage**:
```bash
parse_skill_deps.py --skill-path ~/.claude/skills
parse_skill_deps.py --skill-path /path/to/SKILL.md --output deps.json
parse_skill_deps.py --skill-path ~/.config/opencode/skills --verbose
```

## Utility Scripts

### `apply-rules.sh`
**Purpose**: Applies RULES.md to project files by extracting and merging sections.
**Key Features**:
- Extracts sections from RULES.md files:
  - Code Patterns
  - Common Pitfalls
  - Standard Approaches
- Merges rules from multiple files
- Handles nested directory structures
- Prints merged rules in readable format

**Usage**:
```bash
apply-rules.sh "path/to/rules1.md path/to/rules2.md"
```

### `find-rules-files.sh`
**Purpose**: Locates RULES.md files in project structure.
**Key Features**:
- Traverses directory hierarchy from current directory
- Collects RULES.md files
- Stops at .ralph or .git directories
- Handles IGNORE_PARENT_RULES directive

**Usage**:
```bash
find_rules_files "$(pwd)"  # Find rules files starting from current directory
```

## Usage Instructions

### Running Scripts
All scripts support `--help` for usage information:
```bash
./script-name.sh --help
```

### Common Use Cases

#### Initialize a Ralph Project
```bash
cd /proj/my-project
ralph-init.sh
```

#### Start Ralph Loop
```bash
ralph-loop.sh --tool opencode --max-iterations 100
```

#### Install Agents Globally
```bash
install-agents.sh --global
```

#### Install MCP Servers
```bash
install-mcp-servers.sh --global
```

#### Install Skill Dependencies
```bash
install-skill-deps.sh --dry-run  # Preview
install-skill-deps.sh            # Install
```

## Configuration and Setup

### Script Requirements
All scripts require:
- Bash 4.0+
- Docker (for container management)
- yq (YAML processing)
- jq (JSON processing)
- Python 3.6+ (for parse_skill_deps.py)

### Environment Variables
Key environment variables used by scripts:
- `RALPH_TOOL`: Default AI tool (opencode or claude)
- `RALPH_MAX_ITERATIONS`: Max loop iterations (default: 100)
- `AGENTS_YAML`: Path to agents.yaml configuration
- `SEARXNG_URL`: URL for SearXNG web search MCP server

### Directory Structure
After installation, the scripts are available in:
- Container: `/usr/local/bin/` (accessible from any directory)
- Host: Not directly accessible (run via `./jeeves.ps1 shell` first)

## Error Handling
Scripts use standard error codes:
- `0`: Success
- `1`: General error
- `130`: Interrupted (Ctrl+C)

For debugging, use `--verbose` flag if available or set `RALPH_DEBUG=1`.
