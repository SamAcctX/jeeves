# Ralph Troubleshooting Guide

This guide helps diagnose and resolve common issues with the Ralph Loop system.

---

## Quick Diagnostics

Run these commands first when something goes wrong:

```bash
# Check Ralph installation
ls -la .ralph/

# Check git status
git status

# View recent logs
tail -n 50 .ralph/tasks/*/activity.md

# Check TODO.md state
cat .ralph/tasks/TODO.md

# Check for conflicts in state files
head -5 .ralph/tasks/TODO.md .ralph/tasks/deps-tracker.yaml
```

---

## Common Issues

### Initialization Problems

#### Missing Required Tools
**Error:** `[ERROR] Missing required tools: yq jq git`

**Cause:** One or more required tools are not installed.

**Solution:**
```bash
# Install yq (YAML processor)
# See: https://github.com/mikefarah/yq#install

# Install jq (JSON processor)
# Ubuntu/Debian: sudo apt-get install jq
# macOS: brew install jq

# Verify installations
yq --version
jq --version
git --version
```

#### Template Source Not Found
**Error:** `[ERROR] Template source directory not found: /opt/jeeves/Ralph/templates`

**Cause:** Templates are not staged in the container or installation path is incorrect.

**Solution:**
- Verify Dockerfile has COPY commands for templates
- Check `/opt/jeeves/Ralph/templates/` exists in container
- Rebuild container with `--no-cache` if templates were updated

#### Unknown Option
**Error:** `[ERROR] Unknown option: --invalid-flag`

**Cause:** Invalid command-line argument passed to ralph-init.sh.

**Solution:**
```bash
# View valid options
ralph-init.sh --help

# Valid options: --force, -f, --rules, --help, -h
```

#### Ralph Already Initialized
**Symptom:** `Existing Ralph installation detected at .ralph/`

**Solution:**
```bash
# Use --force to overwrite existing files
ralph-init.sh --force

# Or manually backup and remove
mv .ralph .ralph.backup.$(date +%Y%m%d)
rm -f ralph-loop.sh
ralph-init.sh
```

---

### Loop Execution Issues

#### Loop Appears Stuck
**Symptom:** No output for extended period.

**Diagnosis:**
```bash
# Check if process is running
ps aux | grep opencode

# Check activity.md for recent updates
tail -f .ralph/tasks/*/activity.md

# Check for ABORT line
grep "ABORT" .ralph/tasks/TODO.md
```

**Solutions:**
- Wait longer (large tasks can take time)
- Check task complexity in TASK.md (may need decomposition)
- Press Ctrl+C to interrupt, then investigate
- Check iteration count in loop output

#### TASK_BLOCKED Signal
**Error:** `[ERROR] Task XXXX blocked: <message>`

**Diagnosis:**
```bash
# Check TODO.md for ABORT line
grep "^ABORT:" .ralph/tasks/TODO.md

# Review task activity
cat .ralph/tasks/XXXX/activity.md

# Check deps-tracker.yaml for issues
cat .ralph/tasks/deps-tracker.yaml
```

**Recovery:**
1. Read activity.md to understand blockage
2. Fix the underlying issue manually
3. Remove ABORT line from TODO.md:
   ```bash
   sed -i '/^ABORT:/d' .ralph/tasks/TODO.md
   ```
4. Restart loop: `./ralph-loop.sh`

#### Iteration Limit Reached
**Warning:** `GLOBAL_ITERATION_LIMIT_REACHED: 100 iterations`

**Solution:**
```bash
# Review progress
cat .ralph/tasks/TODO.md

# Check for stuck tasks
grep -r "Attempt" .ralph/tasks/*/attempts.md

# Adjust limit
export RALPH_MAX_ITERATIONS=200
./ralph-loop.sh

# Or remove limit for unlimited iterations
unset RALPH_MAX_ITERATIONS
./ralph-loop.sh
```

#### Invalid Max Iterations
**Warning:** `Invalid RALPH_MAX_ITERATIONS: 'abc' - defaulting to unlimited`

**Cause:** RALPH_MAX_ITERATIONS environment variable contains non-numeric value.

**Solution:**
```bash
# Set to valid number
export RALPH_MAX_ITERATIONS=100

# Or unset to use default
unset RALPH_MAX_ITERATIONS
```

---

### Git Workflow Problems

#### Git Conflicts in TODO.md or deps-tracker.yaml
**Error:** `[ERROR] Git conflict detected: .ralph/tasks/TODO.md`
**Error:** `[ERROR] Conflict markers in: .ralph/tasks/deps-tracker.yaml`

