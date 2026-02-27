# Git Automation Skill Documentation

## Overview

The Git Automation Skill provides comprehensive Git workflow automation for the Ralph Loop. It manages the complete task lifecycle from branch creation through squash merge and cleanup, with robust conflict detection and failure handling.

This skill operates in three repository contexts and provides consistent, safe Git operations that integrate seamlessly with the Ralph Loop execution flow.

## Purpose

The Git Automation Skill addresses the challenge of integrating Git version control with autonomous AI task execution. It ensures that:

- Each task gets an isolated branch for safe development
- Conventional commit messages are generated automatically
- Merge conflicts are detected early and handled properly
- Task branches are properly merged and cleaned up
- The repository remains in a consistent state throughout the loop

## Repository Contexts

The skill detects and operates in three contexts:

### REPO_ROOT - Full Git Integration Mode

**When:** `/proj` contains a `.git` directory (repository root)

**Capabilities:**
- Automatic branch creation and management
- Conventional commit generation
- Squash merge to primary branch
- Branch cleanup after merge
- Full Ralph Loop workflow automation

**Primary branch detection:** Uses 4-tier fallback (main → master → trunk → current)

### SUBFOLDER - Limited Git Integration Mode

**When:** `/proj` is a subdirectory within a Git repository

**Limitations:**
- Git branch operations are disabled (safety constraint)
- File operations only

**Your responsibility:** Manage branches manually outside Ralph Loop

### NO_REPO - File-Based Mode

**When:** No Git repository detected

**Mode:**
- File-based task management only
- Task tracking via TODO.md
- No version control integration

**To enable Git:** Run `git init` in `/proj`

## Key Features

### Repository Context Detection (`git-context.sh`)

- Detect repository context (REPO_ROOT/SUBFOLDER/NO_REPO)
- Identify primary branch using fallback strategy
- Persist context information to `.ralph/config/repo-context`
- Show clear context messages with capabilities and limitations

### Conventional Commit Message Generator (`git-commit-msg.sh`)

- Generate properly formatted conventional commit messages
- Maps agent types to commit types:
  - `feat` - Developer, Architect, UI-Designer
  - `fix` - Fix-related tasks
  - `test` - Tester
  - `docs` - Writer, Researcher
  - `refactor` - Refactor tasks
  - `chore` - Unknown agent types

### Task Branch Creation (`task-branch-create.sh`)

- Creates isolated branches for task execution from the primary branch
- Branch naming convention: `task-XXXX` where XXXX is the 4-digit task ID
- Verifies clean working directory before branch creation
- Pulls latest changes from remote (optional)
- Persists branch info to task state

### Squash Merge (`squash-merge.sh`)

- Merges task branch into primary branch using squash commit for clean history
- Generates commit message automatically
- Deletes task branch (local and remote)
- Emits TASK_COMPLETE signal

### Branch Cleanup (`branch-cleanup.sh`)

- Removes merged task branches to maintain repository hygiene
- Deletes local and remote branches
- Handles stale branches
- Updates branch tracking info

### Conflict Detection (`git-conflict.sh`)

- Detects merge conflicts in the working directory and source files
- Checks for conflict markers and unmerged files
- Provides conflict resolution guidance

### State File Conflict Detection (`state-file-conflicts.sh`)

- Specifically checks Ralph Loop state files for merge conflicts
- Files checked: `.ralph/TODO.md` and `.ralph/deps-tracker.yaml`
- Emits TASK_BLOCKED_0000 signal if conflicts found
- Called by Manager at loop iteration start

### Gitignore Configuration (`configure-gitignore.sh`)

- Configures `.gitignore` with Ralph Loop entries for ephemeral task data
- Handles all repository contexts correctly
- Idempotent - safe to run multiple times

### Safe Git Command Wrapper (`git-wrapper.sh`)

- Provides safe Git operations with automatic failure handling
- Context-aware Git operations
- Automatic conflict detection
- Graceful error handling with TASK_FAILED signals
- Logging of all Git commands

## Usage Examples

### Initialize Git Integration

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

### Start Task Work

```bash
# Manager invokes at task start
TASK_ID="0042"
./task-branch-create.sh --task-id "$TASK_ID"
# Creates branch task-0042 from primary branch
```

### Complete Task with Commit

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

### Squash Merge on Completion

```bash
# Manager invokes on TASK_COMPLETE
./squash-merge.sh --task-id 0042
# Merges task-0042 into primary branch with squash commit
# Deletes task-0042 branch
```

### Handle Conflicts

```bash
# Manager checks at loop start
if ! ./state-file-conflicts.sh; then
    echo "Conflicts detected - human intervention required"
    exit 1
fi
```

## Integration with Ralph Loop

### Initialization Phase (`ralph-init.sh`)

1. **Context Detection**: `git-context.sh` runs to detect repository state
2. **Gitignore Setup**: `configure-gitignore.sh` adds Ralph Loop entries
3. **Primary Branch**: Identified and persisted to `.ralph/config/primary-branch`
4. **User Notification**: Context displayed with capability/limitation summary

### Execution Phase (`ralph-loop.sh`)

1. **Conflict Check**: Manager calls `state-file-conflicts.sh` at start
2. **Task Start**: Manager calls `task-branch-create.sh` for new tasks (REPO_ROOT only)
3. **Task Work**: Worker performs task, commits as needed
4. **Task Complete**: 
   - `git-commit-msg.sh` generates commit message
   - `squash-merge.sh` merges to primary branch
   - `branch-cleanup.sh` removes task branch
5. **Signal Emission**: Manager emits TASK_COMPLETE_XXXX to stdout

## File Structure

```
jeeves/Ralph/skills/git-automation/
├── SKILL.md                     # Skill metadata and documentation
├── README.md                    # This file
├── scripts/
│   ├── git-context.sh          # Repository context detection
│   ├── git-commit-msg.sh       # Commit message generation
│   ├── task-branch-create.sh   # Task branch creation
│   ├── squash-merge.sh         # Squash merge implementation
│   ├── branch-cleanup.sh       # Branch cleanup
│   ├── git-conflict.sh         # Conflict detection
│   ├── state-file-conflicts.sh # State file conflict detection
│   ├── configure-gitignore.sh  # Gitignore configuration
│   └── git-wrapper.sh          # Safe git wrapper
└── references/
    ├── conventional-commits.md  # Conventional commits specification
    ├── git-commands.md         # Git command reference
    ├── git-workflow-user.md    # User guide
    └── troubleshooting.md      # Troubleshooting guide
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

## Version History

- **1.0.0** - Initial release with full workflow automation

## Configuration Files

### Generated Files

- `.ralph/config/repo-context` - Repository context information
- `.ralph/config/primary-branch` - Primary branch name
- `.gitignore` entries for Ralph Loop

### Gitignore Entries

The skill adds the following entries to `.gitignore`:

```
# Ralph Loop - ephemeral task data
.ralph/tasks/*          # Active task data
# !.ralph/tasks/done/   # Uncomment to preserve completed task history

# Ralph Loop - log files and temporary files
.ralph/*.log            # Log files
.ralph/.tmp/            # Temporary files
```

## Technical Details

### Branch Naming Convention

Task branches follow the format: `task-XXXX` where XXXX is the 4-digit zero-padded task ID.

### Commit Message Generation

The conventional commit message format follows:
```
{type}: {subject}
```

Where `type` is determined by agent type and task title keywords.
