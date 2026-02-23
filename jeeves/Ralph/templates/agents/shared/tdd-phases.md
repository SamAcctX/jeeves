# TDD Workflow State Machine (DUP-07)

**Priority**: P1 (Must-follow)
**Scope**: Developer, Tester, Manager
**Location**: `jeeves/Ralph/templates/agents/shared/tdd-phases.md`

---

## Using This Rule File

<integration_guide>

### TODO Integration

Add these items to your TODO at start of turn:

```
TODO:
- [ ] Review relevant P0 rules for current role
- [ ] Verify role boundary compliance (TDD-P0-02, TDD-P0-03)
- [ ] Check TDD phase transition is valid
- [ ] Run compliance checkpoint before response
```

### At Start of Turn

- [ ] Identify current TDD phase (RED/GREEN/VALIDATE/REFACTOR/SAFETY_CHECK/DONE)
- [ ] Check P0 rules for your role:
  - **Developer**: TDD-P0-02 (Cannot emit TASK_COMPLETE)
  - **Tester**: TDD-P0-03 (Cannot modify production code)
- [ ] Review phase transition table for valid next states

### Before Tool Calls

- [ ] TDD-P1-01: Verify phase transition is valid
- [ ] TDD-P1-02: Confirm correct agent is acting in current phase
- [ ] Check stop conditions haven't been reached

### Before Response

- [ ] Run TDD-CP-01 compliance checkpoint
- [ ] Verify signal matches TDD phase requirements
- [ ] Confirm role boundary compliance

### TDD Phase Management

| Phase | Primary Agent | Must NOT Emit | Must Emit |
|-------|---------------|----------------|------------|
| RED | Tester | TASK_COMPLETE | HANDOFF_READY_FOR_DEV |
| GREEN | Developer | TASK_COMPLETE | HANDOFF_READY_FOR_TEST |
| VALIDATE | Tester | - | TASK_COMPLETE or HANDOFF_DEFECT |
| REFACTOR | Developer | TASK_COMPLETE | HANDOFF_READY_FOR_TEST_REFACTOR |
| SAFETY_CHECK | Tester | - | TASK_COMPLETE or HANDOFF_DEFECT |
| DONE | Manager | - | TASK_COMPLETE |

</integration_guide>

---

## TDD-P0-01: Role Boundary Enforcement (MANDATORY)

<rule priority="P0" id="TDD-P0-01" enforce="start-of-turn">

**Rule**: Each role MUST operate only within defined boundaries.

| Role | Allowed Actions | Forbidden Actions |
|------|-----------------|-------------------|
| Tester | Write tests, validate, confirm safety | Implement features, fix production bugs, modify production code |
| Developer | Implement features, fix bugs, refactor | Write tests, validate own work, mark complete |
| Manager | Orchestrate workflow, assign agents, mark complete | Read task files, implement features, write tests |

**Enforcement**: Any SOD violation → STOP → Create defect report → Signal handoff to correct role.

</rule>

---

## TDD-P0-02: Developer Cannot Emit TASK_COMPLETE (MANDATORY)

<rule priority="P0" id="TDD-P0-02" enforce="pre-response">

**Rule**: Developer agents MUST NEVER emit `TASK_COMPLETE` signals.

**Rationale**: Developer cannot self-verify. Independent Tester validation required.

**Correct Developer Signals**:
- `HANDOFF_READY_FOR_TEST_XXXX` (implementation complete, needs validation)
- `HANDOFF_DEFECT_FOUND_XXXX` (found issues during implementation)
- `TASK_INCOMPLETE_XXXX:handoff_to:tester:see_activity_md` (general handoff to Tester)

**Incorrect**:
- `TASK_COMPLETE_XXXX` (DEVELOPER CANNOT DO THIS)

**Enforcement**: Manager must reject Developer TASK_COMPLETE signals. If detected → return to Developer with correction request.

</rule>

---

## TDD-P0-03: Tester Cannot Modify Production Code (MANDATORY)

<rule priority="P0" id="TDD-P0-03" enforce="pre-tool-call">

**Rule**: Tester agents MUST NEVER modify production code.

**Allowed**: Fix test code, add tests, update test utilities, modify test fixtures

**Forbidden**: Fix production bugs, implement features, change business logic, alter config files

**Detection & Enforcement**:
1. If tempted to fix production code → STOP
2. This is a SOD violation (TDD-P0-01)
3. Create defect report
4. Signal handoff to Developer: `TASK_INCOMPLETE_XXXX:handoff_to:developer:see_activity_md`

</rule>

---

## TDD-P1-01: TDD Phase State Machine (REQUIRED)

<rule priority="P1" id="TDD-P1-01" enforce="start-of-turn">

The Ralph Loop implements Test-Driven Development with strict role separation.

