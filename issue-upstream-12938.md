# Upstream Tracking: Subagents can't use 'todowrite' tool

## Type
Bug Fix / Upstream Dependency

## Upstream Reference

| Field | Value |
|-------|-------|
| **Repository** | anomalyco/opencode |
| **Issue** | [#12938](https://github.com/anomalyco/opencode/issues/12938) |
| **Title** | Subagents can't use 'todowrite' tool |
| **Author** | @jsancs |
| **Status** | Open |
| **Labels** | bug, windows |
| **Version** | 1.1.41 |

## Problem Statement

Subagents (agents with `mode: subagent`) cannot access the `todowrite` and `todoread` tools even when explicitly enabled in their agent definition file.

### Expected Behavior
When an agent is configured with:
```yaml
---
description: A Planner specialist focused on breaking down tasks into todolists.
mode: subagent
tools:
  todowrite: true
  todoread: true
permission:
  todoread: allow
  todowrite: allow
---
```

The subagent should be able to use the `todowrite` tool to create todo lists.

### Actual Behavior
Subagents report they don't have access to the `todowrite` tool:
```
I see todowrite is not listed in my available functions.
Looking at my available functions, I have:
- bash
- read
- glob
- grep
- edit
- write
- webfetch
- skill
I don't have a "todowrite" or "write_todos" tool.
```

### Root Cause

The OpenCode source code has **hardcoded permission checks** in [`packages/opencode/src/tool/task.ts`](https://github.com/anomalyco/opencode/blob/main/packages/opencode/src/tool/task.ts) that override agent-level permissions:

```typescript
// Hardcoded deny for subagents
todowrite: { "*": "deny" }
todoread: { "*": "deny" }
```

These hardcoded values take precedence over the agent's own permission configuration in their `.md` file.

## Temporary Workaround (Implemented in Jeeves)

A temporary workaround has been applied in the Jeeves [`Dockerfile.jeeves`](Dockerfile.jeeves:148-151) to flip the hardcoded `deny` to `allow`:

```dockerfile
RUN cd /app/opencode \
    && sed -i "s/todoread: { \"*\": \"deny\" }/todoread: { \"*\": \"allow\" }/g" packages/opencode/src/tool/task.ts \
    && sed -i "s/todowrite: { \"*\": \"deny\" }/todowrite: { \"*\": \"allow\" }/g" packages/opencode/src/tool/task.ts \
    && sed -i 's/todowrite: false/todowrite: true/g' packages/opencode/src/tool/task.ts
```

This workaround:
- Changes the hardcoded `deny` values to `allow`
- Also fixes the `todowrite: false` boolean variant
- Allows subagents to use todo tools regardless of their agent configuration

### Workaround Limitations
- **Security**: Subagents can now use todo tools even if not explicitly configured (less restrictive)
- **Maintenance**: Must be kept in sync with upstream code changes
- **Not upstreamable**: This is a hack, not a proper fix

## Proper Fix Required

The upstream fix should:
1. Remove or modify the hardcoded permission checks in `task.ts`
2. Respect the agent's own `tools` and `permission` configuration from their `.md` file
3. Allow subagents to use todo tools when explicitly enabled

### Files Likely Needing Changes
- `packages/opencode/src/tool/task.ts` - Remove hardcoded `deny` values
- Possibly `packages/opencode/src/agent/agent.ts` - Ensure subagent permissions are parsed correctly

## Impact on Jeeves

### Relevance
This issue directly affects Jeeves users who:
- Use the Ralph Rules System with subagents (decomposer agents)
- Expect subagents to create and manage todo lists during task decomposition
- Use agents like `decomposer-opencode.md` which rely on todo tools

### Without the Workaround
- Subagents cannot create todo lists
- Task decomposition fails or produces incomplete results
- Users must manually create todos or use the main agent instead

## Checklist

- [ ] Issue #12938 fixed in upstream
- [ ] Fix included in upstream release
- [ ] Jeeves Dockerfile updated to remove workaround
- [ ] Test subagent todo functionality in Jeeves
- [ ] Update documentation if behavior changes

## Additional Context

### Related Code Location
The hardcoded permissions are in the task tool definition:
```typescript
// packages/opencode/src/tool/task.ts (approximate location)
export const taskTools = {
  todowrite: {
    permission: { "*": "deny" }  // <-- This overrides agent config
  },
  todoread: {
    permission: { "*": "deny" }  // <-- This overrides agent config
  }
}
```

### User Reports
- **Feb 10, 2026**: Issue opened by @jsancs
- Affects multiple models: glm-4.7-flash, glm-4.5-air, qwen3-code-next
- Issue occurs on Windows 11 (may be cross-platform)

---

**Last Updated**: 2026-03-02
**Tracked by**: Jeeves Project
**Workaround Active**: Yes (in Dockerfile.jeeves)
