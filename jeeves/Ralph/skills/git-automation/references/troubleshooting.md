# Troubleshooting Guide

This guide helps you resolve common issues encountered when using the Ralph Loop Git Automation skill.

---

## Quick Diagnosis

Before diving into specific issues, run the diagnostic command:

```bash
# Check repository context and status
/proj/.ralph/skills/git-automation/scripts/git-context.sh
```

This will show you:
- Current repository context (REPO_ROOT, SUBFOLDER, or NO_REPO)
- Primary branch
- Current branch
- Available capabilities

---

## Common Issues

### Issue: "I'm in SUBFOLDER mode, what do I do?"

**Symptoms:**

```
⚠ Git Integration: LIMITED MODE
Working in subdirectory of repository

Limitations:
  • Git branch operations are disabled
  • File operations only
```

**Explanation:**

Your `/proj` directory is a subdirectory within a larger Git repository. For safety, the automation skill disables automatic branch management to avoid unintended operations on the parent repository.

**Solution:**

You need to manage branches manually from the repository root:

```bash
# 1. Find your repository root
cd /proj
repo_root=$(git rev-parse --show-toplevel)
echo "Repository root: $repo_root"

# 2. Navigate to repository root
cd "$repo_root"

# 3. Create and checkout task branch manually
git checkout -b task-0042

# 4. Push to remote with tracking
git push -u origin task-0042

# 5. Return to /proj to continue working
cd /proj
```

**For Squash Merge (SUBFOLDER):**

```bash
# Navigate to repository root
cd /path/to/repo-root

# Checkout primary branch
git checkout main

# Pull latest
git pull origin main

# Generate commit message
COMMIT_MSG=$(/proj/.ralph/skills/git-automation/scripts/git-commit-msg.sh \
    --task-id 0042 \
    --agent-type developer \
    --task-title "Implement feature")

# Squash merge
git merge --squash task-0042

# Commit
git commit -m "$COMMIT_MSG"

# Push
git push origin main

# Delete branch
git branch -d task-0042
git push origin --delete task-0042
```

---

### Issue: "Branch already exists"

**Symptoms:**

```
[WARNING] Branch 'task-0042' already exists locally
[INFO] Checking out existing branch...
[SUCCESS] Checked out existing branch: task-0042
```

Or:

```
[ERROR] Failed to create branch: branch already exists
```

**Explanation:**

The task branch already exists, either locally or remotely.

**Solution:**

**Option 1: Checkout existing branch (if you want to continue)**

```bash
# The script may have already done this, but you can verify
git checkout task-0042

# Pull latest changes if on remote
git pull origin task-0042
```

**Option 2: Delete and recreate (if you want to start fresh)**

```bash
# Save any work first!
git stash push -m "work-before-recreate"

# Delete local branch
git branch -D task-0042

# Delete remote branch (if exists)
git push origin --delete task-0042

# Recreate from primary branch
git checkout main
git pull origin main
git checkout -b task-0042
```

**Option 3: Use different branch name**

```bash
# Create branch with description to differentiate
git checkout -b task-0042-v2
```

---

### Issue: "Merge conflicts detected"

**Symptoms:**

```
[ERROR] Merge conflicts detected between 'main' and 'task-0042'
[ERROR] TASK_BLOCKED: Merge conflict requires human resolution
```

Or during rebase:

```
Auto-merging file.txt
CONFLICT (content): Merge conflict in file.txt
error: could not apply commit... 
hint: Resolve all conflicts manually...
```

**Explanation:**

Changes in your task branch conflict with changes in the primary branch. Git cannot automatically merge them.

**Solution:**

**Step 1: Identify conflicting files**

```bash
# List files with conflicts
git diff --name-only --diff-filter=U

# Or use the conflict detection script
/proj/.ralph/skills/git-automation/scripts/git-conflict.sh --get-files
```

**Step 2: View conflict details**

```bash
# Show conflict markers
git diff

# View conflicts in specific file
git diff <file-path>
```

**Step 3: Resolve conflicts**

