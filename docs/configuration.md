# Configuration Reference

This document covers all configuration for the Jeeves container and the Ralph Loop system. It is organized into Docker configuration, Ralph project configuration, agent templates, MCP servers, and environment variables.

For command usage, see [commands.md](commands.md). For troubleshooting, see [troubleshooting.md](troubleshooting.md).

---

## Docker Configuration

### Dockerfile Build Stages

The `Dockerfile.jeeves` uses three build stages:

| Stage | Base | Purpose |
|-------|------|---------|
| `base` | `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04` | System packages, Python, Node.js |
| `opencode-builder` | `base` | Builds OpenCode from source (optional desktop binaries) |
| `runtime` | `base` | Final container with user, tools, and configuration |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `UID` | `1000` | Container user UID (mapped from host) |
| `GID` | `1000` | Container user GID (mapped from host) |
| `BUILD_DESKTOP` | (unset) | Include desktop binaries in OpenCode build |
| `INSTALL_CLAUDE_CODE` | `false` | Install Claude Code CLI in the container |

### Docker Compose

Docker Compose files are generated dynamically in the `.tmp/` directory by `jeeves.ps1`. The generated configuration includes:

```yaml
services:
  jeeves:
    build:
      context: ..
      dockerfile: Dockerfile.jeeves
    image: jeeves:latest
    runtime: nvidia
    shm_size: "2gb"
    gpus: all
    environment:
      - NVIDIA_DRIVER_CAPABILITIES=all
      - CUDA_VISIBLE_DEVICES=all
      - PLAYWRIGHT_MCP_HEADLESS=1
      - PLAYWRIGHT_MCP_BROWSER=chromium
      - PLAYWRIGHT_MCP_NO_SANDBOX=1
      - PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1
      - OPENCODE_ENABLE_EXA=false
    volumes:
      - $(pwd):/proj:rw
      - ~/.claude:/home/jeeves/.claude:rw
      - ~/.config/opencode:/home/jeeves/.config/opencode:rw
      - ~/.opencode:/home/jeeves/.opencode:rw
    ports:
      - "3333:3333"
    networks:
      - jeeves-network

networks:
  jeeves-network:
    driver: bridge
```

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| Current working directory | `/proj` | Project workspace (read-write) |
| `~/.claude` | `/home/jeeves/.claude` | Claude Code configuration and settings |
| `~/.config/opencode` | `/home/jeeves/.config/opencode` | OpenCode configuration |
| `~/.opencode` | `/home/jeeves/.opencode` | OpenCode agent directory |

### Container Details

| Property | Value |
|----------|-------|
| User | `jeeves` (non-root) |
| UID/GID | Configurable via build args (default 1000:1000) |
| Port | 3333 |
| GPU | NVIDIA runtime, all GPUs |
| Shared memory | 2 GB |
| Network | `jeeves-network` (bridge driver) |

---

## Ralph Project Configuration

### Directory Structure

Running `ralph-init.sh` creates the `.ralph/` directory in your project root:

```
.ralph/
├── config/
│   ├── agents.yaml              # Agent-to-model mapping
│   └── deps-tracker.yaml        # Task dependency graph
├── prompts/
│   └── ralph-prompt.md          # Manager invocation instructions
├── specs/
│   └── PRD-*.md                 # Product Requirements Documents
├── tasks/
│   ├── TODO.md                  # Master task checklist
│   ├── done/                    # Completed task folders (preserved)
│   └── XXXX/                    # Individual task folders
│       ├── TASK.md              # Task definition
│       ├── activity.md          # Execution log
│       └── attempts.md          # Attempt history
└── logs/
    └── ralph-loop-YYYYMMDD-HHMMSS.log
```

### Configuration Precedence

Values are resolved in this priority order (highest to lowest):

| Priority | Source | Example |
|----------|--------|---------|
| 1 (highest) | CLI flags | `ralph-loop.sh --tool claude --max-iterations 50` |
| 2 | Environment variables | `export RALPH_TOOL=claude` |
| 3 | Project configuration | `.ralph/config/agents.yaml` |
| 4 | User-global configuration | `~/.config/ralph/agents.yaml` |
| 5 (lowest) | Default templates | `jeeves/Ralph/templates/config/` |

---

## agents.yaml

**Location:** `.ralph/config/agents.yaml`
**Template:** `jeeves/Ralph/templates/config/agents.yaml.template`

Maps each agent type to specific LLM models per tool (OpenCode or Claude Code), enabling per-agent model selection for performance and cost optimization.

