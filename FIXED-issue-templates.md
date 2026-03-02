# Stop copying template files to workspace `.ralph/` directory

## Type
Enhancement / UX Improvement

## Problem/Use Case

`ralph-init.sh` currently copies template files from `/opt/jeeves/Ralph/templates/` into the project's `.ralph/` directory. While functional, this creates user confusion about:

1. **Which files should be edited**: Users see template-derived files (e.g., `TODO.md`, `TASK.md`, `activity.md`) in their workspace and may edit them, not realizing these are meant to be generated/copied per-task
2. **Source of truth confusion**: Templates exist in two places—source (`/opt/jeeves/Ralph/templates/`) and workspace (`.ralph/`), creating ambiguity about which to modify
3. **File proliferation**: The workspace gets populated with starter files that may not be needed immediately, cluttering the project structure

### Current Behavior
`ralph-init.sh` copies the following templates during initialization:

**Config templates** → `.ralph/`:
- `config/TODO.md.template` → `.ralph/TODO.md`
- `config/agents.yaml.template` → `.ralph/config/agents.yaml`
- `config/deps-tracker.yaml.template` → `.ralph/config/deps-tracker.yaml`

**Task templates** → `.ralph/`:
- `task/TASK.md.template` → `.ralph/TASK.md`
- `task/activity.md.template` → `.ralph/activity.md`
- `task/attempts.md.template` → `.ralph/attempts.md`

**Prompt templates** → `.ralph/`:
- `prompts/ralph-prompt.md.template` → `.ralph/prompts/ralph-prompt.md`

### User Impact
- Users see `TODO.md`, `TASK.md`, etc. in `.ralph/` and may start editing them manually
- Task decomposition should create these files per-task (e.g., `.ralph/tasks/0001/TASK.md`), not at the root
- Creates confusion about workflow: "Should I edit `.ralph/TODO.md` or wait for the system to generate task-specific files?"

## Proposed Solution

Stop copying template files to the workspace `.ralph/` directory during initialization. Instead:

1. **Keep templates in source location**: `/opt/jeeves/Ralph/templates/`
2. **Generate files on-demand**: Task decomposition and Ralph loop should create files as needed in appropriate locations (e.g., `.ralph/tasks/{id}/`)
3. **Keep only runtime state in `.ralph/`**: Config files that users edit (like `agents.yaml`) can remain, but task/prompt templates should not be copied as starter files

### Files to Stop Copying

**Phase 1: Task templates** (highest priority - most confusing)
- [ ] `task/TASK.md.template` → Stop copying to `.ralph/TASK.md`
- [ ] `task/activity.md.template` → Stop copying to `.ralph/activity.md`
- [ ] `task/attempts.md.template` → Stop copying to `.ralph/attempts.md`

**Phase 2: Prompt templates** (if not user-editable)
- [ ] `prompts/ralph-prompt.md.template` → Stop copying to `.ralph/prompts/ralph-prompt.md`

**Phase 3: Consider for config** (may need to keep)
- [ ] `config/TODO.md.template` → Evaluate if this should be generated vs. copied
- [ ] `config/agents.yaml.template` → Keep (users edit this)
- [ ] `config/deps-tracker.yaml.template` → Keep (users edit this)

## Implementation Plan

### Option A: Stop copying entirely (Recommended)
Remove the copy operations for task templates entirely.

**Files to modify:**
- [ ] `jeeves/bin/ralph-init.sh`
  - Remove or comment out `copy_task_templates()` call (line 485)
  - Remove `copy_prompt_template()` call (line 494)
  - Update `copy_templates()` function to exclude task/prompt templates

**Code changes:**
```bash
# In copy_templates() function (lines 465-504):
# CURRENT:
task_count=$(copy_task_templates)
total_copied=$((total_copied + task_count))
...
prompt_count=$(copy_prompt_template)
total_copied=$((total_copied + prompt_count))

# NEW:
# Remove task and prompt template copying
# Keep: config_count, agent_count, skills_count
```

### Option B: Copy only when explicitly requested
Add flags like `--with-task-templates` or `--with-prompts` for users who want them.

