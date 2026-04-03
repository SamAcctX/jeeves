# Jeeves

**A containerized AI development environment with autonomous task execution.**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-purple.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://github.com/SamAcctX/jeeves/blob/main/LICENSE)

## Overview

Jeeves is a containerized AI development environment built on NVIDIA CUDA. It provides a reproducible, GPU-accelerated workspace with pre-configured AI tooling, MCP servers, and a web-based interface.

Ralph is the autonomous task execution framework that runs inside Jeeves. It decomposes product requirements into atomic tasks, then executes them through an iterative Manager-Worker loop where every iteration starts with fresh context. The core philosophy: **iteration beats perfection** -- failures become data for the next attempt, and eventual consistency replaces brittle long-running sessions.

## Key Features

- **Containerized Environment** -- NVIDIA CUDA base image with GPU support, web UI on port 3333, cross-platform (Windows, macOS, Linux)
- **Autonomous Task Execution** -- Ralph Loop orchestrates task completion with minimal human intervention
- **Fresh Context Per Iteration** -- Every task runs with a clean slate; no conversation history accumulates between iterations
- **11 Specialized Agent Types** -- Manager, Architect, Developer, Tester, UI Designer, Researcher, Writer, Decomposer, Decomposer-Architect, Decomposer-Researcher, Decomposer-Task-Handler
- **Standalone Agents** -- PRD Creator for requirements documents, Deepest-Thinking for deep research
- **TDD Enforcement** -- Test-Driven Development is built into the workflow; Tester validates before Developer implements
- **Dependency Tracking** -- Automatic task dependency management via deps-tracker.yaml with cycle detection
- **Signal-Based State Machine** -- Structured signals (COMPLETE, INCOMPLETE, FAILED, BLOCKED) drive task state transitions
- **Skills System** -- Pluggable skills for dependency tracking, git automation, and system prompt compliance
- **Multi-Platform AI Support** -- Works with OpenCode (default) or Claude Code
- **Pre-configured MCP Servers** -- Sequential Thinking, Fetch, Crawl4AI, SearXNG, Playwright
- **Safety Limits** -- Configurable iteration caps, exponential backoff, and automatic loop detection

## Quick Start

```bash
# Clone and build
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves
./jeeves.ps1 build
./jeeves.ps1 start

# Enter the container
./jeeves.ps1 shell

# Inside the container: initialize a project
cd /proj/my-project
ralph-init.sh

# Phase 1: Create a PRD (invoke the @prd-creator agent in OpenCode)
# Phase 2: Decompose the PRD (invoke the @decomposer agent)
# Phase 3: Run the autonomous loop
ralph-loop.sh --max-iterations 50
```

## Architecture Overview

### Jeeves Container

Jeeves builds a Docker image in three stages (base, opencode-builder, runtime) from `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04`. The container runs as user `jeeves`, exposes a web UI on port 3333, and manages the OpenCode web server as a supervisord service (`opencode-web {start|stop|restart|status|logs}`). Running `opencode` with no arguments auto-attaches the TUI to the running web server.

### Ralph Loop

Ralph operates in three phases:

1. **PRD Generation** -- Define project scope and requirements using the `@prd-creator` agent
2. **Decomposition** -- Break requirements into atomic tasks (<2 hours each) using the `@decomposer` agent, producing `TODO.md` and `deps-tracker.yaml`
3. **Execution** -- `ralph-loop.sh` runs an autonomous Manager-Worker loop:
   - Manager reads `TODO.md` + `deps-tracker.yaml`, selects the next unblocked task, invokes a specialist Worker agent
   - Worker executes with fresh context and emits a signal
   - Manager parses the signal, updates state, and exits
   - The loop script restarts the cycle with a new Manager instance

### Signal System

Workers communicate results through structured signals:

| Signal | Format | Meaning |
|--------|--------|---------|
| TASK_COMPLETE_XXXX | No message | Task finished, all criteria met |
| TASK_INCOMPLETE_XXXX | No message | Partial progress, will retry |
| TASK_FAILED_XXXX | Colon + message | Error encountered, recoverable |
| TASK_BLOCKED_XXXX | Colon + message | Requires human intervention |

### Agent Types

**Ralph Agents** (11 types, with OpenCode and Claude Code templates):

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

**Standalone Agents** (outside the Ralph Loop):

| Agent | Role |
|-------|------|
| PRD Creator | Product Requirements Document generation |
| Deepest-Thinking | Comprehensive research and investigation |

## Repository Structure