### Schema

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

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `agents` | Object | Yes | Root container for all agent definitions |
| `<agent_type>` | Object | Yes | One entry per agent type |
| `description` | String | Yes | Human-readable description of the agent's role |
| `preferred` | Object | Yes | Primary model for each tool |
| `preferred.opencode` | String | Yes | Model for OpenCode (`""` = use default/inherited model) |
| `preferred.claude` | String | Yes | Model for Claude Code |
| `fallback` | Object | Yes | Fallback model if preferred is unavailable |
| `fallback.opencode` | String | Yes | Fallback for OpenCode (`""` = use default/inherited model) |
| `fallback.claude` | String | Yes | Fallback for Claude Code |

### Empty String for OpenCode

The template uses `""` (empty string) for all OpenCode model values. An empty string means "use the default/inherited model for the tool." This is the recommended approach for OpenCode, as it allows the tool to select the most appropriate available model.

### Agent Types (10 total)

| Agent Type | Description | Claude Preferred | Claude Fallback |
|------------|-------------|------------------|-----------------|
| `manager` | Loop orchestrator - selects tasks, invokes workers, manages state | claude-opus-4.5 | claude-sonnet-4.5 |
| `architect` | System design and architecture tasks | claude-opus-4.5 | claude-sonnet-4.5 |
| `developer` | Code implementation and debugging | claude-sonnet-4.5 | claude-sonnet-4.5 |
| `ui-designer` | UI/UX design and implementation | claude-opus-4.5 | claude-sonnet-4.5 |
| `tester` | Testing and quality assurance | claude-sonnet-4.5 | claude-sonnet-4.5 |
| `researcher` | Research, analysis, and documentation | claude-opus-4.5 | claude-sonnet-4.5 |
| `writer` | Documentation and content creation | claude-sonnet-4.5 | claude-sonnet-4.5 |
| `decomposer` | Task decomposition, TODO management, agent coordination | claude-opus-4.5 | claude-sonnet-4.5 |
| `decomposer-architect` | System design, patterns, integration design for PRD decomposition | claude-opus-4.5 | claude-sonnet-4.5 |
| `decomposer-researcher` | Investigation, documentation analysis, knowledge synthesis for PRD decomposition | claude-opus-4.5 | claude-sonnet-4.5 |

### Complete Default Configuration

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

  architect:
    description: "System design and architecture tasks"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: ""
      claude: claude-sonnet-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  ui-designer:
    description: "UI/UX design and implementation"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  tester:
    description: "Testing and quality assurance"
    preferred:
      opencode: ""
      claude: claude-sonnet-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  researcher:
    description: "Research, analysis, and documentation"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  writer:
    description: "Documentation and content creation"
    preferred:
      opencode: ""
      claude: claude-sonnet-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  decomposer:
    description: "Task decomposition, TODO management, agent coordination"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  decomposer-architect:
    description: "Specialized for system design, patterns, best practices, integration design, verification and validation for PRD decomposition"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5

  decomposer-researcher:
    description: "Specialized for investigation, documentation analysis, and knowledge synthesis for PRD decomposition"
    preferred:
      opencode: ""
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5
```

### Model Selection at Runtime

1. The user specifies a tool via `--tool opencode`, `--tool claude`, or the `RALPH_TOOL` environment variable (default: `opencode`).
2. Ralph reads `agents.yaml`.
3. For each agent invocation, Ralph looks up the agent type, retrieves `preferred.<tool>`, and uses that model.
4. If the preferred value is empty or unavailable, Ralph falls back to `fallback.<tool>`.

### Model Recommendations by Agent Type

| Agent Type | Recommended Tier | Rationale |
|------------|-----------------|-----------|
| manager | Tier 1 (opus) | Coordination requires broad reasoning |
| architect | Tier 1 (opus) | Design decisions require strong trade-off analysis |
| developer | Tier 2 (sonnet) | Good balance of coding proficiency and cost |
| ui-designer | Tier 1 (opus) | Visual design requires attention to detail |
| tester | Tier 2 (sonnet) | Detail-oriented but high-volume work |
| researcher | Tier 1 (opus) | Analysis depth and broad knowledge |
| writer | Tier 2 (sonnet) | Clear prose, cost-effective for volume |
| decomposer | Tier 1 (opus) | Complex requirement breakdown |

### Syncing Agent Configuration

After modifying `agents.yaml`, run `sync-agents` to propagate model changes to agent template files. See [commands.md](commands.md) for full usage.

**What sync-agents does:**

1. Reads `agents.yaml` and validates YAML syntax.
2. Searches for agent `.md` files in these paths (priority order):
   - `.ralph/agents/`
   - `.opencode/agents/`
   - `.claude/agents/`
   - `~/.config/opencode/agents/`
   - `~/.claude/agents/`
3. For each agent file found:
   - Reads current frontmatter.
   - Gets model from `preferred.<tool>` in `agents.yaml`.
   - If preferred is empty/null, falls back to `fallback.<tool>`.
   - Updates the `model:` field in frontmatter.
   - Creates a backup before modification.
4. The script is idempotent; re-running with the same configuration makes no unnecessary changes.

---

## deps-tracker.yaml

**Location:** `.ralph/config/deps-tracker.yaml`
**Template:** `jeeves/Ralph/templates/config/deps-tracker.yaml.template`

Tracks task dependencies and blocking relationships so the Manager can determine which tasks are unblocked and ready for execution.

### Schema

```yaml
tasks:
  "<task_id>":
    depends_on: [<task_id>, ...]
    blocks: [<task_id>, ...]
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tasks` | Object | Yes | Root container for all task dependencies |
| `<task_id>` | String | Yes | 4-digit zero-padded task ID (e.g., `"0001"`) |
| `depends_on` | Array | Yes | Task IDs that must complete before this task can start |
| `blocks` | Array | Yes | Task IDs that are waiting on this task (inverse of `depends_on`) |

### Example

```yaml
tasks:
  "0001":
    depends_on: []
    blocks: ["0003"]

  "0002":
    depends_on: []
    blocks: ["0003"]

  "0003":
    depends_on: ["0001", "0002"]
    blocks: ["0004"]

  "0004":
    depends_on: ["0003"]
    blocks: []