**Pros**: Backward compatible, opt-in behavior
**Cons**: More complexity, likely unnecessary

### Option C: Copy to `.ralph/templates/` (not root)
Keep templates organized separately from runtime files.

**Pros**: Templates available for reference, organized location
**Cons**: Still duplicates source files, doesn't solve confusion

## Recommended Approach: Option A

Stop copying task and prompt templates entirely. The Ralph system should:
1. Reference templates from source (`/opt/jeeves/Ralph/templates/`)
2. Generate task-specific files in `.ralph/tasks/{id}/` when decomposing
3. Keep workspace `.ralph/` clean with only:
   - `config/` (user-editable configuration)
   - `tasks/` (runtime task directories)
   - `specs/` (PRD/spec files)
   - `prompts/` (only if user-created)

## Migration Strategy (Non-Breaking)

Since this is a UX improvement (not a bug fix):

1. **Phase 1**: Stop copying task templates
   - Existing projects keep their `.ralph/TASK.md`, etc.
   - New projects don't get these files
   - No functional impact

2. **Phase 2**: Stop copying prompt templates
   - Same approach as Phase 1

3. **Phase 3** (Optional): Clean up documentation
   - Update docs that reference starter files
   - Clarify that templates are source-only

## Documentation Updates

Files mentioning copied templates:
- [ ] `jeeves/Ralph/templates/README.md` (lines 103-114 describe template copying)
- [ ] `jeeves/Ralph/README-Ralph.md` (lines 208-213 mention initialization)
- [ ] `docs/how-to-guide.md` (task template references)
- [ ] `docs/configuration.md` (TODO.md references)

## Testing Checklist

- [ ] `ralph-init.sh` no longer copies task templates
- [ ] `ralph-init.sh` no longer copies prompt templates
- [ ] Ralph loop still works (references source templates)
- [ ] Task decomposition creates files in correct locations
- [ ] Existing projects continue working (no cleanup required)

## Alternatives Considered

### Alternative 1: Keep current behavior
- **Pros**: No changes needed
- **Cons**: Continues user confusion, cluttered workspace

### Alternative 2: Rename copied files with `.template` extension
- **Pros**: Makes it clear they're templates
- **Cons**: Still duplicates source, doesn't solve root problem

### Alternative 3: Add header comments to copied files
- **Pros**: Warns users not to edit
- **Cons**: Cluttered workspace, ignored warnings

**Selected**: Stop copying (Option A) - cleanest solution, no duplication

## Additional Context

### Current Directory Structure After Init
```
.ralph/
├── config/
│   ├── agents.yaml          # User-editable (keep)
│   └── deps-tracker.yaml    # User-editable (keep)
├── prompts/
│   └── ralph-prompt.md      # Copied template (confusing - stop)
├── tasks/                   # Runtime (keep)
│   └── done/
├── specs/                   # Runtime (keep)
├── TODO.md                  # Copied template (confusing - stop)
├── TASK.md                  # Copied template (confusing - stop)
├── activity.md              # Copied template (confusing - stop)
└── attempts.md              # Copied template (confusing - stop)
```

### Proposed Directory Structure After Init
```
.ralph/
├── config/
│   ├── agents.yaml          # User-editable (keep)
│   └── deps-tracker.yaml    # User-editable (keep)
├── tasks/                   # Runtime (keep)
│   └── done/
└── specs/                   # Runtime (keep)
# No copied templates at root - cleaner!
```

### Effort Estimate
- **Scope**: 1 shell script (`ralph-init.sh`) + documentation updates
- **Estimated Time**: 30-60 minutes
- **Risk**: Very low (non-breaking, no existing functionality depends on copied templates)

## Related Issues

- May relate to shared files refactoring (move from `.opencode/agents/shared/` to `.ralph/protocols/`)
- Both issues aim to reduce user confusion about file locations

## Checklist

- [x] I've searched for similar issues
- [x] This change improves UX without breaking functionality
- [x] Existing projects continue working without modification
- [x] Templates remain available in source location (`/opt/jeeves/Ralph/templates/`)
