# Context Window Management (DUP-05)

<!-- version: 1.2.0 | last_updated: 2026-02-25 | canonical: YES -->

**Priority**: P1 (Must-follow); P0 rule embedded below
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/context-check.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## CTX-P0-01: Context Hard Stop (MANDATORY — DO NOT REFERENCE ELSEWHERE)

<rule priority="P0" id="CTX-P0-01" type="hard_stop">
When context usage exceeds **90%**, the agent MUST:
1. STOP all operations immediately
2. Signal `TASK_INCOMPLETE_XXXX:context_limit_exceeded`
3. Create a Context Resumption Checkpoint (see CTX-P1-02)
4. Do NOT attempt any further tool calls

**Enforcement**: Any tool call attempted after 90% threshold is a compliance violation.
**This is a hard stop. No exceptions. No further tool calls permitted.**
</rule>

---

## CTX-P1-01: Context Thresholds (MANDATORY)

<rule priority="P1" id="CTX-P1-01" type="monitoring">
Monitor context usage throughout execution. Take action at these thresholds:

| Threshold | Action Required |
|-----------|-----------------|
| **> 60%** | Prepare for graceful handoff; minimize verbose operations |
| **> 80%** | Signal `TASK_INCOMPLETE_XXXX:context_limit_approaching` AND create checkpoint |
| **> 90%** | Execute CTX-P0-01 hard stop immediately — NO further tool calls |

**Enforcement**: At start-of-turn, agent MUST check current context level against thresholds.
</rule>

---

## CTX-P1-02: Context Limit Response Protocol

<rule priority="P1" id="CTX-P1-02" type="response_protocol">
<trigger when="context_above_80_percent">
When context > 80%:

1. **Signal immediately**:
   ```
   TASK_INCOMPLETE_XXXX:context_limit_approaching
   ```

2. **Create Context Resumption Checkpoint** in activity.md:
   ```markdown
   ## Context Resumption Checkpoint [timestamp]
   **Work Completed**: [summary of finished work]
   **Work Remaining**: [what still needs to be done]
   **Files In Progress**: [list of files being edited]
   **Next Steps**: [ordered list for continuation]
   **Critical Context**: [important state to preserve]
   ```

3. **Handoff Guidance**:
   - Document current state clearly
   - Note any partially completed operations
   - Specify next logical action
   - Include file paths and line numbers if relevant
</trigger>

**Enforcement**: Failure to create checkpoint before handoff is a compliance violation.
</rule>

---

## CTX-P1-03: Context Recovery Strategy

<rule priority="P1" id="CTX-P1-03" type="recovery_protocol">
**When resuming from context limit:**

1. Read the Context Resumption Checkpoint from activity.md
2. Review files listed as "In Progress"
3. Verify current state matches checkpoint
4. Continue with "Next Steps"
5. Do NOT re-read full task history

**Enforcement**: Must read checkpoint before continuing. Starting fresh without checkpoint is a compliance violation.
</rule>

---

## CTX-P2-01: Context Limit Warning Signs

<rule priority="P2" id="CTX-P2-01" type="guidance">
Watch for these measurable indicators of context pressure:

- **Token count indicator**: Conversation history exceeds ~50k tokens (estimated by cumulative tool call count × average cost from CTX-P3-01)
- **Repetition indicator**: Same file read more than twice in one session without modification
- **Recall indicator**: Agent references information that contradicts earlier tool output (sign of context truncation)
- **Tool count indicator**: More than 30 tool calls in a single session without checkpoint
- **Error indicator**: Tool calls returning unexpected results that worked earlier in the session

**Action**: If 2+ indicators are active simultaneously, treat as >60% threshold and begin handoff preparation per CTX-P1-01.
</rule>

---

## CTX-P2-02: Context Limit Pattern Detection

<rule priority="P2" id="CTX-P2-02" type="guidance">
If same task repeatedly hits context limits:

- **Task too large**: Needs decomposition into smaller subtasks
- **Agent needs guidance**: May need more specific instructions
- **Process inefficiency**: May need optimization

**Action**: Signal TASK_BLOCKED with recommendation to decompose task.
</rule>

---

## CTX-P3-01: Estimation Guidelines

