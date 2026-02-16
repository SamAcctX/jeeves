---
name: git-automation
description: Automate Git workflows including branching, commits, and conflict handling with safety checks and best practices enforcement.
license: MIT
metadata:
  version: "1.0.0"
  author: Ralph Loop Team
---

# Git Automation Skill

## Overview

The Git Automation Skill provides comprehensive Git workflow automation for the Ralph Loop. It manages the complete task lifecycle from branch creation through squash merge and cleanup, with robust conflict detection and failure handling.

This skill operates in three repository contexts and provides consistent, safe Git operations that integrate seamlessly with the Ralph Loop execution flow.

## When to Use

Use this skill when:

- **Initializing a new Ralph Loop project** - Set up Git integration and configure repository
- **Starting task work** - Create isolated task branches for safe development
- **Completing tasks** - Generate proper conventional commits and squash merge to primary branch
- **Managing repository state** - Detect and handle merge conflicts in Ralph state files
- **Cleaning up** - Remove merged task branches and maintain repository hygiene
- **Configuring gitignore** - Set up proper exclusions for ephemeral task data

## Repository Contexts

The skill detects and operates in three contexts:

### REPO_ROOT
**Full Git Integration Mode**

- `/proj` contains a `.git` directory (repository root)
- All Git operations are enabled:
  - Automatic branch creation and management
  - Conventional commit generation
  - Squash merge to primary branch
  - Branch cleanup after merge
- Primary branch is detected and tracked automatically
- Full Ralph Loop workflow automation

### SUBFOLDER
**Limited Git Integration Mode**

- `/proj` is a subdirectory within a Git repository
- Git branch operations are disabled (safety constraint)
- Available operations:
  - File operations within the working directory
  - Gitignore configuration at repository root
  - Context detection and user messaging
- **User responsibility**: Manage branches manually outside Ralph Loop

### NO_REPO
**File-Based Mode**

- No Git repository detected
- Git operations are disabled
- Ralph Loop operates in file-only mode:
  - Task tracking via TODO.md
  - State persistence via deps-tracker.yaml
  - No version control integration
- To enable Git: Run `git init` in `/proj`

## Available Scripts

### Core Scripts

#### `git-context.sh` (Task 0066)
**Repository Context Detection**

Detects the repository context and identifies the primary branch for workflow automation.

**Functions:**
- `detect_repo_context()` - Returns REPO_ROOT, SUBFOLDER, or NO_REPO
- `get_repo_root()` - Returns absolute path to repository root
- `get_current_branch()` - Returns current branch name
- `get_primary_branch()` - Detects primary branch using 4-tier fallback (main → master → trunk → current)
- `persist_context()` - Saves context to `.ralph/config/repo-context`

**Usage:**
```bash
# Source to use functions
source /proj/jeeves/Ralph/skills/git-automation/scripts/git-context.sh

# Detect and display context
./git-context.sh
```

**Exit Codes:**
- `0` - REPO_ROOT
- `1` - SUBFOLDER
- `2` - NO_REPO

---

#### `git-commit-msg.sh` (Task 0070)
**Conventional Commit Message Generator**

Generates properly formatted conventional commit messages based on agent type and task metadata.

**Commit Type Mapping:**
- `feat` - Developer, Architect, UI-Designer (default for implementation)
- `fix` - Override keyword: fix, bug, error, crash
- `test` - Tester (default), override keyword: test
- `docs` - Writer, Researcher (default), override keyword: doc, documentation
- `refactor` - Override keyword: refactor
- `chore` - Unknown agent types

**Usage:**
```bash
./git-commit-msg.sh --task-id 0042 --agent-type developer --task-title "Add user authentication"
# Output: feat: add user authentication

./git-commit-msg.sh --task-id 0042 --agent-type tester --task-title "Add auth tests"
# Output: test: add auth tests
```

**Options:**
- `--task-id NNNN` - Task identifier
- `--agent-type TYPE` - Agent type (developer, tester, etc.)
- `--task-title "TITLE"` - Task description
- `--breaking` - Mark as breaking change (adds `!`)

---

#### `task-branch-create.sh` (Task 0067)
**Task Branch Creation**

Creates isolated branches for task execution from the primary branch.

**Branch Naming Convention:**
- Format: `task-XXXX` where XXXX is the 4-digit task ID
- Example: `task-0042`

