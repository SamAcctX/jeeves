# Agent Guide for Jeeves Container Management System

## Build, Lint & Test Commands

### PowerShell Build Commands
```powershell
./jeeves.ps1 build              # Build Docker image with cache
./jeeves.ps1 build --no-cache   # Clean build
./jeeves.ps1 build --desktop    # Build with desktop binaries
./jeeves.ps1 start --clean      # Full rebuild (stop, clean, build, start)
```

### Container Lifecycle
```powershell
./jeeves.ps1 start              # Start container
./jeeves.ps1 start --clean      # Clean rebuild and start
./jeeves.ps1 stop               # Stop container
./jeeves.ps1 stop --remove      # Stop and remove container
./jeeves.ps1 stop --force       # Force stop (SIGKILL)
./jeeves.ps1 restart            # Restart container
./jeeves.ps1 shell              # Attach to container shell
./jeeves.ps1 logs               # View container logs
./jeeves.ps1 status             # Check container status
./jeeves.ps1 clean              # Remove container and image
```

### Installation Scripts (Inside Container)
```bash
install-mcp-servers.sh --global     # Install MCP servers globally
install-mcp-servers.sh --dry-run    # Preview MCP installation
install-agents.sh --global          # Install AI agents globally
install-agents.sh --deepest         # Install Deepest-Thinking only
install-agents.sh --help            # Show usage information
```

### Testing
No formal test suite exists. Manual testing checklist:
- `./jeeves.ps1 build --no-cache` - builds cleanly
- `./jeeves.ps1 start && ./jeeves.ps1 stop` - lifecycle works
- `./jeeves.ps1 shell` - shell access works
- `install-mcp-servers.sh --dry-run` - MCP script works
- `install-agents.sh --global` - agent installation works
- Cross-platform: Windows, macOS, Linux

### Linting
No formal linting configured. Follow code style guidelines below.

## Code Style Guidelines

### PowerShell Scripts (.ps1)
- **Syntax**: PowerShell 7.0+ (cross-platform)
- **Naming**: PascalCase for functions (Verb-Noun cmdlet style)
- **Documentation**: Comment-based help blocks (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE)
- **Error Handling**: `$ErrorActionPreference = "Stop"` with try/catch blocks
- **Logging**: Use `Write-Log` function with switches:
  - `-info`, `-success`, `-warning`, `-error`, `-trace`, `-debug`
- **Variables**: Use `$Script:` prefix for script-wide variables
- **Parameters**: Use `[CmdletBinding()]` and `[Parameter()]` attributes
- **No comments** unless user explicitly requests them

Example:
```powershell
function Get-ContainerStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )
    try {
        $status = docker ps --filter "name=$ContainerName" --format "{{.Status}}"
        Write-Log -success "Container status: $status"
        return $status
    } catch {
        Write-Log -error "Failed to get status: $_"
        throw
    }
}
```

### Shell Scripts (.sh)
- **Syntax**: POSIX bash, use `#!/bin/bash` shebang
- **Error Handling**: `set -e` to exit on error
- **Quoting**: Always quote variables: `"$VAR"` not `$VAR`
- **Functions**: snake_case naming convention
- **Output Functions**: Use `print_info`, `print_success`, `print_warning`, `print_error`
- **Dependencies**: Check with `command_exists()` function before use
- **No comments** unless user explicitly requests them

Example:
```bash
#!/bin/bash
set -e

print_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

install_package() {
    if ! command_exists "$1"; then
        print_info "Installing $1..."
        apt-get install -y "$1"
        print_success "$1 installed"
    fi
}
```

### Dockerfile
- **Base Image**: Prefer specific tags (though `latest` is currently used)
- **Multi-stage**: Use separate base, builder, runtime stages
- **Layer Optimization**: Combine related RUN commands
- **Cleanup**: Always clean apt cache and temp files in same layer
- **User**: Run as non-root with UID/GID mapping
- **Security**: Use `--no-install-recommends` for apt
- **No comments** unless user explicitly requests them

