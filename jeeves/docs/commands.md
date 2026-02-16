# Ralph Commands Reference

## Overview

Ralph is an autonomous AI task execution system that manages development workflows through a series of command-line tools. The Ralph CLI provides utilities for project initialization, autonomous task processing, agent configuration management, and git workflow automation.

All Ralph commands follow consistent patterns:
- Bash scripts with POSIX-compatible syntax
- Color-coded output (blue=info, green=success, yellow=warning, red=error)
- Standard exit codes (0=success, 1=general error)
- Help available via `--help` or `-h`

---

## ralph-init.sh

**Purpose:** Initialize Ralph scaffolding in a project

**Usage:**
```bash
ralph-init.sh [OPTIONS]
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message and exit |
| `--force` | `-f` | Skip overwrite prompts for existing files |
| `--rules` | | Force RULES.md creation even if it exists |

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success - Ralph initialized successfully |
| 1 | General error - Missing tools or other error |

**Description:**
Sets up Ralph scaffolding in the current project directory. Validates required tools (yq, jq, git) and creates the basic Ralph structure including:
- `.ralph/` directory structure (config/, prompts/, tasks/, specs/)
- `.ralph/tasks/done/` directory
- Configuration templates (agents.yaml, TODO.md, deps-tracker.yaml)
- Task templates (TASK.md, activity.md, attempts.md)
- Agent templates for OpenCode and Claude
- Bash scripts installed to `/usr/local/bin/`
- RULES.md file (if not exists or with --rules)
- Updates `.gitignore` with Ralph exclusions

**Preservation Behavior:**
- `agents.yaml` is never overwritten (always preserved)
- Other files can be overwritten with `--force`
- Task data in `.ralph/tasks/done/` is always preserved
- Existing installations are backed up before overwrite (with `--force`)

**Examples:**

```bash
# Initialize in current directory
ralph-init.sh

# Force re-initialization (overwrite existing files)
ralph-init.sh --force

# Force RULES.md creation
ralph-init.sh --rules

# Show help
ralph-init.sh --help
```

**Requirements:**
- `yq`: YAML processor
- `jq`: JSON processor
- `git`: Version control system

---

## ralph-loop.sh

**Purpose:** Main execution loop for autonomous task processing

**Usage:**
```bash
ralph-loop.sh [OPTIONS]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--tool {opencode\|claude}` | Select AI tool to use (default: opencode) |
| `--max-iterations N` | Set maximum iterations (default: 100, 0=unlimited) |
| `--skip-sync` | Skip pre-loop agent synchronization |
| `--no-delay` | Disable backoff delays between iterations |
| `--dry-run` | Print commands without executing |
| `--help`, `-h` | Show help message and exit |

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TOOL` | `opencode` | Default tool selection (opencode or claude) |
| `RALPH_MAX_ITERATIONS` | `100` | Maximum loop iterations (0=unlimited) |
| `RALPH_BACKOFF_BASE` | `2` | Backoff base delay in seconds |
| `RALPH_BACKOFF_MAX` | `60` | Backoff max delay in seconds |
| `RALPH_MANAGER_MODEL` | (none) | Override Manager model selection |

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success - All tasks complete or termination condition met |
| 1 | General error - Invalid tool, missing files, or other error |
| 130 | Interrupted - Received SIGINT/SIGTERM signal |

**Signal Patterns:**

The Manager agent emits signals that control loop behavior:

| Signal | Pattern | Action |
|--------|---------|--------|
| Complete | `TASK_COMPLETE_XXXX` | Task finished successfully, terminates loop |
| Incomplete | `TASK_INCOMPLETE_XXXX` | Task incomplete, continues loop |
| Failed | `TASK_FAILED_XXXX: message` | Task failed, continues loop with warning |
| Blocked | `TASK_BLOCKED_XXXX: message` | Task blocked, terminates loop |
| All Complete | `ALL TASKS COMPLETE, EXIT LOOP` | All tasks done, terminates loop |
| Abort | `ABORT: HELP NEEDED` | Help requested, terminates loop |

**Loop Behavior:**
1. Checks for git conflicts in critical files (TODO.md, deps-tracker.yaml)
2. Invokes Manager agent with configured tool
3. Parses signals from Manager output
4. Checks termination conditions
5. Sleeps with exponential backoff (unless `--no-delay`)
6. Repeats until termination

**Examples:**

```bash
# Run with default settings (OpenCode, 100 iterations)
ralph-loop.sh

# Use Claude with 50 iteration limit
ralph-loop.sh --tool claude --max-iterations 50

# Unlimited iterations with OpenCode
ralph-loop.sh --max-iterations 0

# Skip agent sync and disable delays (faster execution)
ralph-loop.sh --skip-sync --no-delay

# Dry run (show what would be done)
ralph-loop.sh --dry-run

# Run with environment variables
export RALPH_TOOL=claude
export RALPH_MAX_ITERATIONS=200
export RALPH_MANAGER_MODEL=opus
ralph-loop.sh
```

---

## sync-agents

**Purpose:** Synchronize agent model configurations from agents.yaml to agent definition files

