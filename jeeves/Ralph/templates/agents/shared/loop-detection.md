# Infinite Loop Detection (DUP-08)

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `.prompt-optimizer/shared/loop-detection.md`

---

## Rule Definitions

<!-- XML-structured rules for machine-parseable compliance -->

<rules>

<rule id="P1-10" priority="P1" scope="universal" trigger="error-handling">
  <name>Error Loop Detection</name>
  <limits>
    <limit id="P1-10a" type="per-issue">3 attempts to fix SAME issue in ONE session -> TASK_FAILED</limit>
    <limit id="P1-10b" type="cross-iteration">Same error across 3 SEPARATE iterations -> TASK_BLOCKED</limit>
    <limit id="P1-10c" type="multi-issue">5+ DIFFERENT errors in ONE session -> TASK_FAILED</limit>
    <limit id="P1-10d" type="total">10 total attempts per task (default max)</limit>
  </limits>
  <enforcement>
    <mechanism>Agent MUST increment attempt counter before each retry</mechanism>
    <mechanism>Agent MUST compare current error signature to previous errors</mechanism>
    <mechanism>On limit breach: immediately transition to P1-11 response</mechanism>
  </enforcement>
</rule>

<rule id="P2-10" priority="P2" scope="universal" trigger="error-handling">
  <name>Warning Signs (Early Detection)</name>
  <indicators>
    <indicator>Same error message appears 3+ times across attempts</indicator>
    <indicator>Same file modification being made and reverted multiple times</indicator>
    <indicator>Attempt count exceeds 5 on same issue</indicator>
    <indicator>Activity log shows "Attempt X - same as attempt Y" patterns</indicator>
  </indicators>
  <enforcement>
    <mechanism>Agent SHOULD log warning when any indicator is detected</mechanism>
    <mechanism>2+ indicators active simultaneously -> treat as P1-10 breach</mechanism>
  </enforcement>
</rule>

<rule id="P1-11" priority="P1" scope="universal" trigger="error-handling">
  <name>Circular Pattern Response</name>
  <response_sequence>
    <step order="1">STOP immediately - no further fix attempts</step>
    <step order="2">Document in activity.md: error signature, attempt count, pattern description</step>
    <step order="3">Signal: TASK_BLOCKED_XXXX:Circular pattern detected - same error repeated N times</step>
    <step order="4">Exit current task</step>
  </response_sequence>
  <enforcement>
    <mechanism>Steps 1-4 are mandatory and sequential; skipping any step is a P1 violation</mechanism>
    <mechanism>Signal format MUST match: TASK_BLOCKED_XXXX:&lt;description&gt;</mechanism>
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
              +--(P1-10a breach: same issue >= 3)--> [TASK_FAILED]
              +--(P1-10b breach: cross-iteration >= 3)--> [TASK_BLOCKED]
              +--(P1-10c breach: different errors >= 5)--> [TASK_FAILED]
              +--(P1-10d breach: total >= 10)--> [TASK_FAILED]

[TASK_FAILED] --> [P1-11 Response Sequence] --> [EXIT]
[TASK_BLOCKED] --> [P1-11 Response Sequence] --> [EXIT]
```

**Stop conditions**: Any limit breach triggers immediate transition to P1-11. No exceptions.

---

## Compliance Checkpoint

**Invoke at**: error-handling, pre-tool-call (when retrying), pre-response (when reporting errors)

| Check | Rule | Pass? |
|-------|------|-------|
| Attempt count < 3 for same issue | P1-10a | [ ] |
| Total different errors < 5 | P1-10c | [ ] |
| Total attempts < 10 | P1-10d | [ ] |
| Not in circular pattern (no 2+ warning indicators) | P2-10 | [ ] |
| If blocked: documented in activity.md | P1-11 | [ ] |
| If blocked: signal format correct | P1-11 | [ ] |

---

## Using This Rule File

### TODO Integration Guidance

Agents referencing this rule file SHOULD integrate loop detection into their TODO tracking:

**At start of turn:**
- Check: Am I retrying a previously failed task? If yes, load error history.
- Verify P1-10 limits are not already breached from prior turns.

**Before tool calls (when retrying):**
- Increment attempt counter for the current issue.
- Compare current approach to previous attempts - is this actually different?
- If P1-10a/b/c/d limit is reached, do NOT make the tool call; go to P1-11.

**Before response:**
- Run compliance checkpoint table above.
- If any check fails, response MUST include the P1-11 signal.

**Example TODO items:**
```
- [ ] Loop check: Attempt 1/3 for issue "validation error in config.yaml"
- [ ] Loop check: 2/5 different errors this session
- [ ] Loop check: 3/10 total attempts this task
- [x] Loop check: No circular pattern detected
```

**When adding to a task TODO list:**
```
- [ ] PRE-RETRY: Verify attempt count < P1-10 limits
- [ ] PRE-RETRY: Confirm new approach differs from previous attempts
- [ ] POST-ERROR: Update error signature log
- [ ] POST-ERROR: Check P2-10 warning indicators
```
