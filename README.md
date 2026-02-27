# Ralph Toolkit - Autonomous AI Task Execution Framework

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-purple.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://github.com/SamAcctX/jeeves/blob/main/LICENSE)

> A sophisticated autonomous AI task execution framework that combines containerization, specialized agents, and intelligent task orchestration

## ✨ What is the Ralph Toolkit?

The Ralph Toolkit is an intelligent, iterative approach to autonomous software development that prioritizes fresh context over accumulated state. Named after the persistent Ralph Wiggum, it embodies the philosophy that **iteration beats perfection**.

Ralph uses a Manager-Worker architecture with:
- **Fresh Context Per Iteration**: Every task runs with a clean slate
- **Zero Context Accumulation**: No conversation history between iterations  
- **Eventual Consistency**: Failures become data for the next attempt
- **Smart Zone Preservation**: Each task gets the full benefit of the model's optimal context window

## 🚀 Key Features

### Core Capabilities
- **Autonomous Task Execution**: Ralph Loop orchestrates task completion with minimal human intervention
- **Multi-LLM Support**: Works with OpenCode (default) or Claude Code
- **Agent Specialization**: Different agents for different task types (architecture, UI, testing, development)
- **Dependency Tracking**: Automatic task dependency management via deps-tracker.yaml
- **TDD Compliance**: Test-Driven Development built into the workflow
- **Git Integration**: Branch-per-task workflow with squash merges
- **Safety Limits**: Configurable iteration caps and automatic loop detection

### Containerized Environment
- **Consistent Setup**: Docker-based container with NVIDIA CUDA base image
- **Pre-configured MCP Servers**: Sequential Thinking, Fetch, SearxNG, Playwright
- **AI Platform Support**: OpenCode with optional Claude Code support
- **Automatic Dependency Resolution**: Skills' pip/npm/apt dependencies installed automatically
- **Web UI Access**: Browser-based development at http://localhost:3333
- **Cross-platform Support**: Windows, Linux, and macOS with proper file permissions

### Specialized AI Agents
- **Manager**: Orchestrates task execution and agent selection
- **Architect**: System design and architecture planning
- **Developer**: Code implementation and debugging
- **Tester**: QA, test creation, and validation
- **UI Designer**: Interface design and responsive layout
- **Researcher**: Investigation and documentation
- **Writer**: Content creation and editing
- **Decomposer**: Task breakdown and TODO management
- **PRD Creator**: Product Requirements Document creation
- **Deepest-Thinking**: Comprehensive research and investigation

## 📦 Repository Structure

```
/proj/                         # Working directory (mounted from host)
├── jeeves.ps1                 # Main PowerShell management script
├── Dockerfile.jeeves          # Multi-stage Docker build file
├── .tmp/                      # Generated docker-compose files (git-ignored)
├── jeeves/
│   ├── bin/                   # Installation and utility scripts
│   │   ├── install-mcp-servers.sh
│   │   ├── install-agents.sh
│   │   ├── install-skill-deps.sh
│   │   └── ralph-loop.sh
│   ├── PRD/                   # PRD Creator agent templates
│   ├── Deepest-Thinking/      # Research agent templates
│   └── Ralph/                 # Ralph Loop framework
│       ├── README-Ralph.md    # Detailed Ralph documentation
│       ├── docs/              # Ralph-specific documentation
│       ├── skills/            # Task execution skills
│       │   ├── dependency-tracking/
│       │   ├── git-automation/
│       │   └── system-prompt-compliance/
│       └── templates/         # Agent and configuration templates
│           ├── agents/        # OpenCode and Claude Code agent definitions
│           ├── config/        # Configuration file templates
│           └── task/          # Task file templates
├── docs/                      # Project documentation
├── AGENTS.md                  # Agent development guidelines
├── README.md                  # This file - project overview
└── CONTRIBUTING.md            # Contribution guidelines
```

## 🛠️ Prerequisites & System Requirements