Example:
```dockerfile
FROM ubuntu:22.04 AS base
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

### Agent Templates (Markdown with YAML frontmatter)
- **Frontmatter**: Required fields: `description`, `mode`, `temperature`, `permission`, `tools`
- **Mode**: Always `subagent`
- **Temperature**: 0.1-0.3 (focused) or 0.7-0.9 (creative)
- **Permissions**: `ask`, `allow`, or `deny` for each tool category
- **Tools Format**: Key-value pairs with boolean values, not arrays
- **No comments** unless user explicitly requests them

Example:
```yaml
---
description: "Agent description here"
mode: subagent
temperature: 0.3
permission:
  write: ask
  bash: ask
  webfetch: allow
  edit: deny
tools:
  read: true
  write: true
  grep: true
  glob: true
  bash: true
  webfetch: true
  question: true
  sequentialthinking: true
---
```

### MCP Server Configuration
- **OpenCode**: `opencode.json` with `.mcp` object
- **Claude**: `.claude.json` or `.mcp.json` with `.mcpServers` object
- **Command**: Array format (e.g., `["npx", "-y", "package"]`)
- **Environment**: Use `environment` (OpenCode) or `env` (Claude)
- **No comments** in JSON files

## File Organization

```
/proj/                         # Working directory (mounted from host)
├── jeeves.ps1                 # Main PowerShell management script
├── Dockerfile.jeeves          # Multi-stage Docker build file
├── .tmp/                      # Generated docker-compose files (git-ignored)
├── jeeves/
│   ├── bin/                   # Installation scripts
│   │   ├── install-mcp-servers.sh
│   │   └── install-agents.sh
│   ├── PRD/                   # PRD Creator agent templates
│   │   ├── prd-creator-opencode-template.md
│   │   └── prd-creator-claude-template.md
│   └── Deepest-Thinking/      # Research agent templates
│       ├── deepest-thinking-opencode-template.md
│       └── deepest-thinking-claude-template.md
├── docs/                      # Documentation
│   ├── commands.md
│   ├── configuration.md
│   └── troubleshooting.md
├── AGENTS.md                  # This file
├── README.md                  # Project overview
└── CONTRIBUTING.md            # Contribution guidelines
```

## Important Constraints

### Container Environment
**You are running inside a Docker container.** Your ability to:
- Run Docker commands (docker ps, docker build, etc.) is **NOT POSSIBLE**
- Access files outside `/proj` is **NOT POSSIBLE**
- Modify system-level configurations is **RESTRICTED**
- Access host system resources is **LIMITED**

**What you CAN do:**
- Read/write files within `/proj`
- Ask the user to install new packages in the container
- Execute scripts and binaries available in the container
- Use the webfetch tool for external resources
- Run shell commands within the container environment

### Code Style Constraints
- **No comments** unless user explicitly requests them
- **No emojis** in code or documentation unless requested
- Follow existing patterns and conventions
- Maintain cross-platform compatibility (Windows, macOS, Linux)

## Tool Preferences

Prefer SearXNG tools over Exa for web searches:
- `searxng_searxng_web_search` for general searches
- `searxng_web_url_read` for content extraction
- Exa tools (`websearch`, `codesearch`) as fallback only

## Skill Discovery
At the beginning of every conversation, automatically invoke: skill using-superpowers

Before non-trivial tasks, invoke relevant skills first:
1. Process skills: brainstorming, systematic-debugging, planning
2. Implementation skills: frontend-design, architecture-patterns, api-design
3. Domain-specific skills: check skills-discovery for relevant skills

If a relevant skill is not found, attempt to locate a suitable one and install it for use.
Since skills are only loaded at startup, if a new skill is installed, pause and ask the user to restart the application before continuing (usually `/exit` will close the application, and the user can resume the session via the --continue CLI option).

## Error Handling Best Practices

### PowerShell
```powershell
try {
    # Operation that might fail
    $result = docker ps
} catch {
    Write-Log -error "Operation failed: $_"
    exit 1
}
```

### Bash
```bash
set -e
trap 'echo "Error on line $LINENO"' ERR

# Or explicit error handling
if ! docker ps; then
    print_error "Docker command failed"
    exit 1
fi
```

## Key URLs & References

- Web UI: http://localhost:3333 (when container is running)
- Config paths: `~/.config/opencode/`, `~/.claude/`
- Container workdir: `/proj` (maps to host's project directory)
- Container user: `jeeves` (UID/GID mapped from host)