**Operations:**
1. Verify clean working directory
2. Checkout primary branch
3. Pull latest changes (optional)
4. Create and checkout `task-XXXX` branch
5. Persist branch info to task state

**Usage:**
```bash
./task-branch-create.sh --task-id 0042 [--no-pull]
```

**Exit Codes:**
- `0` - Branch created successfully
- `1` - Working directory not clean
- `2` - Branch already exists

---

#### `squash-merge.sh` (Task 0068)
**Squash Merge to Primary Branch**

Merges task branch into primary branch using squash commit for clean history.

**Workflow:**
1. Verify task branch exists and has commits
2. Checkout primary branch
3. Squash merge task branch with generated commit message
4. Delete task branch (local and remote)
5. Emit TASK_COMPLETE signal

**Usage:**
```bash
./squash-merge.sh --task-id 0042 [--message "custom message"]
```

**Safety Checks:**
- Verifies working directory is clean
- Confirms branch has commits to merge
- Validates primary branch exists

---

#### `branch-cleanup.sh` (Task 0069)
**Branch Cleanup After Merge**

Removes merged task branches to maintain repository hygiene.

**Operations:**
- Delete local task branch
- Delete remote task branch (if configured)
- Clean up any stale task branches
- Update branch tracking info

**Usage:**
```bash
./branch-cleanup.sh --task-id 0042 [--dry-run]
```

---

### Conflict & Safety Scripts

#### `git-conflict.sh` (Task 0071)
**Git Conflict Detection**

Detects merge conflicts in the working directory and source files.

**Checks:**
- Working directory conflict markers
- Unmerged files from previous merge
- Staged conflict resolutions

**Usage:**
```bash
./git-conflict.sh [--source-only]
```

**Exit Codes:**
- `0` - No conflicts detected
- `1` - Conflicts detected in working directory
- `2` - Conflicts detected in source files

---

#### `state-file-conflicts.sh` (Task 0072)
**Ralph State File Conflict Detection**

Specifically checks Ralph Loop state files for merge conflicts.

**Files Checked:**
- `.ralph/TODO.md`
- `.ralph/deps-tracker.yaml`

**Behavior:**
- Emits `TASK_BLOCKED_0000` signal if conflicts found
- Provides conflict count per file
- Displays resolution instructions
- Called by Manager at loop iteration start

**Usage:**
```bash
./state-file-conflicts.sh [--fix]
```

**Exit Codes:**
- `0` - No conflicts detected
- `1` - Conflicts detected (TASK_BLOCKED emitted)

---

### Configuration Scripts

#### `configure-gitignore.sh` (Task 0073)
**Gitignore Configuration**

Configures `.gitignore` with Ralph Loop entries for ephemeral task data.

**Entries Added:**
```
# Ralph Loop - ephemeral task data
.ralph/tasks/*          # Active task data
# !.ralph/tasks/done/   # Uncomment to preserve completed task history

# Ralph Loop - log files and temporary files
.ralph/*.log            # Log files
.ralph/.tmp/            # Temporary files
```

**Context-Aware:**
- REPO_ROOT/NO_REPO: Updates `/proj/.gitignore`
- SUBFOLDER: Updates `<repo-root>/.gitignore`

**Idempotent:** Safe to run multiple times; updates existing section if present

**Usage:**
```bash
./configure-gitignore.sh [--preserve-done]
```

---

### Utility Scripts

#### `git-wrapper.sh` (Task 0074)
**Safe Git Command Wrapper**

Provides safe Git operations with automatic failure handling.

**Features:**
- Context-aware Git operations
- Automatic conflict detection
- Graceful error handling with TASK_FAILED signals
- Logging of all Git commands

**Usage:**
```bash
./git-wrapper.sh <git-command> [args...]
```

**Example:**
```bash
./git-wrapper.sh commit -m "message"     # Safe commit with validation
./git-wrapper.sh push origin task-0042   # Safe push with error handling
```

## Workflow Integration

### Initialization Phase (`ralph-init.sh`)

During project initialization:

1. **Context Detection**: `git-context.sh` runs to detect repository state
2. **Gitignore Setup**: `configure-gitignore.sh` adds Ralph Loop entries
3. **Primary Branch**: Identified and persisted to `.ralph/config/primary-branch`
4. **User Notification**: Context displayed with capability/limitation summary