### Hardware Requirements
- **CPU**: 2+ cores for compilation tasks
- **RAM**: 8GB+ (16GB recommended for large projects)
- **Storage**: 5GB+ available disk space
- **GPU**: NVIDIA GPU with CUDA support (optional but recommended for faster processing)

### Software Requirements
- **Docker**: Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- **PowerShell**: PowerShell 7.0+ (Windows) or PowerShell Core (Linux/macOS)
- **Git**: Version control system
- **yq**: YAML processing tool (v4.x)
- **jq**: JSON processing tool (v1.6+)

## 🚀 Getting Started

### 1. Installation & Setup

```bash
# 1. Clone the repository
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves

# 2. Build the Docker image
./jeeves.ps1 build

# 3. Start the container
./jeeves.ps1 start

# 4. Access the container shell
./jeeves.ps1 shell
```

### 2. Verify Installation

Once inside the container:

```bash
# Check Ralph commands are available
command -v ralph-init.sh && echo "ralph-init.sh: OK"
command -v ralph-loop.sh && echo "ralph-loop.sh: OK"
command -v sync-agents && echo "sync-agents: OK"

# Verify tools are installed
yq --version
jq --version
git --version

# Verify Ralph templates exist
ls /opt/jeeves/Ralph/templates/
```

### 3. Initialize Your Project

```bash
# Navigate to your project directory
cd /proj/my-project

# Initialize Ralph scaffolding
ralph-init.sh

# Verify the .ralph directory structure
ls -la .ralph/
```

This creates:
- `.ralph/config/agents.yaml` - Agent model mappings
- `.ralph/config/deps-tracker.yaml` - Task dependencies
- `.ralph/tasks/TODO.md` - Task checklist
- `.opencode/agents/` and `.claude/agents/` - Agent definitions
- `RULES.md` - Project-specific rules

## 📝 Basic Usage Example

### Building a Simple REST API

#### Step 1: Create a PRD (Product Requirements Document)

```bash
mkdir -p .ralph/specs
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

#### Step 2: Decompose the PRD

```bash
# Invoke the decomposer agent (in OpenCode or Claude Code)
# @decomposer
```

The decomposer will:
- Break down requirements into atomic tasks (<2 hours each)
- Analyze dependencies between tasks
- Generate TODO.md with task checklist
- Create task folders in `.ralph/tasks/XXXX/`
- Generate deps-tracker.yaml

#### Step 3: Start the Ralph Loop

```bash
# Start the autonomous task execution loop
ralph-loop.sh --max-iterations 50

# Or use Claude Code instead of OpenCode
ralph-loop.sh --tool claude --max-iterations 50
```

#### Step 4: Monitor Progress

```bash
# Check task status
cat .ralph/tasks/TODO.md

# View detailed activity for a task
cat .ralph/tasks/0001/activity.md

