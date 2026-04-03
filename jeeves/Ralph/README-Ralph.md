# Ralph Loop

**Autonomous AI Task Execution Framework**

Ralph Loop is an intelligent, iterative approach to autonomous software development that prioritizes fresh context over accumulated state. Named after the persistent Ralph Wiggum, it embodies the philosophy that **iteration beats perfection**.

## Core Philosophy

Traditional AI coding sessions accumulate context until the model degrades. Ralph takes a different approach:

- **Fresh Context Per Iteration**: Every task runs with a clean slate
- **Zero Context Accumulation**: No conversation history between iterations
- **Eventual Consistency**: Failures become data for the next attempt
- **Smart Zone Preservation**: Each task gets the full benefit of the model's optimal context window

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Ralph Loop Framework                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Manager Agent│  │Worker Agents │  │ Bash Wrapper │  │
│  │(Orchestrator)│  │(Specialists) │  │(Loop Control)│  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
│         ▼                 ▼                  ▼          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │Task Selection│  │Task Execution│  │  State Mgmt  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
│         └─────────┬───────┴──────────────────┘          │
│                   ▼                                     │
│            ┌──────────────┐                             │
│            │ .ralph/ Data │                             │
│            │  Repository  │                             │
│            └──────────────┘                             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

- **Manager Agent**: Spawned fresh each iteration, reads TODO.md and deps-tracker.yaml, selects unblocked tasks, invokes Worker subagents
- **Worker Agents**: Task-specific specialists (developer, tester, architect, etc.) that execute work with clean context
- **Bash Wrapper**: Simple loop (`ralph-loop.sh`) that spawns fresh Manager instances, handles backoff timing, and monitors for completion

## The Three Phases

1. **PRD Generation** -- Define project scope and requirements using the `@prd-creator` agent
2. **Decomposition** -- Break requirements into atomic tasks (<2 hours each) using the `@decomposer` agent, producing `TODO.md` and `deps-tracker.yaml`
3. **Execution** -- `ralph-loop.sh` runs an autonomous Manager-Worker loop until all tasks complete

## Quick Start

```bash
cd /proj/my-project
ralph-init.sh                              # Initialize Ralph scaffolding
# Phase 1: Create PRD (invoke @prd-creator in OpenCode)
# Phase 2: Decompose (invoke @decomposer)
ralph-loop.sh --max-iterations 50          # Phase 3: Run autonomous loop
```

## Directory Contents

```
Ralph/
├── README-Ralph.md            # This file
├── docs/
│   ├── directory-structure.md # .ralph/ directory layout
│   └── rules-system.md       # RULES.md hierarchical learning system
├── plugins/
│   └── todo.ts                # OpenCode TODO plugin
├── skills/
│   ├── dependency-tracking/   # Task dependency management and cycle detection
│   ├── git-automation/        # Branch management, commits, squash merges
│   ├── rationalization-defense/ # Detect/correct rationalization patterns
│   └── system-prompt-compliance/ # Prompt compliance enforcement
└── templates/
    ├── agents/                # 11 agent types (OpenCode + Claude) + shared rules
    ├── config/                # agents.yaml, deps-tracker.yaml, TODO.md templates
    ├── prompts/               # ralph-prompt.md, prompt-optimizer.md
    └── task/                  # TASK.md, activity.md, attempts.md templates
```

## Agent Types

| Agent | Role |
|-------|------|
| Manager | Task orchestration and agent selection |
| Architect | System design and architecture planning |
| Developer | Code implementation and debugging |
| Tester | QA, test creation, and validation |
| UI Designer | Interface design and responsive layout |
| Researcher | Investigation and analysis |
| Writer | Documentation and content creation |
| Decomposer | Task breakdown and TODO management |
| Decomposer-Architect | Architecture-focused decomposition |
| Decomposer-Researcher | Research-focused decomposition |
| Decomposer-Task-Handler | Task-level decomposition (OpenCode only) |

## Signal System

Workers communicate results through structured signals: `SIGNAL_TYPE_XXXX[: message]`

| Signal | Meaning | Loop Action |
|--------|---------|-------------|
| `TASK_COMPLETE_XXXX` | Task finished | Terminates loop |
| `TASK_INCOMPLETE_XXXX` | Needs more work | Continues loop |
| `TASK_FAILED_XXXX: msg` | Error encountered | Continues with warning |
| `TASK_BLOCKED_XXXX: msg` | Requires intervention | Terminates loop |
| `ALL TASKS COMPLETE, EXIT LOOP` | All done | Terminates loop (sentinel in TODO.md) |

## Documentation

For comprehensive documentation, see the main `docs/` folder:

| Document | Content |
|----------|---------|
| [Guide](../../docs/guide.md) | Workflow guide: setup, phases, agent selection, tips |
| [Reference](../../docs/reference.md) | Commands, flags, configuration, environment variables |
| [Troubleshooting](../../docs/troubleshooting.md) | Common issues and solutions |

### Ralph Internals

| Document | Content |
|----------|---------|
| [Directory Structure](docs/directory-structure.md) | Detailed `.ralph/` directory layout |
| [Rules System](docs/rules-system.md) | RULES.md hierarchical learning system |
| [Templates](templates/README.md) | Agent, config, and task templates |
| [Skills](skills/README.md) | Pluggable skill modules |

---

**Ralph Loop**: *Because iteration beats perfection.*
