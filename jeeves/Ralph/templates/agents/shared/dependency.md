# Dependency Discovery Rules (DUP-04)

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `.prompt-optimizer/shared/dependency.md`

---

<rule id="P1-09" priority="P1" type="dependency_detection">

## P1-09: Dependency Detection

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

<rule id="P1-10" priority="P0" type="circular_dependency_detection">

## P1-10: Circular Dependency Detection

**Priority**: P0 (Must-never-break)
**Enforcement Mechanism**: Immediate stop condition; requires human intervention; must signal TASK_BLOCKED

<trigger when="start-of-turn">Detect circular dependency patterns in deps-tracker.yaml</trigger>

**Warning Signs**:
- A depends on B, B depends on A
- Dependency chain loops back to start
- deps-tracker.yaml shows cycle

**Response**:
```
TASK_BLOCKED_XXXX:Circular dependency detected: A -> B -> C -> A
```

**Stop immediately** - requires human intervention.

</rule>

---

<compliance_checkpoint>

## Compliance Checkpoint

**Invoke at**: start-of-turn

- [ ] P1-09: Dependencies checked
- [ ] P1-10: Circular dependencies detected
- [ ] Hard dependencies signaled

</compliance_checkpoint>

---

<usage_guide>

## Using This Rule File

### TODO Integration Guidance

**At Start of Turn**:
- Check P1-09: Run dependency detection procedure
- Verify TODO.md task status before any work begins

**Before Tool Calls**:
- Verify P1 workflow gates: dependencies must be resolved first
- Hard dependencies (P1-09) block tool execution until resolved

**Before Response**:
- Run compliance checkpoint: all dependency checks complete
- Signal TASK_BLOCKED if circular dependency detected (P1-10)

### Example TODO Items for Dependency Checking

```
TODO: Check TODO.md for task completion status
TODO: Run P1-09 dependency detection procedure
TODO: Verify no circular dependencies (P1-10)
TODO: Signal hard dependencies before proceeding
TODO: Record dependency findings in activity.md
```

### Rule Priority Precedence

1. **P0 (Safety/Stop)**: P1-10 circular detection - immediate stop on detection
2. **P1 (Must-Follow)**: P1-09 dependency detection - mandatory procedure
3. **P2/P3**: Not applicable to this rule set

</usage_guide>
