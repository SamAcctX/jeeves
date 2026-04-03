# Jeeves

**A containerized AI development environment with autonomous task execution.**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-purple.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://github.com/SamAcctX/jeeves/blob/main/LICENSE)

## Overview

Jeeves is a containerized AI development environment built on NVIDIA CUDA. It provides a reproducible, GPU-accelerated workspace with pre-configured AI tooling, MCP servers, and a web-based interface.

Ralph is the autonomous task execution framework that runs inside Jeeves. It decomposes product requirements into atomic tasks, then executes them through an iterative Manager-Worker loop where every iteration starts with fresh context. The core philosophy: **iteration beats perfection** -- failures become data for the next attempt, and eventual consistency replaces brittle long-running sessions.

### Key Features

- **Containerized Environment** -- NVIDIA CUDA base image, web UI on port 3333, cross-platform (Windows, macOS, Linux)
- **Autonomous Task Execution** -- Ralph Loop orchestrates task completion with minimal human intervention
- **Fresh Context Per Iteration** -- Every task runs with a clean slate; no conversation history accumulates
- **11 Specialized Agent Types** -- Manager, Architect, Developer, Tester, UI Designer, Researcher, Writer, Decomposer, and 3 decomposer variants
- **Standalone Agents** -- PRD Creator pipeline for requirements documents, Deepest-Thinking for deep research
- **TDD Enforcement** -- Tester writes tests before Developer implements
- **Dependency Tracking** -- Automatic task dependency management with cycle detection
- **Signal-Based State Machine** -- Structured signals (COMPLETE, INCOMPLETE, FAILED, BLOCKED) drive task state transitions
- **4 Built-in Skills** -- Dependency tracking, git automation, rationalization defense, system prompt compliance
- **Multi-Platform AI Support** -- Works with OpenCode (default) or Claude Code
- **5 Pre-configured MCP Servers** -- Sequential Thinking, Fetch, Crawl4AI, SearXNG, Playwright

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

Running `./jeeves.ps1` without arguments opens an interactive menu for all container operations.

## How It Works

Jeeves builds a Docker image in three stages (base, opencode-builder, runtime) from `nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04`. The container runs as user `jeeves`, exposes a web UI on port 3333, and manages the OpenCode web server via supervisord.

Ralph operates in three phases:

1. **PRD Generation** -- Define project scope using the `@prd-creator` agent pipeline (Creator, domain Advisors, Researcher)
2. **Decomposition** -- Break requirements into atomic tasks (<2 hours each) using the `@decomposer` agent, producing `TODO.md` and `deps-tracker.yaml`
3. **Execution** -- `ralph-loop.sh` runs an autonomous Manager-Worker loop:
   - Manager reads `TODO.md` + `deps-tracker.yaml`, selects the next unblocked task, invokes a specialist Worker
   - Worker executes with fresh context and emits a signal
   - Manager parses the signal, updates state, and exits
   - The loop script restarts the cycle with a new Manager instance

Only `TASK_BLOCKED` and `ALL TASKS COMPLETE` terminate the loop. All other signals (COMPLETE, INCOMPLETE, FAILED) continue to the next iteration.

## Container Management

`jeeves.ps1` manages the full container lifecycle. Most users interact through the interactive menu (`./jeeves.ps1` with no arguments). CLI commands are also available:

| Command | Aliases | Description |
|---------|---------|-------------|
| `build` | `b` | Build Docker image |
| `start` | `up` | Start container |
| `stop` | `down` | Stop container |
| `shell` | `attach`, `sh` | Attach to container shell |
| `status` | `st` | Show container status |
| `list` | `ls`, `ps` | List all running instances |
| `clean` | | Remove container |
| `help` | `h`, `?` | Show help |

See [docs/reference.md](docs/reference.md) for all flags and configuration options.

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
