<!-- version: 2.0.0 | last_updated: 2026-03-17 | canonical: YES -->
<!-- Priority: P0 (Must-never-break) -->
<!-- Scope: Universal (all agents) -->

# Context Exhaustion Protocol

## Purpose
Defines how agents detect and respond to context window exhaustion.
Context exhaustion is detected via platform compaction, not self-monitoring.

## Rule Precedence
This file is AUTHORITATIVE for context exhaustion behavior.
On conflict with other rules: Safety > Signals > Context > Everything else.

---

## CTX-P0-01: Compaction Exit Protocol [CRITICAL]

<rule id="CTX-P0-01" priority="P0" scope="universal" trigger="on-compaction">

When the platform injects a compaction/summarization prompt — a system
message directing you to recap, summarize, or consolidate your progress
— your context window is nearly full.

**Do NOT summarize and continue. This is your EXIT signal.**

### Required Actions (in this order):
1. **STOP** current work immediately — do not start new tool calls
2. **LOG** a detailed activity.md entry:
   - Current attempt number and state machine position
   - Work completed successfully (with file paths and specific outcomes)
   - Work attempted but failed (with error messages and diagnostics)
   - Work remaining (specific actionable next steps, not vague summaries)
   - Files modified or created in this session
   - Critical context the resuming agent needs to know
   - Any blockers or dependencies discovered during this session
3. **EMIT** signal: `TASK_INCOMPLETE_XXXX:context_limit_exceeded`
4. **STOP** — make NO further tool calls after signal emission

### What NOT To Do:
- Do NOT attempt to summarize and keep working
- Do NOT start new implementation work after compaction
- Do NOT skip the activity.md entry
- Do NOT emit any signal other than TASK_INCOMPLETE

### Activity.md Entry Template:
```
## Attempt [N] — Context Limit Reached

### State: [current state machine position]
### Completed:
- [specific item completed with file path and outcome]
- [specific item completed]

### Failed:
- [what was attempted]: [error message or failure reason]

### Remaining:
- [specific next step 1]
- [specific next step 2]

### Files Modified:
- [file path]: [what was changed]

### Context for Next Agent:
- [critical information the next agent must know]
- [any gotchas or pitfalls discovered]
```

</rule>

---

## CTX-P1-02: Context Resumption Protocol

<rule id="CTX-P1-02" priority="P1" scope="universal" trigger="start-of-turn">

When resuming a task after a context limit was hit:

1. **READ** the previous agent's activity.md checkpoint FIRST
2. **REVIEW** files listed as in-progress or modified
3. **VERIFY** current state matches the checkpoint
4. **CONTINUE** from the "Remaining" / "Next Steps" section
5. **DO NOT** re-read full task history or redo completed work

</rule>

---

## CTX-CP-01: Compliance Checkpoint

<checkpoint id="CTX-CP-01" trigger="on-compaction">
- [ ] CTX-P0-01: Recognized compaction prompt as EXIT signal
- [ ] CTX-P0-01: Stopped current work (no new tool calls)
- [ ] CTX-P0-01: Wrote detailed activity.md entry
- [ ] CTX-P0-01: Emitted TASK_INCOMPLETE_XXXX:context_limit_exceeded
- [ ] CTX-P0-01: Made NO further tool calls after signal
</checkpoint>

---

## Related Rules
- SIG-P0-01: Signal format (signals.md) — TASK_INCOMPLETE signal format
- ACT-P1-12: Activity.md format (activity-format.md) — entry structure
- HOF-P0-01: Handoff limit (handoff.md) — handoff count persists across context limits
