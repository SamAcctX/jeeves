# Infinite Loop Detection (DUP-08)

<!-- version: 1.2.0 | last_updated: 2026-02-25 | canonical: YES -->

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/loop-detection.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## Terminology Definitions

| Term | Definition |
|------|-----------|
| **session** | One continuous agent invocation (start of turn to signal emission) |
| **iteration** | One complete handoff cycle (e.g., Developer → Tester → Developer) |
| **attempt** | One fix attempt for a specific error or issue |
| **error signature** | Unique identifier for an error (error type + location + message hash). Persisted in activity.md across sessions/iterations. |

---

## Rule Definitions

<rules>

<rule id="LPD-P1-01" priority="P1" scope="universal" trigger="error-handling">
  <name>Error Loop Detection</name>
  <limits>
    <limit id="LPD-P1-01a" type="per-issue">3 attempts to fix SAME issue in ONE session → TASK_FAILED</limit>
    <limit id="LPD-P1-01b" type="cross-iteration">Same error across 3 SEPARATE iterations → TASK_BLOCKED (check activity.md history for previous iteration error signatures)</limit>
    <limit id="LPD-P1-01c" type="multi-issue">5+ DIFFERENT errors in ONE session → TASK_FAILED</limit>
    <limit id="LPD-P1-01d" type="total">10 total attempts per task (absolute maximum)</limit>
  </limits>
  <enforcement>
    <mechanism>Agent MUST increment attempt counter before each retry</mechanism>
    <mechanism>Agent MUST compare current error signature to previous errors</mechanism>
    <mechanism>On limit breach: immediately transition to LPD-P1-02 response</mechanism>
  </enforcement>
</rule>

<rule id="LPD-P2-01" priority="P2" scope="universal" trigger="error-handling">
  <name>Warning Signs (Early Detection)</name>
  <indicators>
    <indicator>Same error message appears 3+ times across attempts</indicator>
    <indicator>Same file modification being made and reverted multiple times</indicator>
    <indicator>Attempt count exceeds 5 on same issue</indicator>
    <indicator>Activity log shows "Attempt X — same as attempt Y" patterns</indicator>
  </indicators>
  <enforcement>
    <mechanism>Agent SHOULD log warning when any indicator is detected</mechanism>
    <mechanism>2+ indicators active simultaneously → treat as LPD-P1-01 breach</mechanism>
  </enforcement>
</rule>

<rule id="LPD-P1-02" priority="P1" scope="universal" trigger="error-handling">
  <name>Circular Pattern Response (Mandatory Exit Sequence)</name>
  <response_sequence>
    <step order="1">STOP immediately — no further fix attempts</step>
    <step order="2">Document in activity.md: error signature, attempt count, pattern description</step>
    <step order="3">Signal: TASK_BLOCKED_XXXX:Circular_pattern_detected_same_error_repeated_N_times</step>
    <step order="4">Exit current task</step>
  </response_sequence>
  <enforcement>
    <mechanism>Steps 1–4 are mandatory and sequential; skipping any step is a P1 violation</mechanism>
    <mechanism>Signal format MUST be: TASK_BLOCKED_XXXX:&lt;description&gt; (no spaces in description)</mechanism>
  </enforcement>
</rule>

</rules>

---

## State Machine

```
[ATTEMPTING] --error--> [CHECK_LIMITS]
                            |
              +--(under limits)---> [RETRY] --> [ATTEMPTING]
              |
              +--(LPD-P1-01a: same issue >= 3 attempts)--> [TASK_FAILED]
              +--(LPD-P1-01b: cross-iteration same error >= 3)--> [TASK_BLOCKED]
              +--(LPD-P1-01c: different errors >= 5)--> [TASK_FAILED]
              +--(LPD-P1-01d: total attempts >= 10)--> [TASK_FAILED]

[TASK_FAILED]  --> [LPD-P1-02 Response Sequence] --> [EXIT]
[TASK_BLOCKED] --> [LPD-P1-02 Response Sequence] --> [EXIT]
```

**Stop conditions**: Any limit breach triggers immediate transition to LPD-P1-02. No exceptions.

---

## Compliance Checkpoint (LPD-CP-01)

**Invoke at**: error-handling, pre-tool-call (when retrying), pre-response (when reporting errors)

<checkpoint id="LPD-CP-01" triggers="error-handling, pre-tool-call (retry), pre-response">

| Check | Rule | Pass? |
|-------|------|-------|
| Attempt count < 3 for same issue (this session) | LPD-P1-01a | [ ] |
| Total different errors < 5 (this session) | LPD-P1-01c | [ ] |
| Total attempts < 10 (this task) | LPD-P1-01d | [ ] |
| Not in circular pattern (no 2+ warning indicators) | LPD-P2-01 | [ ] |
| If blocked: documented in activity.md | LPD-P1-02 | [ ] |
| If blocked: signal format is TASK_BLOCKED_XXXX:description | LPD-P1-02 | [ ] |

</checkpoint>

---

## Using This Rule File

### TODO Integration Guidance

**At start of turn:**
- [ ] Am I retrying a previously failed task? If yes, load error history from activity.md.
- [ ] Verify LPD-P1-01 limits are not already breached from prior turns (check activity.md).

**Before tool calls (when retrying):**
- [ ] Increment attempt counter for the current issue.
- [ ] Compare current approach to previous attempts — is this actually different?
- [ ] If LPD-P1-01a/b/c/d limit is reached, do NOT make the tool call; go to LPD-P1-02.

**Before response:**
- [ ] Run LPD-CP-01 compliance checkpoint table.
- [ ] If any check fails, response MUST include the LPD-P1-02 signal.

### Example TODO Items

```
- [ ] Loop check: Attempt 1/3 for issue "validation error in config.yaml"
- [ ] Loop check: 2/5 different errors this session
- [ ] Loop check: 3/10 total attempts this task
- [x] Loop check: No circular pattern detected
```

```
- [ ] PRE-RETRY: Verify attempt count < LPD-P1-01 limits
- [ ] PRE-RETRY: Confirm new approach differs from previous attempts
- [ ] POST-ERROR: Update error signature log in activity.md
- [ ] POST-ERROR: Check LPD-P2-01 warning indicators
```

---

## Related Rules

- **SIG-P0-03**: Signal types (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **DEP-P0-01**: Circular dependency detection (see: dependency.md)
- **HOF-P0-01**: Handoff limit — repeated handoff cycles may indicate a loop (see: handoff.md)
- **HOF-P0-02**: Handoff loops — self-handoff prevention (see: handoff.md)
- **CTX-P0-01**: Context hard stop — loop may exhaust context (see: context-check.md)
