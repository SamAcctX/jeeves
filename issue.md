# Refactor: Move shared agent rule files from `.opencode/agents/shared/` to `.ralph/protocols/`

## Type
Enhancement / Technical Debt

## Problem/Use Case

The 10 shared rule files (activity-format.md, signals.md, secrets.md, context-check.md, handoff.md, tdd-phases.md, loop-detection.md, dependency.md, rules-lookup.md, quick-reference.md) are currently copied to `.opencode/agents/shared/` and `.claude/agents/shared/` during project initialization.

OpenCode's agent discovery mechanism auto-detects all `.md` files in `.opencode/agents/` as agent definitions. This causes the shared rule files to appear **in addition to** the actual role-based agents (developer, tester, architect, etc.) in the agent selection interface. This creates user confusion—these are **protocol/reference documents** meant to be linked by agents, not agents themselves.

### Current Behavior
- Shared rule files appear as selectable "agents" in OpenCode
- Users see 10+ extra "agents" (activity-format, signals, secrets, etc.) alongside real agents
- Functionally works (agents can reference files), but UI is cluttered and conceptually confusing

### Desired Behavior
- Agent list shows only actual role-based agents (developer, tester, architect, manager, etc.)
- Shared rule files are accessible as reference documents but not listed as agents
- Cleaner mental model: protocols live with Ralph config, agent definitions are separate

## Proposed Solution

Move shared rule files from:
- **Current**: `.opencode/agents/shared/` and `.claude/agents/shared/`
- **New**: `.ralph/protocols/`

### Rationale
1. **Outside discovery paths**: Neither OpenCode nor Claude auto-detect files in `.ralph/protocols/` as agents
2. **Platform-agnostic**: Rules apply to both platforms, so they belong in the Ralph-agnostic location
3. **Semantic clarity**: "Protocols" accurately describes behavioral rules, not agent definitions
4. **Single source**: One copy serves both platforms (no duplication)

## Implementation Plan

### Files to Modify

#### 1. Shell Scripts (3 files)
- [ ] `jeeves/bin/ralph-init.sh` (lines 234-267)
  - Change `mkdir -p ".opencode/agents/shared"` and `mkdir -p ".claude/agents/shared"` to `mkdir -p ".ralph/protocols"`
  - Update copy destinations from `.opencode/agents/shared/$file` to `.ralph/protocols/$file`
  - Add optional cleanup for old shared directories

- [ ] `jeeves/bin/sync-agents.sh` (lines 19-25)
  - Add `.ralph/protocols` to `AGENT_SEARCH_PATHS` if agents need to discover them

#### 2. Agent Templates (16 files)
All agent templates contain markdown links to shared files:
- [ ] `jeeves/Ralph/templates/agents/writer-opencode.md` (9 shared references)
- [ ] `jeeves/Ralph/templates/agents/writer-claude.md` (9 shared references)
- [ ] `jeeves/Ralph/templates/agents/decomposer-opencode.md` (9 shared references)
- [ ] `jeeves/Ralph/templates/agents/decomposer-claude.md` (9 shared references)
- [ ] `jeeves/Ralph/templates/agents/decomposer-architect-opencode.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/decomposer-architect-claude.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/decomposer-researcher-opencode.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/decomposer-researcher-claude.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/tester-opencode.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/tester-claude.md` (frontmatter dependencies)
- [ ] `jeeves/Ralph/templates/agents/developer-opencode.md` (shared rule references)
- [ ] `jeeves/Ralph/templates/agents/developer-claude.md` (shared rule references)
- [ ] `jeeves/Ralph/templates/agents/ui-designer-opencode.md` (shared rule references)
- [ ] `jeeves/Ralph/templates/agents/ui-designer-claude.md` (shared rule references)
- [ ] `jeeves/Ralph/templates/agents/researcher-opencode.md` (shared rule references)
- [ ] `jeeves/Ralph/templates/agents/researcher-claude.md` (shared rule references)

**Link updates required:**
```markdown
# CURRENT:
| [signals.md](shared/signals.md) | SIG-P0-01...

# NEW:
| [signals.md](../../.ralph/protocols/signals.md) | SIG-P0-01...
```

