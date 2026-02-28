# Command Reference

Complete reference for all Jeeves container management and Ralph loop commands.

For Docker configuration details and environment variables, see [configuration.md](configuration.md).
For troubleshooting, see [troubleshooting.md](troubleshooting.md).

---

## Jeeves Container Management (`jeeves.ps1`)

PowerShell 7.0+ script for managing the Jeeves Docker container on the host machine.

### Command Summary

| Command | Aliases | Description |
|---------|---------|-------------|
| `build` | `b` | Build Docker image |
| `start` | `up` | Start container |
| `stop` | `down` | Stop container |
| `restart` | (none) | Stop and start container |
| `rm` | `remove` | Remove container (stops if running) |
| `shell` | `attach`, `sh` | Attach to container shell |
| `logs` | `log` | Show/follow container logs |
| `status` | `st`, `ps` | Show container and image status |
| `clean` | (none) | Remove container AND image |
| `help` | `h`, `?` | Show help |

Running `./jeeves.ps1` without arguments displays an interactive menu.

### build

Build the Docker image.

```powershell
./jeeves.ps1 build [--no-cache] [--desktop] [--install-claude-code] [--clean]
```

| Flag | Description |
|------|-------------|
| `--no-cache` | Build without Docker layer cache |
| `--desktop` | Include desktop application binaries (sets BUILD_DESKTOP=true) |
| `--install-claude-code` | Install Claude Code in the container (sets INSTALL_CLAUDE_CODE=true) |
| `--clean` | Stop, remove, then rebuild with --no-cache |

```powershell
./jeeves.ps1 build                       # Standard cached build
./jeeves.ps1 build --no-cache            # Clean build from scratch
./jeeves.ps1 build --desktop             # Build with desktop binaries
./jeeves.ps1 build --clean               # Full stop + remove + no-cache rebuild
```

### start

Start the Jeeves container with volume mounts, networking, and GPU access.

```powershell
./jeeves.ps1 start [--clean] [--dind]
```

| Flag | Description |
|------|-------------|
| `--clean` | Full clean rebuild (stop + remove + no-cache build) then start |
| `--dind` | Enable Docker-in-Docker mode (privileged container) |

```powershell
./jeeves.ps1 start                       # Start container
./jeeves.ps1 start --clean               # Full rebuild then start
./jeeves.ps1 start --dind                # Start with Docker-in-Docker
```

### stop

Stop the running container.

```powershell
./jeeves.ps1 stop [--force] [--remove]
```

| Flag | Description |
|------|-------------|
| `--force` | Send SIGKILL instead of SIGTERM |
| `--remove` | Remove container after stopping |

### restart

Stop then start the container. Passes through build and start flags.

```powershell
./jeeves.ps1 restart [--no-cache] [--desktop] [--install-claude-code] [--dind]
```

### shell

Attach an interactive shell to the running container.

```powershell
./jeeves.ps1 shell [--new] [--raw] [--zsh]
```

| Flag | Description |
|------|-------------|
| `--new` | Stop and remove existing container first |
| `--raw` | Disable tmux auto-attach (sets DISABLE_TMUX=1) |
| `--zsh` | Use /bin/zsh instead of /bin/bash |

### rm

Remove the container (stops it first if running).

```powershell
./jeeves.ps1 rm
```

### logs, status, clean, help

```powershell
./jeeves.ps1 logs                        # Follow container logs
./jeeves.ps1 status                      # Show container and image status
./jeeves.ps1 clean                       # Remove container AND image
./jeeves.ps1 help                        # Show help text
```

---

## Ralph Loop Commands

All Ralph scripts are installed to `/usr/local/bin/` inside the container.

### ralph-init.sh

Initialize Ralph project scaffolding in the current directory.

```bash
ralph-init.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--force` | `-f` | Skip overwrite prompts for existing files |
| `--rules` | | Force RULES.md creation even if it exists |
| `--help` | `-h` | Show usage |

Creates the `.ralph/` directory structure including config templates, agent templates, task templates, and skill definitions. Validates that `yq`, `jq`, and `git` are available. Updates `.gitignore` with Ralph exclusions. Runs `install-agents.sh`, `install-mcp-servers.sh`, and `install-skill-deps.sh` automatically.

`agents.yaml` is never overwritten (always preserved). Other files can be overwritten with `--force`.

```bash
ralph-init.sh                            # Interactive setup
ralph-init.sh --force                    # Overwrite existing files
ralph-init.sh --rules                    # Force RULES.md creation
```

### ralph-loop.sh

Main autonomous loop for task execution. Invokes the Manager agent repeatedly, parsing signals to determine loop continuation.

