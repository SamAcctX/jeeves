# Reference

Complete reference for Jeeves container management, Ralph loop commands, and all configuration.

For troubleshooting, see [troubleshooting.md](troubleshooting.md).
For step-by-step workflows, see [guide.md](guide.md).

---

## Jeeves Container Management

### Interactive Menu

Running `./jeeves.ps1` with no arguments opens an interactive menu with submenus for build, start, stop, shell, and clean options. This is the primary interface for most users -- CLI flags below are for scripting and automation.

### CLI Commands

| Command | Aliases | Key Flags | Description |
|---------|---------|-----------|-------------|
| `build` | `b` | `--no-cache`, `--desktop`, `--install-claude-code` | Build Docker image |
| `start` | `up` | `--clean`, `--dind`, `--port <n>`, `--ports <mappings>` | Start container |
| `stop` | `down` | `--force`, `--remove` | Stop container |
| `restart` | (none) | Passes through build and start flags | Stop then start container |
| `rm` | `remove` | (none) | Remove container (stops if running) |
| `shell` | `attach`, `sh` | `--new`, `--raw`, `--zsh` | Attach to container shell |
| `logs` | `log` | (none) | Show/follow container logs |
| `status` | `st` | `--all` | Show container and image status |
| `list` | `ls`, `ps` | (none) | List all running jeeves instances |
| `clean` | (none) | `--image`, `--all`, `--force` | Remove container (optionally image) |
| `help` | `h`, `?` | (none) | Show help |

**Flag details for non-obvious options:**

| Flag | On Command | Description |
|------|-----------|-------------|
| `--no-cache` | `build` | Build without Docker layer cache |
| `--desktop` | `build` | Include desktop application binaries (sets BUILD_DESKTOP=true) |
| `--install-claude-code` | `build` | Install Claude Code CLI in the container |
| `--clean` | `start` | Stop + remove + no-cache rebuild, then start |
| `--dind` | `start` | Enable Docker-in-Docker mode (privileged container) |
| `--port <n>` | `start` | Use specific host port (default: auto-assigned from 3333) |
| `--ports <mappings>` | `start` | Additional port mappings (e.g., `8080:8080,9090:9090`) |
| `--force` | `stop` | Send SIGKILL instead of SIGTERM |
| `--remove` | `stop` | Remove container after stopping |
| `--new` | `shell` | Stop and remove existing container first |
| `--raw` | `shell` | Disable tmux auto-attach (sets DISABLE_TMUX=1) |
| `--zsh` | `shell` | Use /bin/zsh instead of /bin/bash |
| `--all` | `status` | Show all jeeves instances instead of just this project |
| `--image` | `clean` | Also remove the shared Docker image |
| `--all` | `clean` | Remove ALL jeeves containers (not just this project) |
| `--force` | `clean` | Force image removal even if other containers exist |

---

## Ralph Loop

All Ralph scripts are installed to `/usr/local/bin/` inside the container. All scripts support `--help` (or `-h`) for usage information.

### Commands

#### ralph-init.sh

Initialize Ralph project scaffolding in the current directory.

```bash
ralph-init.sh [--force|-f] [--rules] [--help|-h]
```

Creates the `.ralph/` directory structure including config templates, agent templates, task templates, and skill definitions. Validates that `yq`, `jq`, and `git` are available. Updates `.gitignore` with Ralph exclusions. Runs `install-agents.sh`, `install-mcp-servers.sh`, and `install-skill-deps.sh` automatically.

`agents.yaml` is never overwritten (always preserved). Other files can be overwritten with `--force`.

#### ralph-loop.sh

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

Loop behavior: checks for git conflicts in TODO.md and deps-tracker.yaml, invokes the Manager agent, parses output for signals, applies exponential backoff between iterations, and logs to `.ralph/logs/ralph-loop-YYYYMMDD-HHMMSS.log`.

```bash
ralph-loop.sh                            # Default: OpenCode, 100 iterations
ralph-loop.sh --tool claude -m 50        # Claude Code, 50 iterations
ralph-loop.sh --skip-sync --no-delay     # Fast execution, skip sync
RALPH_MANAGER_MODEL=opus ralph-loop.sh   # Override model via env
```