Conflicts appear as:

```
<<<<<<< HEAD
// Code from primary branch (main)
function oldVersion() { ... }
=======
// Code from your branch (task-0042)
function newVersion() { ... }
>>>>>>> task-0042
```

Edit the file to:
1. Keep the desired code
2. Remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
3. Ensure the code is valid

**Step 4: Mark as resolved**

```bash
# Stage resolved file
git add <resolved-file>

# Or stage all resolved files
git add .
```

**Step 5: Complete the merge**

```bash
# If merging
git commit

# If rebasing
git rebase --continue
```

**Prevention:**

```bash
# Always pull latest changes before creating branch
git checkout main
git pull origin main

# Rebase frequently during long-running tasks
git checkout task-0042
git rebase main
```

---

### Issue: "Permission denied"

**Symptoms:**

```
[ERROR] Authentication or permission error detected
Fix instructions:
  1. Check your credentials are correct
  2. Verify you have access to the repository
  3. Ensure SSH keys or tokens are properly configured
TASK_BLOCKED: Git authentication/permission failure - manual intervention required
```

Or:

```
fatal: unable to access 'https://github.com/...': The requested URL returned error: 403
fatal: Authentication failed for 'https://github.com/...'
```

**Explanation:**

Git cannot authenticate with the remote repository.

**Solution:**

**For HTTPS:**

```bash
# Check current remote URL
git remote -v

# Update to use personal access token
git remote set-url origin https://<token>@github.com/username/repo.git

# Or configure credential helper
git config --global credential.helper cache
```

**For SSH:**

```bash
# Check if SSH key is loaded
ssh-add -l

# If not loaded, add your key
ssh-add ~/.ssh/id_rsa

# Test SSH connection
ssh -T git@github.com

# If keys don't exist, generate new ones
ssh-keygen -t ed25519 -C "your.email@example.com"
```

**Verify access:**

```bash
# Test fetch (doesn't require push permissions)
git fetch origin

# Check your permissions
curl -H "Authorization: token <your-token>" \
     https://api.github.com/repos/owner/repo/collaborators
```

---

### Issue: "Network timeout"

**Symptoms:**

```
[WARNING] Retry 2/3 in 4s...
[WARNING] Transient error persisted after 3 attempts
[WARNING] Git operation failed, continuing without git integration
```

Or:

```
fatal: unable to access 'https://github.com/...': 
Could not resolve host: github.com
```

Or:

```
error: RPC failed; curl 56 LibreSSL SSL_read: SSL_ERROR_SYSCALL, errno 54
fatal: the remote end hung up unexpectedly
```

**Explanation:**

Network connectivity issues preventing Git operations.

**Solution:**

**Step 1: Check network connectivity**

```bash
# Test internet connection
ping github.com

# Test HTTPS access
curl -I https://github.com

# Test SSH access
ssh -T git@github.com
```

**Step 2: Retry the operation**

```bash
# The git-wrapper.sh automatically retries with backoff
# You can also retry manually:
git push origin task-0042
```

**Step 3: Configure Git for slow networks**

```bash
# Increase buffer size for large pushes
git config --global http.postBuffer 524288000

# Enable keepalive
git config --global http.keepAlive true

# Set timeout
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 300
```

**Step 4: Use SSH instead of HTTPS (more reliable)**

```bash
# Change remote URL to SSH
git remote set-url origin git@github.com:username/repo.git
```

**Step 5: Work offline and push later**

```bash
# Continue working locally
git commit -m "feat: implement feature"

# Push when network is available
git push origin task-0042
```

---

## Recovery Procedures

### Recover from Failed Squash Merge

**Symptoms:**

```
[ERROR] Squash merge failed
Working directory is in an inconsistent state
```

**Recovery:**

```bash
# 1. Check status
git status

# 2. If merge in progress, abort
git merge --abort

# 3. Reset to clean state
git reset --hard HEAD

# 4. Checkout primary branch
git checkout main

# 5. Pull latest
git pull origin main

# 6. Try merge again
/proj/.ralph/skills/git-automation/scripts/squash-merge.sh --task-id 0042
```