### Execution Phase (`ralph-loop.sh`)

During each loop iteration:

1. **Conflict Check**: Manager calls `state-file-conflicts.sh` at start
2. **Task Start**: Manager calls `task-branch-create.sh` for new tasks (REPO_ROOT only)
3. **Task Work**: Worker performs task, commits as needed
4. **Task Complete**: 
   - `git-commit-msg.sh` generates commit message
   - `squash-merge.sh` merges to primary branch
   - `branch-cleanup.sh` removes task branch
5. **Signal Emission**: Manager emits TASK_COMPLETE_XXXX to stdout

### Task Completion Flow

```
Task Complete Signal Received
        |
        v
+------------------+
| Generate Commit  |  <-- git-commit-msg.sh
|   Message        |
+------------------+
        |
        v
+------------------+
| Squash Merge to  |  <-- squash-merge.sh
| Primary Branch   |
+------------------+
        |
        v
+------------------+
| Delete Branch    |  <-- branch-cleanup.sh
| (Local & Remote) |
+------------------+
        |
        v
+------------------+
| Mark TODO        |
| Complete         |
+------------------+
```

## Dependencies

### Required Tools

- **Git** (2.30+) - Core version control
- **Bash** (4.0+) - Script execution
- **Standard Unix Tools** - grep, sed, awk, mktemp

### Optional Tools

- **yq** - YAML parsing (for advanced dependency tracking)
- **jq** - JSON parsing (for future extensions)

## Safety Philosophy

The Git Automation Skill follows a **safety-first** approach:

### Detection Before Action
- Always detect repository context before Git operations
- Check for conflicts before proceeding
- Verify working directory state

### Graceful Degradation
- SUBFOLDER context disables branch operations (doesn't fail)
- NO_REPO context enables file-only mode (no Git required)
- Conflicts emit TASK_BLOCKED (human intervention)

### Abort vs Auto-Resolve
- State file conflicts emit TASK_BLOCKED (don't auto-resolve)
- Human judgment required for critical state reconciliation
- Simple, predictable behavior (no magic)

### Idempotent Operations
- `configure-gitignore.sh` can run multiple times safely
- Branch creation handles existing branches
- Context detection is non-destructive

## Examples

### Example 1: Initialize Git Integration

```bash
# Run during ralph-init.sh
source /proj/jeeves/Ralph/skills/git-automation/scripts/git-context.sh
CONTEXT=$(detect_repo_context)
PRIMARY=$(get_primary_branch)

if [ "$CONTEXT" = "REPO_ROOT" ]; then
    echo "Git integration: FULL MODE"
    echo "Primary branch: $PRIMARY"
    ./configure-gitignore.sh
fi
```

### Example 2: Start Task Work

```bash
# Manager invokes at task start
TASK_ID="0042"
./task-branch-create.sh --task-id "$TASK_ID"
# Creates branch task-0042 from primary branch
```

### Example 3: Complete Task with Commit

```bash
# Worker generates commit message
COMMIT_MSG=$(./git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Implement user authentication")

git add .
git commit -m "$COMMIT_MSG"
# Result: feat: implement user authentication
```

### Example 4: Squash Merge on Completion

```bash
# Manager invokes on TASK_COMPLETE
./squash-merge.sh --task-id 0042
# Merges task-0042 into primary branch with squash commit
# Deletes task-0042 branch
```

### Example 5: Handle Conflicts

```bash
# Manager checks at loop start
if ! ./state-file-conflicts.sh; then
    echo "Conflicts detected - human intervention required"
    exit 1
fi
```

## Integration Notes

### Manager Agent Responsibilities

1. Call `state-file-conflicts.sh` at loop iteration start
2. Call `task-branch-create.sh` when starting new task (REPO_ROOT only)
3. Call `git-commit-msg.sh` to generate commit messages
4. Call `squash-merge.sh` and `branch-cleanup.sh` on TASK_COMPLETE

### Worker Agent Responsibilities

1. Use Git normally for task work (commits, staging)
2. Request commit message generation from Manager
3. Do NOT call branch management scripts directly

### Bash Wrapper Responsibilities

1. Source context information for scripts
2. Pass task metadata to scripts as needed
3. Handle script exit codes appropriately

## Version History

- **1.0.0** - Initial release with full workflow automation

## License

MIT License - See skill metadata
