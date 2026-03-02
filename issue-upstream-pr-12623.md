# Upstream Tracking: Doom-loop guard for repeated reasoning/output

## Type
Bug Fix / Upstream Dependency

## Upstream Reference

| Field | Value |
|-------|-------|
| **Repository** | anomalyco/opencode |
| **Issue** | [#12716](https://github.com/anomalyco/opencode/issues/12716) |
| **PR** | [#12623](https://github.com/anomalyco/opencode/pull/12623) |
| **Title** | fix: Doom-loop guard for repeated reasoning/output |
| **Author** | @Heinrich-XIAO |
| **Status** | Open (awaiting review) |
| **Branch** | `Heinrich-XIAO:dev` |
| **Target** | `anomalyco:dev` |

## Problem Statement

The doom loop detection previously only caught loops where a tool call is repeatedly called. It did not detect loops that occur during reasoning or normal output phases.

### Reproduction Steps
1. Ask an agent to think about a certain word 100 times
2. Preferably use a smaller model (2-8B parameters)
3. The agent enters a doom loop during reasoning/output without being caught

### Root Cause

The [`SessionProcessor`](https://github.com/anomalyco/opencode/blob/main/packages/opencode/src/session/processor.ts) only checked for repeated tool calls, not for repetitive patterns in:
- Reasoning/thinking text
- Normal output text

## Proposed Fix

Add snippet detection for reasoning and output content:

1. **New helper functions** in `processor.ts`:
   - `hashSnippet()` - Hash function for comparing content
   - `trimWindow()` - Keep last 1024 characters for comparison
   - `snippetMatches()` - Check if content matches a stored snippet
   - `detectRepeatSnippet()` - Detect if the same snippet appears repeatedly

2. **Track history** for reasoning and output:
   - `reasoningHistory: string[]` - Track reasoning content
   - `outputHistory: string[]` - Track output content

3. **Check for loops** when updating parts:
   - After reasoning completion, check for repeated reasoning snippets
   - After text output, check for repeated output snippets
   - Trigger `PermissionNext.ask()` with `doom_loop` permission when detected

### Files Changed

- `packages/opencode/src/session/processor.ts` - Add doom loop detection for reasoning/output
- `packages/opencode/test/session/processor.test.ts` - New test file for snippet detection

## Hot-Patch Applied in Jeeves

A temporary workaround has been applied in [`Dockerfile.jeeves`](Dockerfile.jeeves:147-155) by downloading and applying the PR patch:

```dockerfile
# Temp patches for upstream PRs
RUN curl -L https://github.com/anomalyco/opencode/pull/11812.patch -o /tmp/11812.patch \
    && curl -L https://github.com/anomalyco/opencode/pull/12623.patch -o /tmp/12623.patch \
    && git apply /tmp/11812.patch \
    && git apply /tmp/12623.patch \
    && sed -i "s/todoread: { \"*\": \"deny\" }/todoread: { \"*\": \"allow\" }/g" packages/opencode/src/tool/task.ts \
    && sed -i "s/todowrite: { \"*\": \"deny\" }/todowrite: { \"*\": \"allow\" }/g" packages/opencode/src/tool/task.ts \
    && sed -i 's/todowrite: false/todowrite: true/g' packages/opencode/src/tool/task.ts \
    && sed -i 's/todoread: false/todoread: true/g' packages/opencode/src/tool/task.ts
```

### Patch Application Notes
- Downloads PR patch from GitHub
- Applies via `git apply` during build
- Combined with other patches in the same RUN layer

## Impact on Jeeves

### Relevance
This upstream fix is important for Jeeves users who:
- Use smaller models (2-8B parameters) prone to repetitive behavior
- Experience agents getting stuck in reasoning/output loops
- Want better protection against runaway token consumption

### Without the Patch
- Agents may repeat the same reasoning endlessly
- Output loops waste tokens and time
- Users must manually interrupt stuck sessions

## Checklist

- [ ] PR #12623 merged into upstream `dev` branch
- [ ] Fix included in upstream release
- [ ] Jeeves Dockerfile updated to remove hot-patch
- [ ] Test doom loop detection in reasoning phase
- [ ] Test doom loop detection in output phase
- [ ] Update documentation if behavior changes

## Additional Context

### Discussion Highlights

- **Feb 7, 2026**: PR opened by @Heinrich-XIAO
- **Feb 7, 2026**: GitHub bot flagged for conventional commit format
- **Feb 8, 2026**: Title updated to `fix: Doom-loop guard for repeated reasoning/output`
- **Feb 8, 2026**: Issue #12716 linked ( Fixes: #12716 )

### Related Issues

- [#12716](https://github.com/anomalyco/opencode/issues/12716) - Original bug report
- Similar to doom loop detection for tool calls (already implemented)

### Key Code Changes

The patch adds approximately 97 lines to `processor.ts`:

```typescript
// New constants and helper functions
const LOOP_WINDOW = 1024
const hashSnippet = (value: string) => { ... }
const trimWindow = (value: string) => value.trim().slice(-LOOP_WINDOW)
const snippetMatches = (value: string, snippet: string, signature: number) => { ... }
export function detectRepeatSnippet(values: string[], current: string, threshold = DOOM_LOOP_THRESHOLD) { ... }

// History tracking for reasoning and output
const reasoningHistory: string[] = []
const outputHistory: string[] = []

// Loop detection in reasoning handler
const snippet = detectRepeatSnippet(reasoningHistory, part.text)
if (snippet) {
  await PermissionNext.ask({
    permission: "doom_loop",
    patterns: ["reasoning"],
    ...
  })
}

// Loop detection in output handler  
const snippet = detectRepeatSnippet(outputHistory, currentText.text)
if (snippet) {
  await PermissionNext.ask({
    permission: "doom_loop",
    patterns: ["output"],
    ...
  })
}
```

---

**Last Updated**: 2026-03-02
**Tracked by**: Jeeves Project
**Workaround Active**: Yes (hot-patch in Dockerfile.jeeves)