**Cause:** Manual edits while loop is running or concurrent modifications.

**Solution:**
1. Stop loop with Ctrl+C
2. Resolve conflicts manually:
   ```bash
   git status
   git diff .ralph/tasks/TODO.md
   
   # Edit to resolve conflicts (remove markers)
   vim .ralph/tasks/TODO.md
   
   # Mark resolved
   git add .ralph/tasks/TODO.md
   git add .ralph/tasks/deps-tracker.yaml
   git commit -m "Resolved Ralph state conflicts"
   ```
3. Restart loop

**Prevention:**
- Do not edit TODO.md while loop is running
- Always stop loop before manual edits

#### Working Directory Not Clean
**Error:** Branch creation fails due to uncommitted changes.

**Solution:**
```bash
# Check status
git status

# Stash changes
git stash

# Or commit changes
git add .
git commit -m "WIP: save progress"
```

#### Branch Already Exists
**Error:** Task branch already exists (e.g., `task-0042`).

**Solution:**
```bash
# List task branches
git branch | grep task-

# Switch to existing branch
git checkout task-0042

# Or delete and recreate (if safe)
git branch -D task-0042
git checkout primary-branch
```

---

### Signal System Issues

#### Missing TASK_COMPLETE Signal
**Symptom:** Task finished but loop continues.

**Cause:** Agent did not emit proper signal or signal was not recognized.

**Diagnosis:**
```bash
# Check activity.md for completion evidence
grep -i "complete\|finish\|done" .ralph/tasks/XXXX/activity.md

# Check last lines of output
tail -20 .ralph/tasks/XXXX/activity.md
```

**Solution:**
1. Verify signal format in activity.md
2. Check that signal is on its own line
3. Manually mark complete if needed:
   ```bash
   sed -i 's/- \[ \] XXXX/- [x] XXXX/' .ralph/tasks/TODO.md
   mv .ralph/tasks/XXXX .ralph/tasks/done/
   ```

#### Incorrect Signal Format
**Symptom:** Manager does not recognize Worker response.

**Check:** Signal must be first token on its own line:
```
TASK_COMPLETE_0001           # GOOD - first token, own line

Result: TASK_COMPLETE_0001   # BAD - not first token
Some text TASK_COMPLETE_0001 # BAD - embedded in line
```

**Solution:**
- Ensure agent emits signal on its own line
- No prefix text before signal
- Valid formats:
  - `TASK_COMPLETE_XXXX`
  - `TASK_INCOMPLETE_XXXX`
  - `TASK_FAILED_XXXX: message`
  - `TASK_BLOCKED_XXXX: message`

#### Multiple Signals Detected
**Warning:** `Multiple signals detected (3) - using first valid signal`

**Cause:** Agent emitted more than one signal.

**Solution:**
- Review agent logic to emit only one signal
- Check for copy-paste errors in agent responses
- First valid signal is used, others ignored

---

### Dependency Tracking Problems

#### Circular Dependency Detected
**Error:** `Circular dependency detected` (from deps-cycle.sh)

**Diagnosis:**
```bash
# Check deps-tracker.yaml
cat .ralph/tasks/deps-tracker.yaml
```

**Solution:**
1. Identify the cycle in deps-tracker.yaml
2. Break cycle by removing one dependency edge:
   ```yaml
   # Before (circular)
   0001:
     depends_on: [0002]
   0002:
     depends_on: [0003]
   0003:
     depends_on: [0001]  # Remove this
   
   # After (fixed)
   0001:
     depends_on: [0002]
   0002:
     depends_on: [0003]
   0003:
     depends_on: []  # Fixed
   ```
3. Restart loop

#### Task Blocked by Dependencies
**Symptom:** Task not being selected despite being in TODO.

**Diagnosis:**
```bash
# Check dependency status
yq eval '.tasks.XXXX.depends_on' .ralph/tasks/deps-tracker.yaml

# Check if dependencies are complete
grep "^- \[x\]" .ralph/tasks/TODO.md

# Find unblocked tasks
./deps-select.sh --find-unblocked
```

**Solution:**
- Complete dependency tasks first
- Or remove dependency if no longer needed
- Check for circular dependencies

---

### Configuration Errors

#### agents.yaml Parsing Error
**Error:** `[ERROR] agents.yaml contains invalid YAML syntax`

**Solution:**
```bash
# Validate YAML syntax
yq eval '.' .ralph/config/agents.yaml

# Common issues to check:
# - Tabs instead of spaces (use spaces only)
# - Missing colons after keys
# - Incorrect indentation
# - Unclosed quotes
```

