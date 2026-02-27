# Ralph Toolkit HOW-TO Guide

## 1. Introduction

### What is Ralph?
Ralph is an autonomous AI task execution framework that embodies the philosophy "iteration beats perfection". Named after the persistent Ralph Wiggum, it uses a manager-worker architecture with fresh context per iteration to avoid the degradation issues of traditional AI coding sessions.

### Core Philosophy
- **Fresh Context Per Iteration**: Every task runs with a clean slate
- **Zero Context Accumulation**: No conversation history between iterations
- **Eventual Consistency**: Failures become data for the next attempt
- **Smart Zone Preservation**: Each task gets the full benefit of the model's optimal context window

### Key Features
- Multi-LLM support (OpenCode default, Claude Code optional)
- Agent specialization (manager, architect, developer, tester, UI designer, researcher, writer, decomposer)
- Automatic task dependency management
- Test-Driven Development (TDD) built into the workflow
- Git integration with branch-per-task workflow
- Configurable iteration caps and automatic loop detection

## 2. Prerequisites and System Requirements

### System Requirements
- **Operating System**: Windows 10/11, macOS 10.15+, or Linux (Ubuntu 18.04+)
- **Docker**: Latest stable version (for containerized installation)
- **RAM**: Minimum 8GB (16GB recommended for larger projects)
- **Storage**: At least 10GB of free disk space
- **Network**: Internet connection for downloading dependencies and accessing LLMs

### Required Tools
Ralph requires the following tools to be installed:

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | Latest | Container environment |
| bash | 4.0+ | Script execution |
| yq | 4.x | YAML processing |
| jq | 1.6+ | JSON processing |
| git | 2.x+ | Version control |

### Installing Prerequisites

#### Ubuntu/Debian
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

#### macOS
```bash
# Using Homebrew
brew install yq jq

# Verify installations
yq --version
jq --version
```

