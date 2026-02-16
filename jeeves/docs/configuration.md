# Ralph Configuration Guide

## Overview

Ralph uses a configuration-first approach where all behavior is controlled through YAML and Markdown files. The configuration philosophy emphasizes:

1. **Explicit over Implicit**: All settings are visible and editable
2. **Version Controlled**: Configuration files are tracked in git (except ephemeral task data)
3. **Tool Agnostic**: Same configuration works across OpenCode and Claude Code
4. **Extensible**: Easy to add new agents, models, and behaviors

### File Organization

Configuration files are organized in the `.ralph/` directory:

```
.ralph/
├── config/                      # Configuration files
│   ├── agents.yaml             # Agent-to-model mapping
│   └── (retry_policy.yaml)     # NOT IMPLEMENTED
├── prompts/                    # Prompt templates
│   └── ralph-prompt.md         # Manager invocation instructions
├── tasks/                      # Task management
│   ├── TODO.md                 # Master task checklist
│   ├── deps-tracker.yaml       # Dependency tracking
│   └── 0001/                   # Individual task folders
│       ├── TASK.md
│       ├── activity.md
│       └── attempts.md
└── specs/                      # Product specifications
    └── PRD-*.md
```

---

## agents.yaml

**Location:** `.ralph/config/agents.yaml`

**Purpose:** Maps agent types to specific LLM models per tool, enabling optimal performance and cost efficiency by using appropriate models for each agent type.

### Full Schema

```yaml
agents:
  <agent_type>:
    description: "Human-readable description of agent purpose"
    preferred:
      opencode: <model_name>
      claude: <model_name>
    fallback:
      opencode: <model_name>
      claude: <model_name>
```

### Schema Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `agents` | Object | Yes | Root container for all agent definitions |
| `<agent_type>` | Object | Yes | Individual agent configuration (one per agent type) |
| `description` | String | Yes | Human-readable description of the agent's role |
| `preferred` | Object | Yes | Preferred models for each tool |
| `preferred.opencode` | String | Yes | Model name for OpenCode (use `inherit` for default) |
| `preferred.claude` | String | Yes | Model name for Claude Code |
| `fallback` | Object | Yes | Fallback models if preferred unavailable |
| `fallback.opencode` | String | Yes | Fallback model for OpenCode |
| `fallback.claude` | String | Yes | Fallback model for Claude Code |

### Agent Types

Ralph supports 8 agent types:

| Agent Type | Purpose | Typical Model |
|------------|---------|---------------|
| `manager` | Orchestrates task execution, manages state, handles handoffs | claude-opus-4.5 |
| `architect` | System design, API design, database schema | claude-opus-4.5 |
| `developer` | Code implementation and debugging | claude-sonnet-4.5 |
| `ui-designer` | UI/UX design and implementation | claude-opus-4.5 |
| `tester` | Testing and quality assurance | claude-sonnet-4.5 |
| `researcher` | Research, analysis, and documentation | claude-opus-4.5 |
| `writer` | Documentation and content creation | claude-sonnet-4.5 |
| `decomposer` | Task decomposition, TODO management, agent coordination | claude-opus-4.5 |

### Example Configuration

```yaml
agents:
  manager:
    description: "Ralph Loop Manager - orchestrates task execution, manages state, handles handoffs"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  tester:
    description: "Testing and quality assurance"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5
```

### Important Notes

