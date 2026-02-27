# Dependency Tracking Skill Documentation

## Overview

The Dependency Tracking Skill provides comprehensive dependency management for the Ralph Loop. It handles dependency graph parsing, circular dependency detection, unblocked task selection, runtime dependency updates, and transitive dependency resolution.

This skill is designed to be used by the Manager agent and `ralph-loop.sh` for intelligent task execution ordering.

## Purpose

The Dependency Tracking Skill addresses the core challenge of managing complex task dependencies in autonomous AI systems. It ensures that:

- Tasks are executed in the correct order based on their dependencies
- Circular dependencies are detected early to prevent execution failures
- The system always knows which tasks are unblocked and ready to run
- Runtime dependencies can be dynamically added as tasks discover new requirements
- The full transitive closure of dependencies is analyzed for complete task readiness

## Key Features

### Dependency Graph Parsing (`deps-parse.sh`)

- Parse YAML-based dependency tracker files
- Query direct dependencies for any task
- Query which tasks are blocked by a specific task
- Check if a task is unblocked given completed tasks

### Circular Dependency Detection (`deps-cycle.sh`)

- Detect cycles in the dependency graph using Depth-First Search (DFS)
- Validate the entire dependency graph for cycles
- Provide clear error messages indicating cycle paths

### Unblocked Task Selection (`deps-select.sh`)

- Find all unblocked tasks from the TODO.md checklist
- Select the next task to execute based on dependency analysis
- Maintain compatibility with the TODO.md grammar

### Runtime Dependency Updates (`deps-update.sh`)

- Dynamically add dependencies between tasks
- Remove existing dependencies
- Maintain consistency between dependencies and blocked relationships

### Transitive Dependency Resolution (`deps-closure.sh`)

- Compute the full transitive closure of dependencies for any task
- Check if a task is fully unblocked by analyzing all transitive dependencies
- Determine the depth of dependency chains

## Usage Examples

### Finding the Next Task to Execute

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-select.sh

# Select next unblocked task
next_task=$(deps_select_next_task)
echo "Next task: $next_task"
```

### Detecting Circular Dependencies

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-cycle.sh

# Validate entire graph
if deps_validate_graph; then
    echo "Cycles detected!"
else
    echo "Graph is valid"
fi
```

### Adding Runtime Dependencies

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-update.sh

# Task 0005 discovers it needs output from task 0003
deps_add_dependency 0005 0003
```

### Transitive Dependency Analysis

```bash
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-closure.sh

# Get all dependencies for task 0004
all_deps=$(deps_get_all_dependencies 0004)
echo "Dependencies: $all_deps"
```

## Integration with Ralph Loop

### Manager Agent

The Manager uses these scripts to:
1. Select next task: `deps_select_next_task`
2. Detect cycles: `deps_validate_graph`
3. Update dependencies: `deps_add_dependency`

### ralph-loop.sh

At loop startup:
1. Validate graph: `./deps-cycle.sh --validate-graph`
2. Select task: `./deps-select.sh --select-next`

## File Structure

```
jeeves/Ralph/skills/dependency-tracking/
├── SKILL.md              # Skill metadata and documentation
├── README.md             # This file
├── scripts/
│   ├── deps-parse.sh     # Dependency graph parsing
│   ├── deps-cycle.sh     # Cycle detection
│   ├── deps-select.sh    # Task selection
│   ├── deps-update.sh    # Dependency updates
│   └── deps-closure.sh   # Transitive dependency resolution
└── tests/
    ├── test-deps-parse.sh       # Parse function tests
    ├── test-deps-cycle.sh       # Cycle detection tests
    ├── test-deps-select.sh      # Task selection tests
    ├── test-deps-update.sh      # Update tests
    ├── test-deps-cycle-final.sh # Complex cycle tests
    ├── test-deps-cycle-fixed.sh # Fixed cycle tests
    └── fixtures/
        └── deps-tracker.yaml    # Sample dependency data
```

## Dependencies

- **yq** - YAML parsing and manipulation
- **bash** - Script execution
- **deps-tracker.yaml** - Dependency data file (generated during decomposition)
- **TODO.md** - Task status file (generated during decomposition)

## Error Handling

All scripts follow consistent error handling:
- Exit 0: Success
- Exit 1: General error / Not found / No cycles
- Exit 2: Cycle detected (cycle scripts)
- Exit 4: Invalid input

## Version History

- **1.0.0** - Initial release with deps-parse, deps-cycle, deps-select, deps-update, deps-closure

## Technical Details

### Dependency Graph Representation

The dependency graph is stored in `deps-tracker.yaml` in the following format:

```yaml
tasks:
  {task_id}:
    depends_on: [{list_of_dependency_ids}]
    blocks: [{list_of_blocked_task_ids}]
```

### Task IDs

Task IDs follow a 4-digit zero-padded format (0001-9999) for consistency and readability.

### Performance Considerations

The dependency tracking algorithms are optimized for:
- Small to medium-sized task graphs (up to 1000 tasks)
- Quick dependency lookups using associative arrays
- Efficient cycle detection using DFS
- Minimal overhead during loop iterations