#### ralph-peek.sh

Monitor the active AI session.

```bash
ralph-peek.sh [--tui|-t] [--web|-w]
```

Requires `opencode` and `jq`. Finds the newest session and either attaches to it in TUI mode (default) or prints the web URL with `--web`.

#### sync-agents.sh

Synchronize agent model configurations from `agents.yaml` to agent definition files.

```bash
sync-agents.sh [--tool|-t {opencode|claude}] [--config|-c FILE] [--show|-s] [--dry-run|-d]
```

Reads agent configurations from `agents.yaml` and updates the `model` field in agent markdown files' YAML frontmatter. Searches agent directories in priority order: `.ralph/agents`, `.opencode/agents`, `.claude/agents`, `$HOME/.config/opencode/agents`, `$HOME/.claude/agents` (filtered by selected tool).

#### ralph-filter-output.sh

Filter and format OpenCode JSON output for human-readable display.

```bash
ralph-filter-output.sh [OPTIONS] [INPUT_FILE]
```

| Flag | Description |
|------|-------------|
| `--text` / `--no-text` | Show/hide text responses (default: show) |
| `--tokens` / `--no-tokens` | Show/hide token statistics (default: show) |
| `--tools` / `--no-tools` | Show/hide tool usage (default: show) |
| `--cost` / `--no-cost` | Show/hide cost information (default: show) |
| `--signals` / `--no-signals` | Show/hide task signals (default: show) |
| `--compact` | Compact output format |

Reads from INPUT_FILE or stdin. Used by `ralph-loop.sh` to parse OpenCode output.

#### fetch-opencode-models.sh

Fetch free models from the OpenCode Zen API and populate `agents.yaml` with model configurations.

```bash
fetch-opencode-models.sh [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--free` | Filter to free models only (default behavior) |
| `--output FILE` | Output file path (default: `.ralph/config/agents.yaml`) |
| `--dry-run` | Preview changes without writing files |
| `--list` | List available free models and exit |
| `--model MODEL` | Use a specific model for all agent types |
| `--include MODELS` | Comma-separated additional model IDs to treat as free |

Assigns models to agent types by tier: complex reasoning agents (manager, architect, decomposer) get the strongest free models, coding agents (developer, tester) get coding-optimized models, and general agents (writer, researcher, ui-designer) get general-purpose models.

```bash
fetch-opencode-models.sh --free              # Fetch and assign free models
fetch-opencode-models.sh --list              # List available free models
fetch-opencode-models.sh --model my-model    # Override all agents with one model
```

### Signal System

Agents emit signals to communicate task status to the Ralph loop.

**Format:** `SIGNAL_TYPE_XXXX[: message]` where XXXX is a 4-digit zero-padded task ID.

| Signal | Format | Loop Action |
|--------|--------|-------------|
| Complete | `TASK_COMPLETE_XXXX` | Continues loop (task done, pick next) |
| Incomplete | `TASK_INCOMPLETE_XXXX` | Continues loop (retry or pick next) |
| Failed | `TASK_FAILED_XXXX: message` | Continues loop with warning |
| Blocked | `TASK_BLOCKED_XXXX: message` | Terminates loop (requires intervention) |
| All Complete | `ALL TASKS COMPLETE, EXIT LOOP` | Terminates loop (sentinel in TODO.md) |
| Abort | `ABORT: HELP NEEDED` | Terminates loop (sentinel in TODO.md) |

FAILED and BLOCKED signals require a colon and message. COMPLETE and INCOMPLETE have no message.

**Signal priority** (when multiple detected): TASK_BLOCKED > TASK_FAILED > TASK_INCOMPLETE > TASK_COMPLETE.

### Installation Scripts

Run inside the container. Installed to `/usr/local/bin/`.

#### install-mcp-servers.sh

Install and configure MCP servers for OpenCode and Claude Code.

```bash
install-mcp-servers.sh [--global] [--dry-run]
```

