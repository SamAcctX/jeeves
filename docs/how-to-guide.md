# How-To Guide: From Zero to Autonomous AI Tasks

This guide walks you through the complete Jeeves/Ralph workflow -- from building the container to watching an autonomous loop complete your project. It covers the "how" and "why" at each step, with concrete examples you can follow.

For exhaustive flag listings and file formats, see [commands.md](commands.md). For all configuration options, see [configuration.md](configuration.md). For diagnosing problems, see [troubleshooting.md](troubleshooting.md).

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Prerequisites and Installation](#2-prerequisites-and-installation)
3. [Container Setup](#3-container-setup)
4. [Initializing a Ralph Project](#4-initializing-a-ralph-project)
5. [Phase 1: Creating a PRD](#5-phase-1-creating-a-prd)
6. [Phase 2: Decomposing into Tasks](#6-phase-2-decomposing-into-tasks)
7. [Phase 3: Running the Ralph Loop](#7-phase-3-running-the-ralph-loop)
8. [Agent Configuration](#8-agent-configuration)
9. [The RULES.md Learning System](#9-the-rulesmd-learning-system)
10. [Skills System](#10-skills-system)
11. [Tips and Best Practices](#11-tips-and-best-practices)
12. [Next Steps](#12-next-steps)

---

## 1. Introduction

### What is Ralph?

Ralph is an autonomous AI task execution framework built on a simple insight: **iteration beats perfection**. Instead of trying to complete an entire project in one long AI session (where context degrades and errors compound), Ralph breaks work into small tasks and tackles each one with a fresh context window.

The system uses a manager-worker architecture. A Manager agent reads a task list, selects the next unblocked task, dispatches it to a specialized worker agent (developer, tester, architect, etc.), interprets the result, and loops. Each iteration starts clean -- no conversation history carries over, so every task gets the full benefit of the model's optimal context window.

### Core Philosophy

- **Fresh context per iteration.** Every task runs with a clean slate. No accumulated confusion, no token bloat.
- **Eventual consistency.** A failed task is not a crisis -- it becomes data for the next attempt. The loop retries with exponential backoff.
- **Smart zone preservation.** By keeping tasks small (under 2 hours of human-equivalent work), each one fits comfortably in the model's effective context window.
- **TDD enforcement.** Developers cannot mark their own work complete. Only the Tester agent can approve task completion, enforcing a strict RED-GREEN-VALIDATE cycle.

### What This Guide Covers

This guide takes you through the three-phase Ralph workflow:

1. **Phase 1: PRD** -- Define what you want to build using the `@prd-creator` agent.
2. **Phase 2: Decomposition** -- Break the PRD into atomic tasks using the `@decomposer` agent.
3. **Phase 3: Execution** -- Let `ralph-loop.sh` autonomously complete every task.

Before that, you will set up the Jeeves container and initialize Ralph in your project.

---

## 2. Prerequisites and Installation

### Host Machine Requirements

You need two things on your host machine:

| Tool | Version | Why |
|------|---------|-----|
| Docker Desktop or Engine | Latest stable | Runs the Jeeves container |
| PowerShell | 7.0+ | Runs `jeeves.ps1` (cross-platform) |

PowerShell 7+ runs on Windows, macOS, and Linux. Install it with:

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y powershell

# macOS
brew install powershell
```

On Windows, PowerShell 7 is available from the [Microsoft Store](https://aka.ms/PSWindows) or via `winget install Microsoft.PowerShell`.

### Optional: NVIDIA GPU

The container base image is `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04`. If you have an NVIDIA GPU with drivers installed and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) configured, the container will use GPU acceleration automatically. Without a GPU, everything still works -- the CUDA libraries are simply unused.

### What Ships Inside the Container

You do not need to install these yourself. The container includes:

- bash 4.0+, yq 4.x, jq 1.6+, git 2.x+
- Python 3 with a virtual environment at `/opt/venv`
- Node.js and npm
- OpenCode (AI coding tool)
- All Ralph scripts in `/usr/local/bin/`
- Ralph templates at `/opt/jeeves/Ralph/templates/`
- Four MCP servers (sequential thinking, fetch, SearXNG search, Playwright browser automation)

---

## 3. Container Setup

### Building the Image

From your project root (where `jeeves.ps1` lives):

```powershell
./jeeves.ps1 build
```

This builds the Docker image using layer caching. The first build takes several minutes; subsequent builds are fast.

For a clean build from scratch (no cache):

```powershell
./jeeves.ps1 build --no-cache
```

See [commands.md](commands.md) for additional build flags (`--desktop`, `--install-claude-code`, `--clean`).

### Starting the Container

```powershell
./jeeves.ps1 start
```

This starts the container with volume mounts, networking, and (if available) GPU passthrough. The key volume mounts are:

| Host | Container | Purpose |
|------|-----------|---------|
| Current working directory | `/proj` | Your project workspace |
| `~/.claude` | `/home/jeeves/.claude` | Claude Code settings |
| `~/.config/opencode` | `/home/jeeves/.config/opencode` | OpenCode settings |
| `~/.opencode` | `/home/jeeves/.opencode` | OpenCode agents |

Port 3333 is exposed for the OpenCode Web UI.

If you need a full rebuild-and-start in one command:

```powershell
./jeeves.ps1 start --clean
```

This stops any running container, removes it, rebuilds without cache, and starts fresh.

### Entering the Shell

```powershell
./jeeves.ps1 shell
```

This attaches an interactive bash session inside the container. By default, it auto-attaches to a tmux session. You will see a welcome message with environment details on first entry (suppress with `DISABLE_WELCOME=1`).

Useful shell flags:

```powershell
./jeeves.ps1 shell --raw     # Skip tmux, plain bash
./jeeves.ps1 shell --zsh     # Use zsh instead of bash
```

### Accessing the Web UI

Once the container is running, open `http://localhost:3333` in your browser to access the OpenCode Web UI. The web server runs as a supervisord service inside the container:

```bash
opencode-web status    # Check if running
opencode-web restart   # Restart the service
```

Running `opencode` with no arguments from the container shell auto-attaches the TUI to the running web server session.

### Checking Status

From the host:

```powershell
./jeeves.ps1 status    # Container and image status
./jeeves.ps1 logs      # Container logs (follow mode)
```

For the full command reference including `stop`, `restart`, `rm`, and `clean`, see [commands.md](commands.md).

---

## 4. Initializing a Ralph Project

Once inside the container, navigate to your project directory and run:

```bash
ralph-init.sh
```

This creates the entire Ralph scaffolding in your project. If files already exist, it prompts before overwriting. Use `--force` to skip prompts, or `--rules` to force RULES.md creation even if one exists.

### What Gets Created

```
.ralph/
  config/
    agents.yaml           # Maps 10 agent types to LLM models
    deps-tracker.yaml     # Task dependency graph (empty initially)
  tasks/
    TODO.md               # Master task checklist (empty initially)
    done/                 # Completed task folders move here
  specs/                  # Place your PRDs here

.opencode/agents/         # Agent templates for OpenCode
.claude/agents/           # Agent templates for Claude Code
.opencode/skills/         # Skills for OpenCode
.claude/skills/           # Skills for Claude Code
RULES.md                  # Project-level rules (from template)
```

Task templates (`TASK.md`, `activity.md`, `attempts.md`) are created per-task by the Decomposer agent during Phase 2. The prompt template (`ralph-prompt.md`) is read directly from source at runtime.

The init script also runs three installation scripts automatically:

- `install-agents.sh` -- Installs PRD Creator and Deepest-Thinking agent templates
- `install-mcp-servers.sh` -- Configures the four MCP servers
- `install-skill-deps.sh` -- Installs dependencies for any installed skills

One important detail: `agents.yaml` is **never overwritten** by init, even with `--force`. This protects your model configuration from accidental resets.

### Verifying Initialization

```bash
ls -la .ralph/
ls .ralph/config/
ls .opencode/agents/
```

You should see the directory structure above, agent template files for all 10 agent types, and a populated `agents.yaml`.

For the full directory structure and file format specifications, see [configuration.md](configuration.md).

---

## 5. Phase 1: Creating a PRD

A Product Requirements Document (PRD) defines what you want to build. It is the input to Phase 2 decomposition. You have two options: write one manually, or use the `@prd-creator` agent interactively.

### Using the PRD Creator Agent

The recommended approach is to use the `@prd-creator` agent, which guides you through a conversational process:

```
@prd-creator
```

The agent asks you questions about your project -- what it does, who it is for, what the technical constraints are. You discuss back and forth, and it generates a comprehensive PRD. The output is saved to `.ralph/specs/PRD-<name>.md`.

This is an interactive, human-in-the-loop process. The agent does not generate the PRD in one shot; it asks clarifying questions and iterates with you until the document is complete.

### PRD Sections

A well-structured PRD includes:

- **Overview** -- What you are building and why
- **Goals** -- Measurable objectives
- **User Stories** -- "As a [user], I can [action]" format
- **Technical Architecture** -- Stack, patterns, constraints
- **Data Models** -- Entities and relationships
- **API Specifications** -- Endpoints, request/response formats
- **UI/UX Requirements** -- Layouts, interactions, accessibility
- **Security** -- Authentication, authorization, data protection
- **Testing Strategy** -- What to test and how
- **Implementation Phases** -- Logical groupings of work

Not every PRD needs all sections. A simple CLI tool might only need Overview, Goals, Technical Architecture, and User Stories. The PRD Creator agent adapts to your project's complexity.

### Writing a PRD Manually

If you prefer to write the PRD yourself, create a markdown file in `.ralph/specs/`:

```bash
cat > .ralph/specs/PRD-my-project.md << 'EOF'
# PRD: My Project

## Overview
A REST API for managing widgets.

## Goals
- CRUD operations for widgets
- Search by category
- Pagination on list endpoints

## Technical Architecture
- Python Flask
- PostgreSQL
- RESTful JSON API

## User Stories
- As a user, I can create a widget with a name and category
- As a user, I can list widgets filtered by category
- As a user, I can update a widget's details
- As a user, I can delete a widget

## Acceptance Criteria
- All endpoints return proper HTTP status codes
- Input validation on all write endpoints
- Test coverage above 80%
EOF
```

### PRD Quality Matters

The quality of your PRD directly determines the quality of the task decomposition. Vague requirements produce vague tasks. Specific, measurable requirements produce tasks with clear acceptance criteria that the AI can verify.

Before moving to Phase 2, ask yourself:

- Are the requirements specific enough to test?
- Are edge cases documented?
- Is the technical stack defined?
- Would a developer know what "done" looks like?

---

## 6. Phase 2: Decomposing into Tasks

Phase 2 transforms your PRD into an actionable task list. The Decomposer agent reads the PRD and generates everything the Ralph Loop needs to execute autonomously.

### Running the Decomposer

Invoke the `@decomposer` agent and point it at your PRD:

```
@decomposer

Decompose the PRD at .ralph/specs/PRD-my-project.md into atomic tasks.
```

For projects with complex system architecture, use `@decomposer-architect` instead. For research-heavy projects that need investigation before task planning, use `@decomposer-researcher`. These are specialized variants that consult sub-assistants during decomposition. See [agent-selection-guide.md](agent-selection-guide.md) for when to use each.

### What the Decomposer Produces

The agent generates three artifacts:

**1. TODO.md** (`.ralph/tasks/TODO.md`) -- The master task checklist:

```markdown
# My Project Implementation

## Setup
- [ ] 0001: Initialize Flask project structure
- [ ] 0002: Set up PostgreSQL database connection

## Models
- [ ] 0003: Create Widget model with migrations

## Endpoints
- [ ] 0004: Implement POST /widgets endpoint
- [ ] 0005: Implement GET /widgets endpoint with pagination
- [ ] 0006: Implement GET /widgets/:id endpoint
- [ ] 0007: Implement PUT /widgets/:id endpoint
- [ ] 0008: Implement DELETE /widgets/:id endpoint

## Polish
- [ ] 0009: Add input validation across all endpoints
- [ ] 0010: Write test suite
- [ ] 0011: Create API documentation
```

**2. deps-tracker.yaml** (`.ralph/config/deps-tracker.yaml`) -- The dependency graph:

```yaml
tasks:
  "0001":
    depends_on: []
    blocks: ["0002", "0003"]
  "0002":
    depends_on: ["0001"]
    blocks: ["0003"]
  "0003":
    depends_on: ["0001", "0002"]
    blocks: ["0004", "0005", "0006", "0007", "0008"]
  "0004":
    depends_on: ["0003"]
    blocks: ["0009", "0010"]
  # ... and so on
```

Each task has a `depends_on` list (what must finish first) and a `blocks` list (what is waiting on this task). The Manager uses this graph to select unblocked tasks at runtime.

**3. Task folders** (`.ralph/tasks/XXXX/`) -- One folder per task, each containing:

- `TASK.md` -- Description, acceptance criteria, implementation notes, complexity estimate
- `activity.md` -- Execution log (empty initially)
- `attempts.md` -- Attempt history (empty initially)

### Task Sizing

Every task must be completable in under 2 hours of human-equivalent work. The Decomposer assigns T-shirt sizes:

| Size | Time | Example |
|------|------|---------|
| XS | 0-15 min | Config change, copy operation |
| S | 15-30 min | Single function, simple script |
| M | 30-60 min | Standard feature implementation |
| L | 1-2 hours | Multi-component integration |

If the Decomposer produces an XL task (over 2 hours), it must be broken down further. Review the output and ask the Decomposer to refine if needed.

### Reviewing Before Phase 3

Before starting the loop, review the decomposition:

```bash
cat .ralph/tasks/TODO.md                    # Task list
cat .ralph/config/deps-tracker.yaml         # Dependencies
cat .ralph/tasks/0001/TASK.md               # Sample task definition
```

Check that:

- All PRD requirements are covered by at least one task
- No tasks are oversized (XL)
- Dependencies make logical sense
- Acceptance criteria are specific and testable

This is your last chance to adjust before autonomous execution begins. Edit TODO.md, deps-tracker.yaml, or individual TASK.md files as needed.

For detailed decomposition patterns, refinement techniques, and common mistakes, see [phase2-decomposition-guide.md](phase2-decomposition-guide.md).

---

## 7. Phase 3: Running the Ralph Loop

This is where Ralph takes over. The loop runs autonomously, selecting tasks, dispatching agents, and tracking progress until everything is done.

### Starting the Loop

```bash
ralph-loop.sh
```

By default, this uses OpenCode as the AI tool with a maximum of 100 iterations. Common variations:

```bash
ralph-loop.sh --tool claude --max-iterations 50   # Use Claude Code, cap at 50
ralph-loop.sh --no-delay --skip-sync              # Fast mode: no backoff, skip agent sync
ralph-loop.sh --dry-run                           # Preview commands without executing
```

Environment variables can also control behavior:

```bash
export RALPH_TOOL=claude
export RALPH_MAX_ITERATIONS=200
ralph-loop.sh
```

For the full flag and environment variable reference, see [commands.md](commands.md).

### How the Loop Works

Each iteration follows this sequence:

1. **Sync agents** -- Propagate model configurations from `agents.yaml` to agent templates (skippable with `--skip-sync`).
2. **Read state** -- Parse `TODO.md` and `deps-tracker.yaml` to find incomplete, unblocked tasks.
3. **Select task** -- Pick the next unblocked task based on the dependency graph.
4. **Invoke worker** -- The Manager dispatches the task to the appropriate agent (developer, tester, architect, etc.) based on task keywords and TDD phase signals.
5. **Parse signal** -- The worker emits a signal indicating the result.
6. **Update state** -- Mark tasks complete, record activity, handle failures.
7. **Repeat** -- Loop back to step 2.

### The Signal System

Workers communicate results through four signals:

| Signal | Format | Meaning |
|--------|--------|---------|
| Complete | `TASK_COMPLETE_0042` | Task finished, all criteria met |
| Incomplete | `TASK_INCOMPLETE_0042` | Partial progress, will retry |
| Failed | `TASK_FAILED_0042: error msg` | Error encountered, will retry |
| Blocked | `TASK_BLOCKED_0042: reason` | Needs human intervention |

The Manager also watches for two sentinels in TODO.md:

- `ALL TASKS COMPLETE, EXIT LOOP` -- Written when every task is checked off. Loop exits cleanly.
- `ABORT: HELP NEEDED FOR TASK XXXX: reason` -- Written when a task signals TASK_BLOCKED. Loop stops.

### TDD Enforcement

For implementation tasks, the loop enforces a strict Test-Driven Development cycle:

```
RED:          Tester writes failing tests
GREEN:        Developer implements code to pass tests
VALIDATE:     Tester verifies all tests pass
REFACTOR:     Developer improves code quality (optional)
SAFETY_CHECK: Tester confirms no regressions
DONE:         Tester emits TASK_COMPLETE
```

The critical constraint: **Developers cannot emit TASK_COMPLETE.** If a Developer tries, the Manager rejects it and re-invokes the Tester. Only the Tester can approve completion through the verification chain.

For the full TDD routing table and agent selection logic, see [agent-selection-guide.md](agent-selection-guide.md).

### Monitoring Progress

While the loop runs, you have several monitoring options:

**Attach to the active session:**

```bash
ralph-peek.sh           # Attach via TUI (default)
ralph-peek.sh --web     # Print the Web UI URL instead
```

**Check task progress:**

```bash
cat .ralph/tasks/TODO.md                     # Overall progress
cat .ralph/tasks/0042/activity.md            # Specific task log
```

**Filter verbose output (post-run):**

```bash
ralph-filter-output.sh --signals output.json   # Show only signals
```

### When the Loop Stops

The loop terminates under these conditions:

| Condition | What Happens |
|-----------|--------------|
| All tasks complete | Manager writes `ALL TASKS COMPLETE, EXIT LOOP` to TODO.md |
| TASK_BLOCKED signal | Manager writes `ABORT: HELP NEEDED` to TODO.md |
| Max iterations reached | Loop exits with a warning |
| Ctrl+C | Graceful shutdown (safe to restart) |

### Recovering from a Stopped Loop

If the loop stopped due to a blocked task:

1. Read the reason: `cat .ralph/tasks/XXXX/activity.md`
2. Fix the underlying issue manually
3. Remove the abort line: edit TODO.md and delete the `ABORT:` line
4. Restart: `ralph-loop.sh`

The loop is always safe to restart. It reads state from files, not memory.

For more recovery procedures, see [troubleshooting.md](troubleshooting.md).

---

## 8. Agent Configuration

Ralph uses 10 specialized agent types. Each can be mapped to a different LLM model depending on the task's complexity and your cost tolerance.

### The 10 Agent Types

| Agent | Role |
|-------|------|
| manager | Orchestrates the loop -- selects tasks, invokes workers, manages state |
| architect | System design, API design, technology decisions |
| developer | Code implementation, refactoring, debugging |
| ui-designer | UI/UX design, frontend architecture, accessibility |
| tester | Test creation, QA validation, TDD gatekeeper |
| researcher | Investigation, analysis, knowledge synthesis |
| writer | Documentation, technical writing, content creation |
| decomposer | PRD decomposition, task planning |
| decomposer-architect | Architecture consulting during decomposition |
| decomposer-researcher | Research consulting during decomposition |

For detailed descriptions of each agent's responsibilities, selection logic, and when to use which, see [agent-selection-guide.md](agent-selection-guide.md).

### agents.yaml

The file `.ralph/config/agents.yaml` maps each agent type to preferred and fallback models for both OpenCode and Claude Code:

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

  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: ""
      claude: claude-sonnet-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5
```

For OpenCode, `""` (empty string) means "use the default model" -- this is the recommended setting. For Claude Code, specify the model name directly.

The general recommendation is to use higher-tier models (Opus) for agents that require broad reasoning (manager, architect, decomposer) and cost-effective models (Sonnet) for high-volume work (developer, tester, writer).

### Syncing Configuration Changes

After editing `agents.yaml`, propagate the changes to agent template files:

```bash
sync-agents.sh              # Apply changes for OpenCode (default)
sync-agents.sh --tool claude # Apply changes for Claude Code
sync-agents.sh --show        # Preview without changing anything
sync-agents.sh --dry-run     # Show what would change
```

The sync script reads `agents.yaml`, finds the corresponding agent markdown files, and updates the `model:` field in their YAML frontmatter. It is idempotent -- running it twice with the same config makes no unnecessary changes.

For the complete `agents.yaml` schema, all 10 default configurations, and model recommendation rationale, see [configuration.md](configuration.md).

---

## 9. The RULES.md Learning System

RULES.md files capture project-specific patterns, conventions, and constraints that agents should follow. They serve as institutional memory across iterations -- since each iteration starts with fresh context, RULES.md is how learned patterns persist.

### How It Works

Agents walk up the directory tree from their working directory, collecting every `RULES.md` file they find. Rules are applied root-to-leaf: deeper files override shallower ones on conflict. A file containing `IGNORE_PARENT_RULES` stops inheritance from parent directories.

### What Goes in RULES.md

Typical sections include:

- **Code Patterns** -- Naming conventions, architectural patterns, style rules
- **Common Pitfalls** -- Known issues and how to avoid them
- **Standard Approaches** -- Preferred solutions for recurring problems
- **Auto-Discovered Patterns** -- Patterns agents have learned during execution

Agents can add to the "Auto-Discovered Patterns" section as they work, building up project knowledge over time.

### Example

```markdown
# Project Rules

## Code Patterns
- Use async/await for all I/O operations
- All API responses use the {data, error, meta} envelope format
- Database queries go through the repository layer, never direct SQL

## Common Pitfalls
- The ORM lazy-loads relationships by default; always use eager loading for list endpoints
- Redis connection pool must be initialized before first request

## Standard Approaches
- Use Pydantic models for request/response validation
- Environment variables for all configuration (no hardcoded values)
```

For the full rules system specification including inheritance mechanics and the `IGNORE_PARENT_RULES` directive, see [rules-system.md](../jeeves/Ralph/docs/rules-system.md).

---

## 10. Skills System

Skills are reusable capabilities that agents load on demand. They provide specialized instructions, scripts, and workflows for specific domains. Ralph ships with three built-in skills.

### Dependency Tracking

Manages the task dependency graph. Provides scripts for parsing `deps-tracker.yaml`, detecting circular dependencies, selecting unblocked tasks, and computing transitive closures. The Manager agent uses this skill internally during task selection.

### Git Automation

Handles git operations during task execution. Creates `task/NNNN-description` branches, generates commit messages, detects and resolves conflicts in state files, and manages branch cleanup after task completion.

### System Prompt Compliance

A pre-action checklist that ensures agents follow safety guidelines, emit signals in the correct format, and read required state files before acting. This skill is invoked automatically by agents at the start of each execution.

### Installing Additional Skills

The container includes installation scripts for optional skill sets:

```bash
install-skills.sh --doc-skills    # Document creation (docx, pdf, xlsx, pptx, markitdown)
install-skills.sh --n8n-skills    # n8n workflow automation (7 skills)
install-skills.sh --all           # All available skills
```

Skill dependencies are managed automatically:

```bash
install-skill-deps.sh             # Discover and install skill dependencies
```

---

## 11. Tips and Best Practices

### Getting Started

- **Start small.** Your first Ralph project should have 5-10 tasks. This lets you observe the loop, understand the signal system, and build confidence before tackling larger projects.
- **Review decomposition carefully.** Time spent in Phase 2 saves time in Phase 3. Check that tasks are well-sized, dependencies are correct, and acceptance criteria are testable.
- **Watch the first few iterations.** Use `ralph-peek.sh` to observe the Manager selecting tasks and dispatching agents. This helps you understand the flow and catch issues early.

### Task Design

- **Keep tasks under 2 hours.** AI success rates drop significantly on longer tasks. If a task feels too big, decompose it further.
- **Write specific acceptance criteria.** "Implement the feature" is not testable. "Endpoint returns 201 with the created resource ID" is.
- **Do not pre-assign agents.** The Manager selects agents at runtime based on task keywords and TDD phase. Use clear action verbs in task titles (implement, design, test, document) so the Manager routes correctly.

### During Execution

- **Do not edit TODO.md or deps-tracker.yaml while the loop is running.** This causes git conflicts that halt the loop. Stop the loop first, make your changes, then restart.
- **Trust the retry mechanism.** A `TASK_FAILED` signal is not a crisis. The loop retries with exponential backoff, and the next attempt has the failure context in `activity.md`.
- **Use ABORT for genuine blockers.** If a task truly cannot proceed without human intervention, the `TASK_BLOCKED` signal stops the loop cleanly. Fix the issue, remove the ABORT line from TODO.md, and restart.

### Model Selection

- **Use stronger models for orchestration.** The Manager and Architect benefit from Opus-tier models that excel at reasoning and coordination.
- **Use cost-effective models for volume work.** Developer, Tester, and Writer tasks are numerous and well-defined -- Sonnet-tier models handle them efficiently.
- **Override per-run if needed.** Use `RALPH_MANAGER_MODEL=opus ralph-loop.sh` to temporarily upgrade the Manager model for a complex project.

### Project Hygiene

- **Commit Phase 2 output before starting Phase 3.** This gives you a clean baseline to diff against.
- **Use RULES.md actively.** When you notice the AI making the same mistake twice, add a rule. The next iteration will follow it.
- **Review completed tasks.** Check `.ralph/tasks/done/` periodically to verify quality. If tasks are passing with low-quality output, tighten the acceptance criteria.

---

## 12. Next Steps

Now that you understand the full workflow, explore these resources:

| Resource | What You Will Find |
|----------|--------------------|
| [example-walkthrough.md](example-walkthrough.md) | A complete end-to-end project build with realistic iteration logs, failure recovery, and TDD handoffs |
| [phase2-decomposition-guide.md](phase2-decomposition-guide.md) | Decomposition patterns (feature, layer, workflow, testing pyramid), refinement techniques, common mistakes |
| [agent-selection-guide.md](agent-selection-guide.md) | How the Manager selects agents, TDD phase routing, when to use each agent type |
| [commands.md](commands.md) | Complete flag reference for `jeeves.ps1`, `ralph-loop.sh`, `sync-agents.sh`, and all utility scripts |
| [configuration.md](configuration.md) | Full `agents.yaml` schema, `deps-tracker.yaml` format, `TODO.md` grammar, MCP server configuration, environment variables |
| [troubleshooting.md](troubleshooting.md) | Diagnostic procedures, recovery steps, and solutions for container, loop, agent, signal, and dependency issues |
| [rules-system.md](../jeeves/Ralph/docs/rules-system.md) | Deep dive into the hierarchical RULES.md system |

---

**Ralph Toolkit** -- *Because iteration beats perfection.*