```

### Rules

- Task IDs are 4-digit zero-padded strings (`"0001"` through `"9999"`).
- List only direct dependencies, not transitive ones. The Manager calculates transitive closure automatically.
- The `blocks` field should be the inverse of `depends_on` (maintained for visualization and debugging).
- Use `[]` for tasks with no dependencies or nothing blocked.
- Circular dependencies are detected at runtime and trigger `TASK_BLOCKED`, terminating the loop.

---

## TODO.md

**Location:** `.ralph/tasks/TODO.md`

Master task checklist with a strict grammar that the Manager parses at each loop iteration.

### Grammar

| Line Type | Format | Example |
|-----------|--------|---------|
| Incomplete task | `- [ ] XXXX: Task title` | `- [ ] 0003: Implement init script` |
| Complete task | `- [x] XXXX: Task title` | `- [x] 0001: Create directory structure` |
| Abort | `ABORT: HELP NEEDED FOR TASK XXXX: reason` | `ABORT: HELP NEEDED FOR TASK 0003: Cannot resolve dependency conflict` |
| Completion sentinel | `ALL TASKS COMPLETE, EXIT LOOP` | (exact match, case-sensitive) |
| Group header | `# Phase N: Name` | `# Phase 1: Foundation` |

### Rules

- Task IDs must be 4-digit zero-padded (`0001`-`9999`).
- Group headers (`# ...`) are informational only and do not affect execution.
- Task order in the file is informational; the Manager selects tasks based on `deps-tracker.yaml`.
- The abort and completion sentinel formats must match exactly (case-sensitive).
- No commentary lines other than group headers.

### Example

```markdown
# Phase 1: Foundation
- [x] 0001: Create directory structure
- [x] 0002: Set up utilities
- [ ] 0003: Implement init script

# Phase 2: Core
- [ ] 0004: Implement main loop
- [ ] 0005: Add signal handling
```

---

## TASK.md

**Location:** `.ralph/tasks/XXXX/TASK.md` (one per task)
**Template:** `jeeves/Ralph/templates/task/TASK.md.template`

Defines an individual task with acceptance criteria, implementation guidance, and metadata.

### Sections

| Section | Required | Description |
|---------|----------|-------------|
| `# Task XXXX: Title` | Yes | Task header with 4-digit ID |
| `## Description` | Yes | What needs to be done |
| `## Acceptance Criteria` | Yes | Testable requirements (checkbox list) |
| `## Implementation Notes` | No | Technical guidance, files to modify, validation steps |
| `## Dependencies` | No | Technical dependencies (packages, libraries, APIs) |
| `## Metadata` | No | Complexity estimate and attempt limits |
| `## Notes` | No | Additional context, edge cases |

