# Dependency Discovery Rules (DUP-04)

<!-- version: 1.1.0 | last_updated: 2026-02-24 | canonical: YES -->

**Priority**: P1 (Must-follow); P0 rule embedded below
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/dependency.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## DEP-P1-01: Dependency Detection

<rule id="DEP-P1-01" priority="P1" type="dependency_detection" trigger="start-of-turn">

**Enforcement**: Mandatory checkpoint at start-of-turn; must be recorded in activity.md before proceeding.

**Types**:
- **Hard Dependencies (Blocking)**: Cannot proceed without completion
- **Soft Dependencies (Non-blocking)**: Can proceed with workaround

**Discovery Procedure**:
1. Identify missing prerequisites (files, APIs, data)
2. Check TODO.md for task completion status
3. Evaluate if hard or soft dependency

**Reporting in activity.md**:
```markdown
## Attempt {N} [{timestamp}]
Dependency Discovered:
- Task: XXXX (this task)
- Depends on: YYYY (the task we need)
- Type: [hard/soft]
- Reason: [why this dependency exists]
- Impact: [what is blocked]
```

</rule>

---

## DEP-P0-01: Circular Dependency Detection (MANDATORY — HARD STOP)

<rule id="DEP-P0-01" priority="P0" type="circular_dependency_detection">

**Enforcement**: Immediate stop condition; requires human intervention; must signal TASK_BLOCKED.

<trigger when="start-of-turn">Detect circular dependency patterns in deps-tracker.yaml</trigger>

**Warning Signs**:
- A depends on B, B depends on A
- Dependency chain loops back to start
- deps-tracker.yaml shows cycle

**Response** (all steps mandatory):
1. STOP immediately
2. Document in activity.md: cycle description (A→B→C→A)
3. Signal:
   ```
   TASK_BLOCKED_XXXX:Circular_dependency_detected:A_to_B_to_C_to_A
   ```
4. Await human intervention — do NOT attempt to resolve autonomously

</rule>

---

## Compliance Checkpoint (DEP-CP-01)

**Invoke at**: start-of-turn

<checkpoint id="DEP-CP-01" trigger="start-of-turn">
- [ ] DEP-P1-01: Dependency detection procedure executed
- [ ] DEP-P1-01: TODO.md task statuses checked
- [ ] DEP-P1-01: Dependency findings recorded in activity.md
- [ ] DEP-P0-01: Circular dependency scan complete (checked deps-tracker.yaml)
- [ ] DEP-P0-01: If cycle detected → STOPPED and signaled TASK_BLOCKED
</checkpoint>

---

## Using This Rule File

### TODO Integration Guidance

**At Start of Turn**:
- [ ] Check DEP-P1-01: Run dependency detection procedure
- [ ] Verify TODO.md task status before any work begins
- [ ] Check DEP-P0-01: Scan deps-tracker.yaml for cycles

**Before Tool Calls**:
- [ ] Verify P1 workflow gates: hard dependencies (DEP-P1-01) must be resolved first
- [ ] Hard dependencies block tool execution until resolved

**Before Response**:
- [ ] Run DEP-CP-01 compliance checkpoint (all 5 items)
- [ ] If circular dependency detected (DEP-P0-01): verify TASK_BLOCKED signal emitted

### Example TODO Items

```
TODO: Check TODO.md for task completion status
TODO: Run DEP-P1-01 dependency detection procedure
TODO: Scan deps-tracker.yaml for circular dependencies (DEP-P0-01)
TODO: If hard dependency found — signal before proceeding
TODO: Record dependency findings in activity.md
```

### Rule Priority Precedence

1. **P0 (Safety/Stop)**: DEP-P0-01 circular detection — immediate stop on detection
2. **P1 (Must-Follow)**: DEP-P1-01 dependency detection — mandatory procedure
3. **P2/P3**: Not applicable to this rule set

---

## Related Rules

- **SIG-P0-03**: Signal types (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **CTX-P0-01**: Context hard stop (see: context-check.md)