Installs 5 MCP servers: `sequentialthinking`, `fetch`, `crawl4ai`, `searxng`, `playwright`. Use `--global` for user home scope, `--dry-run` to preview.

#### install-agents.sh

Install AI agent templates (PRD Creator, PRD Advisors, PRD Researcher, Deepest-Thinking) to OpenCode.

```bash
install-agents.sh [--all|-a] [--deepest|-d] [--global|-g] [--help|-h]
```

Installs to OpenCode only. Use `--deepest` for Deepest-Thinking only, `--global` for user home scope.

#### install-skills.sh

Install Agent Skills for both Claude Code and OpenCode platforms.

```bash
install-skills.sh [--doc-skills|-d] [--n8n-skills|-n] [--all|-a] [--global|-g]
```

At least one skill set must be specified. `--doc-skills` installs document creation skills (docx, pdf, xlsx, pptx, markitdown). `--n8n-skills` installs 7 n8n workflow development skills.

#### install-skill-deps.sh

Install dependencies for installed Ralph skills. Parses `SKILL.md` files for apt, pip, and npm requirements.

```bash
install-skill-deps.sh [--dry-run|-d] [--verbose|-v] [--help|-h]
```

### Utility Scripts (Sourced)

These scripts are sourced by other Ralph scripts and provide shared functions.

| Script | Purpose |
|--------|---------|
| `ralph-paths.sh` | Path detection/expansion (find_project_root, find_ralph_dir, find_task_dir, find_agent_file) |
| `ralph-validate.sh` | Validation utilities (validate_task_id, validate_yaml, validate_file_exists, validate_git_repo) |
| `find-rules-files.sh` | Locate RULES.md files up the directory tree |
| `apply-rules.sh` | Extract and merge RULES.md sections into project files |

### Git Automation (Skill Script)

#### task-branch-create.sh

Create a git branch for a task following the `task/NNNN-description` naming convention.

```bash
task-branch-create.sh --task-id NNNN [--description "short-desc"] [--dry-run]
```

Handles uncommitted changes by stashing, creates the branch from the primary branch, pushes to remote with tracking, and logs to `activity.md`.

---

## Configuration

### Docker Build

#### Build Stages

| Stage | Base | Purpose |
|-------|------|---------|
| `base` | `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04` | System packages, Python, Node.js |
| `opencode-builder` | `base` | Builds OpenCode from source (optional desktop binaries) |
| `runtime` | `base` | Final container with user, tools, and configuration |

#### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `UID` | `1000` | Container user UID (mapped from host) |
| `GID` | `1000` | Container user GID (mapped from host) |
| `BUILD_DESKTOP` | (unset) | Include desktop binaries in OpenCode build |
| `INSTALL_CLAUDE_CODE` | `false` | Install Claude Code CLI in the container |

### Docker Compose

Docker Compose files are generated dynamically in `.tmp/<slug>/` by `jeeves.ps1`. The `<slug>` is derived from the project directory name, allowing multiple concurrent containers with per-project networks.

Key settings: build context is `../..` (relative to the generated compose file), GPU support (`runtime: nvidia` and `gpus: all`) is commented out by default, shared memory is 2 GB, network is `jeeves-<slug>-network` (bridge driver).

#### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| Current working directory | `/proj` | Project workspace (read-write) |
| `~/.claude` | `/home/jeeves/.claude` | Claude Code configuration and settings |
| `~/.config/opencode` | `/home/jeeves/.config/opencode` | OpenCode configuration |
| `~/.opencode` | `/home/jeeves/.opencode` | OpenCode agent directory |
| `~/.local/share/opencode` | `/home/jeeves/.local/share/opencode` | OpenCode session data |
| `~/.local/state/opencode` | `/home/jeeves/.local/state/opencode` | OpenCode state data |

#### Container Details

| Property | Value |
|----------|-------|
| User | `jeeves` (non-root) |
| UID/GID | Configurable via build args (default 1000:1000) |
| Port | Auto-assigned from 3333 (per-project, incrementing) |
| GPU | NVIDIA runtime (commented out by default, uncomment to enable) |
| Shared memory | 2 GB |
| Network | `jeeves-<slug>-network` (bridge driver, per-project) |