#### agents.yaml Not Found
**Error:** `[ERROR] agents.yaml not found: .ralph/config/agents.yaml`

**Solution:**
```bash
# Re-initialize Ralph
ralph-init.sh --force

# Or copy from template
cp .ralph/config/agents.yaml.template .ralph/config/agents.yaml
```

#### Invalid Task ID Format
**Error:** `Error: Task ID must be 4 digits`
**Error:** `Error: Task ID must be numeric`

**Cause:** Task folder names do not follow 4-digit format.

**Solution:**
```bash
# Rename folders to 4-digit format
mv .ralph/tasks/1 .ralph/tasks/0001
mv .ralph/tasks/42 .ralph/tasks/0042

# Must be exactly 4 digits: 0001-9999
```

---

### Agent/Tool Issues

#### Invalid Tool Selection
**Error:** `Invalid tool: 'invalid-tool'. Valid tools are: opencode, claude`

**Solution:**
```bash
# Use valid tool
./ralph-loop.sh --tool opencode
# or
./ralph-loop.sh --tool claude

# Or set environment variable
export RALPH_TOOL=opencode
```

#### Agent Not Found
**Symptom:** `Agent 'developer' not found` during sync.

**Solution:**
```bash
# Check agent file exists
ls -la .opencode/agents/developer.md
# or
ls -la ~/.config/opencode/agents/developer.md

# Run sync-agents
sync-agents

# Re-initialize if agents are missing
ralph-init.sh --force
```

#### Agent Sync Failed
**Warning:** `Agent sync failed after 5s (continuing anyway)`

**Cause:** Non-critical error during agent synchronization.

**Solution:**
- Check agents.yaml syntax: `yq eval '.' .ralph/config/agents.yaml`
- Verify yq is installed: `yq --version`
- Loop continues regardless - agent sync is optional

#### Tool Command Not Found
**Error:** `opencode: command not found` or `claude: command not found`

**Solution:**
- Verify tool is installed
- Check PATH includes tool binary
- For OpenCode: ensure `opencode` CLI is installed
- For Claude Code: ensure `claude` CLI is installed

#### Model Unavailable
**Symptom:** `Model 'X' not available`

**Solution:**
- Check agents.yaml for correct model name
- Update to available model
- Fallback model should be used automatically
- Run `sync-agents` to update agent configurations

---

## Debugging Techniques

### Analyzing activity.md

Key sections to check:
1. **Most recent attempt** - What was tried last
2. **Error messages** - What went wrong
3. **Iteration count** - How many attempts made
4. **Approach changes** - Is agent trying different strategies

```bash
# View most recent activity
tail -n 30 .ralph/tasks/XXXX/activity.md

# Search for specific errors
grep -n "ERROR\|FAILED\|BLOCKED" .ralph/tasks/XXXX/activity.md
```

---

### Log Aggregation

```bash
# View all recent activity
tail -n 20 .ralph/tasks/*/activity.md

# Search for errors across all tasks
grep -r "ERROR" .ralph/tasks/

# Check attempt counts
grep -h "Attempt" .ralph/tasks/*/attempts.md | tail -20

# Find tasks with many attempts (potential stuck tasks)
for f in .ralph/tasks/*/attempts.md; do
  count=$(grep -c "^## Attempt" "$f" 2>/dev/null || echo 0)
  if [ "$count" -gt 5 ]; then
    echo "$f: $count attempts"
  fi
done
```

---

### State Inspection

```bash
# Full state snapshot
echo "=== TODO.md ===" && cat .ralph/tasks/TODO.md
echo "=== Dependencies ===" && cat .ralph/tasks/deps-tracker.yaml
echo "=== Active Tasks ===" && ls .ralph/tasks/ | grep -E '^[0-9]{4}$'
echo "=== Done Tasks ===" && ls .ralph/tasks/done/
echo "=== Git Status ===" && git status --short
```

---

## Recovery Procedures

### Complete Reset

**When:** Ralph state completely corrupted.

**Procedure:**
```bash
# Stop loop
Ctrl+C

# Backup current state
cp -r .ralph .ralph.backup.$(date +%Y%m%d)

# Reset to clean state
rm -rf .ralph/tasks/*
git checkout HEAD -- .ralph/tasks/TODO.md
git checkout HEAD -- .ralph/tasks/deps-tracker.yaml

# Re-initialize
ralph-init.sh --force

# Restart loop
./ralph-loop.sh
```

---

### Recovering from TASK_BLOCKED

