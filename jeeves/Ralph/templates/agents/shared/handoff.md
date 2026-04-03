# Handoff Guidelines (DUP-06)

<!-- version: 1.3.0 | last_updated: 2026-03-13 | canonical: YES -->

**Priority**: P1 (Must-follow); P0 rules embedded below
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/handoff.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## HOF-P0-01: Forbidden — Exceeding Handoff Limit (CRITICAL — NEVER EXCEED)

<rule priority="P0" id="HOF-P0-01" type="forbidden">
<condition>handoff_count >= 8</condition>
<action>STOP — emit TASK_INCOMPLETE_XXXX:handoff_limit_reached</action>
</rule>

**Maximum: 8 Worker subagent invocations per task.**
**Enforcement**: Any attempt to invoke a 9th Worker subagent MUST be blocked. No exceptions.
**Signal**: `TASK_INCOMPLETE_XXXX:handoff_limit_reached` (DO NOT reference elsewhere — this limit is absolute)

---

## HOF-P0-02: Forbidden — Handoff Loops

<rule priority="P0" id="HOF-P0-02" type="forbidden">
<condition>target_agent == last_handoff_from_agent (same agent type as the immediately preceding handoff source)</condition>
<action>STOP — emit TASK_INCOMPLETE_XXXX:handoff_loop_detected</action>
</rule>

**Enforcement**: Cannot handoff BACK to the same agent type that just handed off to you. This creates A→B→A→B infinite loops.

**Clarification**:
- `Developer → Tester → Developer` is **ALLOWED** (normal review cycle — different agent initiated handoff)
- `Developer → Developer` is **FORBIDDEN** (self-handoff)
- `Developer → Tester → Developer → Tester → Developer` — each individual handoff is valid, but if the same error persists, LPD-P1-01b (loop-detection.md) applies after 3 cross-iteration repetitions

**Detection**: Compare `target_agent` against `last_handoff_from` field in activity.md. If equal → block.

---

## HOF-P1-01: Handoff Limit Details (MANDATORY)

**Maximum 8 total Worker subagent invocations per task.**

- Count includes: Original invocation + up to 7 handoffs
- Does NOT include: Manager self-consultation, skills-finder, other orchestration
- Applies to Worker agents only (developer, tester, architect, etc.)

---

## Handoff Counter State Machine

<state_machine id="HOF-COUNTER">
<state name="initialized" value="1"/>
<transition event="handoff" condition="count < 8" action="count += 1"/>
<transition event="handoff" condition="count >= 8" action="STOP — emit handoff_limit_reached"/>
</state_machine>

| Step | Action |
|------|--------|
| Initialize | `handoff_count = 1` (for original Worker invocation) |
| Increment | `handoff_count += 1` on each handoff |
| Check | Before each handoff, verify `handoff_count < 8` |
| At Limit | Emit `TASK_INCOMPLETE_XXXX:handoff_limit_reached` |

**Enforcement**: Pre-tool-call validator MUST check handoff_count before invoking subagent.

---

## HOF-P1-02: Handoff Signal Format

<validator type="regex" id="HOF-SIG-REGEX">
^TASK_INCOMPLETE_\d{4}:handoff_to:[a-z-]+:see_activity_md$
</validator>

**Standard Format**:
```
TASK_INCOMPLETE_XXXX:handoff_to:AGENT:see_activity_md
```

**Example**:
```
TASK_INCOMPLETE_0042:handoff_to:developer:see_activity_md
```

**Note**: Task ID is exactly 4 digits with leading zeros (see SIG-P0-02 in signals.md). This regex uses `\d{4}` to enforce that.

**Valid Target Agents**:
- `developer` — Code implementation
- `tester` — Test validation
- `architect` — System design
- `researcher` — Investigation
- `writer` — Documentation
- `ui-designer` — Interface design
- `decomposer` — Task breakdown

---

## HOF-P1-03: Handoff Process

<workflow id="HOF-PROCESS">
<step id="1">Update activity.md with handoff details</step>
<step id="2">Signal handoff with TASK_INCOMPLETE format</step>
<step id="3">Manager verifies count and invokes target agent</step>
</workflow>

**Initiating Handoff**:

1. Update activity.md with handoff details:
   ```markdown
   ## Handoff Record [timestamp]
   **From**: {current_agent}
   **To**: {target_agent}
   **State**: {READY_FOR_REVIEW|READY_FOR_FINAL_REVIEW|DEFECT_FOUND|REVIEW_COMPLETE}
   **Context**: [summary of work done and next steps]
   ```

2. Signal handoff:
   ```
   TASK_INCOMPLETE_XXXX:handoff_to:TARGET:see_activity_md
   ```

3. Manager will:
   - Parse handoff target from signal
   - Verify handoff_count < 8
   - Invoke target agent with context
   - Increment handoff_count

**Receiving Handoff**:

1. Check activity.md for handoff status
2. Verify handoff State matches your role (e.g., READY_FOR_REVIEW → Tester, DEFECT_FOUND → Developer)
3. Read context from previous agent
4. Continue work as specified
5. Return control to original agent when complete (unless defect found)

---

## HOF-P2-01: Handoff Best Practices

**DO**:
- Document context clearly in activity.md
- Specify what work was done and what remains
- Include relevant file paths and line numbers
- Note any blockers or issues encountered

**DON'T**:
- Handoff without updating activity.md
- Exceed 8 total invocations
- Handoff to same agent type (creates loops)
- Use handoffs for simple questions (signal BLOCKED instead)

---

## HOF-P1-05: Compliance Checkpoint (Pre-Handoff)

**Invoke at**: pre-handoff (before any subagent invocation)

<checkpoint id="HOF-CP-01" trigger="pre-handoff">
- [ ] HOF-P0-01: handoff_count < 8 (STOP immediately if at limit — emit handoff_limit_reached)
- [ ] HOF-P0-02: target_agent != current_agent (no self-loops)
- [ ] HOF-P1-01: Handoff count verified and will be incremented
- [ ] HOF-P1-02: Signal format matches regex `^TASK_INCOMPLETE_\d{4}:handoff_to:[a-z-]+:see_activity_md$`
- [ ] HOF-P1-02: Target agent is in valid list (developer/tester/architect/researcher/writer/ui-designer/decomposer)
- [ ] HOF-P1-03: activity.md updated with handoff details
- [ ] HOF-P1-03: Context summary provided for receiving agent
</checkpoint>

**[P0 REINFORCEMENT — verify before EVERY subagent invocation]**
```
HOF-P0-01: handoff_count < 8? If NO → STOP, emit handoff_limit_reached
HOF-P0-02: target != current agent? If NO → STOP, emit handoff_loop_detected
```

---

## File-Based State Requirements

| State Field | Valid Range | Action if Invalid |
|-------------|-------------|-------------------|
| handoff_count | 1–8 | STOP if > 8 (HOF-P0-01) |
| target_agent | valid agent list | STOP if invalid |
| last_handoff_from | agent name | Compare to prevent loops (HOF-P0-02) |

---

## Using This Rule File (TODO Integration)

### At Start of Turn

- [ ] Check HOF-P0-01: Read handoff_count from activity.md state
- [ ] Check HOF-P0-02: Verify target != current agent (no loop risk)

### Before Tool Call (subagent invocation)

- [ ] HOF-P0-01: handoff_count >= 8 → STOP with handoff_limit_reached
- [ ] HOF-P0-02: target == current → STOP with handoff_loop_detected
- [ ] HOF-P1-02: Validate signal format against regex
- [ ] HOF-P1-03: Verify activity.md updated

### Before Response (handoff completion)

- [ ] Run HOF-CP-01 compliance checkpoint (all 7 items)
- [ ] HOF-P1-03: Context summary clear for next agent

### Example TODO Items

```
TODO: Initialize handoff_count=1 on first Worker invocation
TODO: Before each subagent call — verify handoff_count < 8
TODO: On each handoff — increment handoff_count and update activity.md
TODO: At limit (8) — emit TASK_INCOMPLETE_XXXX:handoff_limit_reached
TODO: Verify no handoff loops — target_agent != current_agent
TODO: Pre-handoff checkpoint — validate all HOF-CP-01 items
```

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **SIG-P1-03**: Handoff signal format (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **TDD-P0-01**: Role boundary enforcement (see: workflow-phases.md)
- **LPD-P1-01b**: Cross-iteration loop detection — same error across 3+ handoff cycles (see: loop-detection.md)
- **CTX-P0-01**: Context hard stop — may force handoff at >90% (see: context-check.md)