**Usage:**
```bash
sync-agents [OPTIONS]
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message and exit |
| `--tool` | `-t` | Specify tool (opencode or claude) [default: opencode] |
| `--config` | `-c` | Specify agents.yaml path [default: .ralph/config/agents.yaml] |
| `--show` | `-s` | Show parsed agents (don't sync) |
| `--dry-run` | `-d` | Show what would be updated (don't modify files) |

**Environment Variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TOOL` | `opencode` | Tool to use (opencode or claude) |
| `AGENTS_YAML` | `.ralph/config/agents.yaml` | Path to agents.yaml file |

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success - Agents synchronized successfully |
| 1 | General error - Invalid tool, missing files, invalid YAML, etc. |

**Agent Search Paths (in priority order):**
1. `.ralph/agents`
2. `.opencode/agents`
3. `.claude/agents`
4. `$HOME/.config/opencode/agents`
5. `$HOME/.claude/agents`

Paths are filtered based on selected tool (opencode or claude).

**Description:**
Reads agent configurations from `agents.yaml` and updates the `model` field in agent markdown files' YAML frontmatter. Supports both preferred and fallback model selection from agents.yaml.

**Examples:**

```bash
# Sync for OpenCode (default)
sync-agents

# Sync for Claude
sync-agents --tool claude
# or
RALPH_TOOL=claude sync-agents

# Use custom config file
sync-agents --config /path/to/custom-agents.yaml

# Show parsed agents without syncing
sync-agents --show

# Dry run - show what would change
sync-agents --dry-run

# Combined options
sync-agents -t claude -c ./config/agents.yaml -d
```

