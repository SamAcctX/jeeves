# Git Workflow User Guide

## Overview

This guide explains how the Ralph Loop Git Automation skill integrates with your workflow. It covers the three repository contexts, what Ralph handles automatically, your responsibilities, and common workflows.

---

## Quick Start Guide

### 1. Check Your Repository Context

```bash
# Detect your current context
/proj/.ralph/skills/git-automation/scripts/git-context.sh
```

### 2. Start Working on a Task

```bash
# Create task branch (REPO_ROOT context only)
/proj/.ralph/skills/git-automation/scripts/task-branch-create.sh --task-id 0042

# Or with description
/proj/.ralph/skills/git-automation/scripts/task-branch-create.sh --task-id 0042 --description "implement-feature"
```

### 3. Commit Your Work

```bash
# Generate conventional commit message
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Add user authentication")

# Commit with generated message
git add .
git commit -m "$COMMIT_MSG"
```

### 4. Complete Task (Squash Merge)

```bash
# Merge task branch to primary branch
/proj/.ralph/skills/git-automation/scripts/squash-merge.sh --task-id 0042

# Clean up branch
/proj/.ralph/skills/git-automation/scripts/branch-cleanup.sh --task-id 0042
```

---

## Repository Contexts Explained

The Git Automation skill operates in three contexts based on your repository structure:

### REPO_ROOT - Full Git Integration Mode

**When:** `/proj/.git` directory exists

**Capabilities:**

- Full branch management (create, merge, delete)
- Automatic workflow integration
- Primary branch tracking
- Automatic conflict detection

**Your Responsibilities:**

- Review and test your changes
- Write meaningful commit messages
- Resolve merge conflicts when they occur

**Example Output:**

```
========================================
  Git Integration Status
========================================

✓ Git Integration: FULL MODE
  Repository root detected at /proj

  Primary branch: main
  Current branch: task-0042

  Capabilities:
    • Full branch management
    • Automatic workflow integration
    • Primary branch tracking

========================================
```

---

### SUBFOLDER - Limited Git Integration Mode

**When:** `/proj` is a subdirectory within a Git repository

**Limitations:**

- Git branch operations are **disabled** (safety constraint)
- File operations only
- No automatic branch creation or merging

**Your Responsibilities:**

- Create task branches manually
- Commit and push changes manually
- Merge branches manually
- Keep track of repository root

**Example Output:**

```
========================================
  Git Integration Status
========================================

⚠ Git Integration: LIMITED MODE
  Working in subdirectory of repository
  Repository root: /home/user/myproject

  Limitations:
    • Git branch operations are disabled
    • File operations only

  Your Responsibility:
    You must manage branches manually.
    Create and switch branches outside of Ralph Loop.

========================================
```

**Manual Branch Creation:**

```bash
# Navigate to repository root
cd /home/user/myproject

# Create and checkout task branch
git checkout -b task-0042

# Push to remote with tracking
git push -u origin task-0042
```

---

### NO_REPO - File-Based Mode

**When:** No Git repository detected

**Mode:**

- File-based task management only
- No git operations will be performed
- Task tracking via TODO.md

**Your Responsibilities:**

- Initialize Git repository if needed: `git init`
- Commit changes manually
- Track task progress manually

**To Enable Full Features:**

```bash
# Initialize git repository
git init

# Configure git
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Run context detection again
/proj/.ralph/skills/git-automation/scripts/git-context.sh
```

---

## What Ralph Handles Automatically

### REPO_ROOT Context

| Task | Ralph Handles | You Handle |
|------|---------------|------------|
| Context Detection | ✓ Detects REPO_ROOT/SUBFOLDER/NO_REPO | — |
| Branch Creation | ✓ Creates task branches from primary | — |
| Commit Messages | ✓ Generates conventional commits | — |
| Merge Detection | ✓ Detects merge conflicts before merge | — |
| Squash Merge | ✓ Merges to primary, deletes task branch | — |
| Remote Cleanup | ✓ Deletes remote branches | — |
| Gitignore Setup | ✓ Configures .gitignore | — |
| File Operations | ✓ All file modifications | — |
| Code Quality | — | ✓ Testing, code review |
| Commit Review | — | ✓ Verify commit message is accurate |

### SUBFOLDER Context