- **Model Updates**: You are responsible for updating model names as providers change
- **Tool Selection**: The `--tool` flag or `RALPH_TOOL` environment variable determines which models are used
- **Fallback Models**: Used automatically if the preferred model is unavailable or errors out
- **Inherit Value**: Use `inherit` to use the default model for that tool (uses OpenCode/Claude's default selection)
- **Sync Required**: After modifying `agents.yaml`, run `sync-agents` to update agent definition files

---

## deps-tracker.yaml

**Location:** `.ralph/tasks/deps-tracker.yaml`

**Purpose:** Tracks task dependencies and blocking relationships for intelligent task execution ordering.

### Format

```yaml
tasks:
  <task_id>:
    depends_on: [<task_id>, <task_id>]
    blocks: [<task_id>, <task_id>]
```

### Schema Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tasks` | Object | Yes | Root container for all task dependencies |
| `<task_id>` | Object | Yes | Individual task entry (4-digit zero-padded ID) |
| `depends_on` | Array | Yes | List of task IDs this task depends on (must complete first) |
| `blocks` | Array | Yes | List of task IDs blocked by this task (inverse of depends_on) |

### Task ID Format

- **Range:** 0001 to 9999
- **Format:** 4-digit zero-padded (e.g., 0001, 0042, 0999)
- **Maximum:** 9999 tasks per project

### Example

```yaml
tasks:
  # Independent task - can start immediately
  0001:
    depends_on: []
    blocks: [0003]

  # Another independent task
  0002:
    depends_on: []
    blocks: [0003]

  # Dependent task - requires 0001 and 0002
  0003:
    depends_on: [0001, 0002]
    blocks: [0004]

  # Single dependency
  0004:
    depends_on: [0003]
    blocks: []
```

### Important Notes

- **Direct Dependencies Only**: List only immediate dependencies, not transitive ones
- **Manager Calculates Transitive Closure**: The Manager automatically calculates full dependency chains
- **Circular Dependencies Detected**: Cycles trigger `TASK_BLOCKED` and terminate the loop
- **Empty Arrays**: Use `[]` for tasks with no dependencies or nothing blocked
- **Bidirectional Consistency**: The `blocks` field should be the inverse of `depends_on` (for visualization/debugging)

---

## retry_policy.yaml

**Status: NOT IMPLEMENTED**

**Location:** `.ralph/config/retry_policy.yaml` (file does not exist)

**Purpose:** Configure retry behavior and backoff strategy for task iterations.

### Note

This configuration file is **not currently implemented** in the Ralph Loop. The retry behavior is hardcoded in `ralph-loop.sh` using the following environment variables:

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `RALPH_BACKOFF_BASE` | 2 | Base delay in seconds |
| `RALPH_BACKOFF_MAX` | 60 | Maximum delay cap in seconds |

### Proposed Schema (if implemented)

```yaml
retry_policy:
  strategy: "exponential_backoff"  # or "fixed"
  base_delay: 5                     # seconds
  max_delay: 60                     # cap at 1 minute
  jitter: true                      # add randomness
```

### Proposed Strategies

- **exponential_backoff**: Double delay each retry (with optional jitter)
- **fixed**: Constant delay between iterations

### Current Workaround

Use environment variables to control retry behavior:

```bash
export RALPH_BACKOFF_BASE=5
export RALPH_BACKOFF_MAX=120
ralph-loop.sh
```

---

## TODO.md

**Location:** `.ralph/tasks/TODO.md`

**Purpose:** Master task checklist using strict grammar for tracking task completion status.

### Strict Grammar Rules

TODO.md uses a strict parsing grammar. Only these formats are valid:

#### 1. Task Lines

Two formats only:

```markdown
- [ ] 0001: Task title here      # Incomplete task
- [x] 0001: Task title here      # Complete task
```

**Rules:**
- Must start with `- [ ]` (incomplete) or `- [x]` (complete)
- Task ID must be 4-digit zero-padded (0001-9999)
- Followed by colon and space: `: `
- Task title on same line
- No additional text after task title on the same line

#### 2. Abort Lines

```markdown
ABORT: HELP NEEDED FOR TASK 0001: Brief explanation of the blockage
```

**Rules:**
- Must start with exactly: `ABORT: HELP NEEDED FOR TASK `
- Followed by 4-digit task ID
- Followed by colon and space: `: `
- Brief explanation on same line

#### 3. Completion Sentinel

```markdown
ALL TASKS COMPLETE, EXIT LOOP
```

**Rules:**
- Must match exactly (case-sensitive)
- No additional text on same line
- Signals loop termination when all tasks done

#### 4. Group Headers

```markdown
# Phase 1: Foundation
# Category Name
```

**Rules:**
- Start with `# `
- Informational only - no functionality
- Used for organization and readability

### Parsing Patterns

The Manager agent uses these grep patterns:

```bash
# Incomplete tasks
grep "^- \[ \]" TODO.md

# Complete tasks
grep "^- \[x\]" TODO.md

# Aborted tasks
grep "^ABORT:" TODO.md

# All done sentinel
grep "^ALL TASKS COMPLETE" TODO.md
```

### Example

```markdown
# Phase 1: Foundation
- [x] 0001: Create directory structure
- [x] 0002: Set up utilities
- [ ] 0003: Implement init script

# Phase 2: Core
- [ ] 0004: Implement main loop
- [ ] 0005: Add signal handling

ABORT: HELP NEEDED FOR TASK 0003: Cannot resolve dependency conflict
```

### Important Notes

- **Task Order is Informational**: The order of tasks in TODO.md does not affect execution order
- **Manager Selects Dynamically**: Tasks are selected based on deps-tracker.yaml, not TODO.md order
- **Grouping is Informational**: Phase/category headers are for human readability only
- **No Comments**: Do not add commentary lines (except group headers)
- **Do Not Modify Formats**: The abort/completion formats must match exactly

---

## TASK.md Template

**Location:** `.ralph/tasks/XXXX/TASK.md` (per task)

**Purpose:** Define individual tasks with acceptance criteria, implementation notes, and metadata.

### Standard Sections

```markdown
# Task XXXX: [Title]

## Description
[Detailed description of what needs to be implemented]

## Acceptance Criteria
- [ ] Criterion 1: Specific, testable requirement
- [ ] Criterion 2: Another specific requirement
- [ ] All tests pass (defined per task type)
- [ ] No scope creep (only what was requested)

## Implementation Notes
[Specific technical details, patterns to follow, files to modify]

### Files to Create/Modify
- `/path/to/file1` - Purpose
- `/path/to/file2` - Purpose

### Technical Details
[Any specific algorithms, data structures, APIs, or patterns]

### Validation Steps
```bash
# Commands to verify implementation
command1
command2
```

## Dependencies
[Technical dependencies only - packages, libraries, external resources]
- Package/Library: [Purpose - worker should self-resolve]
- External API: [Purpose]

Note: Task dependencies are tracked in deps-tracker.yaml, not here.

## Metadata
- **Estimated Complexity**: [XS/S/M/L]
  - XS: 0-15 min (trivial fixes, copy operations)
  - S: 15-30 min (simple scripts, straightforward impl)
  - M: 30-60 min (multi-function, moderate complexity)
  - L: 1-2 hours (complex integrations)
- **Max Attempts**: [default: 10, override if needed]

## Notes
[Additional context, edge cases, or special considerations]
```

### Required Sections

| Section | Required | Description |
|---------|----------|-------------|
| `# Task XXXX: Title` | Yes | Task header with 4-digit ID |
| `## Description` | Yes | What needs to be done |
| `## Acceptance Criteria` | Yes | Testable requirements |
| `## Implementation Notes` | No | Technical guidance |
| `## Dependencies` | No | Technical dependencies (not task deps) |
| `## Metadata` | No | Complexity and attempt limits |
| `## Notes` | No | Additional context |

### Complexity Levels

| Level | Time | Examples |
|-------|------|----------|
| XS | 0-15 min | Trivial fixes, copy operations |
| S | 15-30 min | Simple scripts, straightforward implementation |
| M | 30-60 min | Multi-function, moderate complexity |
| L | 1-2 hours | Complex integrations, multiple systems |

---

## .gitignore Configuration

**Location:** Project root `.gitignore`

**Purpose:** Exclude ephemeral Ralph data from version control.

### Recommended Entries

```gitignore
# Ralph Loop .gitignore Template
# Copy this file to your project root as .gitignore

# Ralph active task data (ephemeral, should not be tracked)
.ralph/tasks/
.ralph/tasks/*/activity.md
.ralph/tasks/*/attempts.md

# Optional: Track completed tasks for project history
# Uncomment the following line if you want to track completed tasks
# !.ralph/tasks/done/

# Ralph temporary files and logs
.ralph/logs/
.ralph/tmp/
.ralph/cache/

# Agent session files (temporary)
.ralph/sessions/
.ralph/state/
```

### Rationale

| Pattern | Purpose |
|---------|---------|
| `.ralph/tasks/` | Exclude entire tasks directory (ephemeral execution data) |
| `.ralph/tasks/*/activity.md` | Exclude activity.md files in task subdirectories |
| `.ralph/tasks/*/attempts.md` | Exclude attempts.md files in task subdirectories |
| `!.ralph/tasks/done/` | Include done/ folder for historical record (optional) |
| `.ralph/logs/` | Exclude log files |
| `.ralph/tmp/` | Exclude temporary files |
| `.ralph/cache/` | Exclude cache files |
| `.ralph/sessions/` | Exclude session state |
| `.ralph/state/` | Exclude runtime state |

### Template Location

The `.gitignore` template is located at:
`/proj/jeeves/Ralph/templates/config/.gitignore.template`

This template is copied to the project root by `ralph-init.sh`.

---

## Configuration Precedence

Configuration values are resolved in this priority order (highest to lowest):

1. **CLI Flags** (highest priority)
   - Example: `ralph-loop.sh --tool claude --max-iterations 50`

2. **Environment Variables**
   - Example: `export RALPH_TOOL=claude`

3. **Project Configuration Files**
   - `.ralph/config/agents.yaml`
   - `.ralph/config/retry_policy.yaml` (if implemented)

4. **User-Global Configuration**
   - `~/.config/ralph/agents.yaml` (if exists)

5. **Default Templates** (lowest priority)
   - `/proj/jeeves/Ralph/templates/config/`

### Precedence Example

```bash
# 1. CLI flag takes highest priority
ralph-loop.sh --tool claude --max-iterations 50

# 2. Environment variables override project config
export RALPH_TOOL=claude
export RALPH_MAX_ITERATIONS=200
ralph-loop.sh

# 3. Project configuration
# (from .ralph/config/agents.yaml)

# 4. User-global configuration
# (from ~/.config/ralph/agents.yaml)

# 5. Default templates
# (from /proj/jeeves/Ralph/templates/)
```

---

## Common Configuration Scenarios

### Switching Between OpenCode and Claude

**Option 1: CLI Flag**
```bash
# Use Claude
ralph-loop.sh --tool claude

# Use OpenCode (default)
ralph-loop.sh --tool opencode
```

**Option 2: Environment Variable**
```bash
# Set default for session
export RALPH_TOOL=claude
ralph-loop.sh

# Or one-shot
RALPH_TOOL=claude ralph-loop.sh
```

**Option 3: Edit agents.yaml**
```yaml
agents:
  developer:
    preferred:
      opencode: your-opencode-model
      claude: your-claude-model
```
Then run: `sync-agents --tool claude`

### Adjusting Model Preferences

Edit `.ralph/config/agents.yaml`:

```yaml
agents:
  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5
    fallback:
      opencode: grok-4.1
      claude: claude-haiku-4.5
```

Then sync the agents:
```bash
sync-agents --show  # Preview changes
sync-agents          # Apply changes
```

### Adding a New Task Dependency

Edit `.ralph/tasks/deps-tracker.yaml`:

```yaml
tasks:
  0042:
    depends_on: [0040, 0041]
    blocks: [0043]
  0043:
    depends_on: [0042]
    blocks: []
```

### Updating Task Status

Edit `.ralph/tasks/TODO.md`:

```markdown
# Before
- [ ] 0042: Implement feature X

# After
- [x] 0042: Implement feature X
```

### Customizing Retry Behavior

Since `retry_policy.yaml` is not implemented, use environment variables:

```bash
# Faster retries (shorter delays)
export RALPH_BACKOFF_BASE=1
export RALPH_BACKOFF_MAX=30
ralph-loop.sh

# Slower retries (longer delays)
export RALPH_BACKOFF_BASE=10
export RALPH_BACKOFF_MAX=300
ralph-loop.sh
```

---

## Validation and Troubleshooting

### Validating agents.yaml

```bash
# Check YAML syntax
yq eval '.agents' .ralph/config/agents.yaml

# Verify all agent types are defined
yq eval '.agents | keys' .ralph/config/agents.yaml

# Check specific agent
yq eval '.agents.developer.preferred.claude' .ralph/config/agents.yaml
```

### Validating deps-tracker.yaml

```bash
# Check YAML syntax
yq eval '.tasks' .ralph/tasks/deps-tracker.yaml

# List all task IDs
yq eval '.tasks | keys' .ralph/tasks/deps-tracker.yaml

# Check specific task dependencies
yq eval '.tasks.0042.depends_on' .ralph/tasks/deps-tracker.yaml
```

### Validating TODO.md Grammar

```bash
# Check for incomplete tasks
grep "^- \[ \]" .ralph/tasks/TODO.md

# Check for complete tasks
grep "^- \[x\]" .ralph/tasks/TODO.md

# Check for abort lines
grep "^ABORT:" .ralph/tasks/TODO.md

# Check for completion sentinel
grep "^ALL TASKS COMPLETE" .ralph/tasks/TODO.md
```

### Common Issues

#### Issue: Agent sync fails
**Symptoms:** `sync-agents` returns error
**Diagnosis:**
```bash
# Check YAML syntax
yq eval '.' .ralph/config/agents.yaml

# Verify agent files exist
ls .opencode/agents/
ls .claude/agents/
```
**Solution:** Fix YAML syntax or create missing agent files

#### Issue: Task not being selected
**Symptoms:** Manager never picks a task
**Diagnosis:**
```bash
# Check if task is in TODO.md
grep "0042" .ralph/tasks/TODO.md

# Check if task has unmet dependencies
yq eval '.tasks.0042.depends_on' .ralph/tasks/deps-tracker.yaml

# Check if dependencies are complete
grep -E "^- \[x\] 0040:|^- \[x\] 0041:" .ralph/tasks/TODO.md
```
**Solution:** Complete dependencies or update deps-tracker.yaml

#### Issue: Circular dependency detected
**Symptoms:** `TASK_BLOCKED` signal with cycle message
**Diagnosis:**
```bash
# Check deps-tracker.yaml for cycles
# Task A depends on B, B depends on A
yq eval '.tasks.0042.depends_on' .ralph/tasks/deps-tracker.yaml
yq eval '.tasks.0043.depends_on' .ralph/tasks/deps-tracker.yaml
```
**Solution:** Remove circular dependency in deps-tracker.yaml

#### Issue: TODO.md not parsing correctly
**Symptoms:** Tasks not recognized by Manager
**Diagnosis:**
```bash
# Verify task line format
grep "^- \[ \] 0042:" .ralph/tasks/TODO.md

# Check for extra spaces or characters
cat -A .ralph/tasks/TODO.md | head -20
```
**Solution:** Ensure exact format: `- [ ] 0042: Description` (no extra spaces)

#### Issue: Git conflicts in configuration
**Symptoms:** Ralph-loop.sh exits with conflict error
**Diagnosis:**
```bash
# Check for conflicts
grep -E "^<{7}|^={7}|^>{7}" .ralph/tasks/TODO.md
grep -E "^<{7}|^={7}|^>{7}" .ralph/tasks/deps-tracker.yaml
```
**Solution:** Resolve git conflicts before running ralph-loop.sh

---

## Template Locations

All configuration templates are located in `/proj/jeeves/Ralph/templates/`:

| Template | Location |
|----------|----------|
| agents.yaml | `config/agents.yaml.template` |
| deps-tracker.yaml | `config/deps-tracker.yaml.template` |
| TODO.md | `config/TODO.md.template` |
| .gitignore | `config/.gitignore.template` |
| TASK.md | `task/TASK.md.template` |
| activity.md | `task/activity.md.template` |
| attempts.md | `task/attempts.md.template` |
| ralph-prompt.md | `prompts/ralph-prompt.md.template` |

### Creating a New Project

```bash
# Templates are automatically copied by ralph-init.sh
ralph-init.sh

# Verify configuration files were created
ls -la .ralph/config/
ls -la .ralph/tasks/
```

---

## Environment Variables Reference

| Variable | Scripts | Default | Description |
|----------|---------|---------|-------------|
| `RALPH_TOOL` | ralph-loop.sh, sync-agents | `opencode` | AI tool selection |
| `RALPH_MAX_ITERATIONS` | ralph-loop.sh | `100` | Maximum loop iterations |
| `RALPH_BACKOFF_BASE` | ralph-loop.sh | `2` | Backoff base delay (seconds) |
| `RALPH_BACKOFF_MAX` | ralph-loop.sh | `60` | Backoff max delay (seconds) |
| `RALPH_MANAGER_MODEL` | ralph-loop.sh | (none) | Override Manager model |
| `AGENTS_YAML` | sync-agents | `.ralph/config/agents.yaml` | Path to agents.yaml |
| `RALPH_DIR` | ralph-init.sh, sync-agents | `.ralph` | Ralph directory path |

---

## See Also

- `README-Ralph.md` - Ralph system overview
- `commands.md` - Command reference
- `directory-structure.md` - File organization
- `.ralph/config/agents.yaml` - Live agent configuration
- `.ralph/tasks/TODO.md` - Live task tracking
- `.ralph/tasks/deps-tracker.yaml` - Live dependency tracking
