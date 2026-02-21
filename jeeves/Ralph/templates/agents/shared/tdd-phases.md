# TDD Workflow State Machine (DUP-07)

**Priority**: P1 (Must-follow)
**Scope**: Developer, Tester, Manager
**Location**: `.prompt-optimizer/shared/tdd-phases.md`

---

## Using This Rule File

<integration_guide>

### TODO Integration

Add these items to your TODO at start of turn:

```
TODO:
- [ ] Review relevant P0 rules for current role
- [ ] Verify role boundary compliance (P0-06, P0-07)
- [ ] Check TDD phase transition is valid
- [ ] Run compliance checkpoint before response
```

### At Start of Turn

- [ ] Identify current TDD phase (RED/GREEN/VALIDATE/REFACTOR/SAFETY_CHECK/DONE)
- [ ] Check P0 rules for your role:
  - **Developer**: P0-06 (Cannot emit TASK_COMPLETE)
  - **Tester**: P0-07 (Cannot modify production code)
- [ ] Review phase transition table for valid next states

### Before Tool Calls

- [ ] P1-01: Verify phase transition is valid
- [ ] P1-02: Confirm correct agent is acting in current phase
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

## P0-05: Role Boundary Enforcement (MANDATORY)

<rule priority="P0" id="P0-05" enforce="start-of-turn">

**Rule**: Each role MUST operate only within defined boundaries.

| Role | Allowed Actions | Forbidden Actions |
|------|-----------------|-------------------|
| Tester | Write tests, validate, confirm safety | Implement features, fix production bugs, modify production code |
| Developer | Implement features, fix bugs, refactor | Write tests, validate own work, mark complete |
| Manager | Orchestrate workflow, assign agents, mark complete | Read task files, implement features, write tests |

**Enforcement**: Any SOD violation → STOP → Create defect report → Signal handoff to correct role.

</rule>

---

## P0-06: Developer Cannot Emit TASK_COMPLETE (MANDATORY)

<rule priority="P0" id="P0-06" enforce="pre-response">

**Rule**: Developer agents MUST NEVER emit `TASK_COMPLETE` signals.

**Rationale**: Developer cannot self-verify. Independent Tester validation required.

**Correct Developer Signals**:
- `HANDOFF_READY_FOR_TEST_XXXX` (implementation complete, needs validation)
- `HANDOFF_DEFECT_FOUND_XXXX` (found issues during implementation)
- `TASK_INCOMPLETE_XXXX:handoff_to:tester` (general handoff to Tester)

**Incorrect**:
- `TASK_COMPLETE_XXXX` (DEVELOPER CANNOT DO THIS)

**Enforcement**: Manager must reject Developer TASK_COMPLETE signals. If detected → return to Developer with correction request.

</rule>

---

## P0-07: Tester Cannot Modify Production Code (MANDATORY)

<rule priority="P0" id="P0-07" enforce="pre-tool-call">

**Rule**: Tester agents MUST NEVER modify production code.

**Allowed**: Fix test code, add tests, update test utilities, modify test fixtures

**Forbidden**: Fix production bugs, implement features, change business logic, alter config files

**Detection & Enforcement**:
1. If tempted to fix production code → STOP
2. This is a SOD violation (P0-05)
3. Create defect report
4. Signal handoff to Developer: `TASK_INCOMPLETE_XXXX:handoff_to:developer`

</rule>

---

## P1-01: TDD Phase State Machine (REQUIRED)

<rule priority="P1" id="P1-01" enforce="start-of-turn">

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

## P1-02: Phase Transitions (REQUIRED)

<rule priority="P1" id="P1-02" enforce="pre-transition">

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

## P1-03: Verification Chain Requirements (REQUIRED)

<rule priority="P1" id="P1-03" enforce="pre-response">

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

## P2-01: Stop Conditions (SHOULD)

<rule priority="P2" id="P2-01" enforce="start-of-turn">

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

- [ ] P0-05: Operating within role boundaries
- [ ] P0-06: Will NOT emit TASK_COMPLETE
- [ ] P0-06: Will handoff to Tester instead
- [ ] P1-01: Current phase allows Developer action
- [ ] P1-02: Transition to next state is valid

### For Tester

- [ ] P0-05: Operating within role boundaries
- [ ] P0-07: Not modifying production code
- [ ] P0-07: Only test code changes
- [ ] P1-01: Current phase allows Tester action
- [ ] P1-02: Transition to next state is valid

### For Manager

- [ ] P0-05: Operating within role boundaries
- [ ] P1-03: Verification chain satisfied before marking complete
- [ ] P1-03: Final signal came from Tester
- [ ] P1-03: All defects resolved (if any)

</checkpoint>
</trigger>

---

## XML Structure Summary

<xml_structure>

```xml
<rule priority="P0" id="P0-05" enforce="start-of-turn">
  Role Boundary Enforcement
</rule>

<rule priority="P0" id="P0-06" enforce="pre-response">
  Developer Cannot Emit TASK_COMPLETE
</rule>

<rule priority="P0" id="P0-07" enforce="pre-tool-call">
  Tester Cannot Modify Production Code
</rule>

<rule priority="P1" id="P1-01" enforce="start-of-turn">
  TDD Phase State Machine
</rule>

<rule priority="P1" id="P1-02" enforce="pre-transition">
  Phase Transitions
</rule>

<rule priority="P1" id="P1-03" enforce="pre-response">
  Verification Chain Requirements
</rule>

<rule priority="P2" id="P2-01" enforce="start-of-turn">
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

(End of file - total 252 lines)
