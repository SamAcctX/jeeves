# Handoff Guidelines (DUP-06)

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/handoff.md`

---

## HOF-P0-01: Forbidden - Exceeding Handoff Limit

<rule priority="P0" id="HOF-P0-01" type="forbidden">
<condition>handoff_count >= 8</condition>
<action>STOP - emit TASK_INCOMPLETE_XXXX:handoff_limit_reached</action>
</rule>

**Enforcement**: Any attempt to invoke a 9th Worker subagent must be blocked. No exceptions.

---

## HOF-P0-02: Forbidden - Handoff Loops

<rule priority="P0" id="HOF-P0-02" type="forbidden">
<condition>target_agent == current_agent</condition>
<action>STOP - emit TASK_INCOMPLETE_XXXX:handoff_loop_detected</action>
</rule>

**Enforcement**: Cannot handoff to same agent type twice in succession. This creates infinite loops.

---

## HOF-P1-01: Handoff Limit (MANDATORY)

**Maximum 8 total Worker subagent invocations per task.**

- Count includes: Original invocation + up to 7 handoffs
- Does NOT include: Manager self-consultation, skills-finder, other orchestration
- Applies to Worker agents only (developer, tester, architect, etc.)

---

## Handoff Counter State Machine

<state_machine id="HOF-COUNTER">
<state name="initialized" value="1"/>
<transition event="handoff" condition="count < 8" action="count += 1"/>
<transition event="handoff" condition="count >= 8" action="STOP"/>
</state_machine>

**Initialize**: `handoff_count = 1` (for original Worker invocation)

**Increment**: `handoff_count += 1` on each handoff

**Check**: Before each handoff, verify `handoff_count < 8`

**At Limit**: Emit `TASK_INCOMPLETE_XXXX:handoff_limit_reached`

**Enforcement**: Pre-tool-call validator MUST check handoff_count before invoking subagent.

---

## HOF-P1-02: Handoff Signal Format

<validator type="regex">^TASK_INCOMPLETE_[0-9]+:handoff_to:[a-z-]+:see_activity_md$</validator>

**Standard Format**:
```
TASK_INCOMPLETE_XXXX:handoff_to:AGENT:see_activity_md
```

**Example**:
```
TASK_INCOMPLETE_0042:handoff_to:developer:see_activity_md
```

**Valid Target Agents**:
- `developer` - Code implementation
- `tester` - Test validation
- `architect` - System design
- `researcher` - Investigation
- `writer` - Documentation
- `ui-designer` - Interface design
- `decomposer` - Task breakdown

---

## HOF-P1-03: Handoff Process

<workflow>
<step id="1">Update activity.md with handoff details</step>
<step id="2">Signal handoff with TASK_INCOMPLETE format</step>
<step id="3">Manager verifies count & invokes target agent</step>
</workflow>

**Initiating Handoff**:

1. Update activity.md with handoff details:
   ```markdown
   ## Handoff Record [timestamp]
   **From**: {current_agent}
   **To**: {target_agent}
   **State**: {READY_FOR_DEV|READY_FOR_TEST|DEFECT_FOUND|etc.}
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
2. Verify READY_FOR_* status matches your role
3. Read context from previous agent
4. Continue work as specified
5. Return control to original agent when complete (unless defect found)

---

## HOF-P1-04: TDD Handoff Patterns

| Current State | Signal | Next Agent | Instruction |
|---------------|--------|------------|-------------|
| Tests drafted | `HANDOFF_READY_FOR_DEV_XXXX` | Developer | "Tests ready. Implement minimal code." |
| Implementation complete | `HANDOFF_READY_FOR_TEST_XXXX` | Tester | "Implementation complete. Validate tests." |
| Refactor complete | `HANDOFF_READY_FOR_TEST_REFACTOR_XXXX` | Tester | "Refactor complete. Confirm no regressions." |
| Defects found | `HANDOFF_DEFECT_FOUND_XXXX` | Developer | "Defects found. Fix production code." |

**Note**: TDD phase signals are emitted BY Workers and parsed BY Manager.

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

## HOF-P1-05: Compliance Checkpoint

<trigger when="pre-handoff">

- [ ] **HOF-P0-01**: handoff_count < 8 (STOP if at limit)
- [ ] **HOF-P0-02**: target_agent != current_agent (no loops)
- [ ] **HOF-P1-01**: Handoff count verified
- [ ] **HOF-P1-02**: Signal format matches regex
- [ ] **HOF-P1-02**: Target agent in valid list
- [ ] **HOF-P1-03**: activity.md updated with handoff details
- [ ] **HOF-P1-03**: Context summary provided

</trigger>

---

## Using This Rule File (TODO Integration)

This section provides TODO guidance for agents managing handoffs.

### At Start of Turn

<todolist>
<item priority="P0">Check HOF-P0-01: Verify handoff_count from state file</item>
<item priority="P0">Check HOF-P0-02: Verify target != current agent (no loop risk)</item>
</todolist>

### Before Tool Call (subagent invocation)

<todolist>
<item priority="P0">Run HOF-P0-01 check: handoff_count >= 8 → STOP with handoff_limit_reached</item>
<item priority="P0">Run HOF-P0-02 check: target == current → STOP with handoff_loop_detected</item>
<item priority="P1">Run HOF-P1-02 check: Validate signal format against regex</item>
<item priority="P1">Run HOF-P1-03 check: Verify activity.md updated</item>
</todolist>

### Before Response (handoff completion)

<todolist>
<item priority="P1">Run HOF-P1-05 Compliance Checkpoint (7 items)</item>
<item priority="P1">Verify HOF-P1-03: Context summary clear for next agent</item>
</todolist>

### Example TODO Items for Handoff Management

```
TODO: Initialize handoff_count=1 on first Worker invocation
TODO: Before each subagent call - verify handoff_count < 8
TODO: On each handoff - increment handoff_count and update activity.md
TODO: At limit (8) - emit TASK_INCOMPLETE_XXXX:handoff_limit_reached
TODO: Verify no handoff loops - target_agent != current_agent
TODO: Pre-handoff checkpoint - validate all P0/P1 rules
```

### File-Based State Requirements

| State File | Field | Valid Range | Action if Invalid |
|------------|-------|-------------|-------------------|
| activity.md | handoff_count | 1-8 | STOP if > 8 |
| activity.md | target_agent | valid agent list | STOP if invalid |
| activity.md | last_handoff_from | agent name | Compare to prevent loops |

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **SIG-P1-03**: Handoff signal format (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **TDD-P0-01**: Role boundary enforcement (see: tdd-phases.md)
