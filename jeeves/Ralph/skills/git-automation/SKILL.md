---
name: git-automation
description: Git commit protocol for the Ralph Loop. Commit on successful handoff, reset on failure.
license: MIT
metadata:
  version: "2.0.0"
  author: Ralph Loop Team
---

# Git Automation Skill

## When to Load

Load this skill (`skill git-automation`) at the start of every Ralph
Loop agent session, alongside `using-superpowers` and
`system-prompt-compliance`.

## Protocol Summary

Agents commit at handoff boundaries so progress is saved and failed
attempts can be rolled back with `git reset --hard`.

| Outcome | Action | Rule |
|---------|--------|------|
| Successful handoff (TASK_COMPLETE, handoff_to:*) | Commit all work, then emit signal | GIT-P1-01 |
| Incomplete exit (compaction, TASK_FAILED, TASK_BLOCKED) | Reset, log attempt, commit logs, then emit signal | GIT-P1-02 |

## GIT-P1-01: Commit on Successful Handoff

Before emitting `TASK_COMPLETE` or `TASK_INCOMPLETE:handoff_to:*`:

```bash
SCRIPTS="/proj/jeeves/Ralph/skills/git-automation/scripts"

# Generate commit message (--scope adds task ID)
MSG=$("$SCRIPTS/git-commit-msg.sh" \
    --task-id {{id}} \
    --agent-type {{agent}} \
    --scope {{id}} \
    --task-title "{{title}}")

git add -A
git commit -m "$MSG"
```

Then emit the signal. The commit is the last action before the signal.

**If git fails**: Log the failure in activity.md but still emit the
signal. Git enhances the workflow but does not block it.

## GIT-P1-02: Reset on Incomplete Exit

On compaction prompt, `TASK_FAILED`, or `TASK_BLOCKED`:

```bash
# 1. Discard all uncommitted work
git reset --hard HEAD
git clean -fd

# 2. Write attempt summary to activity.md and attempts.md

# 3. Commit ONLY the state files
git add -- '**/activity.md' '**/attempts.md'
git commit -m "chore({{id}}): log failed attempt ({{reason}})"
```

Then emit the signal.

**Why reset?** The attempt is already logged in activity.md. The next
agent has full context on what was tried. Partial work would just need
undoing anyway.

## Decomposer Variant

The decomposer creates many files over a long session. Commit
incrementally so completed specs survive compaction:

```bash
# After each task folder passes Gate 1 review:
git add .ralph/tasks/{{id}}/
git commit -m "chore(ralph): add task {{id}} spec"

# After TODO.md and deps-tracker.yaml finalized:
git add -A
git commit -m "chore(ralph): decompose PRD into N tasks"
```

On compaction: follow GIT-P1-02. Already-committed task folders survive.

## Commit Message Generation

The `git-commit-msg.sh` script generates conventional commit messages:

```bash
SCRIPTS="/proj/jeeves/Ralph/skills/git-automation/scripts"

"$SCRIPTS/git-commit-msg.sh" --task-id 0042 --agent-type developer --scope 0042 --task-title "Implement user auth"
# Output: feat(0042): implement user auth

"$SCRIPTS/git-commit-msg.sh" --task-id 0042 --agent-type tester --scope 0042 --task-title "Add auth tests"
# Output: test(0042): add auth tests

"$SCRIPTS/git-commit-msg.sh" --task-id 0042 --agent-type developer --scope 0042 --task-title "Fix login crash"
# Output: fix(0042): fix login crash
```

### Type Selection (first keyword match wins)

| Title keyword | Type |
|---------------|------|
| fix, bug, error, crash | fix |
| refactor | refactor |
| test | test |
| doc, documentation | docs |

### Agent Defaults (when no keyword match)

| Agent | Type |
|-------|------|
| developer | feat |
| tester | test |
| architect | feat |
| writer | docs |
| researcher | docs |
| ui-designer | feat |
| decomposer | chore |

### Message Format

`<type>(<scope>): <description>`

- **scope**: 4-digit task ID or `ralph` for decomposer
- **description**: imperative, lowercase, no trailing period
- Add `--breaking` flag for breaking changes: `feat!(0042): ...`

## Safe Git Operations

The `git-wrapper.sh` script provides safe git with retry and error
categorization. Source it to use `git_safe` instead of raw `git`:

```bash
source /proj/jeeves/Ralph/skills/git-automation/scripts/git-wrapper.sh
git_safe commit -m "feat(0042): implement user auth"
git_safe reset --hard HEAD
```

Error categories:
- **TRANSIENT** (network): 3x retry with backoff
- **NON-CRITICAL** (nothing to commit): returns success
- **USER_ERROR** (auth): emits TASK_BLOCKED
- **CRITICAL** (corruption): emits TASK_BLOCKED

## Ordering Constraint

```
activity.md updated -> git commit -> signal emitted
```

The signal is ALWAYS the very last thing the agent outputs.

---

## Future: Branch-Per-Task Workflow

The following scripts support an optional branch-per-task workflow
that is **not currently active** in the Ralph Loop. They are preserved
for future use:

| Script | Purpose |
|--------|---------|
| `git-context.sh` | Detect repo context (REPO_ROOT / SUBFOLDER / NO_REPO) |
| `task-branch-create.sh` | Create `task-XXXX` branch from primary |
| `squash-merge.sh` | Squash merge task branch into primary |
| `branch-cleanup.sh` | Delete merged task branches |
| `git-conflict.sh` | Detect merge conflicts in working directory |
| `state-file-conflicts.sh` | Detect conflicts in Ralph state files |
| `configure-gitignore.sh` | Add Ralph entries to .gitignore |