<rule priority="P3" id="CTX-P3-01" type="guidance">
**Typical Token Costs** (approximate):

- Read small file (~100 lines): ~500 tokens
- Read large file (~500 lines): ~2,000 tokens
- Write file: ~1.5x read cost
- Bash command: ~200–500 tokens
- Web fetch: ~1,000–5,000 tokens
- Grep/glob: ~100–300 tokens

**Conservative Planning**:
- Small tasks: Completable within ~20k tokens
- Medium tasks: Completable within ~40k tokens
- Large tasks: Should be decomposed
</rule>

---

## Compliance Checkpoint (CTX-CP-01)

**Invoke at**: start-of-turn, pre-tool-call, pre-response

<checkpoint id="CTX-CP-01" triggers="start-of-turn, pre-tool-call, pre-response">
- [ ] CTX-P0-01: If context >90% — STOP and do not make any tool calls
- [ ] CTX-P1-01: Context usage monitored (check current threshold level)
- [ ] CTX-P1-01: At >60%, minimize verbose operations and prepare handoff
- [ ] CTX-P1-01: At >80%, signal context_limit_approaching + create checkpoint
- [ ] CTX-P1-01: At >90%, execute CTX-P0-01 hard stop (no further tool calls)
- [ ] CTX-P1-02: Checkpoint documented in activity.md (if >80%)
</checkpoint>

**Enforcement**: This checkpoint MUST be run at each trigger point. Missing checkpoint execution is a compliance violation.

**[P0 REINFORCEMENT — verify every 5 tool calls]**
```
CTX-P0-01: Context < 90%? If NO → STOP immediately, no more tool calls
CTX-P1-01: Context level check: <60% | 60-80% | 80-90% | >90%
Current action based on level: normal | prep handoff | signal+checkpoint | HARD STOP
```

---

## Context Monitoring Workflow

<workflow id="CONTEXT-MONITOR">
1. **At session start**: Read context usage, add CTX-P1-01 threshold check to TODO
2. **Every 5 tool calls**: Run CTX-CP-01 compliance checkpoint
3. **At >60%**: Add graceful handoff preparation to TODO
4. **At >80%**: Execute CTX-P1-02 protocol immediately; signal and create checkpoint
5. **At >90%**: Execute CTX-P0-01 hard stop; do NOT proceed with any tool call
6. **On resumption**: Execute CTX-P1-03 recovery protocol before continuing
</workflow>

---

## Rule Priority Reference

| Priority | Rule IDs | Action |
|----------|----------|--------|
| **P0** | CTX-P0-01 | HARD STOP — Must never be bypassed |
| **P1** | CTX-P1-01, CTX-P1-02, CTX-P1-03 | Must-follow workflow gates |
| **P2** | CTX-P2-01, CTX-P2-02 | Should-follow guidance |
| **P3** | CTX-P3-01 | Best-practice estimates |

---

## Using This Rule File

### TODO Items for Context Monitoring

Add these items to your TODO list at the start of each session:

```
TODO items for context management:
- [ ] Check current context usage against CTX-P1-01 thresholds
- [ ] Verify compliance checkpoint CTX-CP-01 is scheduled every 5 tool calls
- [ ] If resuming from checkpoint: Execute CTX-P1-03 recovery protocol
```

### When to Reference This Rule File

| Trigger Point | Action Required |
|---------------|-----------------|
| **Start of Turn** | Check CTX-P1-01 thresholds; update TODO with current context level |
| **Pre-Tool-Call** | Verify CTX-P0-01 hard stop not triggered; run CTX-CP-01 checkpoint |
| **Post-Tool-Call** | Monitor context after large operations (read/write/fetch) |
| **Pre-Response** | Final CTX-CP-01 checkpoint; ensure no pending signals |
| **Task Handoff** | Execute CTX-P1-02 response protocol if >80% |

---

## Related Rules

- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **SIG-P0-01**: Signal format (see: signals.md)
- **HOF-P0-01**: Handoff limit (see: handoff.md)
- **LPD-P1-01**: Loop detection — repeated context limits may indicate task too large (see: loop-detection.md)
- **DEP-P0-01**: Circular dependency — may cause context exhaustion (see: dependency.md)