1. Investigate root cause in activity.md:
   ```bash
   cat .ralph/tasks/XXXX/activity.md
   ```

2. Apply manual fix based on error

3. Remove ABORT line from TODO.md:
   ```bash
   sed -i '/^ABORT:/d' .ralph/tasks/TODO.md
   ```

4. Consider adding RULES.md entry if pattern discovered

5. Restart loop:
   ```bash
   ./ralph-loop.sh
   ```

---

### Manual Task Completion

When automatic completion fails:

```bash
# Mark done manually in TODO.md
sed -i 's/- \[ \] 0001/- [x] 0001/' .ralph/tasks/TODO.md

# Move folder manually
mv .ralph/tasks/0001 .ralph/tasks/done/

# Perform git operations manually if in REPO_ROOT context
git checkout primary-branch
git merge --squash task-0001
git commit -m "feat(scope): task 0001 completed"
git branch -d task-0001
```

---

### Clearing Stuck Tasks

**When:** Task has too many attempts without progress.

```bash
# Check attempt count
wc -l .ralph/tasks/XXXX/attempts.md

# Option 1: Reset task (remove activity, keep task)
mv .ralph/tasks/XXXX/activity.md .ralph/tasks/XXXX/activity.md.old
mv .ralph/tasks/XXXX/attempts.md .ralph/tasks/XXXX/attempts.md.old

# Option 2: Decompose task
# Mark current as complete
sed -i 's/- \[ \] XXXX/- [x] XXXX/' .ralph/tasks/TODO.md
mv .ralph/tasks/XXXX .ralph/tasks/done/

# Create new smaller tasks (0010, 0011, 0012)
# Add to TODO.md and deps-tracker.yaml
```

---

## FAQ

**Q: Can I run Ralph without Docker?**

A: Yes, but all dependencies (yq, jq, bash 4.0+) must be installed manually.

---

**Q: How do I pause the loop?**

A: Press Ctrl+C. Loop can be restarted safely.

---

**Q: Can I edit TODO.md while loop is running?**

A: Not recommended. Stop loop first, edit, then restart.

---

**Q: What if a task is too big?**

A: Signal TASK_BLOCKED, then decompose into smaller tasks. Update deps-tracker.yaml with new dependencies.

---

**Q: How do I add a new agent type?**

A: 
1. Edit agents.yaml to add agent configuration
2. Create agent.md file in appropriate directory
3. Run sync-agents to apply model settings

---

**Q: Can I use multiple tools in one project?**

A: No. One tool per loop run. Switch with --tool flag:
```bash
./ralph-loop.sh --tool opencode
./ralph-loop.sh --tool claude
```

---

**Q: How do I check if Ralph is initialized correctly?**

A:
```bash
ls -la .ralph/          # Should show config/, tasks/, specs/
ls -la .ralph/tasks/    # Should show done/
cat .ralph/config/agents.yaml  # Should show agent definitions
```

---

**Q: What does SUBFOLDER context mean?**

A: Your project is a subdirectory within a larger git repository. Git branch operations are disabled for safety. Manage branches manually outside Ralph Loop.

---

**Q: How do I detect circular dependencies?**

A:
```bash
# Validate dependency graph
./deps-cycle.sh --validate-graph

# Or check manually in deps-tracker.yaml
# Look for A depends on B, B depends on C, C depends on A
```

---

**Q: What is the ABORT line in TODO.md?**

A: When a task signals TASK_BLOCKED, the Manager adds `ABORT: HELP NEEDED` to TODO.md. This causes the loop to stop. Remove the line after fixing the issue.

---

**Q: How do I back off and let a task cool down?**

A: The loop has built-in exponential backoff. Delays increase automatically between iterations. Use `--no-delay` flag to disable:
```bash
./ralph-loop.sh --no-delay
```

---

## Error Message Reference

### ralph-init.sh
- `[ERROR] Missing required tools: ...` - Install missing dependencies
- `[ERROR] Template source directory not found: ...` - Check container installation
- `[ERROR] Unknown option: ...` - Use --help for valid options
- `[ERROR] Template not found: ...` - Template file missing from /opt/jeeves/Ralph/templates
- `[WARNING] Skipping existing file: ...` - Use --force to overwrite

