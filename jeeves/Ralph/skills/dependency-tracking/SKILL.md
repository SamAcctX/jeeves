---
name: dependency-tracking
description: Dependency tracking utilities for Ralph Loop including graph parsing, cycle detection, task selection, and transitive closure.
license: MIT
metadata:
  version: "1.0.0"
  author: Ralph Loop Team
---

# Dependency Tracking Skill

## Overview

The Dependency Tracking Skill provides comprehensive dependency management for the Ralph Loop. It handles dependency graph parsing, circular dependency detection, unblocked task selection, runtime dependency updates, and transitive dependency resolution.

This skill is designed to be used by the Manager agent and ralph-loop.sh for intelligent task execution ordering.

## When to Use

Use this skill when:

- **Selecting next task** - Find tasks with no incomplete dependencies
- **Detecting cycles** - Identify circular dependencies before they cause issues
- **Updating dependencies** - Add discovered runtime dependencies
- **Transitive analysis** - Understand full dependency closure

## Available Scripts

### Core Scripts

#### `deps-parse.sh` (Task 0077)

Dependency graph parsing utilities.

**Functions:**
- `deps_get_dependencies(task_id)` - Get direct dependencies
- `deps_get_blocked(task_id)` - Get tasks blocked by given task
- `deps_is_unblocked(task_id, completed_tasks)` - Check if unblocked

**CLI:**
```bash
./deps-parse.sh --get-dependencies 0001
./deps-parse.sh --get-blocked 0001
./deps-parse.sh --is-unblocked 0001 "0001 0002"
```

---

#### `deps-cycle.sh` (Task 0078)

Circular dependency detection using DFS.

**Functions:**
- `deps_detect_cycle(task_id)` - Detect cycles starting from task
- `deps_validate_graph()` - Check entire graph for cycles

**CLI:**
```bash
./deps-cycle.sh --detect-cycle 0001
./deps-cycle.sh --validate-graph
```

**Exit Codes:**
- 0 - Cycle(s) found
- 1 - No cycles / Valid graph

---

#### `deps-select.sh` (Task 0079)

Unblocked task selection from TODO.md.

**Functions:**
- `deps_get_incomplete_tasks()` - Get incomplete tasks
- `deps_get_completed_tasks()` - Get completed tasks
- `deps_find_unblocked_tasks()` - Find unblocked tasks
- `deps_select_next_task()` - Select next task

**CLI:**
```bash
./deps-select.sh --get-incomplete
./deps-select.sh --get-completed
./deps-select.sh --find-unblocked
./deps-select.sh --select-next
```

---

#### `deps-update.sh` (Task 0080)

Runtime dependency updates.

**Functions:**
- `deps_add_dependency(from_task, to_task)` - Add dependency
- `deps_remove_dependency(from_task, to_task)` - Remove dependency

**CLI:**
```bash
./deps-update.sh --add-dependency 0001 0002
./deps-update.sh --remove-dependency 0001 0002
```

---

#### `deps-closure.sh` (Task 0081)

Transitive dependency resolution.

**Functions:**
- `deps_get_all_dependencies(task_id)` - Get transitive closure
- `deps_is_fully_unblocked(task_id, completed)` - Check transitive deps
- `deps_get_dependency_depth(task_id)` - Get max depth

**CLI:**
```bash
./deps-closure.sh --all-dependencies 0001
./deps-closure.sh --is-fully-unblocked 0001 "0001 0002"
./deps-closure.sh --depth 0001
```

---

## Usage Examples

### Finding Next Task

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-select.sh

# Select next unblocked task
next_task=$(deps_select_next_task)
echo "Next task: $next_task"
```

### Detecting Cycles

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh

# Validate entire graph
if deps_validate_graph; then
    echo "Cycles detected!"
else
    echo "Graph is valid"
fi
```

### Adding Runtime Dependency

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh

# Task 0005 discovers it needs output from task 0003
deps_add_dependency 0005 0003
```

### Transitive Analysis

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-closure.sh

# Get all dependencies for task 0004
all_deps=$(deps_get_all_dependencies 0004)
echo "Dependencies: $all_deps"
```

## Integration

### Manager Agent

The Manager uses these scripts to:

1. Select next task: `deps_select_next_task`
2. Detect cycles: `deps_validate_graph`
3. Update dependencies: `deps_add_dependency`

### ralph-loop.sh

At loop startup:

1. Validate graph: `./deps-cycle.sh --validate-graph`
2. Select task: `./deps-select.sh --select-next`

## Dependencies

- **yq** - YAML parsing
- **bash** - Script execution
- **deps-tracker.yaml** - Dependency data file
- **TODO.md** - Task status file

## Error Handling

All scripts follow consistent error handling:
- Exit 0: Success
- Exit 1: General error / Not found / No cycles
- Exit 2: Cycle detected (cycle scripts)
- Exit 4: Invalid input

## Version History

- **1.0.0** - Initial release with deps-parse, deps-cycle, deps-select, deps-update, deps-closure