### Ralph Project Configuration

#### Directory Structure

Running `ralph-init.sh` creates the `.ralph/` directory in your project root:

```
.ralph/
├── config/
│   └── agents.yaml              # Agent-to-model mapping
├── specs/
│   └── PRD-*.md                 # Product Requirements Documents
└── tasks/
    ├── TODO.md                  # Master task checklist
    ├── deps-tracker.yaml        # Task dependency graph
    ├── done/                    # Completed task folders (preserved)
    └── XXXX/                    # Individual task folders
        ├── TASK.md              # Task definition (created by Decomposer)
        ├── activity.md          # Execution log (created by Decomposer)
        └── attempts.md          # Attempt history (created by Decomposer)
```

The `logs/` subdirectory is created at runtime by `ralph-loop.sh` (not by init).

#### Configuration Precedence

| Priority | Source | Example |
|----------|--------|---------|
| 1 (highest) | CLI flags | `ralph-loop.sh --tool claude --max-iterations 50` |
| 2 | Environment variables | `export RALPH_TOOL=claude` |
| 3 | Project configuration | `.ralph/config/agents.yaml` |
| 4 (lowest) | Default templates | `jeeves/Ralph/templates/config/` |

#### agents.yaml

**Location:** `.ralph/config/agents.yaml`

Maps each agent type to specific LLM models per tool (OpenCode or Claude Code), enabling per-agent model selection.

**Schema:**

```yaml
agents:
  <agent_type>:
    description: "Human-readable description"
    preferred:
      opencode: <model_name_or_empty_string>
      claude: <model_name>
    fallback:
      opencode: <model_name_or_empty_string>
      claude: <model_name>
```

| Field | Type | Description |
|-------|------|-------------|
| `agents.<type>.description` | String | Human-readable description of the agent's role |
| `agents.<type>.preferred.<tool>` | String | Primary model for the tool (`""` = use default/inherited model) |
| `agents.<type>.fallback.<tool>` | String | Fallback model if preferred is unavailable |

An empty string (`""`) for OpenCode model values means "use the default/inherited model." This is the recommended approach for OpenCode.

**Example (single agent):**

```yaml
agents:
  manager:
    description: "Loop orchestrator - selects tasks, invokes workers, manages state"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5
```

**Agent Types (11 total):**

| Agent Type | Description |
|------------|-------------|
| `manager` | Loop orchestrator - selects tasks, invokes workers, manages state |
| `architect` | System design and architecture tasks |
| `developer` | Code implementation and debugging |
| `ui-designer` | UI/UX design and implementation |
| `tester` | Testing and quality assurance |
| `researcher` | Research, analysis, and documentation |
| `writer` | Documentation and content creation |
| `decomposer` | Task decomposition, TODO management, agent coordination |
| `decomposer-architect` | System design, patterns, integration design for PRD decomposition |
| `decomposer-researcher` | Investigation, documentation analysis, knowledge synthesis for PRD decomposition |
| `decomposer-task-handler` | Task-level decomposition and handling (OpenCode only) |

**Model selection at runtime:** Ralph reads `agents.yaml`, looks up the agent type for the selected tool (`--tool` flag or `RALPH_TOOL` env var), uses `preferred.<tool>`, and falls back to `fallback.<tool>` if preferred is empty or unavailable. After modifying `agents.yaml`, run `sync-agents.sh` to propagate changes to agent template files.

#### deps-tracker.yaml

**Location:** `.ralph/tasks/deps-tracker.yaml`

Tracks task dependencies and blocking relationships so the Manager can determine which tasks are unblocked.

```yaml
tasks:
  "<task_id>":
    depends_on: [<task_id>, ...]
    blocks: [<task_id>, ...]
```

