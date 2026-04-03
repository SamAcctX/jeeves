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
./jeeves.ps1 start              # Start container (aliases: up)
./jeeves.ps1 start --clean      # Clean rebuild and start
./jeeves.ps1 start --dind       # Start with Docker-in-Docker
./jeeves.ps1 start --port 4444  # Start on specific port
./jeeves.ps1 stop               # Stop container (aliases: down)
./jeeves.ps1 stop --remove      # Stop and remove container
./jeeves.ps1 stop --force       # Force stop (SIGKILL)
./jeeves.ps1 restart            # Restart container
./jeeves.ps1 rm                 # Remove container (stops if running)
./jeeves.ps1 shell              # Attach to container shell (aliases: attach, sh)
./jeeves.ps1 shell --zsh        # Attach with zsh instead of bash
./jeeves.ps1 shell --new        # Stop/remove existing container first
./jeeves.ps1 shell --raw        # Disable tmux auto-attach
./jeeves.ps1 logs               # View container logs
./jeeves.ps1 status             # Check container status (aliases: st)
./jeeves.ps1 status --all       # Show all jeeves instances
./jeeves.ps1 list               # List all running instances (aliases: ls, ps)
./jeeves.ps1 clean              # Remove container (aliases: none)
./jeeves.ps1 clean --image      # Remove container and image
./jeeves.ps1 clean --all        # Remove ALL jeeves containers
./jeeves.ps1 clean --force      # Force image removal even if other containers exist
./jeeves.ps1 help               # Show help (aliases: h, ?)
```

Running `./jeeves.ps1` without arguments displays an interactive menu.

### Installation Scripts (Inside Container)
```bash
install-mcp-servers.sh --global     # Install MCP servers globally
install-mcp-servers.sh --dry-run    # Preview MCP installation
install-agents.sh --global          # Install PRD agents to OpenCode and Claude
install-agents.sh --deepest         # Install Deepest-Thinking only
install-agents.sh --help            # Show usage information
install-skills.sh --all             # Install all agent skills
fetch-opencode-models.sh --free     # Fetch free models for agents.yaml
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
function Write-Log {
    param(
        [string]$message,
        [switch]$info,
        [switch]$trace,
        [switch]$error,
        [switch]$warning,
        [switch]$success,
        [switch]$debug
    )
    $timestamp = ((Get-Date -Format "MM/dd/yyyy HH:mm:ss.fff").toString() + ": ")
    
    $foregroundColor = $null
    if ($error) {
        $foregroundColor = "Red"
    } elseif ($warning) {
        $foregroundColor = "Yellow"
    } elseif ($success) {
        $foregroundColor = "Green"
    } elseif ($info) {
        $foregroundColor = "White"
    } elseif ($trace) {
        $foregroundColor = "Gray"
    } elseif ($debug) {
        $foregroundColor = "Cyan"
    }
    
    Write-Host -ForegroundColor $foregroundColor ($timestamp + $message)
}

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
- **Base Image**: `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04` (pinned CUDA tag)
- **Multi-stage**: Use separate base, builder, runtime stages
- **Layer Optimization**: Combine related RUN commands
- **Cleanup**: Always clean apt cache and temp files in same layer
- **User**: Run as non-root with UID/GID mapping
- **Security**: Use `--no-install-recommends` for apt
- **No comments** unless user explicitly requests them

Example:
```dockerfile
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04 AS base
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

### Agent Templates (Markdown with YAML frontmatter)
- **Frontmatter**: Required fields: `name`, `description`, `mode`, `model`, `permission`, `tools`
- **Mode**: `subagent` (most agents) or `all` (manager, decomposer) for OpenCode; omitted for Claude
- **Temperature**: 0.1-0.3 (focused) or 0.7-0.9 (creative)
- **Permissions**: `ask`, `allow`, or `deny` for each tool category
- **Tools Format**: Key-value booleans (OpenCode) or comma-separated string (Claude)
- **No comments** unless user explicitly requests them

### MCP Server Configuration
- **OpenCode**: `opencode.json` with `.mcp` object, `"type": "local"` required, `environment` key, `command` as array
- **Claude**: `.claude.json` or `.mcp.json` with `.mcpServers` object, `env` key, `command` as string with separate `args` array
- **No comments** in JSON files

## File Organization

```
<repo-root>/
├── jeeves.ps1                 # Main PowerShell management script
├── Dockerfile.jeeves          # Multi-stage Docker build file
├── .tmp/                      # Generated docker-compose files (git-ignored)
├── docs/                      # Project documentation
│   ├── guide.md               # Workflow guide (setup, phases, agents, tips)
│   ├── reference.md           # Commands and configuration reference
│   └── troubleshooting.md     # Problem/solution guide
├── jeeves/
│   ├── bin/                   # Installation and utility scripts
│   │   ├── AGENTS.md          # Script development guide
│   │   ├── ralph-init.sh
│   │   ├── ralph-loop.sh
│   │   ├── ralph-peek.sh
│   │   ├── ralph-paths.sh
│   │   ├── ralph-validate.sh
│   │   ├── ralph-filter-output.sh
│   │   ├── sync-agents.sh
│   │   ├── apply-rules.sh
│   │   ├── find-rules-files.sh
│   │   ├── install-mcp-servers.sh
│   │   ├── install-agents.sh
│   │   ├── install-skills.sh
│   │   ├── install-skill-deps.sh
│   │   ├── fetch-opencode-models.sh
│   │   └── parse_skill_deps.py
│   ├── config/
│   │   └── searxng/
│   │       └── settings.yml   # SearXNG sidecar configuration
│   ├── PRD/                   # PRD Creator agent templates
│   ├── Deepest-Thinking/      # Research agent templates
│   └── Ralph/                 # Ralph Loop Framework
│       ├── README-Ralph.md    # Ralph overview
│       ├── docs/
│       │   ├── directory-structure.md
│       │   └── rules-system.md
│       ├── plugins/
│       │   └── todo.ts        # OpenCode TODO plugin
│       ├── skills/
│       │   ├── dependency-tracking/
│       │   ├── git-automation/
│       │   ├── rationalization-defense/
│       │   └── system-prompt-compliance/
│       └── templates/
│           ├── README.md
│           ├── RULES.md.template
│           ├── agents/        # 11 agent types (OpenCode + Claude)
│           │   └── shared/    # 10 shared rule files
│           ├── config/        # agents.yaml, deps-tracker.yaml, TODO.md templates
│           ├── prompts/       # ralph-prompt.md.template, prompt-optimizer.md
│           └── task/          # TASK.md, activity.md, attempts.md templates
├── AGENTS.md                  # This file
├── README.md
└── CONTRIBUTING.md
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

### Services
- **OpenCode web** runs as a supervisord service, managed via `opencode-web {start|stop|restart|status|logs}`
- Running `opencode` with no arguments auto-attaches the TUI to the running web server session

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

Since skills are only loaded at startup, if a new skill is installed as part of your working process, pause and ask the user to restart the application before continuing (usually `/exit` will close the application, and the user can resume the session via the --continue CLI option)

## Key References

- Web UI: http://localhost:3333 (when container is running)
- Config paths: `~/.config/opencode/`, `~/.claude/`
- Container workdir: `/proj` (maps to host's project directory)
- Container user: `jeeves` (UID/GID mapped from host, default 1000:1000)
- Workflow guide: `docs/guide.md`
- Command and config reference: `docs/reference.md`
- Troubleshooting: `docs/troubleshooting.md`