---

### Recover from Failed Rebase

**Symptoms:**

```
[ERROR] Rebase failed
You are in the middle of a rebase
```

**Recovery:**

```bash
# Option 1: Continue rebase after fixing conflicts
git add <resolved-files>
git rebase --continue

# Option 2: Abort rebase and try merge instead
git rebase --abort
git checkout main
git merge task-0042

# Option 3: Hard reset (loses uncommitted work)
git rebase --abort
git checkout task-0042
git reset --hard origin/task-0042
```

---

### Recover Lost Commits

**Symptoms:**

Accidentally deleted branch or reset too far.

**Recovery:**

```bash
# 1. Find lost commits in reflog
git reflog

# 2. Locate the commit hash before the loss
# Example output:
# abc1234 HEAD@{0}: reset: moving to HEAD~1
# def5678 HEAD@{1}: commit: feat: add feature

# 3. Create branch from lost commit
git checkout -b recovery-branch def5678

# 4. Cherry-pick to current branch
git checkout task-0042
git cherry-pick def5678
```

---

### Recover from Corrupted Repository

**Symptoms:**

```
fatal: corrupt loose object
error: object file is empty
fatal: bad object HEAD
```

**Recovery:**

```bash
# 1. Try git fsck (file system check)
git fsck --full

# 2. Try to repair
git gc --prune=now

# 3. If still corrupted, clone fresh and apply changes
# (Save your work first!)
cp -r /proj /proj-backup
cd /tmp
git clone <repository-url> fresh-clone
cd fresh-clone
git checkout -b task-0042
cp -r /proj-backup/* .
git add .
git commit -m "feat: recover from corruption"
```

---

## Context-Specific Issues

### NO_REPO Context Issues

**Symptoms:**

```
✗ Git Integration: NOT AVAILABLE
No git repository detected
```

**Solution:**

```bash
# 1. Initialize repository
cd /proj
git init

# 2. Configure user
git config user.name "Your Name"
git config user.email "your.email@example.com"

# 3. Create initial commit
git add .
git commit -m "Initial commit"

# 4. Add remote (if needed)
git remote add origin <repository-url>

# 5. Run context detection again
/proj/.ralph/skills/git-automation/scripts/git-context.sh
```

---

### SUBFOLDER Context - Finding Repository Root

**Issue:** Don't know where repository root is

**Solution:**

```bash
# From /proj, find repository root
git rev-parse --show-toplevel

# Or use the context script
source /proj/.ralph/skills/git-automation/scripts/git-context.sh
get_repo_root
```

---

## Prevention Checklist

Avoid common issues by following these practices:

- [ ] Always pull latest changes before creating branches
- [ ] Commit frequently with meaningful messages
- [ ] Push to remote regularly (backup)
- [ ] Rebase or merge primary branch into task branch frequently
- [ ] Test before squash merging
- [ ] Keep task branches short-lived
- [ ] Configure git user name and email
- [ ] Set up SSH keys for reliable authentication
- [ ] Review generated commit messages before committing

---

## Getting Help

If issues persist:

1. Check the [Git Commands Reference](git-commands.md) for command syntax
2. Review the [Git Workflow User Guide](git-workflow-user.md) for workflow details
3. Consult the [Conventional Commits Guide](conventional-commits.md) for commit format
4. Check the [Skill Documentation](../SKILL.md) for complete feature reference

---

## Emergency Commands

```bash
# Check everything
/proj/.ralph/skills/git-automation/scripts/git-context.sh
git status
git branch -v
git log --oneline -5

# Abort any in-progress operations
git merge --abort 2>/dev/null || true
git rebase --abort 2>/dev/null || true
git cherry-pick --abort 2>/dev/null || true

# Clean working directory (DANGER: discards changes)
git reset --hard HEAD
git clean -fd

# Reset to remote state
git fetch origin
git reset --hard origin/<branch-name>
```
