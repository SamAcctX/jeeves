# Example Project Walkthrough: Task Management CLI

This walkthrough demonstrates using Ralph Loop to build a complete project from start to finish. We will create a **Task Management CLI** - a simple Python command-line tool for managing todo lists - using all three phases of the Ralph workflow.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Phase 1: Creating the PRD](#phase-1-creating-the-prd)
4. [Phase 2: Task Decomposition](#phase-2-task-decomposition)
5. [Phase 3: Execution Loop](#phase-3-execution-loop)
6. [Results](#results)
7. [Lessons Learned](#lessons-learned)
8. [Next Steps](#next-steps)

## Introduction

### Example Project Overview

**Project:** Task Management CLI (Python)

**Features:**
- Add tasks with description and priority
- List all tasks with filtering by status
- Mark tasks as complete
- Delete tasks
- Persistent JSON storage
- Simple and intuitive commands

**Technical Stack:**
- Language: Python 3.8+
- Storage: JSON file (~/.tasks.json)
- Interface: CLI commands with argparse

### Why This Example?

This walkthrough uses a real, concrete project to demonstrate:
- Full Ralph workflow from initialization to completion
- How runtime dependencies are discovered and handled
- How failures are recovered and retried
- How git integration works with branch-per-task
- Realistic iteration logs with actual signal patterns

## Prerequisites

Before starting, ensure you have:

1. **Ralph initialized** in your container environment
2. **Python 3.8+** available
3. **Basic familiarity with bash**
4. **Required tools installed**: yq, jq, git

Verify your environment:
```bash
# Check required tools
command -v yq && echo "yq: OK"
command -v jq && echo "jq: OK"
command -v git && echo "git: OK"
command -v ralph-init.sh && echo "ralph-init.sh: OK"
```

## Phase 1: Creating the PRD

### Step 1: Initialize Ralph in Project

First, create your project directory and initialize Ralph:

```bash
mkdir task-cli && cd task-cli
ralph-init.sh
```

**Output:**
```
[INFO] Starting Ralph initialization...
[INFO] Validating required tools...
[SUCCESS] yq found: /usr/local/bin/yq
[SUCCESS] jq found: /usr/bin/jq
[SUCCESS] git found: /usr/bin/git
[INFO] Project root detected: /proj/task-cli
[INFO] Checking for RULES.md...
[INFO] Configuring git integration...
[INFO] Current branch: main
[SUCCESS] Updated .gitignore with Ralph exclusions
[INFO] Creating Ralph directory structure...
[SUCCESS] Created directory: .ralph/config
[SUCCESS] Created directory: .ralph/prompts
[SUCCESS] Created directory: .ralph/tasks
[SUCCESS] Created directory: .ralph/specs
[SUCCESS] Created directory: .ralph/tasks/done
[INFO] Copying Ralph templates...
[SUCCESS] Template source validated: /opt/jeeves/Ralph/templates
[SUCCESS] Created: config/agents.yaml
[SUCCESS] Created: TODO.md
[SUCCESS] Created: config/deps-tracker.yaml
[SUCCESS] Created: TASK.md
[SUCCESS] Created: activity.md
[SUCCESS] Created: attempts.md
[SUCCESS] Template copying completed: 10 files copied
[SUCCESS] Ralph initialization completed successfully!
[INFO] Your Ralph project structure is ready for use
```

### Step 2: Write the PRD

Create the Product Requirements Document:

```bash
mkdir -p .ralph/specs
cat > .ralph/specs/PRD-task-cli.md << 'EOF'
# Task Management CLI - Product Requirements

## Overview
Simple CLI tool for managing personal todo lists.

## Features
1. Add tasks with description and priority
2. List all tasks (filter by status)
3. Mark tasks as complete
4. Delete tasks
5. Persistent storage in JSON file

## Technical Specs
- Language: Python 3.8+
- Storage: JSON file (~/.tasks.json)
- Interface: CLI commands
  - `task add "Description" --priority high`
  - `task list --status pending`
  - `task complete <id>`
  - `task delete <id>`

## Acceptance Criteria
- All commands work without errors
- Data persists between sessions
- Handles edge cases (empty list, invalid IDs)
- Has --help for all commands
EOF
```

## Phase 2: Task Decomposition

### Step 3: Run Decomposition

Invoke the decomposer agent to decompose the PRD into tasks:

```bash
# Read the PRD and pipe to the decomposer agent
cat .ralph/specs/PRD-task-cli.md | opencode --agent decomposer --prompt "Decompose this PRD into atomic tasks"
```

The decomposer agent will:
1. Read the PRD document
2. Break down requirements into atomic tasks (<2 hours each)
3. Analyze dependencies between tasks
4. Generate TODO.md with task checklist
5. Create task folders in `.ralph/tasks/XXXX/`
6. Generate deps-tracker.yaml

### Step 4: Generated Tasks

The decomposition creates 10 tasks:

| Task ID | Title | Description | Complexity |
|---------|-------|-------------|------------|
| 0001 | Set up project structure | Create directory layout, setup.py, requirements.txt | S |
| 0002 | Implement Task model | Task class with id, description, priority, status; JSON serialization | S |
| 0003 | Implement storage module | Read/write ~/.tasks.json, handle file not found, data validation | M |
| 0004 | Implement 'add' command | Parse arguments, create task, save to storage | S |
| 0005 | Implement 'list' command | Display formatted table, filter by status, handle empty list | S |
| 0006 | Implement 'complete' command | Find task by ID, update status, save changes | S |
| 0007 | Implement 'delete' command | Find and remove task, confirm before delete | S |
| 0008 | Add CLI entry point | argparse setup, command routing, help text | M |
| 0009 | Write tests | Unit tests for Task model, integration tests for commands | M |
| 0010 | Create documentation | README.md with usage examples | S |

### Step 5: Initial TODO.md

The generated `.ralph/tasks/TODO.md`:

```markdown
# Task Management CLI Implementation

## Setup
- [ ] 0001: Set up project structure

## Core
- [ ] 0002: Implement Task model
- [ ] 0003: Implement storage module

## Commands
- [ ] 0004: Implement 'add' command
- [ ] 0005: Implement 'list' command
- [ ] 0006: Implement 'complete' command
- [ ] 0007: Implement 'delete' command

## Polish
- [ ] 0008: Add CLI entry point
- [ ] 0009: Write tests
- [ ] 0010: Create documentation
```

### Step 6: Dependency Analysis

The generated `.ralph/tasks/deps-tracker.yaml`:

```yaml
tasks:
  0001:
    depends_on: []
    blocks: [0002, 0003]
  0002:
    depends_on: [0001]
    blocks: [0004, 0005, 0006, 0007]
  0003:
    depends_on: [0001]
    blocks: [0004, 0005, 0006, 0007]
  0004:
    depends_on: [0002, 0003]
    blocks: [0008]
  0005:
    depends_on: [0002, 0003]
    blocks: [0008]
  0006:
    depends_on: [0002, 0003]
    blocks: [0008]
  0007:
    depends_on: [0002, 0003]
    blocks: [0008]
  0008:
    depends_on: [0004, 0005, 0006, 0007]
    blocks: [0009, 0010]
  0009:
    depends_on: [0008]
    blocks: []
  0010:
    depends_on: [0008]
    blocks: []
```

## Phase 3: Execution Loop

### Step 7: Start the Loop

Begin autonomous execution:

```bash
./ralph-loop.sh
```

**Initial Output:**
```
[INFO] Ralph Loop initialized
[INFO]   Tool: opencode
[INFO]   Max iterations: 100
[INFO]   Project root: /proj/task-cli
[INFO] Running agent synchronization...
[SUCCESS] Agent sync completed in 2s
[INFO] Starting Ralph Loop (iteration 0, max: 100)
```

### Step 8: Iteration Log

The loop proceeds through iterations, selecting and executing tasks:

**Iteration 0:**
```
[INFO] === Iteration 0 ===
[INFO] Invoking Manager agent (iteration 0, tool: opencode)...
[INFO] Invoking OpenCode Manager...

[Manager] Reading TODO.md...
[Manager] Selecting unblocked task...
[Manager] Selected: 0001 (Set up project structure)
[Manager] Invoking @developer agent...

[Worker 0001] Creating project structure...
[Worker 0001] Writing setup.py...
[Worker 0001] Writing requirements.txt...
[Worker 0001] Creating task_cli/ directory...
[Worker 0001] TASK_COMPLETE_0001

[Manager] Marking 0001 complete
[Manager] Moving task 0001 to done/ folder
[SUCCESS] Task 0001 completed
```

**Iteration 1-2 (Parallel Execution):**
Tasks 0002 and 0003 execute independently (no dependencies between them):

```
[INFO] === Iteration 1 ===
[Manager] Reading TODO.md...
[Manager] Selected: 0002 (Implement Task model)
[Manager] Invoking @developer agent...

[Worker 0002] Creating Task class...
[Worker 0002] Implementing JSON serialization...
[Worker 0002] TASK_COMPLETE_0002

[SUCCESS] Task 0002 completed

[INFO] === Iteration 2 ===
[Manager] Selected: 0003 (Implement storage module)
[Manager] Invoking @developer agent...

[Worker 0003] Creating Storage class...
[Worker 0003] Implementing read/write methods...
[Worker 0003] TASK_COMPLETE_0003

[SUCCESS] Task 0003 completed
```

**Iteration 3 (Runtime Dependency Discovery):**

```
[INFO] === Iteration 3 ===
[Manager] Selected: 0004 (Implement 'add' command)
[Manager] Invoking @developer agent...

[Worker 0004] Starting implementation...
[Worker 0004] ERROR: Storage module missing 'update' method
[Worker 0004] Need: Task 0003 to add update method before continuing
[Worker 0004] TASK_INCOMPLETE_0004: Depends on storage.update() method

[Manager] Discovered runtime dependency
[Manager] Updating deps-tracker.yaml...
  Added: 0003.blocks += [0004-enhancement]
[Manager] Will retry 0004 after 0003 enhancement completes

[WARNING] Task 0004 incomplete - continuing loop
```

**Iteration 4 (Dependency Resolution):**

```
[INFO] === Iteration 4 ===
[Manager] Selected: 0003-enhancement (Add update method to storage)
[Manager] Invoking @developer agent...

[Worker 0003] Reading activity.md for context...
[Worker 0003] Adding update_task() method to Storage class...
[Worker 0003] Adding tests for update functionality...
[Worker 0003] TASK_COMPLETE_0003

[SUCCESS] Task 0003 enhancement completed
```

**Iteration 5 (Retry with Resolved Dependency):**

```
[INFO] === Iteration 5 ===
[Manager] Selected: 0004 (Implement 'add' command - retry)
[Manager] Invoking @developer agent...

[Worker 0004] Reading attempts.md for previous context...
[Worker 0004] Using new storage.update_task() method...
[Worker 0004] Implementing 'add' command with argparse...
[Worker 0004] TASK_COMPLETE_0004

[SUCCESS] Task 0004 completed
```

### Step 9: Mid-Project TODO.md

After completing tasks 0001-0004:

```markdown
# Task Management CLI Implementation

## Setup
- [x] 0001: Set up project structure

## Core
- [x] 0002: Implement Task model
- [x] 0003: Implement storage module

## Commands
- [x] 0004: Implement 'add' command
- [ ] 0005: Implement 'list' command
- [ ] 0006: Implement 'complete' command
- [ ] 0007: Implement 'delete' command

## Polish
- [ ] 0008: Add CLI entry point
- [ ] 0009: Write tests
- [ ] 0010: Create documentation
```

### Step 10: Git Workflow

Check the branches created by Ralph:

```bash
git branch -a
```

**Output:**
```
  main
  task-0001
  task-0002
  task-0003
  task-0004
```

View commits on main:

```bash
git log --oneline main
```

**Output:**
```
a1b2c3d feat(cli): set up project structure (task-0001)
b2c3d4e feat(model): implement Task model (task-0002)
c3d4e5f feat(storage): implement storage module (task-0003)
d4e5f6g feat(cmd): implement 'add' command (task-0004)
```

### Step 11: Handling Failure

**Iteration 11 - Task 0009 (Tests):**

```
[INFO] === Iteration 11 ===
[Manager] Selected: 0009 (Write tests)
[Manager] Invoking @tester agent...

[Worker 0009] Running pytest...
[Worker 0009] FAILED: test_task_model.py::test_task_creation
[Worker 0009] Error: AssertionError on line 15
[Worker 0009] Expected: task.id = 1, Got: task.id = None
[Worker 0009] TASK_FAILED_0009: Test failure - assertion error on line 15

[WARNING] Task 0009 failed: Test failure - assertion error on line 15
[WARNING] Task 0009 failed - will retry in next iteration
```

**Iteration 12 - Retry:**

```
[INFO] === Iteration 12 ===
[Manager] Selected: 0009 (Write tests - attempt 2)
[Manager] Invoking @tester agent...

[Worker 0009] Reading attempts.md...
[Worker 0009] Previous failure: assertion error on line 15
[Worker 0009] Checking test logic...
[Worker 0009] Fixed: corrected expected value to match actual implementation
[Worker 0009] Running pytest... PASSED
[Worker 0009] All tests passing
[Worker 0009] TASK_COMPLETE_0009

[SUCCESS] Task 0009 completed
```

### Step 12: Final TODO.md

When all tasks are complete:

```markdown
# Task Management CLI Implementation

## Setup
- [x] 0001: Set up project structure

## Core
- [x] 0002: Implement Task model
- [x] 0003: Implement storage module

## Commands
- [x] 0004: Implement 'add' command
- [x] 0005: Implement 'list' command
- [x] 0006: Implement 'complete' command
- [x] 0007: Implement 'delete' command

## Polish
- [x] 0008: Add CLI entry point
- [x] 0009: Write tests
- [x] 0010: Create documentation

ALL TASKS COMPLETE, EXIT LOOP
```

**Loop Termination:**
```
[INFO] ALL TASKS COMPLETE, EXIT LOOP sentinel detected
[INFO] Termination conditions met - exiting loop
[SUCCESS] Ralph Loop finished after 12 iterations
```

## Results

### Final Project Structure

```
task-cli/
├── .ralph/
│   ├── config/
│   │   ├── agents.yaml
│   │   └── deps-tracker.yaml
│   ├── specs/
│   │   └── PRD-task-cli.md
│   ├── tasks/
│   │   ├── TODO.md
│   │   └── done/
│   │       ├── 0001/
│   │       │   ├── TASK.md
│   │       │   ├── activity.md
│   │       │   └── attempts.md
│   │       ├── 0002/
│   │       │   └── ...
│   │       └── ... (0003-0010)
│   └── prompts/
│       └── ralph-prompt.md
├── task_cli/
│   ├── __init__.py
│   ├── models.py
│   ├── storage.py
│   └── commands.py
├── tests/
│   ├── test_models.py
│   ├── test_storage.py
│   └── test_commands.py
├── setup.py
├── requirements.txt
├── README.md
└── RULES.md
```

### Usage Example

```bash
# Install the package
pip install -e .

# Add tasks
task add "Buy groceries" --priority high
task add "Call dentist" --priority medium

# List tasks
task list
```

**Output:**
```
ID  Description       Priority  Status
--  -----------       --------  ------
1   Buy groceries     high      pending
2   Call dentist      medium    pending
```

```bash
# Complete task
task complete 1

# List pending tasks only
task list --status pending
```

**Output:**
```
ID  Description       Priority  Status
--  -----------       --------  ------
2   Call dentist      medium    pending
```

## Lessons Learned

### What Worked Well

1. **Fine-grained tasks** - Each task was completable in one context window (~30-60 min of human work equivalent)
2. **Dependency tracking** - Runtime discovery handled missed dependencies gracefully
3. **Git workflow** - Clean history with squash merges and descriptive commit messages
4. **Fresh context** - Each iteration started clean, preventing token burn and context degradation
5. **Signal system** - Clear, machine-parseable signals enabled reliable automation

### Challenges Encountered

1. **Runtime dependency discovery** - Storage module needed enhancement mid-project
   - **What happened:** Task 0004 needed an `update()` method that wasn't in original Task 0003
   - **Resolution:** Worker emitted `TASK_INCOMPLETE_0004: Depends on storage.update()`
   - **Outcome:** Manager added dependency, created enhancement task, retried successfully

2. **Test failure** - Assertion error on first test run
   - **What happened:** Expected value in test didn't match actual implementation
   - **Resolution:** Worker emitted `TASK_FAILED_0009`, analyzed in retry, fixed test logic
   - **Outcome:** Passed on second attempt with corrected expectations

3. **Signal parsing edge case** - Initial confusion about message format
   - **Resolution:** Referenced actual ralph-loop.sh signal patterns:
     - `TASK_COMPLETE_XXXX` (no colon)
     - `TASK_FAILED_XXXX: message` (colon + space + message)

### Best Practices Demonstrated

- **Keep tasks under 2 hours** - Each task was sized S or M (15-60 min)
- **Use clear acceptance criteria** - Every TASK.md had specific, testable criteria
- **Let Manager handle orchestration** - Workers focused on implementation only
- **Trust the loop** - Failures became data for retry, not blockers
- **Use git branches for isolation** - Each task had its own branch, merged when complete
- **Document runtime dependencies** - When discovered, dependencies were added to deps-tracker.yaml

## Next Steps

Now that you've seen Ralph in action, you can:

1. **Try Ralph on your own project**
   - Run `ralph-init.sh` in your project directory
   - Create a PRD in `.ralph/specs/`
   - Use the decomposer agent for decomposition

2. **Experiment with different agent types**
   - Architect for system design tasks
   - UI-Designer for frontend work
   - Tester for validation tasks
   - Researcher for investigation tasks

3. **Configure custom model mappings**
   - Edit `.ralph/config/agents.yaml` to use different models per agent type
   - Set `RALPH_MANAGER_MODEL` environment variable for Manager agent

4. **Add RULES.md for your project patterns**
   - Document discovered patterns
   - Define standard approaches
   - List common pitfalls to avoid

5. **Explore advanced features**
   - Handoff patterns for inter-worker coordination
   - Context limit management for large tasks
   - Retry policies and backoff configuration
   - Integration with CI/CD pipelines

---

## Quick Reference

### Signal Formats

| Signal | Format | Description |
|--------|--------|-------------|
| Complete | `TASK_COMPLETE_XXXX` | Task finished successfully |
| Incomplete | `TASK_INCOMPLETE_XXXX` or `TASK_INCOMPLETE_XXXX: message` | Task needs more work (message optional) |
| Failed | `TASK_FAILED_XXXX: message` | Error encountered, will retry |
| Blocked | `TASK_BLOCKED_XXXX: message` | Blocked, needs human intervention |
| All Complete | `ALL TASKS COMPLETE, EXIT LOOP` | All tasks done, exit loop |

### TODO.md Grammar

```markdown
# Phase 1: Setup
- [ ] 0001: Incomplete task
- [x] 0002: Complete task

ABORT: HELP NEEDED FOR TASK 0007: Circular dependency detected
ALL TASKS COMPLETE, EXIT LOOP
```

### Commands

```bash
# Initialize Ralph
ralph-init.sh

# Run execution loop
ralph-loop.sh

# Run with specific options
ralph-loop.sh --tool claude --max-iterations 50 --no-delay
```

### File Locations

- Task definitions: `.ralph/tasks/XXXX/TASK.md`
- Activity logs: `.ralph/tasks/XXXX/activity.md`
- Attempt tracking: `.ralph/tasks/XXXX/attempts.md`
- Task list: `.ralph/tasks/TODO.md`
- Dependencies: `.ralph/config/deps-tracker.yaml`