### ralph-loop.sh
- `[ERROR] Ralph directory not found: ...` - Run ralph-init.sh first
- `[ERROR] Invalid tool: ...` - Use 'opencode' or 'claude'
- `[ERROR] Prompt file not found: ...` - Check .ralph/prompts/ directory
- `[ERROR] Conflict detected - terminating loop` - Resolve git conflicts first
- `[ERROR] ABORT: HELP NEEDED detected in TODO.md` - Fix blocked task, remove ABORT line
- `[WARNING] GLOBAL_ITERATION_LIMIT_REACHED` - Adjust RALPH_MAX_ITERATIONS
- `[WARNING] Agent sync failed ... (continuing anyway)` - Non-critical, check agents.yaml

### sync-agents.sh
- `[ERROR] yq is not installed` - Install yq
- `[ERROR] Invalid tool: ...` - Use 'opencode' or 'claude'
- `[ERROR] agents.yaml not found: ...` - Run ralph-init.sh
- `[ERROR] agents.yaml is not readable` - Check file permissions
- `[ERROR] agents.yaml contains invalid YAML syntax` - Fix YAML syntax
- `[ERROR] No agents found in agents.yaml` - Add agent definitions
- `[WARNING] No agent files found to synchronize` - Check agent search paths
- `[WARNING] No model configured for ...` - Add model in agents.yaml

### ralph-validate.sh
- `Error: Task ID cannot be empty` - Provide 4-digit task ID
- `Error: Task ID must be numeric` - Use digits only (0001-9999)
- `Error: Task ID must be 4 digits` - Pad with zeros (42 -> 0042)
- `Error: Task ID must be between 0001 and 9999` - Use valid range
- `Error: YAML file does not exist: ...` - Check file path
- `Error: Invalid YAML syntax in file: ...` - Fix YAML syntax
- `Error: File does not exist: ...` - Check file path
- `Error: Directory does not exist: ...` - Check directory path
- `Error: Current directory is not a git repository` - Run git init
- `Error: git command not found` - Install git
- `Error: Not a valid git repository` - Check .git directory

---

## Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_MAX_ITERATIONS` | 100 | Maximum loop iterations (0=unlimited) |
| `RALPH_TOOL` | opencode | Default AI tool (opencode or claude) |
| `RALPH_BACKOFF_BASE` | 2 | Base delay for exponential backoff (seconds) |
| `RALPH_BACKOFF_MAX` | 60 | Maximum backoff delay (seconds) |
| `RALPH_MANAGER_MODEL` | inherit | Override Manager model selection |
| `AGENTS_YAML` | .ralph/config/agents.yaml | Path to agents configuration |

---

## Signal Format Reference

Valid signal formats (must be first token on own line):

| Signal | Format | Example |
|--------|--------|---------|
| TASK_COMPLETE | `TASK_COMPLETE_XXXX` | `TASK_COMPLETE_0042` |
| TASK_INCOMPLETE | `TASK_INCOMPLETE_XXXX` | `TASK_INCOMPLETE_0042` |
| TASK_FAILED | `TASK_FAILED_XXXX: message` | `TASK_FAILED_0042: syntax error` |
| TASK_BLOCKED | `TASK_BLOCKED_XXXX: message` | `TASK_BLOCKED_0042: needs human input` |

Where XXXX is a 4-digit task ID (0001-9999).

---

## File Locations Reference

| File | Location | Purpose |
|------|----------|---------|
| TODO.md | .ralph/tasks/TODO.md | Task list and completion status |
| deps-tracker.yaml | .ralph/tasks/deps-tracker.yaml | Task dependency graph |
| agents.yaml | .ralph/config/agents.yaml | Agent model configuration |
| activity.md | .ralph/tasks/XXXX/activity.md | Per-task execution log |
| attempts.md | .ralph/tasks/XXXX/attempts.md | Per-task attempt history |
| TASK.md | .ralph/tasks/XXXX/TASK.md | Task requirements and criteria |
| Prompt | .ralph/prompts/ralph-prompt.md | Manager agent prompt |

---

## Version Information

- **Document Version:** 1.0.0
- **Compatible With:** Ralph Loop 1.0.0+
- **Last Updated:** 2026-02-16

---

## Getting More Help

If this guide does not resolve your issue:

1. Check the relevant SKILL.md files:
   - `/proj/jeeves/Ralph/skills/git-automation/SKILL.md`
   - `/proj/jeeves/Ralph/skills/dependency-tracking/SKILL.md`

2. Review other documentation:
   - `/proj/jeeves/docs/commands.md`
   - `/proj/jeeves/docs/configuration.md`

3. Inspect the source scripts:
   - `/proj/jeeves/bin/ralph-init.sh`
   - `/proj/jeeves/bin/ralph-loop.sh`
   - `/proj/jeeves/bin/sync-agents.sh`
   - `/proj/jeeves/bin/ralph-validate.sh`