# Check loop status in real-time
watch -n 5 cat .ralph/tasks/TODO.md
```

## 🎯 Ralph Loop Commands

### ralph-init.sh
Initialize Ralph scaffolding in your project.

```bash
ralph-init.sh [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help message
- `--force`, `-f`: Skip overwrite prompts
- `--rules`: Force RULES.md creation

### ralph-loop.sh
Main loop orchestration script.

```bash
ralph-loop.sh [OPTIONS]
```

**Options:**
- `--tool {opencode|claude}`: Select AI tool (default: opencode)
- `--max-iterations N`: Maximum iterations (default: 100)
- `--skip-sync`: Skip pre-loop agent synchronization
- `--no-delay`: Disable exponential backoff delays
- `--dry-run`: Print commands without executing
- `--help`, `-h`: Show help message

### sync-agents
Synchronize agent model configurations from agents.yaml to agent files.

```bash
sync-agents [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help message
- `--tool TOOL`, `-t`: Specify tool (opencode|claude)
- `--config FILE`, `-c`: Custom agents.yaml path
- `--show`, `-s`: Show parsed agents (don't sync)
- `--dry-run`, `-d`: Show what would be updated

## 🏗️ Core Components

### The Three Phases of Ralph

#### Phase 1: PRD Generation (User-Driven)
- Define project scope and objectives
- Specify technical requirements
- Document success criteria
- Create `.ralph/specs/PRD-*.md`

#### Phase 2: Decomposition (Agent-Assisted)
- Invoke `@decomposer` agent
- Review generated task breakdown
- Refine task granularity (each <2 hours)
- Validate dependencies
- Confirm task count (<9999 tasks)

#### Phase 3: Execution (Autonomous Loop)
- Run `ralph-loop.sh`
- Manager selects unblocked tasks
- Workers execute with fresh context
- State updates after each iteration
- Exponential backoff between iterations

### Skills System

Ralph includes specialized skills for task execution:

#### Dependency Tracking
- Scripts: `deps-parse.sh`, `deps-cycle.sh`, `deps-select.sh`, `deps-update.sh`, `deps-closure.sh`
- Purpose: Manage task dependencies and detect cycles
- Usage: Analyze and update dependency relationships

#### Git Automation
- Scripts: `git-context.sh`, `git-commit-msg.sh`, `task-branch-create.sh`, `squash-merge.sh`, etc.
- Purpose: Integrate with Git workflows
- Usage: Branch management, commit messages, conflict resolution

#### System Prompt Compliance
- Purpose: Ensure compliance with system prompts and guidelines
- Usage: Safety and compliance checks

### Agent Templates

Ralph provides pre-configured agent templates for:
- **Manager**: Task orchestration
- **Architect**: System design
- **Developer**: Implementation
- **Tester**: QA and testing
- **UI Designer**: Interface design
- **Researcher**: Investigation
- **Writer**: Documentation
- **Decomposer**: Task breakdown
- **PRD Creator**: Requirements creation
- **Deepest-Thinking**: Research

## 📚 Documentation

### Core Documentation
- [README-Ralph.md](jeeves/Ralph/README-Ralph.md) - Detailed Ralph Loop documentation
- [Ralph Directory Structure](jeeves/Ralph/docs/directory-structure.md) - Directory organization
- [Rules System](jeeves/Ralph/docs/rules-system.md) - RULES.md hierarchical learning system
- [Agent Templates](jeeves/Ralph/templates/README.md) - Agent template documentation
- [Skills Overview](jeeves/Ralph/skills/README.md) - Skills system overview

### Project Documentation
- [Command Reference](docs/commands.md) - Complete command documentation
- [Configuration Guide](docs/configuration.md) - Configuration options
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions
- [How-to Guide](docs/how-to-guide.md) - Step-by-step tutorials
- [AGENTS.md](AGENTS.md) - Agent development guidelines

### Jeeves System Documentation
- [Jeeves Commands](jeeves/docs/commands.md) - Jeeves container commands
- [Jeeves Configuration](jeeves/docs/configuration.md) - Container configuration
- [Troubleshooting](jeeves/docs/troubleshooting.md) - Jeeves-specific issues
- [Agent Selection Guide](jeeves/docs/agent-selection-guide.md) - Agent choice recommendations

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Development Setup

```bash
# Clone repository
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves

# Create development branch
git checkout -b feature/your-feature-name

# Make changes and test
./jeeves.ps1 build --no-cache
./jeeves.ps1 start

# Submit pull request
git add .
git commit -m "Add your feature"
git push origin feature/your-feature-name
```

## 🆘 Support & Community

- **Issues**: [GitHub Issues](https://github.com/SamAcctX/jeeves/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SamAcctX/jeeves/discussions)
- **Documentation**: [Full Docs](https://github.com/SamAcctX/jeeves/tree/main/docs)

## 📄 License & Legal

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses
- **OpenCode**: MIT License
- **Claude Code**: Commercial License (Terms of Service)
- **MCP Servers**: Various Open Source Licenses

---

**Built with ❤️ by the Ralph team**

*Iteration beats perfection.*
