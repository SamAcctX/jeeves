# Dependency Discovery Rules (DUP-04)

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/dependency.md`

---

## DEP-P1-01: Dependency Detection

<rule id="DEP-P1-01" priority="P1" type="dependency_detection">

**Priority**: P1 (Must-follow)
**Enforcement Mechanism**: Mandatory checkpoint at start-of-turn; must be recorded in activity.md before proceeding

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

## DEP-P0-01: Circular Dependency Detection

<rule id="DEP-P0-01" priority="P0" type="circular_dependency_detection">

**Priority**: P0 (Must-never-break)
**Enforcement Mechanism**: Immediate stop condition; requires human intervention; must signal TASK_BLOCKED

<trigger when="start-of-turn">Detect circular dependency patterns in deps-tracker.yaml</trigger>

**Warning Signs**:
- A depends on B, B depends on A
- Dependency chain loops back to start
- deps-tracker.yaml shows cycle

**Response**:
```
TASK_BLOCKED_XXXX:Circular_dependency_detected:A_to_B_to_C_to_A
```

**Stop immediately** - requires human intervention.

</rule>

---

## Compliance Checkpoint

<compliance_checkpoint id="DEP-CP-01">

**Invoke at**: start-of-turn

- [ ] DEP-P1-01: Dependencies checked
- [ ] DEP-P0-01: Circular dependencies detected
- [ ] Hard dependencies signaled

</compliance_checkpoint>

---

## Using This Rule File

<usage_guide>

### TODO Integration Guidance

**At Start of Turn**:
- Check DEP-P1-01: Run dependency detection procedure
- Verify TODO.md task status before any work begins

**Before Tool Calls**:
- Verify P1 workflow gates: dependencies must be resolved first
- Hard dependencies (DEP-P1-01) block tool execution until resolved

**Before Response**:
- Run compliance checkpoint: all dependency checks complete
- Signal TASK_BLOCKED if circular dependency detected (DEP-P0-01)

### Example TODO Items for Dependency Checking

```
TODO: Check TODO.md for task completion status
TODO: Run DEP-P1-01 dependency detection procedure
TODO: Verify no circular dependencies (DEP-P0-01)
TODO: Signal hard dependencies before proceeding
TODO: Record dependency findings in activity.md
```

### Rule Priority Precedence

1. **P0 (Safety/Stop)**: DEP-P0-01 circular detection - immediate stop on detection
2. **P1 (Must-Follow)**: DEP-P1-01 dependency detection - mandatory procedure
3. **P2/P3**: Not applicable to this rule set

</usage_guide>

---

## Related Rules

- **SIG-P0-03**: Signal types (see: signals.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **CTX-P0-01**: Context hard stop (see: context-check.md)
