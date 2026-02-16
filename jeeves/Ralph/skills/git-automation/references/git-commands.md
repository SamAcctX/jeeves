# Git Commands Reference

This document provides a comprehensive reference for all Git commands used by the Ralph Loop Git Automation skill.

---

## Table of Contents

1. [Branch Operations](#branch-operations)
2. [Commit Operations](#commit-operations)
3. [Conflict Resolution Commands](#conflict-resolution-commands)
4. [Remote Operations](#remote-operations)
5. [Safety Commands](#safety-commands)
6. [Context Detection Commands](#context-detection-commands)

---

## Branch Operations

### Create Branch

```bash
# Create and checkout new branch
git checkout -b <branch-name>

# Create from specific branch
git checkout -b <branch-name> <base-branch>

# Create from remote branch
git checkout -b <branch-name> origin/<remote-branch>

# Create branch without switching
git branch <branch-name>
```

**Script Usage:** `task-branch-create.sh`

**Exit Codes:**

| Code | Meaning |
|------|---------|
| 0 | Branch created successfully |
| 1 | Working directory not clean |
| 2 | Branch already exists |

---

### Switch Branches

```bash
# Switch to existing branch
git checkout <branch-name>

# Create and switch to new branch
git checkout -b <branch-name>

# Switch to previous branch
git checkout -

# Switch to specific commit (detached HEAD)
git checkout <commit-hash>
```

**Safety Check:**

```bash
# Check for uncommitted changes before switching
if ! git diff-index --quiet HEAD --; then
    echo "Uncommitted changes detected"
    git stash push -m "stash-before-switch"
fi
```

---

### List Branches

```bash
# List local branches
git branch

# List all branches (local and remote)
git branch -a

# List remote branches only
git branch -r

# Show merged branches
git branch --merged

# Show unmerged branches
git branch --no-merged

# Show branch with last commit
git branch -v
```

---

### Delete Branch

```bash
# Delete merged branch (safe delete)
git branch -d <branch-name>

# Delete unmerged branch (force delete)
git branch -D <branch-name>

# Delete remote branch
git push origin --delete <branch-name>
```

**Script Usage:** `branch-cleanup.sh`

**Pre-Deletion Checks:**

```bash
# Check if branch is merged
if git merge-base --is-ancestor <branch> <primary-branch>; then
    echo "Branch is merged - safe to delete"
else
    echo "Branch is NOT merged - commits will be lost!"
fi

# Check if currently on branch
current_branch=$(git branch --show-current)
if [ "$current_branch" = "<branch-name>" ]; then
    echo "Currently on branch - switch first"
    git checkout <primary-branch>
fi
```

---

### Merge Branch

```bash
# Standard merge
git merge <branch-name>

# Squash merge (creates single commit)
git merge --squash <branch-name>

# Merge with no fast-forward
git merge --no-ff <branch-name>

# Abort merge in progress
git merge --abort
```

**Script Usage:** `squash-merge.sh`

**Squash Merge Workflow:**

```bash
# 1. Checkout primary branch
git checkout main

# 2. Pull latest changes
git pull origin main

# 3. Squash merge
git merge --squash task-0042

# 4. Create commit
git commit -m "feat: implement user authentication"

# 5. Push
git push origin main
```

---

### Rebase Branch

```bash
# Rebase current branch onto another
git rebase <base-branch>

# Rebase onto specific commit
git rebase <commit-hash>

# Continue rebase after resolving conflicts
git rebase --continue

# Abort rebase
git rebase --abort

# Skip current commit during rebase
git rebase --skip
```

**Conflict Resolution During Rebase:**

```bash
# 1. Fix conflicts in files
# 2. Stage resolved files
git add <resolved-files>
# 3. Continue rebase
git rebase --continue
```

---

## Commit Operations

### Create Commit

```bash
# Commit with message
git commit -m "commit message"

# Commit all modified files
git commit -am "commit message"

# Commit with multi-line message
git commit -m "Subject line" -m "Body paragraph 1" -m "Body paragraph 2"

# Amend last commit
git commit --amend

# Amend without changing message
git commit --amend --no-edit
```

**Script Usage:** `git-commit-msg.sh` generates conventional commit messages

---

### View Commits

```bash
# Show commit history
git log

# Show compact history
git log --oneline

# Show graph view
git log --oneline --graph --all

# Show last N commits
git log -n 5

# Show commits with stats
git log --stat

# Show commits with patches
git log -p
```

**Useful Aliases:**

```bash
# Add to ~/.gitconfig
git config --global alias.lg "log --oneline --graph --all"
git config --global alias.ls "log --oneline -10"
```

---

### Stage Changes

```bash
# Stage specific file
git add <file-path>

# Stage all changes
git add .

# Stage all changes in directory
git add <directory>/

# Stage by patch (interactive)
git add -p

# Stage only updated files (not new files)
git add -u

# Unstage file
git restore --staged <file-path>
```

---

### Unstage/Uncommit

```bash
# Unstage file (keep changes)
git restore --staged <file-path>

# Discard changes in working directory
git restore <file-path>

# Unstage all files
git restore --staged .

# Reset last commit (keep changes)
git reset --soft HEAD~1

# Reset last commit (discard changes)
git reset --hard HEAD~1
```

---

## Conflict Resolution Commands

### Detect Conflicts

```bash
# Check for merge conflicts
git status

# Check porcelain status (for scripts)
git status --porcelain=v1

# Check if merge in progress
if [ -f .git/MERGE_HEAD ]; then
    echo "Merge in progress"
fi

# Check for rebase in progress
if [ -d .git/rebase-merge ]; then
    echo "Rebase in progress"
fi
```

**Script Usage:** `git-conflict.sh`

**Conflict Codes (Porcelain v1):**

| Code | Meaning |
|------|---------|
| UU | Both modified (conflict) |
| AA | Both added (conflict) |
| DD | Both deleted (conflict) |
| AU | Added by us, modified by them |
| UA | Modified by us, added by them |
| DU | Deleted by us, modified by them |
| UD | Modified by us, deleted by them |

---

### View Conflicts

```bash
# Show files with conflicts
git diff --name-only --diff-filter=U

# Show conflict details
git diff

# Show conflicts in specific file
git diff <file-path>

# Show common ancestors
git merge-base <branch1> <branch2>
```

---

### Resolve Conflicts

```bash
# After editing files to resolve conflicts:

# 1. Stage resolved files
git add <resolved-files>

# 2. Complete merge
git commit

# Or complete rebase
git rebase --continue
```

**Finding Conflict Markers:**

```bash
# Search for conflict markers
grep -r "<<<<<<< HEAD" .
grep -r "=======" .
grep -r ">>>>>>>" .

# In specific files
grep -n "<<<<<<<" <file-path>
```

---

### Cancel Merge/Rebase

```bash
# Abort merge
git merge --abort

# Abort rebase
git rebase --abort

# Abort cherry-pick
git cherry-pick --abort
```

---

## Remote Operations

### Remote Configuration

```bash
# List remotes
git remote -v

# Add remote
git remote add <name> <url>

# Remove remote
git remote remove <name>

# Rename remote
git remote rename <old-name> <new-name>

# Set remote URL
git remote set-url <name> <new-url>
```

---

### Push Operations

```bash
# Push current branch
git push

# Push specific branch
git push origin <branch-name>

# Push and set upstream
git push -u origin <branch-name>

# Force push (use with caution!)
git push --force

# Force push with lease (safer)
git push --force-with-lease

# Push all branches
git push --all origin

# Push tags
git push --tags
```

---

### Pull Operations

```bash
# Pull current branch
git pull

# Pull specific branch
git pull origin <branch-name>

# Pull with rebase
git pull --rebase

# Fetch only (no merge)
git fetch

# Fetch all remotes
git fetch --all

# Prune deleted remote branches
git fetch --prune
```

---

### Prune Remote References

```bash
# Prune stale remote-tracking branches
git remote prune origin

# Fetch and prune
git fetch --prune

# Prune all remotes
git remote prune --all
```

**Script Usage:** `branch-cleanup.sh` calls `git remote prune origin`

---

## Safety Commands

### Check Repository Status

```bash
# Show working tree status
git status

# Short status
git status -s
git status --short

# Porcelain status (for scripts)
git status --porcelain=v1
```

**Status Output Legend:**

| Left Column | Right Column | Meaning |
|-------------|--------------|---------|
| A | | Added to index |
| M | | Modified in index |
| D | | Deleted from index |
| R | | Renamed in index |
| C | | Copied in index |
| U | | Updated but unmerged |
| | M | Modified in work tree |
| | D | Deleted in work tree |
| | ? | Untracked |
| | ! | Ignored |

---

### Check Working Directory Clean

```bash
# Check if clean (exit 0 if clean, 1 if dirty)
if git diff-index --quiet HEAD --; then
    echo "Working directory is clean"
else
    echo "Uncommitted changes exist"
fi

# Check with untracked files
if [ -z "$(git status --porcelain)" ]; then
    echo "Working directory is clean"
fi
```

**Script Usage:** `task-branch-create.sh` checks before branch creation

---

### Stash Changes

```bash
# Stash current changes
git stash

# Stash with message
git stash push -m "description"

# Stash including untracked files
git stash push -u -m "description"

# List stashes
git stash list

# Apply latest stash
git stash pop

# Apply specific stash
git stash apply stash@{n}

# Drop specific stash
git stash drop stash@{n}

# Clear all stashes
git stash clear
```

**Script Usage:** `task-branch-create.sh` stashes uncommitted changes

---

### Show Differences

```bash
# Show unstaged changes
git diff

# Show staged changes
git diff --staged
git diff --cached

# Show changes between branches
git diff <branch1> <branch2>

# Show changes in specific file
git diff <file-path>

# Show staged changes for file
git diff --staged <file-path>
```

---

### Show Branch Information

```bash
# Show current branch
git branch --show-current

# Show branches containing commit
git branch --contains <commit>

# Show branches merged into current
git branch --merged

# Show branches not merged
git branch --no-merged

# Show branch with tracking info
git branch -vv
```

---

## Context Detection Commands

### Repository Detection

```bash
# Check if directory is git repository
git rev-parse --git-dir

# Get repository root
git rev-parse --show-toplevel

# Check if current directory is repo root
if [ -d .git ]; then
    echo "REPO_ROOT"
elif git rev-parse --git-dir >/dev/null 2>&1; then
    echo "SUBFOLDER"
else
    echo "NO_REPO"
fi
```

**Script Usage:** `git-context.sh`

---

### Primary Branch Detection

```bash
# Check for main branch
if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
fi

# Check for master branch
if git show-ref --verify --quiet refs/heads/master; then
    echo "master"
fi

# Check for trunk branch
if git show-ref --verify --quiet refs/heads/trunk; then
    echo "trunk"
fi

# Get current branch
git branch --show-current
```

**Script Usage:** `git-context.sh` uses 4-tier fallback:
1. main
2. master
3. trunk
4. current branch

---

### Gitignore Management

```bash
# Check gitignore patterns
git check-ignore -v <file-path>

# List ignored files
git status --ignored

# Show untracked files
git ls-files --others --exclude-standard
```

**Script Usage:** `configure-gitignore.sh`

**Recommended .gitignore Patterns:**

```
# Ralph Loop - ephemeral task data
.ralph/tasks/*          # Active task data
# !.ralph/tasks/done/   # Uncomment to preserve completed task history

# Ralph Loop - log files and temporary files
.ralph/*.log            # Log files
.ralph/.tmp/            # Temporary files
```

---

## Quick Reference Card

| Operation | Command |
|-----------|---------|
| Create branch | `git checkout -b <name>` |
| Switch branch | `git checkout <name>` |
| Delete branch | `git branch -d <name>` |
| Merge branch | `git merge <name>` |
| Squash merge | `git merge --squash <name>` |
| Commit | `git commit -m "msg"` |
| Stage all | `git add .` |
| Push | `git push -u origin <name>` |
| Pull | `git pull` |
| Fetch | `git fetch` |
| Status | `git status` |
| Log | `git log --oneline` |
| Diff | `git diff` |
| Stash | `git stash` |
| Pop stash | `git stash pop` |

---

## Related Documentation

- [Git Workflow User Guide](git-workflow-user.md)
- [Conventional Commits Guide](conventional-commits.md)
- [Troubleshooting Guide](troubleshooting.md)
