<!-- version: 1.1.0 | last_updated: 2026-03-26 | canonical: YES -->

# Git Commit Protocol

Agents MUST commit at defined checkpoints so progress is saved and
failed attempts can be rolled back with `git reset --hard`.

**Tooling**: Use the git-automation skill scripts at
`/proj/jeeves/Ralph/skills/git-automation/scripts/`:

| Script | Purpose |
|--------|---------|
| `git-wrapper.sh` | Safe git operations with retry and error categorization (source it, then call `git_safe`) |
| `git-commit-msg.sh` | Generates commit type from agent type + task title keywords |
| `git-context.sh` | Detects repo context (REPO_ROOT / SUBFOLDER / NO_REPO) |

## GIT-P1-01: Commit on Successful Handoff

Before emitting `TASK_COMPLETE` or `TASK_INCOMPLETE:handoff_to:*`:

```bash
SCRIPTS="/proj/jeeves/Ralph/skills/git-automation/scripts"
source "$SCRIPTS/git-wrapper.sh"

# Generate commit type from agent type + title keywords
TYPE=$("$SCRIPTS/git-commit-msg.sh" --task-id {{id}} --agent-type {{agent}} --task-title "{{title}}" | cut -d: -f1)

git add -A
git_safe commit -m "${TYPE}({{id}}): {{description}}"
```

Then emit the signal. The commit is the last action before the signal.

**If git fails**: Log the failure in activity.md but still emit the
signal. Git enhances the workflow but does not block it.

## GIT-P1-02: Reset on Incomplete Exit

On compaction prompt, `TASK_FAILED`, or `TASK_BLOCKED` — the agent did
not finish. Discard partial work, preserve only the attempt log:

```bash
SCRIPTS="/proj/jeeves/Ralph/skills/git-automation/scripts"
source "$SCRIPTS/git-wrapper.sh"

# 1. Nuke all uncommitted work (tracked and untracked)
git_safe reset --hard HEAD
git clean -fd

# 2. Write attempt summary to activity.md and attempts.md

# 3. Commit ONLY the state files
git add -- '**/activity.md' '**/attempts.md'
git_safe commit -m "chore({{id}}): log failed attempt ({{reason}})"
```

Then emit the signal.

**Why reset?** The attempt is logged in activity.md. The next agent
invocation has full context on what was tried. Partial/broken work
would just need undoing anyway.

## Commit Type Selection

Use Conventional Commits. The `git-commit-msg.sh` script auto-selects
type from agent type and title keywords. Override rules (first match):

| Title keyword | Type | Overrides agent default |
|---------------|------|------------------------|
| fix, bug, error, crash | fix | yes |
| refactor | refactor | yes |
| test | test | yes |
| doc, documentation | docs | yes |

Agent defaults (when no keyword match):

| Agent | Default type |
|-------|-------------|
| developer | feat |
| tester | test |
| architect | feat |
| writer | docs |
| researcher | docs |
| ui-designer | feat |
| (unknown) | chore |

## Message Format

`<type>(<scope>): <description>`

- **type**: from script or table above
- **scope**: 4-digit task ID (e.g., `0042`) or `ralph` for decomposer
- **description**: imperative, lowercase, no trailing period
- Append `!` after type for breaking changes: `feat!(0042): ...`

## Ordering Constraint

```
activity.md updated -> git commit -> signal emitted
```

The signal is ALWAYS the very last thing the agent outputs.