#### Windows
For Windows, use WSL2 (Windows Subsystem for Linux) to run Ralph. Follow the [official WSL2 installation guide](https://learn.microsoft.com/en-us/windows/wsl/install) and then install the prerequisites within your WSL2 distribution.

## 3. Installation and Setup Process

### Container Setup (Recommended)
Ralph is designed to run inside a Docker container with persistent volume mounts. This ensures a consistent environment across all platforms.

```powershell
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

### Local Installation (Alternative)
For advanced users who prefer not to use Docker, you can install Ralph locally:

1. Clone the repository
2. Add `jeeves/bin/` to your PATH
3. Install the required tools (yq, jq, git)
4. Configure your environment variables

## 4. Initializing a New Ralph Project

### Project Initialization
Initialize Ralph in your project directory:

```bash
cd /proj/my-project
ralph-init.sh

# Or with force mode (overwrites existing files)
ralph-init.sh --force
```

This creates the following structure:
- `.ralph/` - Main Ralph directory
- `.ralph/config/agents.yaml` - Agent model mappings
- `.ralph/config/deps-tracker.yaml` - Task dependencies
- `.ralph/tasks/TODO.md` - Task checklist
- `.ralph/specs/` - Specifications directory (for PRDs)
- `.opencode/agents/` and `.claude/agents/` - Agent definitions
- `RULES.md` - Project-specific rules

### ralph-init.sh Options
```bash
ralph-init.sh [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help
- `--force`, `-f`: Skip overwrite prompts
- `--rules`: Force RULES.md creation

## 5. Creating and Working with PRDs (Product Requirements Documents)

### What is a PRD?
A Product Requirements Document (PRD) is a comprehensive description of what you're building, why you're building it, and how it should behave. It serves as the foundation for task decomposition.

### PRD Structure
Create a PRD in `.ralph/specs/` with the following sections:

```markdown
# PRD: [Feature Name]

## Overview
Description of what we're building and why it's valuable.

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

## User Stories
- As a user, I can...
- As an admin, I can...

## Edge Cases
- What happens when...
- How does it handle...
```

### Example PRD
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

## User Stories
- As a user, I can retrieve a list of all users
- As a user, I can create a new user
- As a user, I can update an existing user
- As a user, I can delete a user

## Edge Cases
- Handling invalid user IDs
- Duplicate user email addresses
- Large numbers of users (pagination)
EOF
```

### PRD Best Practices
- Be specific and measurable
- Avoid technical jargon
- Focus on user needs
- Include success criteria
- Document edge cases

## 6. Task Decomposition Process

### What is Task Decomposition?
Task decomposition is the process of breaking down a PRD into atomic tasks that can be completed in less than 2 hours each. This makes it easier for the AI agents to work on them incrementally.

### Running the Decomposer Agent
Run the decomposer agent to break down the PRD into tasks:

```bash
# In OpenCode
opencode --agent decomposer

# In Claude Code
claude -p --dangerously-skip-permissions --model claude-sonnet-4.5
```

### Decomposition Prompt
Provide this prompt to the decomposer agent:

```
Decompose the PRD at .ralph/specs/PRD-simple-api.md into atomic tasks (<2 hours each).
Focus on:
1. Project setup
2. Database schema
3. API endpoints (one task per endpoint)
4. Testing
5. Documentation

Generate:
- TODO.md with task checklist
- deps-tracker.yaml with dependencies
- Task folders in .ralph/tasks/XXXX/
```

### Example Decomposition
The decomposer might generate a TODO.md like this:

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

### Dependency Management
The decomposer will also create a `deps-tracker.yaml` file to track task dependencies:

```yaml
tasks:
  0001:
    depends_on: []
    blocks: [0002, 0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010]

  0002:
    depends_on: [0001]
    blocks: [0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010]

  0003:
    depends_on: [0002]
    blocks: [0004, 0005, 0006, 0007, 0008, 0009, 0010]

  0004:
    depends_on: [0003]
    blocks: [0009, 0010]

  0005:
    depends_on: [0003]
    blocks: [0009, 0010]

  0006:
    depends_on: [0003]
    blocks: [0009, 0010]

  0007:
    depends_on: [0003]
    blocks: [0009, 0010]

  0008:
    depends_on: [0003]
    blocks: [0009, 0010]

  0009:
    depends_on: [0004, 0005, 0006, 0007, 0008]
    blocks: [0010]

  0010:
    depends_on: [0009]
    blocks: []
```

### Task Decomposition Best Practices
- Keep tasks <2 hours in duration
- Make tasks atomic and focused
- Define clear dependencies
- Include all phases (setup, implementation, testing, documentation)
- Review and adjust the decomposition before starting the loop

## 7. Running the Ralph Loop

### What is the Ralph Loop?
The Ralph Loop is the core execution engine that orchestrates the completion of tasks. It uses a manager agent to select tasks, assign them to specialized workers, and track progress.

### Starting the Loop
```bash
# Default run (OpenCode, 100 iterations max)
ralph-loop.sh

# Or with specific options
ralph-loop.sh --tool claude --max-iterations 50

# Fast mode (no delays, skip sync)
ralph-loop.sh --no-delay --skip-sync

# Unlimited iterations
ralph-loop.sh --max-iterations 0
```

### ralph-loop.sh Options
```bash
ralph-loop.sh [OPTIONS]
```

**Options:**
- `--tool {opencode|claude}`: Select AI tool (default: opencode)
- `--max-iterations N`: Maximum iterations (default: 100, 0=unlimited)
- `--skip-sync`: Skip pre-loop agent synchronization
- `--no-delay`: Disable exponential backoff delays
- `--dry-run`: Print commands without executing
- `--help`, `-h`: Show help

### Monitoring Progress
- **Terminal Output**: Shows loop status and task completion
- **TODO.md**: Checkboxes update as tasks complete
- **Activity Logs**: `.ralph/tasks/XXXX/activity.md` for detailed progress
- **Attempts Log**: `.ralph/tasks/XXXX/attempts.md` for attempt history

### Stopping the Loop
- Press `Ctrl+C` for graceful shutdown
- Or add an ABORT line in TODO.md: `ABORT: HELP NEEDED FOR TASK XXXX: Reason`

## 8. Understanding the Ralph Workflow Phases

### Phase 1: PRD Generation
- **Goal**: Define what to build
- **Output**: PRD document
- **Key Agent**: PRD Creator (optional, for automatic PRD generation)

### Phase 2: Decomposition
- **Goal**: Break PRD into manageable tasks
- **Output**: TODO.md, deps-tracker.yaml, task folders
- **Key Agent**: Decomposer

### Phase 3: Execution (Ralph Loop)
- **Goal**: Complete all tasks
- **Process**:
  1. Manager agent selects an unblocked task
  2. Worker agent executes the task
  3. Results are evaluated
  4. Task status is updated
  5. Loop continues to next task
- **Key Agents**: Manager, Architect, Developer, Tester, UI Designer, Researcher, Writer

## 9. Working with Agents and Templates

### Agent Types
Ralph supports specialized agents for different roles:

| Agent | Role |
|-------|------|
| Manager | Orchestrates task execution and loop management |
| Architect | Designs system architecture and technical decisions |
| Developer | Implements code and fixes bugs |
| Tester | Creates and runs tests |
| UI Designer | Designs user interfaces and frontend components |
| Researcher | Conducts research and gathers information |
| Writer | Creates documentation and content |
| Decomposer | Breaks PRDs into tasks |

### Agent Configuration
Located at `.ralph/config/agents.yaml`:

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

  tester:
    description: "QA - test creation and validation"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5
```

**Notes:**
- Use `inherit` for OpenCode to use the default model
- Changes take effect after running `sync-agents`

### Synchronizing Agents
```bash
sync-agents [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help
- `--tool TOOL`: Specify tool (opencode|claude)
- `--config FILE`: Custom agents.yaml path
- `--show`: Show parsed agents (don't sync)
- `--dry-run`: Show what would be updated

### Custom Agent Creation
1. Create a new agent template:
   ```bash
   cat > .opencode/agents/my-specialist.md << 'EOF'
   ---
   description: "My specialist agent"
   mode: subagent
   temperature: 0.1
   
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
   
   # My Specialist Agent
   
   Describe what this agent does and how it should approach tasks...
   EOF
   ```

2. Add to agents.yaml:
   ```yaml
   agents:
     my-specialist:
       description: "My specialist agent"
       preferred:
         opencode: inherit
         claude: claude-sonnet-4.5
       fallback:
         opencode: inherit
         claude: claude-sonnet-4.5
   ```

3. Sync agents: `sync-agents`

## 10. Skills and Capabilities

### What are Skills?
Skills are reusable capabilities that agents can use to perform specific tasks. They include scripts and instructions for common activities.

### Available Skills

#### Dependency Tracking Skill
Manages task dependencies:
- **Scripts**: `deps-parse.sh`, `deps-cycle.sh`, `deps-select.sh`, `deps-update.sh`, `deps-closure.sh`
- **Functions**: Parse TODO.md, detect cycles, select unblocked tasks, update dependencies

#### Git Automation Skill
Handles Git operations:
- **Scripts**: `git-context.sh`, `git-commit-msg.sh`, `task-branch-create.sh`, `squash-merge.sh`, `branch-cleanup.sh`, `git-conflict.sh`, `state-file-conflicts.sh`, `configure-gitignore.sh`, `git-wrapper.sh`
- **Features**: Branch per task, commit message formatting, conflict resolution

#### System Prompt Compliance Skill
Ensures compliance with safety guidelines and restrictions.

### Skill Architecture
Each skill has:
- `SKILL.md`: Skill description and usage instructions
- `scripts/`: Shell scripts implementing the skill
- `tests/`: Test files for verification
- `activity.md`: Activity template for agent communication

## 11. Configuration Options

### Configuration Files

#### agents.yaml
Agent model mappings (see Section 9 for details)

#### deps-tracker.yaml
Task dependency tracking:

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

#### TODO.md
Master task checklist:

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

**Strict Grammar:**
- Task lines: `- [ ] 0001: Task title` or `- [x] 0001: Task title`
- Blockage lines: `ABORT: HELP NEEDED FOR TASK XXXX: Reason`
- Completion line: `ALL TASKS COMPLETE, EXIT LOOP`

#### RULES.md
Project-specific rules and guidelines:

```markdown
# Project Rules

## Code Patterns
- Use async/await instead of callbacks
- Always handle errors with try/catch
- Use TypeScript for type safety

## Common Pitfalls
- Avoid nested promises
- Don't overuse global variables
- Be careful with state management

## Standard Approaches
- API responses should be in JSON format
- Use JWT for authentication
- Store configuration in environment variables
```

### Environment Variables
- `RALPH_DEBUG`: Enable verbose output (set to 1)
- `RALPH_BACKOFF_BASE`: Base delay for exponential backoff (default: 2)
- `RALPH_BACKOFF_MAX`: Maximum delay (default: 60)
- `RALPH_MANAGER_MODEL`: Override manager agent model

## 12. Troubleshooting Common Issues

### "yq not found" during ralph-init.sh
**Solution:**
```bash
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### "Ralph directory not found" when starting loop
**Solution:**
```bash
ralph-init.sh
```

### Git conflicts in TODO.md
**Cause:** Editing TODO.md while loop is running

**Solution:**
1. Stop the loop (Ctrl+C)
2. Resolve conflicts manually:
   ```bash
   vim .ralph/tasks/TODO.md
   git add .ralph/tasks/TODO.md
   ```
3. Restart loop: `ralph-loop.sh`

### Loop stuck on same task
**Solution:**
1. Check task activity: `cat .ralph/tasks/XXXX/activity.md`
2. Look for patterns in attempts.md
3. If blocked, add to TODO.md: `ABORT: HELP NEEDED FOR TASK XXXX: Description of issue`
4. Fix manually, then restart

### "Agent not found" errors
**Solution:**
1. Sync agents: `sync-agents`
2. Verify agents.yaml has the agent type defined
3. Check agent files exist in `.opencode/agents/` or `.claude/agents/`

### Debug Mode
Run with verbose output:
```bash
export RALPH_DEBUG=1
ralph-loop.sh
```

### Log Files
Ralph automatically creates log files at: `.ralph/logs/ralph-loop-YYYYMMDD-HHMMSS.log`

## 13. Best Practices for Effective Use

### Getting Started
1. **Start Small**: Begin with 5-10 tasks for your first project
2. **Review Decomposition**: Always review TODO.md before starting loop
3. **Monitor Early**: Watch first few iterations to ensure proper behavior
4. **Iterate on Process**: Adjust task granularity based on results

### Task Management
1. **Task Sizing**: Keep tasks <2 hours for optimal performance
2. **Dependency Management**: Clearly define dependencies in deps-tracker.yaml
3. **Git Discipline**: Don't edit TODO.md or deps-tracker.yaml while loop is running
4. **Documentation**: Use RULES.md to capture project-specific patterns

### Performance Optimization
1. **Model Selection**: Use more capable models for complex tasks (e.g., Claude Opus for architecture)
2. **Backoff Configuration**: Adjust RALPH_BACKOFF_BASE and RALPH_BACKOFF_MAX
3. **Iteration Limits**: Set appropriate max iterations based on project size

### Advanced Usage
1. **Custom Agents**: Create specialized agents for unique tasks
2. **Rule-Based Learning**: Capture patterns in RULES.md for future iterations
3. **Integration**: Add Ralph to your CI/CD pipeline for automated execution

## 14. Example Project Walkthrough

### Building a Simple REST API with Ralph

1. **Initialize Project**:
   ```bash
   cd /proj/my-api
   ralph-init.sh
   ```

2. **Create PRD**:
   (see Section 5 for PRD creation)

3. **Run Decomposition**:
   (see Section 6 for decomposition process)

4. **Review TODO.md**:
   (see Section 6 for example TODO.md)

5. **Start Ralph Loop**:
   ```bash
   ralph-loop.sh --max-iterations 50
   ```

6. **Completion**:
   When you see `ALL TASKS COMPLETE, EXIT LOOP`, the loop terminates automatically.

## 15. Command Reference

### ralph-init.sh
Initialize Ralph scaffolding:
```bash
ralph-init.sh [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help
- `--force`, `-f`: Skip overwrite prompts
- `--rules`: Force RULES.md creation

### ralph-loop.sh
Main loop execution:
```bash
ralph-loop.sh [OPTIONS]
```

**Options:**
- `--tool {opencode|claude}`: Select AI tool (default: opencode)
- `--max-iterations N`: Maximum iterations (default: 100, 0=unlimited)
- `--skip-sync`: Skip pre-loop agent synchronization
- `--no-delay`: Disable exponential backoff delays
- `--dry-run`: Print commands without executing
- `--help`, `-h`: Show help

### sync-agents
Synchronize agent model configurations:
```bash
sync-agents [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help
- `--tool TOOL`: Specify tool (opencode|claude)
- `--config FILE`: Custom agents.yaml path
- `--show`: Show parsed agents (don't sync)
- `--dry-run`: Show what would be updated

### apply-rules.sh
Apply project rules:
```bash
apply-rules.sh
```

### find-rules-files.sh
Find rules files in the project:
```bash
find-rules-files.sh
```

### ralph-paths.sh
Detect Ralph paths:
```bash
ralph-paths.sh
```

### ralph-validate.sh
Validate Ralph configuration:
```bash
ralph-validate.sh
```

---

**Ralph Toolkit**: *Because iteration beats perfection.*