**Requirements:**
- `yq`: YAML processor (https://github.com/mikefarah/yq)

---

## task-branch-create.sh

**Purpose:** Create task branch with proper naming convention

**Usage:**
```bash
task-branch-create.sh --task-id NNNN [--description "short-desc"]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--task-id NNNN` | Task ID (4 digits, zero-padded, e.g., 0067) - **Required** |
| `--description "desc"` | Short description (defaults to task title from TASK.md) |
| `--dry-run` | Show what would be done without making changes |
| `--help`, `-h` | Show help message and exit |

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success - Branch created or checked out successfully |
| 1 | General error - Invalid arguments, git errors, etc. |

**Branch Naming Convention:**

Format: `task/NNNN-description`

Examples:
- `task/0067-implement-branch-creation`
- `task/0070-conventional-commits`

**Repository Contexts:**

| Context | Behavior |
|---------|----------|
| `REPO_ROOT` | Full git integration - creates branches automatically |
| `SUBFOLDER` | Shows manual command for user to execute |
| `NO_REPO` | Skips silently (no git repository detected) |

**Description:**
Creates a git branch for a specific task following the `task/NNNN-description` naming convention. The description defaults to the task title extracted from `.ralph/tasks/NNNN/TASK.md`. Handles uncommitted changes by stashing them before branch creation.

**Examples:**

```bash
# Create branch from task title in TASK.md
task-branch-create.sh --task-id 0067

# Create branch with custom description
task-branch-create.sh --task-id 0067 --description "implement-branch-creation"

# Dry run to preview actions
task-branch-create.sh --task-id 0070 --description "conventional-commits" --dry-run

# Show help
task-branch-create.sh --help
```

**Workflow:**
1. Extracts task title from TASK.md (or uses provided description)
2. Generates branch name: `task/NNNN-description`
3. Detects repository context
4. Handles uncommitted changes (stash if needed)
5. Checks if branch exists locally or on remote
6. Creates new branch from primary branch
7. Pushes to remote with tracking
8. Logs branch creation to `activity.md`

---

## Common Patterns

### Starting a New Project

Initialize Ralph in a new project:

```bash
# Navigate to project directory
cd /path/to/project

# Initialize Ralph
ralph-init.sh

# Verify installation
ls -la .ralph/
```

### Running with Different Tools

Switch between OpenCode and Claude:

```bash
# OpenCode (default)
ralph-loop.sh

# Claude Code
ralph-loop.sh --tool claude

# Via environment variable
export RALPH_TOOL=claude
ralph-loop.sh
```

### Managing Long-Running Tasks

Control iteration limits for long-running tasks:

```bash
# Set global iteration limit
export RALPH_MAX_ITERATIONS=100
ralph-loop.sh

# Unlimited iterations (use with caution)
ralph-loop.sh --max-iterations 0

# Fast execution (no delays)
ralph-loop.sh --no-delay

# Skip sync for faster startup
ralph-loop.sh --skip-sync --no-delay
```

### Synchronizing Agent Models

After modifying `agents.yaml`:

```bash
# Sync all agents
sync-agents

# Verify configuration
sync-agents --show

# Sync for specific tool
sync-agents --tool claude
```

### Creating Task Branches

Standard workflow for new tasks:

```bash
# Create branch from task
task-branch-create.sh --task-id 0097

# Create branch with description
task-branch-create.sh --task-id 0098 --description "update-documentation"

# Verify branch
git branch -a | grep task/0097
```

---

## Signal Reference

Signals are emitted by agents to communicate task status to the Ralph loop.

### Signal Format

All signals follow the pattern: `SIGNAL_TYPE_XXXX[: message]`

Where:
- `SIGNAL_TYPE`: TASK_COMPLETE, TASK_INCOMPLETE, TASK_FAILED, TASK_BLOCKED
- `XXXX`: 4-digit task ID with leading zeros (0001-9999)
- `:`: Colon separator (required for FAILED and BLOCKED)
- `message`: Optional description (required for FAILED/BLOCKED)

### Complete Signal

```
TASK_COMPLETE_0097
```

**Meaning:** Task completed successfully. The loop will terminate.

### Incomplete Signal

```
TASK_INCOMPLETE_0097
```

**Meaning:** Task is incomplete and requires more work. The loop will continue.

### Failed Signal

```
TASK_FAILED_0097: Error message describing what went wrong
```

**Meaning:** Task encountered an error. The loop will continue and retry.

### Blocked Signal

```
TASK_BLOCKED_0097: Reason why task is blocked
```

**Meaning:** Task is blocked and cannot proceed. The loop will terminate and requires human intervention.

### All Tasks Complete

```
ALL TASKS COMPLETE, EXIT LOOP
```

**Meaning:** All tasks in TODO.md are complete. The loop will terminate.

### Abort Signal

```
ABORT: HELP NEEDED
```

**Meaning:** Help is requested in TODO.md. The loop will terminate.

### Signal Priority

When multiple signals are detected, the loop uses the first valid signal found:
1. TASK_BLOCKED (terminates)
2. TASK_COMPLETE (terminates)
3. TASK_FAILED (continues with warning)
4. TASK_INCOMPLETE (continues)

---

## Environment Variables Reference

| Variable | Scripts | Default | Description |
|----------|---------|---------|-------------|
| `RALPH_TOOL` | ralph-loop.sh, sync-agents | `opencode` | Default AI tool selection |
| `RALPH_MAX_ITERATIONS` | ralph-loop.sh | `100` | Maximum loop iterations |
| `RALPH_BACKOFF_BASE` | ralph-loop.sh | `2` | Backoff base delay (seconds) |
| `RALPH_BACKOFF_MAX` | ralph-loop.sh | `60` | Backoff max delay (seconds) |
| `RALPH_MANAGER_MODEL` | ralph-loop.sh | (none) | Override Manager model |
| `AGENTS_YAML` | sync-agents | `.ralph/config/agents.yaml` | Path to agents.yaml |
| `RALPH_DIR` | ralph-init.sh, sync-agents | `.ralph` | Ralph directory path |

---

## Error Handling and Best Practices

### Common Mistakes to Avoid

1. **Running ralph-loop.sh without initialization**
   - Always run `ralph-init.sh` first
   - Error: "Ralph directory not found: .ralph"

2. **Missing required tools**
   - Install `yq`, `jq`, and `git` before running `ralph-init.sh`
   - Use `--force` carefully - it overwrites existing files

3. **Invalid task ID format**
   - Task IDs must be 4 digits: `0067`, not `67` or `67`
   - Use leading zeros

4. **Git conflicts**
   - Ralph checks for conflicts in TODO.md and deps-tracker.yaml
   - Resolve conflicts before running `ralph-loop.sh`

### Best Practices

1. **Use dry-run first**
   ```bash
   ralph-loop.sh --dry-run
   sync-agents --dry-run
   task-branch-create.sh --task-id 0097 --dry-run
   ```

2. **Set reasonable iteration limits**
   ```bash
   export RALPH_MAX_ITERATIONS=50  # Prevent runaway loops
   ```

3. **Check signals in output**
   - Monitor for TASK_BLOCKED that requires intervention
   - Review TASK_FAILED messages for errors

4. **Preserve agent configuration**
   - Use `sync-agents --show` to verify before syncing
   - agents.yaml is never overwritten by ralph-init.sh

5. **Create branches early**
   ```bash
   task-branch-create.sh --task-id 0097
   ```
   This stashes changes and sets up proper tracking.

---

## Exit Codes Summary

| Command | 0 | 1 | 130 |
|---------|---|---|-----|
| ralph-init.sh | Success | General error | - |
| ralph-loop.sh | Success | General error | Interrupted (SIGINT) |
| sync-agents | Success | General error | - |
| task-branch-create.sh | Success | General error | - |

---

## Requirements Summary

### System Requirements
- Bash 4.0+
- Git
- yq (YAML processor)
- jq (JSON processor)

### AI Tools (at least one)
- OpenCode CLI (`opencode`)
- Claude Code CLI (`claude`)

### Optional
- Docker (for containerized environments)
- PowerShell (for Windows hosts using jeeves.ps1)

---

## See Also

- `README-Ralph.md` - Ralph system overview and architecture
- `AGENTS.md` - Agent configuration and templates
- `.ralph/config/agents.yaml` - Agent model configuration
- `.ralph/tasks/TODO.md` - Task tracking
- `RULES.md` - Project-specific rules and patterns
