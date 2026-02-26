# Jeeves Binary Scripts Directory

This directory contains essential bash scripts for managing the Jeeves container environment and Ralph Loop workflow.

## Purpose

The scripts in this directory provide:
- Container lifecycle management
- Agent installation and configuration
- Ralph Loop initialization and execution
- Skill dependency management
- MCP server configuration

## Key Files and Their Functions

### Core Management Scripts

| Script | Purpose |
|--------|---------|
| `ralph-init.sh` | Initialize Ralph Loop scaffolding in a project |
| `ralph-loop.sh` | Main Ralph Loop orchestration script |
| `ralph-validate.sh` | Validate Ralph configuration files |
| `ralph-paths.sh` | Centralized path definitions for Ralph |
| `ralph-filter-output.sh` | Filter and parse Ralph Loop output |
| `sync-agents.sh` | Synchronize agent model configurations |

### Installation Scripts

| Script | Purpose |
|--------|---------|
| `install-agents.sh` | Install PRD Creator and Deepest-Thinking agent templates |
| `install-mcp-servers.sh` | Configure MCP servers for OpenCode and Claude Code |
| `install-skills.sh` | Install Ralph skills from templates |
| `install-skill-deps.sh` | Install dependencies for Ralph skills |
| `parse_skill_deps.py` | Python script to parse SKILL.md dependencies |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `apply-rules.sh` | Apply RULES.md to project files |
| `find-rules-files.sh` | Locate RULES.md files in project structure |

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

## Directory Structure

After installation, the scripts are available in:
- Container: `/usr/local/bin/` (accessible from any directory)
- Host: Not directly accessible (run via `./jeeves.ps1 shell` first)

## Error Handling

Scripts use standard error codes:
- `0`: Success
- `1`: General error
- `130`: Interrupted (Ctrl+C)

For debugging, use `--verbose` flag if available or set `RALPH_DEBUG=1`.