| Task | Ralph Handles | You Handle |
|------|---------------|------------|
| Context Detection | ✓ Detects SUBFOLDER mode | — |
| Branch Creation | — | ✓ Manual branch management |
| Commit Messages | ✓ Generates suggestions | ✓ Apply manually |
| File Operations | ✓ All file modifications | — |
| Merge Operations | — | ✓ Manual merge operations |
| Gitignore Setup | ✓ Configures at repo root | — |

### NO_REPO Context

| Task | Ralph Handles | You Handle |
|------|---------------|------------|
| Context Detection | ✓ Detects NO_REPO mode | — |
| Git Operations | Not available | ✓ Manual Git initialization |
| File Operations | ✓ All file modifications | — |
| Task Tracking | ✓ Via TODO.md | — |

---

## Common Workflows

### Workflow 1: Starting a New Task (REPO_ROOT)

```bash
# 1. Ensure you're on the primary branch
git checkout main

# 2. Pull latest changes
git pull origin main

# 3. Create task branch
/proj/.ralph/skills/git-automation/scripts/task-branch-create.sh --task-id 0042

# 4. Make your changes
# ... edit files ...

# 5. Stage and commit
git add .
git commit -m "WIP: implement feature"

# 6. Push to remote
git push
```

### Workflow 2: Starting a New Task (SUBFOLDER)

```bash
# 1. Navigate to repository root (not /proj)
cd /path/to/repo-root

# 2. Pull latest changes
git checkout main
git pull origin main

# 3. Create task branch manually
git checkout -b task-0042

# 4. Push to remote
git push -u origin task-0042

# 5. Work in /proj as normal
# Ralph will handle file operations
```

### Workflow 3: Completing a Task with Squash Merge

```bash
# 1. Ensure all changes are committed
git status  # Should be clean

# 2. Run squash merge script
/proj/.ralph/skills/git-automation/scripts/squash-merge.sh --task-id 0042

# 3. Clean up branch
/proj/.ralph/skills/git-automation/scripts/branch-cleanup.sh --task-id 0042
```

### Workflow 4: Committing Work in Progress

```bash
# 1. Generate conventional commit message
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Implement user authentication")

# 2. Review the message
echo "$COMMIT_MSG"
# Output: feat: implement user authentication

# 3. Commit with generated message
git add .
git commit -m "$COMMIT_MSG"
```

### Workflow 5: Handling Merge Conflicts

```bash
# 1. Check for conflicts
/proj/.ralph/skills/git-automation/scripts/git-conflict.sh --check-all

# 2. If conflicts detected, view report
/proj/.ralph/skills/git-automation/scripts/git-conflict.sh --report

# 3. Resolve conflicts manually
# Edit files to resolve <<<<<<< HEAD markers

# 4. Stage resolved files
git add <resolved-files>

# 5. Complete merge
git commit
```

### Workflow 6: Safe Git Operations with Wrapper

```bash
# Use git-wrapper.sh for safe operations
source /proj/.ralph/skills/git-automation/scripts/git-wrapper.sh

# Safe push with retry logic
git_safe push origin task-0042

# Safe pull with error handling
git_safe pull origin main

# Safe fetch
git_safe fetch --all
```

### Workflow 7: Configure Gitignore

```bash
# Standard configuration
/proj/.ralph/skills/git-automation/scripts/configure-gitignore.sh

# Preserve completed task history
/proj/.ralph/skills/git-automation/scripts/configure-gitignore.sh --preserve-done
```

---

## Cross-References

- **Git Commands Reference**: See [git-commands.md](git-commands.md)
- **Conventional Commits Guide**: See [conventional-commits.md](conventional-commits.md)
- **Troubleshooting**: See [troubleshooting.md](troubleshooting.md)
- **Skill Documentation**: See [../SKILL.md](../SKILL.md)

---

## Best Practices

### 1. Commit Often

Make small, focused commits rather than large, monolithic changes.

### 2. Review Generated Commit Messages

Always review the conventional commit message before committing.

### 3. Keep Task Branches Short-Lived

Create branches for specific tasks and delete them after merge.

### 4. Pull Before Starting

Always pull the latest changes before creating a new task branch.

### 5. Test Before Merging

Run tests and verify functionality before completing a task.

### 6. Use Descriptive Branch Names

The skill generates branch names like `task/0042-description`. Keep descriptions concise.

---

## Questions?

For more details on specific commands, see the linked reference documents above.

For issues or unexpected behavior, see the [Troubleshooting Guide](troubleshooting.md).
