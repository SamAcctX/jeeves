# Bug: Path Mismatch Between Decomposer-Created TODO.md and Manager-Expected Location

## Type
Bug / Path Inconsistency

## Problem Statement

There's a path inconsistency in the Ralph Loop system where different components expect/create `TODO.md` in different locations:

### Current Behavior (Inconsistent)

| Component | Expected/Creates Path | Status |
|-----------|----------------------|--------|
| `ralph-init.sh` line 111 | `.ralph/TODO.md` (root) | **WRONG** |
| `state-file-conflicts.sh` line 17 | `.ralph/TODO.md` (root) | **WRONG** |
| `ralph-loop.sh` line 167 | `.ralph/tasks/TODO.md` | **Correct** |
| `ralph-loop.sh` line 211 | `.ralph/tasks/TODO.md` | **Correct** |
| `deps-select.sh` | `.ralph/tasks/TODO.md` | **Correct** |
| Documentation | `.ralph/tasks/TODO.md` | **Correct** |

### Error Manifestation

```
Error: File not found: /proj/.ralph/tasks/TODO.md
✱ Glob "**/.ralph/**/*.yaml" 2 matches
✱ Glob "**/TODO.md" 1 match
→ Read .ralph/TODO.md
```

The decomposer (via `ralph-init.sh`) creates TODO.md at `.ralph/TODO.md`, but the manager agents (via `ralph-loop.sh`) look for it at `.ralph/tasks/TODO.md`.

## Root Cause Analysis

### File: `jeeves/bin/ralph-init.sh` (line 111)

```bash
local config_templates=(
    "config/agents.yaml.template:config/agents.yaml"
    "config/TODO.md.template:TODO.md"  # <-- WRONG: should be "tasks/TODO.md"
    "config/deps-tracker.yaml.template:config/deps-tracker.yaml"
)
```

This copies `TODO.md.template` to `.ralph/TODO.md` instead of `.ralph/tasks/TODO.md`.

### File: `jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh` (lines 16-17)

```bash
readonly STATE_FILES=(
    "/proj/.ralph/TODO.md"      # <-- WRONG: should be "/proj/.ralph/tasks/TODO.md"
    "/proj/.ralph/deps-tracker.yaml"
)
```

Note: `deps-tracker.yaml` is correctly in `.ralph/` root (per documentation), but `TODO.md` should be in `tasks/`.

## Canonical Location

Per the Ralph architecture documentation and the majority of code references:

**The canonical location for TODO.md is:**
```
.ralph/tasks/TODO.md
```

This is because:
1. TODO.md is task-related state (belongs in `tasks/` subdirectory)
2. `ralph-loop.sh` (the main orchestrator) expects it there
3. `deps-select.sh` and dependency tracking expect it there
4. Agent templates (manager-*.md) reference it there
5. Documentation consistently shows `.ralph/tasks/TODO.md`

## Proposed Fix

### Option A: Fix Init and State-Conflict Scripts (Recommended)

Update the two files that use the wrong path to use the correct path:

1. **`jeeves/bin/ralph-init.sh`** line 111:
   ```bash
   "config/TODO.md.template:tasks/TODO.md"  # Change from "TODO.md"
   ```

2. **`jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh`** line 17:
   ```bash
   "/proj/.ralph/tasks/TODO.md"  # Change from "/proj/.ralph/TODO.md"
   ```

And line 184:
   ```bash
   echo "  4. Mark resolved: git add .ralph/tasks/TODO.md .ralph/deps-tracker.yaml"
   ```

**Pros:**
- Aligns with documented architecture
- Matches what ralph-loop.sh expects
- Minimal changes (2 files, 3 lines)
- No changes needed to agent templates or documentation

**Cons:**
- Existing projects with TODO.md at root need to move file (migration path needed)

### Option B: Fix Loop and Manager Scripts

Change all the manager/loop scripts to look in `.ralph/TODO.md` instead of `.ralph/tasks/TODO.md`.

**Pros:**
- TODO.md is somewhat "config-like" (could argue it belongs in root)

**Cons:**
- Requires changing many more files (ralph-loop.sh, deps-select.sh, all manager agent templates)
- Breaks with documented directory structure
- Tasks are logically grouped in `tasks/` directory

### Option C: Support Both Paths with Fallback

Make the scripts check both locations with a fallback mechanism.

**Pros:**
- Backward compatible
- No migration needed

**Cons:**
- Adds complexity
- Ambiguity about "correct" location
- Harder to maintain

## Recommended Solution: Option A

Fix the two files that have incorrect paths. This aligns with:
- The documented directory structure
- The majority of the codebase
- Logical organization (task files in `tasks/`)

### Implementation