#### 3. Shared Files Themselves (10 files)
- [ ] `jeeves/Ralph/templates/agents/shared/activity-format.md`
- [ ] `jeeves/Ralph/templates/agents/shared/signals.md`
- [ ] `jeeves/Ralph/templates/agents/shared/secrets.md`
- [ ] `jeeves/Ralph/templates/agents/shared/context-check.md`
- [ ] `jeeves/Ralph/templates/agents/shared/handoff.md`
- [ ] `jeeves/Ralph/templates/agents/shared/tdd-phases.md`
- [ ] `jeeves/Ralph/templates/agents/shared/loop-detection.md`
- [ ] `jeeves/Ralph/templates/agents/shared/dependency.md`
- [ ] `jeeves/Ralph/templates/agents/shared/rules-lookup.md`
- [ ] `jeeves/Ralph/templates/agents/shared/quick-reference.md`

**Updates needed:**
- Update `Location:` metadata header to reflect new path
- Optionally move source files to `jeeves/Ralph/templates/protocols/`

#### 4. Documentation (8+ files)
- [ ] `CONTRIBUTING.md` (line 153)
- [ ] `jeeves/AGENTS.md` (lines 20, 33)
- [ ] `jeeves/Ralph/templates/README.md` (lines 44-59, 109-111, 129)
- [ ] `jeeves/Ralph/README-Ralph.md` (line 212)
- [ ] `jeeves/Ralph/docs/directory-structure.md` (line 93)
- [ ] `docs/configuration.md` (lines 306-310)
- [ ] `docs/troubleshooting.md` (lines 101, 156)
- [ ] `docs/how-to-guide.md` (lines 202-204)
- [ ] `docs/commands.md` (line 236)

### Migration Strategy (Non-Breaking)

Since this is a UI/UX cleanup (not a functional fix):

1. **Phase 1**: Update `ralph-init.sh` to copy files to `.ralph/protocols/`
2. **Phase 2**: Update all agent template references to use new relative paths
3. **Phase 3**: Update shared file headers and documentation
4. **Phase 4** (Optional): Users can manually delete old `.opencode/agents/shared/` directories—existing projects continue to work

### Testing Checklist

- [ ] `ralph-init.sh` copies shared files to `.ralph/protocols/`
- [ ] Agent templates render correct relative links
- [ ] OpenCode agent list shows only role-based agents (no shared files)
- [ ] Agents can still reference shared files via markdown links
- [ ] Documentation references are accurate

## Alternatives Considered

### Option 1: Keep Current Structure
- **Pros**: No changes needed
- **Cons**: Continued UI confusion; shared files appear as agents

### Option 2: Move to `.opencode/protocols/` (platform-split)
- **Pros**: Keeps OpenCode-specific files in .opencode
- **Cons**: Creates asymmetry between platforms; less clean conceptually

### Option 3: Rename shared files to non-.md extension
- **Pros**: Prevents agent discovery
- **Cons**: Breaks markdown rendering; hacky solution

**Selected**: `.ralph/protocols/` - Cleanest conceptual model, platform-agnostic, single source of truth

## Additional Context

### Current File Structure
```
.opencode/agents/
├── developer.md          # Actual agent
├── tester.md             # Actual agent
├── shared/               # PROBLEM: Treated as agents
│   ├── activity-format.md
│   ├── signals.md
│   ├── secrets.md
│   └── ... (7 more files)
```

### Proposed Structure
```
.opencode/agents/
├── developer.md          # Actual agent
├── tester.md             # Actual agent
└── (no shared/ directory)

.ralph/protocols/         # NEW: Platform-agnostic protocols
├── activity-format.md
├── signals.md
├── secrets.md
└── ... (7 more files)
```

### Effort Estimate
- **Scope**: ~30 files across shell scripts, markdown templates, and documentation
- **Estimated Time**: 2-3 hours focused work
- **Risk**: Low (non-breaking change)

## Checklist

- [x] I've searched for similar issues
- [x] This refactoring aligns with the project's architecture goals
- [x] This is a non-breaking change (existing projects continue to work)