### Complexity Levels

| Level | Time Estimate | Examples |
|-------|---------------|----------|
| XS | 0-15 min | Trivial fixes, copy operations |
| S | 15-30 min | Simple scripts, straightforward implementation |
| M | 30-60 min | Multi-function, moderate complexity |
| L | 1-2 hours | Complex integrations, multiple systems |

### Default Max Attempts

The default maximum attempts per task is **10**, overridable in the `## Metadata` section.

---

## RULES.md

**Location:** Any directory in the project tree.

Hierarchical configuration files that define code patterns, conventions, and constraints. Agents walk up the directory tree collecting `RULES.md` files and apply them root-to-leaf (deeper files override shallower ones on conflict).

### Inheritance

- **Read order:** Root to leaf (deepest rules take precedence on conflicts).
- **Stop marker:** A `RULES.md` containing `IGNORE_PARENT_RULES` stops inheritance from parent directories.

### Standard Sections

| Section | Purpose |
|---------|---------|
| Code Patterns | Naming conventions, style rules, architectural patterns |
| Common Pitfalls | Known issues and how to avoid them |
| Standard Approaches | Preferred solutions for recurring problems |
| Auto-Discovered Patterns | Patterns agents have learned during execution |

---

## Agent Templates

Agent templates are Markdown files with YAML frontmatter. The frontmatter format differs between OpenCode and Claude Code.

### OpenCode Format

```yaml
---
name: agent-name
description: "What it does"
mode: all
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

### Claude Code Format

```yaml
---
name: agent-name
description: "What it does. Use when..."
tools: Read, Write, Grep, Glob, Bash, Web, SequentialThinking
model: inherit
---
```

### Key Differences

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Tools format | Key-value booleans | Comma-separated string |
| Permission block | Required (ask/allow/deny) | Not used |
| `model` field | Not used | Optional (`inherit` = use default) |
| `mode` field | `all` | Not used |

### Permission Levels (OpenCode)

| Level | Behavior |
|-------|----------|
| `ask` | Prompt user for approval before executing |
| `allow` | Automatically allow without confirmation |
| `deny` | Never allow the operation |

### Available Tools

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

---

## MCP Servers

Four MCP servers are installed in the container:

| Server | Package | Purpose |
|--------|---------|---------|
| `sequentialthinking` | `@modelcontextprotocol/server-sequential-thinking` | Structured reasoning and analysis |
| `fetch` | `python -m mcp_server_fetch` | URL content retrieval |
| `searxng` | `mcp-searxng` | Web search via SearXNG |
| `playwright` | `@playwright/mcp@latest` | Browser automation |

### OpenCode MCP Configuration

**File:** `~/.config/opencode/opencode.json` (key: `mcp`)

```json
{
  "mcp": {
    "sequentialthinking": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "type": "local",
      "command": ["python", "-m", "mcp_server_fetch"]
    },
    "searxng": {
      "type": "local",
      "command": ["npx", "-y", "mcp-searxng"],
      "environment": {
        "SEARXNG_URL": "https://searxng.example.com"
      }
    },
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest", "--isolated", "--no-sandbox"],
      "environment": {
        "PLAYWRIGHT_MCP_HEADLESS": "true",
        "PLAYWRIGHT_MCP_BROWSER": "chromium"
      }
    }
  }
}
```

### Claude Code MCP Configuration

**File:** `~/.claude.json` or project-level `.mcp.json` (key: `mcpServers`)

```json
{
  "mcpServers": {
    "sequentialthinking": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": ["python", "-m", "mcp_server_fetch"]
    },
    "searxng": {
      "command": ["npx", "-y", "mcp-searxng"],
      "env": {
        "SEARXNG_URL": "https://searxng.example.com"
      }
    },
    "playwright": {
      "command": ["npx", "-y", "@playwright/mcp@latest", "--isolated", "--no-sandbox"],
      "env": {
        "PLAYWRIGHT_MCP_HEADLESS": "true",
        "PLAYWRIGHT_MCP_BROWSER": "chromium",
        "PLAYWRIGHT_MCP_NO_SANDBOX": "true",
        "PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS": "true"
      }
    }
  }
}
```

### Key Differences Between Platforms

| Property | OpenCode | Claude Code |
|----------|----------|-------------|
| Config key | `mcp` | `mcpServers` |
| Server type | `"type": "local"` required | Not used |
| Environment key | `environment` | `env` |

---

## Environment Variables

### Ralph Loop Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TOOL` | `opencode` | AI tool selection (`opencode` or `claude`) |
| `RALPH_MAX_ITERATIONS` | `100` | Maximum loop iterations before stopping |
| `RALPH_BACKOFF_BASE` | `2` | Exponential backoff base delay in seconds |
| `RALPH_BACKOFF_MAX` | `60` | Maximum backoff delay cap in seconds |
| `RALPH_MANAGER_MODEL` | (empty) | Override the Manager agent's model |