**Files to modify:**

1. [`jeeves/bin/ralph-init.sh`](jeeves/bin/ralph-init.sh:111) - Line 111
   ```bash
   # Change:
   "config/TODO.md.template:TODO.md"
   # To:
   "config/TODO.md.template:tasks/TODO.md"
   ```

2. [`jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh`](jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh:17) - Line 17
   ```bash
   # Change:
   "/proj/.ralph/TODO.md"
   # To:
   "/proj/.ralph/tasks/TODO.md"
   ```

3. [`jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh`](jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh:184) - Line 184
   ```bash
   # Change:
   echo "  4. Mark resolved: git add .ralph/TODO.md .ralph/deps-tracker.yaml"
   # To:
   echo "  4. Mark resolved: git add .ralph/tasks/TODO.md .ralph/deps-tracker.yaml"
   ```

4. [`jeeves/Ralph/skills/git-automation/SKILL.md`](jeeves/Ralph/skills/git-automation/SKILL.md:229) - Line 229 (if applicable)

5. [`jeeves/Ralph/skills/git-automation/README.md`](jeeves/Ralph/skills/git-automation/README.md:108) - Line 108

### Migration Path for Existing Projects

Projects that already have TODO.md at `.ralph/TODO.md` will need to:

```bash
# Move the file to correct location
mv .ralph/TODO.md .ralph/tasks/TODO.md

# Update git tracking (if applicable)
git rm --cached .ralph/TODO.md
git add .ralph/tasks/TODO.md
```

Or provide a migration script:
```bash
#!/bin/bash
# migrate-todo-location.sh
if [ -f ".ralph/TODO.md" ] && [ ! -f ".ralph/tasks/TODO.md" ]; then
    mv .ralph/TODO.md .ralph/tasks/TODO.md
    echo "Migrated TODO.md to .ralph/tasks/TODO.md"
fi
```

## Verification Checklist

- [ ] `ralph-init.sh` creates TODO.md in `.ralph/tasks/TODO.md`
- [ ] `ralph-loop.sh` finds TODO.md at `.ralph/tasks/TODO.md`
- [ ] `state-file-conflicts.sh` checks `.ralph/tasks/TODO.md`
- [ ] Manager agents can read TODO.md successfully
- [ ] Decomposer creates TODO.md in correct location
- [ ] Dependency tracking scripts work correctly

## Related Files Reference

**Expect `.ralph/tasks/TODO.md` (Correct):**
- [`jeeves/bin/ralph-loop.sh`](jeeves/bin/ralph-loop.sh:167) - Critical files list
- [`jeeves/bin/ralph-loop.sh`](jeeves/bin/ralph-loop.sh:211) - should_terminate function
- [`jeeves/bin/ralph-loop.sh`](jeeves/bin/ralph-loop.sh:378) - parse_todo_md function
- [`jeeves/Ralph/skills/dependency-tracking/scripts/deps-select.sh`](jeeves/Ralph/skills/dependency-tracking/scripts/deps-select.sh:40) - Default TODO file path
- [`jeeves/Ralph/templates/agents/manager-*.md`](jeeves/Ralph/templates/agents/manager-claude.md:478) - All manager agent templates
- [`jeeves/Ralph/docs/directory-structure.md`](jeeves/Ralph/docs/directory-structure.md:18) - Documentation
- [`jeeves/Ralph/README-Ralph.md`](jeeves/Ralph/README-Ralph.md:211) - Documentation

**Use `.ralph/TODO.md` (Incorrect - needs fix):**
- [`jeeves/bin/ralph-init.sh`](jeeves/bin/ralph-init.sh:111) - Template copy destination
- [`jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh`](jeeves/Ralph/skills/git-automation/scripts/state-file-conflicts.sh:17) - State files list
- [`jeeves/Ralph/skills/git-automation/SKILL.md`](jeeves/Ralph/skills/git-automation/SKILL.md:229) - Documentation
- [`jeeves/Ralph/skills/git-automation/README.md`](jeeves/Ralph/skills/git-automation/README.md:108) - Documentation

## Effort Estimate

- **Scope:** 3 files, ~5 lines changed
- **Estimated Time:** 30 minutes
- **Risk:** Low (path fix, no logic changes)
- **Testing:** Verify Ralph loop starts correctly with new initialization

## Additional Context

The error message shows the glob finding TODO.md at root level:
```
✱ Glob "**/TODO.md" 1 match
→ Read .ralph/TODO.md
```

This confirms the file is being created in the wrong location by `ralph-init.sh`, and then the manager agents (which use stricter path) cannot find it at `.ralph/tasks/TODO.md`.

---

**Last Updated**: 2026-03-02
**Status**: Ready for implementation