```bash
ralph-loop.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--tool {opencode\|claude}` | `-t` | AI tool to use (default: opencode) |
| `--max-iterations N` | `-m` | Max iterations; 0=unlimited (default: 100) |
| `--skip-sync` | `-s` | Skip pre-loop agent synchronization |
| `--no-delay` | `-n` | Disable exponential backoff delays |
| `--dry-run` | `-d` | Print commands without executing |
| `--verbose` | `-v` | Enable JSON format output (OpenCode) |
| `--help` | `-h` | Show usage |

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TOOL` | `opencode` | AI tool selection |
| `RALPH_MAX_ITERATIONS` | `100` | Max loop iterations (0=unlimited) |
| `RALPH_BACKOFF_BASE` | `2` | Backoff base delay in seconds |
| `RALPH_BACKOFF_MAX` | `60` | Backoff max delay in seconds |
| `RALPH_MANAGER_MODEL` | (empty) | Override Manager model |

**Loop behavior:** Checks for git conflicts in TODO.md and deps-tracker.yaml, invokes the Manager agent, parses output for signals, applies exponential backoff between iterations, and logs to `.ralph/logs/ralph-loop-YYYYMMDD-HHMMSS.log`.

```bash
ralph-loop.sh                            # Default: OpenCode, 100 iterations
ralph-loop.sh --tool claude -m 50        # Claude Code, 50 iterations
ralph-loop.sh --skip-sync --no-delay     # Fast execution, skip sync
ralph-loop.sh --dry-run                  # Preview commands
RALPH_MANAGER_MODEL=opus ralph-loop.sh   # Override model via env
```

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | All tasks complete or termination condition met |
| 1 | General error (invalid tool, missing files) |
| 130 | Interrupted (SIGINT/SIGTERM) |

### ralph-peek.sh

Monitor the active AI session.

```bash
ralph-peek.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--tui` | `-t` | Attach via TUI (default) |
| `--web` | `-w` | Print Web UI URL for the session |

Requires `opencode` and `jq`. Finds the newest session and either attaches to it in TUI mode or prints the web URL.

```bash
ralph-peek.sh                            # Attach via TUI (default)
ralph-peek.sh --web                      # Print web URL
```

### sync-agents.sh

Synchronize agent model configurations from `agents.yaml` to agent definition files.

```bash
sync-agents.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--tool {opencode\|claude}` | `-t` | Tool selection (default: opencode) |
| `--config FILE` | `-c` | Config file (default: .ralph/config/agents.yaml) |
| `--show` | `-s` | Show parsed agents without syncing |
| `--dry-run` | `-d` | Preview changes without modifying files |
| `--help` | `-h` | Show usage |

Reads agent configurations from `agents.yaml` and updates the `model` field in agent markdown files' YAML frontmatter. Searches agent directories in priority order: `.ralph/agents`, `.opencode/agents`, `.claude/agents`, `$HOME/.config/opencode/agents`, `$HOME/.claude/agents` (filtered by selected tool).

```bash
sync-agents.sh                           # Sync for OpenCode (default)
sync-agents.sh --tool claude             # Sync for Claude Code
sync-agents.sh --show                    # Show parsed agents
sync-agents.sh --dry-run                 # Preview changes
sync-agents.sh -t claude -c ./agents.yaml -d  # Combined options
```

### Signal System

Agents emit signals to communicate task status to the Ralph loop.

**Signal Format:** `SIGNAL_TYPE_XXXX[: message]` where XXXX is a 4-digit zero-padded task ID.

| Signal | Format | Loop Action |
|--------|--------|-------------|
| Complete | `TASK_COMPLETE_XXXX` | Terminates loop |
| Incomplete | `TASK_INCOMPLETE_XXXX` | Continues loop |
| Failed | `TASK_FAILED_XXXX: message` | Continues with warning |
| Blocked | `TASK_BLOCKED_XXXX: message` | Terminates loop |
| All Complete | `ALL TASKS COMPLETE, EXIT LOOP` | Terminates loop (sentinel in TODO.md) |
| Abort | `ABORT: HELP NEEDED` | Terminates loop (sentinel in TODO.md) |

FAILED and BLOCKED signals require a colon and message. COMPLETE and INCOMPLETE have no message.

**Signal priority** (when multiple detected): TASK_BLOCKED > TASK_COMPLETE > TASK_FAILED > TASK_INCOMPLETE.

---

## Utility Scripts (Sourced)

These scripts are sourced by other Ralph scripts and provide shared functions.

| Script | Purpose |
|--------|---------|
| `ralph-paths.sh` | Path detection/expansion (find_project_root, find_ralph_dir, find_task_dir, expand_path) |
| `ralph-validate.sh` | Validation utilities (validate_task_id, validate_yaml, validate_file_exists) |
| `ralph-filter-output.sh` | Filter OpenCode JSON output (signals, tokens, tools, cost) |
| `find-rules-files.sh` | Locate RULES.md files up the directory tree |
| `apply-rules.sh` | Extract and merge RULES.md sections into project files |

---

## Installation Scripts

Run inside the container. Installed to `/usr/local/bin/`.

### install-mcp-servers.sh

Install and configure MCP servers for OpenCode and Claude Code.

```bash
install-mcp-servers.sh [--global] [--dry-run]
```

| Flag | Description |
|------|-------------|
| `--global` | Install to user home (global scope) |
| `--dry-run` | Preview changes without installing |

Installs: `sequentialthinking`, `fetch`, `searxng`, `playwright`.

```bash
install-mcp-servers.sh                   # Project scope
install-mcp-servers.sh --global          # User home scope
install-mcp-servers.sh --global --dry-run  # Preview global install
```

### install-agents.sh

Install AI agent templates (PRD Creator, Deepest-Thinking) for both platforms.

```bash
install-agents.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--all` | `-a` | Install all agents (default) |
| `--deepest` | `-d` | Install Deepest-Thinking only |
| `--global` | `-g` | Install to user home |
| `--help` | `-h` | Show usage |

```bash
install-agents.sh                        # All agents, project scope
install-agents.sh --global               # All agents, user home
install-agents.sh --deepest              # Deepest-Thinking only
```

### install-skills.sh

Install Agent Skills for both Claude Code and OpenCode platforms.

```bash
install-skills.sh [OPTIONS]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--doc-skills` | `-d` | Document creation skills (docx, pdf, xlsx, pptx, markitdown) |
| `--n8n-skills` | `-n` | n8n automation skills (7 workflow development skills) |
| `--all` | `-a` | All skill sets |
| `--global` | `-g` | Install to user home |
| `--help` | `-h` | Show usage |

At least one skill set (`--doc-skills`, `--n8n-skills`, or `--all`) must be specified.

```bash
install-skills.sh -d                     # Document skills, project scope
install-skills.sh -n -g                  # n8n skills, user home
install-skills.sh -a                     # All skills, project scope
```

### install-skill-deps.sh

Install dependencies for installed Ralph skills. Parses `SKILL.md` files for apt, pip, and npm requirements using `parse_skill_deps.py`.

```bash
install-skill-deps.sh [--dry-run] [--verbose]
```

---

## Git Automation (Skill Script)

### task-branch-create.sh

Create a git branch for a task following the `task/NNNN-description` naming convention. Installed as part of the `git-automation` skill.

```bash
task-branch-create.sh --task-id NNNN [--description "short-desc"] [--dry-run]
```

| Flag | Description |
|------|-------------|
| `--task-id NNNN` | 4-digit zero-padded task ID (required) |
| `--description "desc"` | Short description (defaults to task title from TASK.md) |
| `--dry-run` | Preview without making changes |
| `--help`, `-h` | Show usage |

Handles uncommitted changes by stashing, creates the branch from the primary branch, pushes to remote with tracking, and logs to `activity.md`.

```bash
task-branch-create.sh --task-id 0067
task-branch-create.sh --task-id 0070 --description "conventional-commits"
task-branch-create.sh --task-id 0097 --dry-run
```

---

## Container Environment Variables

Key variables affecting container behavior. For the full Docker configuration, see [configuration.md](configuration.md).

| Variable | Description |
|----------|-------------|
| `DISABLE_WELCOME=1` | Suppress the welcome message on shell attach |
| `DISABLE_TMUX=1` | Skip tmux auto-attach (used by `shell --raw`) |
| `ENABLE_DIND=true` | Docker-in-Docker mode (used by `start --dind`) |
| `WORKSPACE` | Container workspace path (default: `/proj`) |
| `VIRTUAL_ENV` | Python virtual environment path (default: `/opt/venv`) |

---

## Quick Reference

| Task | Command |
|------|---------|
| Build image | `./jeeves.ps1 build` |
| Start container | `./jeeves.ps1 start` |
| Attach shell | `./jeeves.ps1 shell` |
| Check status | `./jeeves.ps1 status` |
| View logs | `./jeeves.ps1 logs` |
| Stop container | `./jeeves.ps1 stop` |
| Full rebuild | `./jeeves.ps1 start --clean` |
| Remove everything | `./jeeves.ps1 clean` |
| Initialize Ralph | `ralph-init.sh` |
| Start Ralph loop | `ralph-loop.sh` |
| Monitor session | `ralph-peek.sh` |
| Sync agent models | `sync-agents.sh` |
| Create task branch | `task-branch-create.sh --task-id NNNN` |

---

## Exit Codes

| Command | 0 | 1 | 130 |
|---------|---|---|-----|
| jeeves.ps1 | Success | Error | -- |
| ralph-init.sh | Success | Error | -- |
| ralph-loop.sh | Success | Error | Interrupted (SIGINT) |
| sync-agents.sh | Success | Error | -- |
| task-branch-create.sh | Success | Error | -- |

---

## See Also

- [configuration.md](configuration.md) -- Docker, volume, network, and environment configuration
- [troubleshooting.md](troubleshooting.md) -- Common issues and solutions
- [how-to-guide.md](how-to-guide.md) -- Step-by-step workflows