| Field | Type | Description |
|-------|------|-------------|
| `<task_id>` | String | 4-digit zero-padded task ID (e.g., `"0001"`) |
| `depends_on` | Array | Task IDs that must complete before this task can start |
| `blocks` | Array | Task IDs waiting on this task (inverse of `depends_on`) |

Rules: list only direct dependencies (Manager calculates transitive closure), use `[]` for no dependencies, `blocks` should be the inverse of `depends_on`. Circular dependencies are detected at runtime and trigger `TASK_BLOCKED`.

#### TODO.md

**Location:** `.ralph/tasks/TODO.md`

Master task checklist with a strict grammar parsed by the Manager at each loop iteration.

| Line Type | Format | Example |
|-----------|--------|---------|
| Incomplete task | `- [ ] XXXX: Task title` | `- [ ] 0003: Implement init script` |
| Complete task | `- [x] XXXX: Task title` | `- [x] 0001: Create directory structure` |
| Abort | `ABORT: HELP NEEDED FOR TASK XXXX: reason` | `ABORT: HELP NEEDED FOR TASK 0003: Cannot resolve dependency conflict` |
| Completion sentinel | `ALL TASKS COMPLETE, EXIT LOOP` | (exact match, case-sensitive) |
| Group header | `# Phase N: Name` | `# Phase 1: Foundation` |

Task IDs must be 4-digit zero-padded (`0001`-`9999`). Group headers are informational only. Task order is informational; the Manager selects tasks based on `deps-tracker.yaml`.

#### TASK.md

**Location:** `.ralph/tasks/XXXX/TASK.md` (one per task)

| Section | Required | Description |
|---------|----------|-------------|
| `# Task XXXX: Title` | Yes | Task header with 4-digit ID |
| `## Description` | Yes | What needs to be done |
| `## Acceptance Criteria` | Yes | Testable requirements (checkbox list) |
| `## Implementation Notes` | No | Technical guidance, files to modify, validation steps |
| `## Dependencies` | No | Technical dependencies (packages, libraries, APIs) |
| `## Metadata` | No | Complexity estimate and attempt limits |
| `## Notes` | No | Additional context, edge cases |

Complexity levels: XS (0-15 min), S (15-30 min), M (30-60 min), L (1-2 hours). Default max attempts per task: **10**.

#### RULES.md

**Location:** Any directory in the project tree.

Hierarchical configuration files that define code patterns, conventions, and constraints. Agents walk up the directory tree collecting `RULES.md` files.

- **Read order:** Root to leaf (deepest rules take precedence on conflicts).
- **Stop marker:** A `RULES.md` containing `IGNORE_PARENT_RULES` stops inheritance from parent directories.

Standard sections: Code Patterns, Common Pitfalls, Standard Approaches, Auto-Discovered Patterns.

### Agent Templates

Agent templates are Markdown files with YAML frontmatter. The format differs between OpenCode and Claude Code.

#### Format Comparison

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Tools format | Key-value booleans (`read: true`) | Comma-separated string (`Read, Write, Bash`) |
| Permission block | Required (`ask`/`allow`/`deny` per tool) | Not used |
| `name` field | Required (agent identifier) | Required |
| `model` field | `""` (empty string = use default) | Optional (`inherit` = use default) |
| `mode` field | `subagent` or `all` (role-dependent) | Not used |

#### Permission Levels (OpenCode)

| Level | Behavior |
|-------|----------|
| `ask` | Prompt user for approval before executing |
| `allow` | Automatically allow without confirmation |
| `deny` | Never allow the operation |

#### Available Tools

| Tool (OpenCode) | Tool (Claude Code) | Description |
|-----------------|-------------------|-------------|
| `read` | `Read` | Read files from filesystem |
| `write` | `Write` | Write files to filesystem |
| `grep` | `Grep` | Search file contents |
| `glob` | `Glob` | Find files by pattern |
| `bash` | `Bash` | Execute shell commands |
| `webfetch` | `Web` | Retrieve web content |
| `question` | `Question` | Ask user questions |
| `edit` | (via Write) | Edit file contents |
| `sequentialthinking` | `SequentialThinking` | Structured analysis |

### MCP Servers