```
jeeves/
├── jeeves.ps1                          # Main PowerShell management script
├── Dockerfile.jeeves                   # Multi-stage Docker build (base, opencode-builder, runtime)
├── .tmp/                               # Generated docker-compose files (git-ignored)
├── jeeves/
│   ├── bin/                            # Installation and utility scripts
│   │   ├── ralph-init.sh              #   Initialize Ralph scaffolding
│   │   ├── ralph-loop.sh             #   Main autonomous loop orchestrator
│   │   ├── ralph-peek.sh             #   Inspect loop state
│   │   ├── ralph-paths.sh            #   Path resolution utilities
│   │   ├── ralph-validate.sh         #   Validate Ralph configuration
│   │   ├── ralph-filter-output.sh    #   Filter agent output for signals
│   │   ├── sync-agents.sh            #   Sync agent model configurations
│   │   ├── apply-rules.sh            #   Apply RULES.md hierarchy
│   │   ├── find-rules-files.sh       #   Walk directory tree for RULES.md files
│   │   ├── install-mcp-servers.sh    #   Install MCP servers
│   │   ├── install-agents.sh         #   Install AI agent templates
│   │   ├── install-skills.sh         #   Install Ralph skills
│   │   ├── install-skill-deps.sh     #   Install skill dependencies (pip/npm/apt)
│   │   ├── fetch-opencode-models.sh  #   Fetch free models for agents.yaml
│   │   └── parse_skill_deps.py       #   Parse skill dependency manifests
│   ├── PRD/                            # PRD Creator agent pipeline
│   │   ├── README-PRD.md
│   │   ├── prd-creator-*-template.md   #   Creator templates (OpenCode + Claude)
│   │   ├── prd-researcher-*-template.md #  Researcher templates
│   │   └── prd-advisor-*-template.md   #   5 domain advisor templates
│   ├── Deepest-Thinking/               # Deepest-Thinking research agent
│   │   ├── README-Deepest-Thinking.md
│   │   ├── deepest-thinking-opencode-template.md
│   │   └── deepest-thinking-claude-template.md
│   └── Ralph/                          # Ralph Loop framework
│       ├── README-Ralph.md
│       ├── docs/
│       │   ├── directory-structure.md
│       │   └── rules-system.md
│       ├── skills/
│       │   ├── dependency-tracking/   #   Task dependency management and cycle detection
│       │   ├── git-automation/        #   Branch management, commits, squash merges
│       │   ├── rationalization-defense/ # Detect/correct rationalization patterns
│       │   └── system-prompt-compliance/  # Prompt compliance verification
│       └── templates/
│           ├── agents/                #   11 agent types (OpenCode + Claude) + shared rules
│           │   └── shared/            #   10 shared rule files included by all agents
│           ├── config/                #   Configuration file templates
│           ├── prompts/               #   Prompt templates
│           └── task/                  #   Task file templates (TASK.md, activity.md, etc.)
├── docs/                               # Project documentation
│   ├── guide.md                       #   Workflow guide (setup, phases, agents, tips)
│   ├── reference.md                   #   Commands and configuration reference
│   └── troubleshooting.md            #   Common issues and solutions
├── AGENTS.md                           # Agent development guidelines
├── CONTRIBUTING.md                     # Contribution guidelines
└── LICENSE                             # AGPL-3.0
```

## Container Management

`jeeves.ps1` manages the full container lifecycle:

| Command | Aliases | Description |
|---------|---------|-------------|
| `build` | `b` | Build Docker image (flags: `--no-cache`, `--desktop`, `--install-claude-code`, `--clean`) |
| `start` | `up` | Start container (flags: `--clean`, `--dind`, `--port <n>`, `--ports <mappings>`) |
| `stop` | `down` | Stop container (flags: `--force`, `--remove`) |
| `restart` | | Restart container |
| `rm` | `remove` | Remove container |
| `shell` | `attach`, `sh` | Attach to container shell (flags: `--new`, `--raw`, `--zsh`) |
| `logs` | `log` | View container logs |
| `status` | `st` | Check container status (flag: `--all`) |
| `list` | `ls`, `ps` | List all running jeeves instances |
| `clean` | | Remove container (flags: `--image`, `--all`, `--force`) |
| `help` | `h`, `?` | Show help |

See [docs/reference.md](docs/reference.md) for the complete command and configuration reference.

## Documentation

| Document | Description |
|----------|-------------|
| [Guide](docs/guide.md) | Workflow guide: setup, Ralph phases, agent selection, decomposition, tips |
| [Reference](docs/reference.md) | Commands, flags, configuration, agents.yaml, environment variables |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |
| [Ralph Overview](jeeves/Ralph/README-Ralph.md) | Ralph Loop architecture and component index |
| [Rules System](jeeves/Ralph/docs/rules-system.md) | RULES.md hierarchical learning system |
| [AGENTS.md](AGENTS.md) | AI agent development guidelines |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

## Prerequisites

- **Docker**: Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- **PowerShell**: 7.0+
- **bash**: 4.0+
- **yq**: 4.x
- **jq**: 1.6+
- **git**: 2.x+
- **GPU** (optional): NVIDIA GPU with CUDA support for GPU-accelerated workloads

### Windows (WSL2) Requirements

If you are running Docker via WSL2 on Windows, you must add the following to `%USERPROFILE%\.wslconfig` before starting the container:

```ini
[wsl2]
firewall=false
guiApplications=true
```

Then restart WSL for the settings to take effect:

```powershell
wsl --shutdown
```

Without these settings the container will start but the `opencode-web` service will crash immediately with a segfault. See [Troubleshooting](docs/troubleshooting.md) for more details.

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
