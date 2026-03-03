# Ralph Loop

**Autonomous AI Task Execution Framework**

Ralph Loop is an intelligent, iterative approach to autonomous software development that prioritizes fresh context over accumulated state. Named after the persistent Ralph Wiggum, it embodies the philosophy that **iteration beats perfection**.

## Table of Contents

- [What is Ralph?](#what-is-ralph)
- [Architecture](#architecture)
- [Core Components](#core-components)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [The Three Phases](#the-three-phases)
- [Command Reference](#command-reference)
- [Configuration Files](#configuration-files)
- [Example Project Walkthrough](#example-project-walkthrough)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## What is Ralph?

Ralph Loop is an autonomous AI task execution framework designed for software development. It prioritizes fresh context over accumulated state, embodying the philosophy that **iteration beats perfection**.

### Core Philosophy

Traditional AI coding sessions accumulate context until the model degrades. Ralph Loop takes a different approach:

- **Fresh Context Per Iteration**: Every task runs with a clean slate
- **Zero Context Accumulation**: No conversation history between iterations
- **Eventual Consistency**: Failures become data for the next attempt
- **Smart Zone Preservation**: Each task gets the full benefit of the model's optimal context window

### Key Features

- **Multi-LLM Support**: Works with OpenCode (default) or Claude Code
- **Agent Specialization**: Different agents for different task types (architecture, UI, testing, development)
- **Dependency Tracking**: Automatic task dependency management via deps-tracker.yaml
- **TDD Compliance**: Test-Driven Development built into the workflow
- **Git Integration**: Branch-per-task workflow with squash merges
- **Safety Limits**: Configurable iteration caps and automatic loop detection

## Architecture

Ralph Loop follows a modular, agent-based architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                     Ralph Loop Framework                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Manager Agent│  │Worker Agents │  │ Bash Wrapper │      │
│  │(Orchestrator)│  │(Specialists) │  │(Loop Control)│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │              │
│         ▼                 ▼                  ▼              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Task Selection│  │Task Execution│  │State Management│    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                  │              │
│         └─────────┬───────┴──────────────────┘              │
│                   ▼                                         │
│            ┌──────────────┐                                 │
│            │ .ralph/ Data │                                 │
│            │  Repository  │                                 │
│            └──────────────┘                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Manager-Worker Architecture

- **Manager Agent**: Spawned fresh each iteration, reads TODO.md and deps-tracker.yaml, selects unblocked tasks, invokes Worker subagents
- **Worker Agents**: Task-specific specialists (developer, tester, architect, etc.) that execute work with clean context
- **Bash Wrapper**: Simple loop that spawns fresh Manager instances, handles backoff timing, and monitors for completion

## Core Components

Ralph Loop is composed of several key components:

### 1. Templates

Located in `jeeves/Ralph/templates/`, these provide:
- Agent definitions for OpenCode and Claude Code platforms
- Configuration file templates (agents.yaml, deps-tracker.yaml, TODO.md)
- Task-related file templates (TASK.md, activity.md, attempts.md)
- Prompt templates and optimizers
- Project rules template (RULES.md)

### 2. Skills

Located in `jeeves/Ralph/skills/`, these are modular, reusable components:
- **dependency-tracking**: Comprehensive dependency management (graph parsing, circular dependency detection, unblocked task selection)
- **git-automation**: Git workflow automation (branch management, commit message generation, squash merges)
- **rationalization-defense**: Detect and correct rationalization patterns that lead to compliance violations (7 pathways, self-diagnostic protocol)
- **system-prompt-compliance**: System prompt compliance enforcement (TODO tracking, mid-process activity logging, signal format, periodic reinforcement)

### 3. Documentation

Located in `jeeves/Ralph/docs/`:
- **directory-structure.md**: Detailed description of Ralph's file organization
- **rules-system.md**: Comprehensive guide to the RULES.md hierarchical learning system

### 4. Configuration

Generated in `.ralph/config/` when initializing a project:
- `agents.yaml`: Maps agent types to specific LLM models
- `deps-tracker.yaml`: Tracks task dependencies
- `TODO.md`: Master task checklist

## Installation

### Prerequisites

Ralph Loop requires the following tools:

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | Latest | Container environment |
| bash | 4.0+ | Script execution |
| yq | 4.x | YAML processing |
| jq | 1.6+ | JSON processing |
| git | 2.x+ | Version control |

### Installing Prerequisites

**Ubuntu/Debian:**
```bash
# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Install jq
sudo apt-get update && sudo apt-get install -y jq

# Verify installations
yq --version
jq --version
bash --version
git --version
```

**macOS:**
```bash
# Using Homebrew
brew install yq jq

# Verify installations
yq --version
jq --version
```

### Container Setup

Ralph Loop is designed to run inside a Docker container with persistent volume mounts:

```bash
# Build the container (run from project root)
./jeeves.ps1 build

# Start the container
./jeeves.ps1 start

# Enter the container shell
./jeeves.ps1 shell
```

The container provides:
- Pre-installed tools (yq, jq, git)
- Ralph templates at `/opt/jeeves/Ralph/`
- Ralph scripts in `/usr/local/bin/`
- Project workspace at `/proj/`

### Verifying Installation

Once inside the container:

```bash
# Check that all required tools are available
command -v yq && echo "yq: OK"
command -v jq && echo "jq: OK"
command -v ralph-init.sh && echo "ralph-init.sh: OK"
command -v ralph-loop.sh && echo "ralph-loop.sh: OK"
command -v sync-agents && echo "sync-agents: OK"

# Verify Ralph templates exist
ls /opt/jeeves/Ralph/templates/
```

## Quick Start

### 5 Steps from Initialization to First Loop

#### Step 1: Initialize Ralph in Your Project

```bash
# Navigate to your project directory
cd /proj/my-project

# Run initialization
ralph-init.sh

# Or with force mode (overwrites existing files)
ralph-init.sh --force
```

This creates:
- `.ralph/` directory structure
- `.ralph/config/agents.yaml` - Agent model mappings
- `.ralph/config/deps-tracker.yaml` - Task dependencies
- `.ralph/tasks/TODO.md` - Task checklist
- `.opencode/agents/` and `.claude/agents/` - Agent definitions
- `RULES.md` - Project-specific rules

#### Step 2: Create Your PRD

Create a Product Requirements Document in `.ralph/specs/`:

```bash
mkdir -p .ralph/specs
cat > .ralph/specs/PRD-my-feature.md << 'EOF'
# PRD: My Feature

## Overview
Description of what we're building.

## Requirements
- Feature must do X
- Feature must support Y
- Performance: <200ms response time

## Technical Specifications
- Use REST API
- PostgreSQL database
- React frontend

## Success Criteria
- All acceptance criteria met
- Test coverage >80%
- No critical bugs
EOF
```

#### Step 3: Run Decomposition with Decomposer Agent

```bash
# Invoke the decomposer agent for decomposition
# (In OpenCode: @decomposer, in Claude: @decomposer)
```

The decomposer agent will:
1. Read your PRD
2. Break down requirements into atomic tasks (<2 hours each)
3. Analyze dependencies between tasks
4. Generate TODO.md with task checklist
5. Create task folders in `.ralph/tasks/XXXX/`
6. Generate deps-tracker.yaml

**Review the output** and provide feedback. The decomposition is iterative - refine until the task breakdown is satisfactory.

#### Step 4: Configure Agents (Optional)

Edit `.ralph/config/agents.yaml` to customize model mappings:

```yaml
agents:
  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5
```

Sync agent configurations:

```bash
# Sync agent models from agents.yaml to agent files
sync-agents

# Or specify tool explicitly
RALPH_TOOL=claude sync-agents
```

#### Step 5: Start Ralph Loop

```bash
# Start the loop with default settings (OpenCode, max 100 iterations)
ralph-loop.sh

# Or with specific options
ralph-loop.sh --tool claude --max-iterations 50
```

Monitor progress:
- Loop status displayed in terminal
- Task completion shown in TODO.md
- Detailed logs in `.ralph/tasks/XXXX/activity.md`

**To stop the loop**: Press `Ctrl+C` or create an ABORT line in TODO.md

## The Three Phases

### Phase 1: PRD Generation (User-Driven)

**Goal**: Create comprehensive requirements

**Activities**:
- Define project scope and objectives
- Specify technical requirements
- Document success criteria
- Create `.ralph/specs/PRD-*.md`

**Duration**: 30 minutes - 2 hours

**Output**: Product Requirements Document

### Phase 2: Decomposition (Agent-Assisted)

**Goal**: Break PRD into atomic, executable tasks

**Activities**:
- Invoke `@decomposer` agent
- Review generated task breakdown
- Refine task granularity (each <2 hours)
- Validate dependencies
- Confirm task count (<9999 tasks)

**Duration**: 1-3 hours (iterative)

**Outputs**:
- `.ralph/tasks/TODO.md` - Master checklist
- `.ralph/tasks/deps-tracker.yaml` - Dependencies
- `.ralph/tasks/XXXX/TASK.md` - Individual task definitions
- `.ralph/tasks/XXXX/activity.md` - Activity logs
- `.ralph/tasks/XXXX/attempts.md` - Attempt tracking

**Task Sizing Guide**:

| Size | Time | Example |
|------|------|---------|
| XS | 0-15 min | Fix typo, config change |
| S | 15-30 min | Add test, minor refactor |
| M | 30-60 min | Implement endpoint |
| L | 1-2 hours | Complex integration |
| XL | >2 hours | **Must decompose further** |

### Phase 3: Execution (Autonomous Loop)

**Goal**: Execute tasks autonomously until completion

**Activities**:
- Run `ralph-loop.sh`
- Manager selects unblocked tasks
- Workers execute with fresh context
- State updates after each iteration
- Exponential backoff between iterations

**Duration**: Varies by project size (hours to days)

**Process Flow**:

```
┌─────────────────┐
│   ralph-loop.sh │
│   (bash wrapper)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│  sync-agents    │────►│ Update agent │
│  (once at start)│     │ models       │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│  Manager Agent  │────►│ Read TODO.md │
│  (fresh context)│     │ & deps-tracker│
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Select Task     │────►│ Check deps   │
│ (unblocked only)│     │ are complete │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Invoke Worker   │────►│ Execute task │
│ (subagent call) │     │ with context │
└────────┬────────┘     └──────────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────┐
│ Parse Signal    │────►│ Update state │
│ (stdout)        │     │ (TODO.md)    │
└────────┬────────┘     └──────────────┘
         │
         ▼
    [Repeat]
```

## Command Reference

### ralph-init.sh

Initialize Ralph scaffolding in the current project directory.

**Usage:**
```bash
ralph-init.sh [OPTIONS]
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message and exit |
| `--force` | `-f` | Skip overwrite prompts (except agents.yaml) |
| `--rules` | | Force RULES.md creation even if exists |

**Examples:**
```bash
# Interactive setup
ralph-init.sh

# Force overwrite existing files
ralph-init.sh --force

# Force RULES.md creation
ralph-init.sh --rules
```

**Exit Codes:**
- `0` - Success
- `1` - Error (missing tools, file system errors)

---

### ralph-loop.sh

Main Ralph Loop - autonomous task execution orchestration.

**Usage:**
```bash
ralph-loop.sh [OPTIONS]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--tool {opencode\|claude}` | Select AI tool | `opencode` |
| `--max-iterations N` | Maximum iterations (0=unlimited) | `100` |
| `--skip-sync` | Skip pre-loop agent synchronization | `false` |
| `--no-delay` | Disable exponential backoff delays | `false` |
| `--dry-run` | Print commands without executing | `false` |
| `--help`, `-h` | Show help message | - |

**Environment Variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `RALPH_TOOL` | Default tool selection | `opencode` |
| `RALPH_MAX_ITERATIONS` | Maximum loop iterations | `100` |
| `RALPH_BACKOFF_BASE` | Backoff base delay (seconds) | `2` |
| `RALPH_BACKOFF_MAX` | Backoff max delay (seconds) | `60` |
| `RALPH_MANAGER_MODEL` | Override Manager model | (none) |

**Examples:**
```bash
# Default run (OpenCode, 100 iterations max)
ralph-loop.sh

# Use Claude Code
ralph-loop.sh --tool claude

# Unlimited iterations
ralph-loop.sh --max-iterations 0

# Fast mode (no delays, skip sync)
ralph-loop.sh --no-delay --skip-sync

# Limited run
ralph-loop.sh --max-iterations 10
```

**Exit Codes:**
- `0` - All tasks complete or graceful shutdown
- `1` - Error (missing Ralph directory, invalid arguments)
- `130` - Interrupted (Ctrl+C)

**Signals Emitted:**

The loop monitors for these signals in stdout:

| Signal | Meaning | Action |
|--------|---------|--------|
| `TASK_COMPLETE_XXXX` | Task finished | Mark complete, move to done/ |
| `TASK_INCOMPLETE_XXXX` | Needs more work | Continue loop |
| `TASK_FAILED_XXXX: msg` | Error encountered | Retry with backoff |
| `TASK_BLOCKED_XXXX: msg` | Blocked | Add ABORT line, terminate |
| `ALL TASKS COMPLETE, EXIT LOOP` | All done | Graceful exit |

---

### sync-agents

Synchronize agent model configurations from agents.yaml to agent definition files.

**Usage:**
```bash
sync-agents [OPTIONS]
```

**Options:**

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message |
| `--tool TOOL` | `-t` | Specify tool (opencode\|claude) |
| `--config FILE` | `-c` | Custom agents.yaml path |
| `--show` | `-s` | Show parsed agents (don't sync) |
| `--dry-run` | `-d` | Show what would be updated |

**Environment Variables:**

| Variable | Description |
|----------|-------------|
| `RALPH_TOOL` | Tool to use (opencode\|claude) |
| `AGENTS_YAML` | Path to agents.yaml |

**Examples:**
```bash
# Sync for OpenCode (default)
sync-agents

# Sync for Claude
sync-agents -t claude

# Show current configuration
sync-agents --show

# Dry run (preview changes)
sync-agents --dry-run

# Use custom config
sync-agents -c /path/to/agents.yaml
```

**Exit Codes:**
- `0` - Success
- `1` - Error (yq not found, invalid YAML, etc.)

---

### Agent Invocation (Tool-Specific)

Workers are invoked as subagents by the Manager:

**OpenCode:**
```bash
opencode --agent {agent_type}
```

**Claude Code:**
```bash
claude -p --dangerously-skip-permissions --model {model}
```

**Available Agent Types:**

| Agent Type | Purpose | Example Tasks |
|------------|---------|---------------|
| `manager` | Orchestration | Task selection, Worker invocation |
| `architect` | System design | API design, database schema |
| `developer` | Implementation | Coding, debugging, refactoring |
| `tester` | QA | Test creation, validation |
| `ui-designer` | UI/UX | Interface design, responsive layout |
| `researcher` | Investigation | Analysis, documentation |
| `writer` | Documentation | Content creation, editing |
| `decomposer` | Decomposition | Task breakdown, TODO management |
| `decomposer-architect` | Architecture analysis | System design during decomposition |
| `decomposer-researcher` | Technical research | Context investigation during decomposition |

## Configuration Files

### agents.yaml

**Location:** `.ralph/config/agents.yaml`

**Purpose:** Maps agent types to specific LLM models for optimal performance and cost efficiency.

**Format:**
```yaml
agents:
  {agent_type}:
    description: "What this agent does"
    preferred:
      opencode: {model_name}
      claude: {model_name}
    fallback:
      opencode: {model_name}
      claude: {model_name}
```

**Example:**
```yaml
agents:
  manager:
    description: "Ralph Loop Manager - orchestrates task execution"
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
```

**Notes:**
- Use `inherit` for OpenCode to use the default model
- Model names are examples; update based on current availability
- Changes take effect after running `sync-agents`

---

### deps-tracker.yaml

**Location:** `.ralph/tasks/deps-tracker.yaml`

**Purpose:** Tracks task dependencies for the Ralph Loop. Manager uses this to determine which tasks are unblocked and ready for work.

**Format:**
```yaml
tasks:
  {task_id}:
    depends_on: [{list_of_dependency_ids}]
    blocks: [{list_of_blocked_task_ids}]
```

**Example:**
```yaml
tasks:
  0001:
    depends_on: []
    blocks: [0003]

  0002:
    depends_on: []
    blocks: [0003]

  0003:
    depends_on: [0001, 0002]
    blocks: []
```

**Rules:**
- All tasks must be listed (even with empty arrays)
- Task IDs are 4-digit zero-padded (0001-9999)
- A task is "unblocked" when all tasks in `depends_on` are complete
- Circular dependencies will block the loop

---

### TODO.md

**Location:** `.ralph/tasks/TODO.md`

**Purpose:** Master task checklist. Manager reads this to determine what work remains.

**Strict Grammar:**

Only these line types are allowed:

```markdown
# Phase headers (informational)

- [ ] 0001: Task title here        # Incomplete task
- [x] 0001: Task title here        # Complete task

ABORT: HELP NEEDED FOR TASK 0001: Reason  # Blockage

ALL TASKS COMPLETE, EXIT LOOP              # Completion sentinel
```

**Example:**
```markdown
# Ralph Tasks

# Phase 1: Foundation
- [x] 0001: Set up project structure
- [ ] 0002: Configure database
- [ ] 0003: Create API endpoints

# Phase 2: Features
- [ ] 0004: Implement authentication
- [ ] 0005: Add user management

ABORT: HELP NEEDED FOR TASK 0004: Database connection failing
```

**Important:**
- Task order is informational only - Manager can select any unblocked task
- Use 4-digit IDs with leading zeros
- Don't edit while loop is running (causes conflicts)

---

### Task Files

Each task gets its own folder: `.ralph/tasks/XXXX/`

**TASK.md** - Task definition:
- Description and acceptance criteria
- Implementation notes
- Files to create/modify
- Dependencies and metadata

**activity.md** - Activity log:
- TDD phase tracking
- Handoff history
- Defect reports
- Progress log
- Decisions and lessons learned

**attempts.md** - Attempt history:
- Detailed attempt log
- Errors encountered
- Lessons learned per attempt

## Example Project Walkthrough

### Building a Simple REST API with Ralph

**Step 1: Initialize Project**
```bash
cd /proj/my-api
ralph-init.sh
```

**Step 2: Create PRD**
```bash
cat > .ralph/specs/PRD-simple-api.md << 'EOF'
# PRD: Simple User API

## Overview
REST API for user management with CRUD operations.

## Requirements
- GET /users - List all users
- GET /users/:id - Get single user
- POST /users - Create user
- PUT /users/:id - Update user
- DELETE /users/:id - Delete user

## Technical Specs
- Node.js with Express
- PostgreSQL database
- Jest for testing

## Success Criteria
- All endpoints functional
- Test coverage >80%
- Response time <200ms
EOF
```

**Step 3: Decomposition**

Invoke `@decomposer` agent with prompt:
```
Decompose the PRD at .ralph/specs/PRD-simple-api.md into atomic tasks.
Focus on:
1. Project setup
2. Database schema
3. API endpoints (one task per endpoint)
4. Testing
5. Documentation
```

Expected output: ~10 tasks created in `.ralph/tasks/`

**Step 4: Review TODO.md**
```bash
cat .ralph/tasks/TODO.md
```

Example output:
```markdown
# Phase 1: Setup
- [ ] 0001: Initialize Node.js project with Express
- [ ] 0002: Set up PostgreSQL database connection

# Phase 2: Database
- [ ] 0003: Create users table schema

# Phase 3: API Implementation
- [ ] 0004: Implement GET /users endpoint
- [ ] 0005: Implement GET /users/:id endpoint
- [ ] 0006: Implement POST /users endpoint
- [ ] 0007: Implement PUT /users/:id endpoint
- [ ] 0008: Implement DELETE /users/:id endpoint

# Phase 4: Testing
- [ ] 0009: Write unit tests for all endpoints
- [ ] 0010: Set up integration tests
```

**Step 5: Start Ralph Loop**
```bash
ralph-loop.sh --max-iterations 50
```

**Monitor Progress:**
- Watch terminal for task completion signals
- Check TODO.md for checkbox updates
- Review activity.md files for detailed progress

**Expected Timeline:**
- Task 0001-0003: ~2 hours
- Task 0004-0008: ~4 hours (30-45 min each)
- Task 0009-0010: ~2 hours

**Completion:**
When you see:
```
ALL TASKS COMPLETE, EXIT LOOP
```

The loop terminates automatically. All tasks are in `.ralph/tasks/done/`.

## Troubleshooting

### Common Issues

#### Issue: "yq not found" during ralph-init.sh

**Symptoms:**
```
[ERROR] yq is not installed. Please install yq to use sync-agents.
```

**Solution:**
```bash
# Install yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

---

#### Issue: "Ralph directory not found" when starting loop

**Symptoms:**
```
[ERROR] Ralph directory not found: /proj/my-project/.ralph
```

**Solution:**
Run initialization first:
```bash
ralph-init.sh
```

---

#### Issue: Git conflicts in TODO.md

**Symptoms:**
```
[ERROR] Git conflict detected: .ralph/tasks/TODO.md
[ERROR] Conflict markers in: .ralph/tasks/TODO.md
```

**Cause:**
Editing TODO.md while loop is running

**Solution:**
1. Stop the loop (Ctrl+C)
2. Resolve conflicts manually:
   ```bash
   # Edit TODO.md to resolve conflicts
   vim .ralph/tasks/TODO.md
   
   # Mark as resolved
   git add .ralph/tasks/TODO.md
   ```
3. Restart loop:
   ```bash
   ralph-loop.sh
   ```

**Prevention:**
Don't edit TODO.md or deps-tracker.yaml while loop is running

---

#### Issue: Loop stuck on same task

**Symptoms:**
Same task fails repeatedly for 5+ iterations

**Solution:**
1. Check task activity:
   ```bash
   cat .ralph/tasks/XXXX/activity.md
   ```
2. Look for patterns in attempts.md
3. If blocked, add to TODO.md:
   ```markdown
   ABORT: HELP NEEDED FOR TASK XXXX: Description of issue
   ```
4. Loop will terminate - fix manually, then restart

---

#### Issue: "Agent not found" errors

**Symptoms:**
```
[WARNING] Agent file not found: developer.md
```

**Solution:**
1. Sync agents:
   ```bash
   sync-agents
   ```
2. Verify agents.yaml has the agent type defined
3. Check agent files exist in `.opencode/agents/` or `.claude/agents/`

---

#### Issue: Task takes too long

**Symptoms:**
Single task running for >1 hour without completion

**Solution:**
1. Check if task is too large (should be <2 hours)
2. Press Ctrl+C to interrupt
3. Decompose further in Phase 2
4. Restart loop

---

#### Issue: Context limit warnings

**Symptoms:**
```
TASK_INCOMPLETE_XXXX:context_limit_approaching
```

**Solution:**
This is expected for large tasks. The task will:
1. Document context checkpoint in activity.md
2. Signal for continuation
3. Next iteration resumes from checkpoint

If frequent, consider decomposing tasks smaller.

---

### Debug Mode

Run with verbose output:
```bash
# Set debug environment variable
export RALPH_DEBUG=1
ralph-loop.sh
```

### Getting Help

1. Check task activity logs: `.ralph/tasks/XXXX/activity.md`
2. Review attempts history: `.ralph/tasks/XXXX/attempts.md`
3. Read Ralph documentation: 
   - `/proj/jeeves/Ralph/README-Ralph.md` - Main overview
   - `/proj/jeeves/Ralph/docs/directory-structure.md` - Directory organization
   - `/proj/jeeves/Ralph/docs/rules-system.md` - Rules system
4. Check RULES.md for project-specific guidance

## Next Steps

### Documentation

- **[Ralph Loop Documentation](docs/README.md)** - Overview of all Ralph documentation
- **[Directory Structure](docs/directory-structure.md)** - Detailed description of Ralph's file organization
- **[Rules System](docs/rules-system.md)** - Comprehensive guide to the RULES.md hierarchical learning system
- **[Templates](templates/README.md)** - Information about agent, configuration, and task templates
- **[Skills](skills/README.md)** - Documentation for reusable Ralph skills

### Advanced Topics

- **Custom Agent Creation**: Define specialized agents for your domain
- **Rule-Based Learning**: Use RULES.md to capture project patterns
- **Integration Patterns**: Connect with CI/CD pipelines
- **Performance Tuning**: Optimize model selection and task sizing

### Best Practices

1. **Start Small**: Begin with 5-10 tasks for your first project
2. **Review Decomposition**: Always review TODO.md before starting loop
3. **Monitor Early**: Watch first few iterations to ensure proper behavior
4. **Iterate on Process**: Adjust task granularity based on results
5. **Document Patterns**: Use RULES.md to capture learnings

### Community

- Report issues: [Project Issues]
- Share patterns: Contribute RULES.md examples
- Improve agents: Submit agent template enhancements

---

**Ralph Loop**: *Because iteration beats perfection.*