Five MCP servers are installed in the container:

| Server | Package | Purpose |
|--------|---------|---------|
| `sequentialthinking` | `@modelcontextprotocol/server-sequential-thinking` | Structured reasoning and analysis |
| `fetch` | `python -m mcp_server_fetch` | URL content retrieval |
| `crawl4ai` | `python -m crawler_agent.mcp_server` | Web crawling and content extraction |
| `searxng` | `mcp-searxng` | Web search via SearXNG |
| `playwright` | `@playwright/mcp@latest` | Browser automation |

#### Platform Configuration Differences

| Property | OpenCode | Claude Code |
|----------|----------|-------------|
| Config file | `~/.config/opencode/opencode.json` | `~/.claude.json` or `.mcp.json` |
| Config key | `mcp` | `mcpServers` |
| Server type | `"type": "local"` required | Not used |
| Command format | `"command": ["cmd", "arg1", "arg2"]` (single array) | `"command": "cmd"` + `"args": ["arg1", "arg2"]` (split) |
| Environment key | `environment` | `env` |

### Environment Variables

All environment variables in one table, grouped by context.

#### Ralph Loop

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TOOL` | `opencode` | AI tool selection (`opencode` or `claude`) |
| `RALPH_MAX_ITERATIONS` | `100` | Maximum loop iterations before stopping |
| `RALPH_BACKOFF_BASE` | `2` | Exponential backoff base delay in seconds |
| `RALPH_BACKOFF_MAX` | `60` | Maximum backoff delay cap in seconds |
| `RALPH_MANAGER_MODEL` | (empty) | Override the Manager agent's model |

#### Container

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/proj` | Container workspace path |
| `VIRTUAL_ENV` | `/opt/venv` | Python virtual environment path |
| `DISABLE_WELCOME` | (unset) | Set to `1` to suppress the welcome message |
| `DISABLE_TMUX` | (unset) | Set to `1` to skip tmux auto-attach |
| `ENABLE_DIND` | (unset) | Set to `true` for Docker-in-Docker support. Also installs `kubectl`, `helm`, and `kind` at startup. |
| `UV_USE_IO_URING` | `0` | Disable io_uring for compatibility in containers |
| `GIT_AUTHOR_NAME` | (from host) | Forwarded from host for git identity |
| `GIT_AUTHOR_EMAIL` | (from host) | Forwarded from host for git identity |

#### Docker Compose

| Variable | Default | Description |
|----------|---------|-------------|
| `PLAYWRIGHT_MCP_HEADLESS` | `1` | Run Playwright in headless mode |
| `PLAYWRIGHT_MCP_BROWSER` | `chromium` | Default Playwright browser |
| `PLAYWRIGHT_MCP_NO_SANDBOX` | `1` | Disable browser sandbox (required in container) |
| `PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS` | `1` | Allow Playwright file access |
| `OPENCODE_ENABLE_EXA` | `false` | Disable Exa web search |
| `SEARXNG_URL` | (empty) | SearXNG search service URL |

#### ralph-filter-output.sh

| Variable | Default | Description |
|----------|---------|-------------|
| `SHOW_TEXT` | `true` | Show text responses |
| `SHOW_TOKENS` | `true` | Show token statistics |
| `SHOW_TOOLS` | `true` | Show tool usage |
| `SHOW_COST` | `true` | Show cost information |
| `SHOW_SIGNALS` | `true` | Show task signals |
| `COMPACT` | `false` | Compact output format |

---

## Exit Codes

| Command | 0 | 1 | 130 |
|---------|---|---|-----|
| `jeeves.ps1` | Success | Error | -- |
| `ralph-init.sh` | Success | Error | -- |
| `ralph-loop.sh` | Success | Error | Interrupted (SIGINT) |
| `sync-agents.sh` | Success | Error | -- |
| `task-branch-create.sh` | Success | Error | -- |

---

## See Also

- [troubleshooting.md](troubleshooting.md) -- Diagnosing and resolving common issues
- [guide.md](guide.md) -- Step-by-step workflows
