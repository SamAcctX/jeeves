# Ralph Directory Structure Documentation

## Overview

The Ralph Loop organizes project work using a standardized `.ralph/` directory structure. This structure provides clear separation between configuration, active tasks, completed tasks, and specifications while maintaining clean project organization.

## Directory Structure

```
/proj/                           # Project root (user's repository)
├── .ralph/                      # Ralph scaffolding directory
│   ├── config/                  # Configuration files
│   │   └── agents.yaml          # Agent-to-model mapping configuration
│   ├── tasks/                   # Task management
│   │   ├── deps-tracker.yaml    # Dependency tracking across all tasks
│   │   ├── TODO.md              # Master task checklist
│   │   ├── done/                # Completed tasks (archived)
│   │   │   └── 0001/            # Completed task folder
│   │   │       ├── TASK.md      # Task definition
│   │   │       ├── attempts.md  # Attempt history
│   │   │       └── activity.md  # Activity log
│   │   ├── 0002/                # Active task folder
│   │   │   ├── TASK.md          # Task definition
│   │   │   ├── attempts.md      # Attempt history
│   │   │   └── activity.md      # Activity log
│   │   └── 0003/                # Another active task
│   │       └── ...
│   └── specs/                   # Product specifications
│       └── PRD-*.md             # Product Requirements Documents
├── .opencode/                   # OpenCode-specific configurations
│   └── agents/                  # Project-scope agent definitions
│       ├── manager.md
│       ├── developer.md
│       ├── tester.md
│       └── ...
├── .claude/                     # Claude-specific configurations
│   └── agents/                  # Project-scope agent definitions
│       └── ...
├── src/                         # User's application code
├── .gitignore                   # Excludes .ralph/tasks/
└── README.md                    # User's project documentation
```

## Directory and File Purposes

### `.ralph/` - Ralph Scaffolding

The root directory containing all Ralph Loop files and data. This directory is created by `ralph-init.sh` when initializing a project for Ralph Loop development.

### `.ralph/config/` - Configuration

Contains configuration files that control Ralph Loop behavior.

#### `agents.yaml`
Maps agent types to specific LLM models for optimal performance and cost efficiency. Each agent type (architect, developer, tester, etc.) can have preferred and fallback models for different tools (opencode, claude).

### `.ralph/tasks/` - Task Management

Central hub for all task-related files and tracking.

#### `deps-tracker.yaml`
Tracks dependencies between tasks. Each task lists what it depends on and what tasks it blocks. Used by the Manager agent to determine which tasks are ready for execution.

#### `TODO.md`
Master checklist of all tasks in the project. Uses strict grammar format with checkboxes for tracking completion status. Tasks are ordered but Manager can select any unblocked task.

#### Task Folders (`0001/`, `0002/`, etc.)
Each task gets its own folder with a 4-digit zero-padded ID (0001-9999). Contains three standardized files:

- **`TASK.md`** - Task definition with description, acceptance criteria, implementation notes, dependencies, and complexity estimate
- **`attempts.md`** - Detailed log of each attempt to complete the task, including what was tried, results, errors encountered, and lessons learned
- **`activity.md`** - Narrative log of task execution progress, verification results, and handoff coordination between agents

#### `done/` - Completed Tasks
When a task is completed successfully, its folder is moved from the active tasks area to the `done/` directory. This preserves complete history while keeping the active workspace clean.

### `.ralph/specs/` - Product Specifications

Contains project requirements and specifications documents.

#### `PRD-*.md`
Product Requirements Documents that define the project scope, requirements, technical specifications, and success criteria. These serve as input for the task decomposition phase.

### `.opencode/agents/` and `.claude/agents/` - Agent Definitions

Project-specific agent customizations and definitions. These override global agent configurations and allow projects to tailor agent behavior, prompts, and tool permissions to their specific needs.

## Task ID Convention

Tasks use a **4-digit zero-padded ID system**:
- Range: 0001 to 9999
- Format: `tasks/0001/`, `tasks/0002/`, etc.
- Maximum: 9999 tasks per project
- Enforcement: Non-compliant folder names cause errors requiring manual correction

## File Relationships

### Jeeves Source vs Staged Locations
- **Source**: `/proj/jeeves/` - Development repository
- **Staged**: `/opt/jeeves/` - Container installation location
- **Templates**: Ralph templates are staged from source to system location for use in new projects

### Git Integration
- **`.gitignore`**: Excludes `.ralph/tasks/` to prevent ephemeral task data from being committed
- **Completed tasks**: `.ralph/tasks/done/` can optionally be included for historical record
- **Branch strategy**: Each task works in a dedicated branch (`task-XXX`) and squash-merges to primary branch on completion

## Key Design Principles

1. **Isolation**: All Ralph files are contained within `.ralph/` directory
2. **Standardization**: Consistent file structure across all projects
3. **Clean History**: Completed tasks are archived separately from active work
4. **Flexibility**: Support for both project-specific and global agent configurations
5. **Git-Friendly**: Designed to work seamlessly with version control workflows

## Usage Notes

- The `.ralph/` directory should not contain executable code - it's data-only
- Task folders are created automatically during the decomposition phase
- The Manager agent handles all file movements and state updates
- Human intervention is only needed for blocked tasks or configuration changes