### Container Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKSPACE` | `/proj` | Container workspace path |
| `VIRTUAL_ENV` | `/opt/venv` | Python virtual environment path |
| `DISABLE_WELCOME` | (unset) | Set to `1` to suppress the welcome message |
| `DISABLE_TMUX` | (unset) | Set to `1` to skip tmux auto-attach |
| `ENABLE_DIND` | (unset) | Set to `true` for Docker-in-Docker support |

### Docker Compose Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PLAYWRIGHT_MCP_HEADLESS` | `1` | Run Playwright in headless mode |
| `PLAYWRIGHT_MCP_BROWSER` | `chromium` | Default Playwright browser |
| `PLAYWRIGHT_MCP_NO_SANDBOX` | `1` | Disable browser sandbox (required in container) |
| `PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS` | `1` | Allow Playwright file access |
| `OPENCODE_ENABLE_EXA` | `false` | Disable Exa web search |
| `SEARXNG_URL` | (empty) | SearXNG search service URL |

---

## .gitignore for Ralph Projects

The `ralph-init.sh` script copies a `.gitignore` template to your project root. Recommended entries:

```gitignore
# Ralph active task data (ephemeral)
.ralph/tasks/
.ralph/tasks/*/activity.md
.ralph/tasks/*/attempts.md

# Ralph temporary files and logs
.ralph/logs/
.ralph/tmp/
.ralph/cache/
.ralph/sessions/
.ralph/state/
```

Optionally track completed tasks for project history by adding `!.ralph/tasks/done/`.

---

## Template Locations

All configuration templates live in `jeeves/Ralph/templates/`:

| Template | Path (relative to templates/) |
|----------|-------------------------------|
| agents.yaml | `config/agents.yaml.template` |
| deps-tracker.yaml | `config/deps-tracker.yaml.template` |
| TODO.md | `config/TODO.md.template` |
| .gitignore | `config/.gitignore.template` |
| TASK.md | `task/TASK.md.template` |
| activity.md | `task/activity.md.template` |
| attempts.md | `task/attempts.md.template` |
| ralph-prompt.md | `prompts/ralph-prompt.md.template` |

---

## Common Configuration Scenarios

### Switching Between OpenCode and Claude Code

```bash
# CLI flag (highest priority)
ralph-loop.sh --tool claude

# Environment variable
export RALPH_TOOL=claude
ralph-loop.sh

# One-shot
RALPH_TOOL=claude ralph-loop.sh
```

### Adjusting Model Preferences

Edit `.ralph/config/agents.yaml`, then sync:

```bash
sync-agents --show   # Preview changes
sync-agents          # Apply changes
```

### Customizing Retry Behavior

Retry policy is controlled via environment variables (no config file):

```bash
# Faster retries
export RALPH_BACKOFF_BASE=1
export RALPH_BACKOFF_MAX=30

# Slower retries
export RALPH_BACKOFF_BASE=10
export RALPH_BACKOFF_MAX=300
```

### Adding Custom MCP Servers

Add entries to the appropriate configuration file for your tool:

**OpenCode** (`~/.config/opencode/opencode.json`):
```json
{
  "mcp": {
    "your-server": {
      "type": "local",
      "command": ["your-server-command", "--arg1"],
      "environment": {
        "CUSTOM_VAR": "value"
      }
    }
  }
}
```

**Claude Code** (`~/.claude.json` or `.mcp.json`):
```json
{
  "mcpServers": {
    "your-server": {
      "command": ["your-server-command", "--arg1"],
      "env": {
        "CUSTOM_VAR": "value"
      }
    }
  }
}
```

---

## See Also

- [commands.md](commands.md) -- Command reference for `jeeves.ps1`, `ralph-loop.sh`, `sync-agents`, and other scripts
- [troubleshooting.md](troubleshooting.md) -- Diagnosing and resolving common issues
- [how-to-guide.md](how-to-guide.md) -- Step-by-step workflows
