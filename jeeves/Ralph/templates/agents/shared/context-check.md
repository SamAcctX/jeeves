<!-- version: 3.0.0 | last_updated: 2026-03-31 | canonical: YES -->
<!-- Priority: P0 (Must-never-break) -->
<!-- Scope: Universal (all agents) -->

# Context Exhaustion Protocol

## Purpose
Defines how agents detect and respond to context window exhaustion.
Context exhaustion is detected via platform compaction, not self-monitoring.

## Rule Precedence
This file is AUTHORITATIVE for context exhaustion behavior.
On conflict with other rules: Safety > Signals > Context > Everything else.

## Detection Heuristics

**Phase 1 (compaction prompt arriving):**
The platform sends a message containing "Do not call any tools" and requesting a
summary with `## Goal`, `## Instructions`, `## Discoveries`, `## Accomplished`,
`## Relevant files` sections. Tools are disabled for this turn.

**Phase 2 (post-compaction resume):**
Your context begins with a compacted summary (has `## Goal` / `## Accomplished`
headings) followed by a platform-injected message: "Continue if you have next steps,
or stop and ask for clarification if you are unsure how to proceed."

---

## CTX-P0-01: Compaction Exit Protocol [CRITICAL]

<rule id="CTX-P0-01" priority="P0" scope="universal" trigger="on-compaction">

When the platform injects a compaction/summarization prompt — a system
message directing you to recap, summarize, or consolidate your progress
— your context window is nearly full.

**Tool calls are FORBIDDEN during compaction.** You cannot write files,
update activity.md, or emit signals. Your summary text is the ONLY
bridge to your next turn.

### Phase 1: Compaction Turn (no tools available)
1. **STOP** current work — do not attempt new operations
2. **PRODUCE** the summary using the platform's template, embedding recovery state:

| Platform Section | Must Include |
|-----------------|-------------|
| **Instructions** | Task ID, state machine position, current attempt number |
| **Discoveries** | Gotchas, blockers, dependencies discovered this session |
| **Accomplished** | Work completed (file paths + outcomes), work failed (errors), specific next steps remaining. **Final line MUST be**: "Next: Execute Phase 2 of CTX-P0-01 — write activity.md and emit TASK_INCOMPLETE signal." |
| **Relevant files** | activity.md path, TASK.md path, all files modified or created this session |

### Phase 2: Post-Compaction Turn (tools available)
After compaction, the platform injects "Continue if you have next steps..."
and your tools are restored. You are NOT resuming work — you are persisting
state and exiting.

1. **DETECT**: If your context begins with a compacted summary (## Goal / ## Accomplished sections), you were just compacted
2. **WRITE** activity.md: Transfer the Accomplished/Discoveries/Remaining info from your summary into a proper activity.md entry using the template below
3. **EMIT**: `TASK_INCOMPLETE_XXXX:context_limit_exceeded`
4. **STOP** — no further work. The manager will re-invoke as needed.

### Activity.md Entry Template (for Phase 2):
```
## Attempt [N] — Context Limit Reached

### State: [current state machine position]
### Completed:
- [specific item completed with file path and outcome]

### Failed:
- [what was attempted]: [error message or failure reason]

### Remaining:
- [specific next step 1]
- [specific next step 2]

### Files Modified:
- [file path]: [what was changed]

### Context for Next Agent:
- [critical information the next agent must know]
```

### Best-Effort Pre-Compaction Logging:
Activity.md should be updated **during normal work** (after each significant
milestone), not only at compaction time. This ensures recovery state exists
even if Phase 2 fails to execute.

### What NOT To Do:
- Do NOT attempt tool calls during Phase 1 (the platform forbids them)
- Do NOT continue working in Phase 2 — only persist state and emit signal
- Do NOT produce a vague summary — include specific file paths, error messages, and next steps

</rule>

---

## CTX-CP-01: Compliance Checkpoint

<checkpoint id="CTX-CP-01" trigger="on-compaction">
Phase 1 (compaction turn):
- [ ] Recognized compaction prompt — stopped current work
- [ ] Summary includes task ID, state, completed/failed/remaining work
- [ ] Summary includes file paths for all modified files
- [ ] No tool calls attempted during compaction response

Phase 2 (post-compaction turn):
- [ ] Detected compacted summary in context
- [ ] Wrote activity.md entry with recovery state
- [ ] Emitted TASK_INCOMPLETE_XXXX:context_limit_exceeded
- [ ] Stopped — no further work attempted
</checkpoint>

---

## Related Rules
- SIG-P0-01: Signal format (signals.md) — TASK_INCOMPLETE signal format
- ACT-P1-12: Activity.md format (activity-format.md) — entry structure
- HOF-P0-01: Handoff limit (handoff.md) — handoff count persists across context limits