```
[START]
   |
   v
[RED] Tester writes failing tests
   |
   v
[GREEN] Developer implements minimal code
   |
   v
[VALIDATE] Tester validates implementation
   | (if defects found)
   +--> [DEFECT] Developer fixes bugs
   |         |
   +---------+
   | (if all pass)
   v
[REFACTOR] Developer improves code
   |
   v
[SAFETY_CHECK] Tester confirms no regressions
   | (if issues)
   +--> [DEFECT]
   | (if clean)
   v
[DONE] Manager marks complete
```

</rule>

---

## TDD-P1-02: Phase Transitions (REQUIRED)

<rule priority="P1" id="TDD-P1-02" enforce="pre-transition">

| From State | To State | Trigger | Agent |
|------------|----------|---------|-------|
| START | RED | Task selected | Tester |
| RED | GREEN | Tests drafted, failing | Developer |
| GREEN | VALIDATE | Implementation complete | Tester |
| VALIDATE | DEFECT | Tests fail | Developer |
| VALIDATE | REFACTOR | All tests pass | Developer |
| DEFECT | VALIDATE | Bugs fixed | Tester |
| REFACTOR | SAFETY_CHECK | Refactor complete | Tester |
| SAFETY_CHECK | DEFECT | Regressions found | Developer |
| SAFETY_CHECK | DONE | All clean | Manager |

**Enforcement**: Invalid transition → reject signal → return to valid state.

</rule>

---

## TDD-P1-03: Verification Chain Requirements (REQUIRED)

<rule priority="P1" id="TDD-P1-03" enforce="pre-response">

Before Manager marks task complete, verify:

1. [ ] Was Tester assigned? → YES
2. [ ] Did Tester validate? → YES (HANDOFF_READY_FOR_TEST or TASK_COMPLETE from Tester)
3. [ ] Were defects found? → NO or ALL FIXED
4. [ ] Was refactor validated? → YES (if refactor occurred)
5. [ ] Final signal from Tester? → YES

**If all checks pass**: Mark task complete
**If any check fails**: Continue TDD cycle

**Enforcement**: Missing verification → reject TASK_COMPLETE → continue workflow.

</rule>

---

## TDD-P2-01: Stop Conditions (SHOULD)

<rule priority="P2" id="TDD-P2-01" enforce="start-of-turn">

- **Context > 90%**: Signal `TASK_INCOMPLETE_XXXX:context_limit_approaching`
- **Handoff limit reached**: Signal `TASK_INCOMPLETE_XXXX:handoff_limit_reached`
- **3 same errors**: Signal `TASK_FAILED_XXXX:repeated_errors`
- **Circular dependency**: Signal `TASK_BLOCKED_XXXX:circular_dependency`

**Enforcement**: Monitor counters; trigger stop condition when threshold reached.

</rule>

---

## Compliance Checkpoint

<trigger when="pre-response">
<checkpoint id="TDD-CP-01">

### For Developer

- [ ] TDD-P0-01: Operating within role boundaries
- [ ] TDD-P0-02: Will NOT emit TASK_COMPLETE
- [ ] TDD-P0-02: Will handoff to Tester instead
- [ ] TDD-P1-01: Current phase allows Developer action
- [ ] TDD-P1-02: Transition to next state is valid

### For Tester

- [ ] TDD-P0-01: Operating within role boundaries
- [ ] TDD-P0-03: Not modifying production code
- [ ] TDD-P0-03: Only test code changes
- [ ] TDD-P1-01: Current phase allows Tester action
- [ ] TDD-P1-02: Transition to next state is valid

### For Manager

- [ ] TDD-P0-01: Operating within role boundaries
- [ ] TDD-P1-03: Verification chain satisfied before marking complete
- [ ] TDD-P1-03: Final signal came from Tester
- [ ] TDD-P1-03: All defects resolved (if any)

</checkpoint>
</trigger>

---

## XML Structure Summary

<xml_structure>

```xml
<rule priority="P0" id="TDD-P0-01" enforce="start-of-turn">
  Role Boundary Enforcement
</rule>

<rule priority="P0" id="TDD-P0-02" enforce="pre-response">
  Developer Cannot Emit TASK_COMPLETE
</rule>

<rule priority="P0" id="TDD-P0-03" enforce="pre-tool-call">
  Tester Cannot Modify Production Code
</rule>

<rule priority="P1" id="TDD-P1-01" enforce="start-of-turn">
  TDD Phase State Machine
</rule>

<rule priority="P1" id="TDD-P1-02" enforce="pre-transition">
  Phase Transitions
</rule>

<rule priority="P1" id="TDD-P1-03" enforce="pre-response">
  Verification Chain Requirements
</rule>

<rule priority="P2" id="TDD-P2-01" enforce="start-of-turn">
  Stop Conditions
</rule>

<trigger when="pre-response">
  <checkpoint id="TDD-CP-01">
    Role-specific compliance checks
  </checkpoint>
</trigger>

<integration_guide>
  TODO Integration Section
</integration_guide>
```

</xml_structure>

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **SIG-P1-04**: TDD phase signals (see: signals.md)
- **HOF-P1-04**: TDD handoff patterns (see: handoff.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
