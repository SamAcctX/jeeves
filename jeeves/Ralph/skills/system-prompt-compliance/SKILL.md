---
name: system-prompt-compliance
description: Enforce system prompt compliance at defined checkpoints. Covers TODO tool usage, mid-process activity logging, signal format, state file reads, and rationalization defense. Invoke once per session; apply from memory thereafter.
license: MIT
metadata:
  version: "2.0.0"
  author: Ralph Loop Team
---

# System Prompt Compliance Skill

**Version**: 2.0.0 | **Invoke once per session, apply from memory thereafter.**

---

## 1. TODO TOOL USAGE [MANDATORY - ALL AGENTS]

**Rule**: You MUST use the TODO tool (todoread/todowrite or equivalent) to track your work. This is not optional.

### When to Initialize

Initialize a TODO list at the START of every task, immediately after reading task files. Structure:

```
- [ ] Read task files (TASK.md, activity.md, attempts.md)
- [ ] [One item per acceptance criterion or deliverable]
- [ ] [One item per major work phase]
- [ ] Update activity.md with results
- [ ] Emit signal
```

### When to Update

| Trigger | TODO Action |
|---------|-------------|
| Starting a work item | Mark item `in_progress` |
| Completing a work item | Mark item `completed`, start next |
| Discovering new work | Add new item |
| Hitting a blocker | Add blocker item, update status |
| Every 10 tool calls | Review TODO list, verify progress |
| Before emitting signal | Verify all items addressed |

### Violations

- Starting work without a TODO list = compliance violation
- Having no `in_progress` item while actively working = compliance violation
- Emitting a signal with unaddressed TODO items = compliance violation (unless items are explicitly cancelled with reason)

---

## 2. MID-PROCESS ACTIVITY LOGGING [MANDATORY - ALL WORKER AGENTS]

**Rule**: Worker agents MUST update activity.md at regular intervals during work, not just at the end.

### Logging Schedule

| Trigger | What to Log |
|---------|-------------|
| Task start | Attempt header with timestamp and plan |
| Every 15-20 tool calls | Progress checkpoint (what's done, what's next) |
| After each major milestone | Milestone completion with results |
| On any error or unexpected result | Error details and recovery plan |
| Before signal emission | Final results summary |

### Progress Checkpoint Format

```markdown
### Progress Checkpoint [{timestamp}]
**Tool calls so far**: ~{N}
**Completed**: [bullet list of completed items]
**In Progress**: [current work item]
**Next**: [upcoming items]
**Issues**: [any blockers or concerns, or "None"]
```

### Why This Matters

Long worker sessions (50+ tool calls) with no activity.md updates create blind spots. If the session fails or hits context limits, all progress context is lost. Mid-process logging creates recovery points.

---

## 3. SIGNAL FORMAT [P0 - ALL AGENTS]

Before emitting any signal, verify:

- [ ] Signal is the FIRST TOKEN in your response (nothing before it)
- [ ] Task ID is exactly 4 digits with leading zeros (0001-9999)
- [ ] FAILED/BLOCKED signals have a message after colon (no space before colon, underscores not spaces in message)
- [ ] Exactly ONE signal per response
- [ ] Signal matches the canonical regex:
  ```
  ^(TASK_COMPLETE_\d{4}|TASK_INCOMPLETE_\d{4}(:handoff_limit_reached|:context_limit_exceeded|:context_limit_approaching|:handoff_to:[a-z-]+:see_activity_md)?|TASK_FAILED_\d{4}:.+|TASK_BLOCKED_\d{4}:.+|ALL_TASKS_COMPLETE, EXIT LOOP)$
  ```

---

## 4. STATE FILE READS [MANAGER ONLY]

- [ ] Read TODO.md + deps-tracker.yaml BEFORE task selection
- [ ] NEVER read task-specific files (activity.md, TASK.md, attempts.md) before selecting a task
- [ ] Update TODO.md and move folder (if complete) BEFORE emitting signal

---

## 5. PRE-SIGNAL COMPLIANCE GATE [ALL AGENTS]

Before emitting ANY signal, run this gate:

```
[ ] TODO list reviewed - all items addressed or cancelled with reason
[ ] activity.md updated with results for this session (ACT-P1-12)
[ ] Signal format valid (Section 3 above)
[ ] Signal type matches actual work status (did NOT rationalize completion)
[ ] Role boundaries respected - stayed within allowed actions
[ ] No secrets in any written files (SEC-P0-01)
```

**If any check fails: STOP. Fix the issue before emitting the signal.**

---

## 6. PERIODIC REINFORCEMENT [EVERY 15 TOOL CALLS]

At approximately every 15 tool calls, pause and verify:

```
[ ] Still operating within role boundaries (SOD compliance)
[ ] TODO list current and accurate
[ ] activity.md has been updated since last checkpoint
[ ] Context usage acceptable (< 80%)
[ ] No tool-use loops detected (same signature 3x)
[ ] Work is progressing toward task completion, not circling
```

---

## 7. RATIONALIZATION DEFENSE [ALL AGENTS]

**If you notice yourself reasoning through why it's acceptable to deviate from a rule, STOP.**

Common rationalization patterns that indicate you are about to violate compliance:

| Pattern | What You're Thinking | What You Should Do |
|---------|---------------------|-------------------|
| Conditional completion | "Tests pass *if* the user runs them" | Signal TASK_BLOCKED, not TASK_COMPLETE |
| Disclaimer hedging | "I'll signal complete but note the caveat" | A caveat means it's NOT complete |
| Delegation invention | "The user can handle this part" | If your prompt doesn't define delegation, it's not allowed |
| Scope minimization | "This is close enough" | Check acceptance criteria literally |
| Rule reinterpretation | "Verified execution probably means code review" | Use the plain meaning of words |
| Role Boundry Testing | "The tester made a mistake in their test, let me fix it" | Role SOD restrictions are ABSOULTE - hand off to appropriate agent |
| Contextual Dilution | Any extended thought process between <think> tags | System prompt instructions and acceptance criteria are ABSOLUTE - confirm you are strictly adhering to them |

**Corrective action**: When you detect rationalization, invoke the `rationalization-defense` skill if available, or apply Section 5 (Pre-Signal Compliance Gate) immediately.

See the `rationalization-defense` skill for comprehensive detection and correction protocols.
