# TDD Workflow State Machine (DUP-07)

<!-- version: 1.2.0 | last_updated: 2026-02-25 | canonical: YES -->

**Priority**: P1 (Must-follow); P0 rules embedded below
**Scope**: Developer, Tester, Manager
**Location**: `jeeves/Ralph/templates/agents/shared/tdd-phases.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## TDD-P0-01: Role Boundary Enforcement (MANDATORY — SOD)

<rule priority="P0" id="TDD-P0-01" enforce="start-of-turn">

**Rule**: Each role MUST operate only within defined boundaries. Separation of Duties (SOD) is strictly enforced.

| Role | Allowed Actions | Forbidden Actions |
|------|-----------------|-------------------|
| Tester | Write tests, validate, confirm safety | Implement features, fix production bugs, modify production code |
| Developer | Implement features, fix bugs, refactor | Write tests, validate own work, emit TASK_COMPLETE |
| Manager | Orchestrate workflow, assign agents, mark complete | Read/modify implementation or test files directly, implement features, write tests |

**On SOD Violation**: STOP → Create defect report → Signal handoff to correct role.
**Enforcement**: Any SOD violation is a P0 breach. Stop immediately.

</rule>

---

## TDD-P0-02: Developer Cannot Emit TASK_COMPLETE (MANDATORY)

<rule priority="P0" id="TDD-P0-02" enforce="pre-response">

**Rule**: Developer agents MUST NEVER emit `TASK_COMPLETE` signals.

**Rationale**: Developer cannot self-verify. Independent Tester validation is required.

**Correct Developer Signals**:
- `HANDOFF_READY_FOR_TEST_XXXX` — implementation complete, needs validation
- `HANDOFF_DEFECT_FOUND_XXXX` — found issues during implementation
- `TASK_INCOMPLETE_XXXX:handoff_to:tester:see_activity_md` — general handoff to Tester

**Forbidden**:
- `TASK_COMPLETE_XXXX` — DEVELOPER CANNOT EMIT THIS UNDER ANY CIRCUMSTANCES

**Enforcement**: Manager MUST reject Developer TASK_COMPLETE signals. If detected → return to Developer with correction request.

</rule>

---

## TDD-P0-03: Tester Cannot Modify Production Code (MANDATORY)

<rule priority="P0" id="TDD-P0-03" enforce="pre-tool-call">

**Rule**: Tester agents MUST NEVER modify production code.

**Allowed**: Fix test code, add tests, update test utilities, modify test fixtures

**Forbidden**: Fix production bugs, implement features, change business logic, alter config files that are not test-only

**Detection & Response**:
1. If tempted to fix production code → STOP immediately
2. This is a SOD violation (TDD-P0-01)
3. Create defect report in activity.md
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

## TDD-P2-01: Stop Conditions (SHOULD-FOLLOW)

<rule priority="P2" id="TDD-P2-01" enforce="start-of-turn">

Monitor these conditions throughout TDD execution:

| Condition | Threshold | Signal | Authority |
|-----------|-----------|--------|-----------|
| Context approaching limit | > 80% | `TASK_INCOMPLETE_XXXX:context_limit_approaching` | CTX-P1-01 |
| Context hard stop | > 90% | `TASK_INCOMPLETE_XXXX:context_limit_exceeded` (+ STOP all ops) | CTX-P0-01 |
| Handoff limit reached | handoff_count = 8 | `TASK_INCOMPLETE_XXXX:handoff_limit_reached` | HOF-P0-01 |
| Same error repeated | 3 attempts same issue | `TASK_FAILED_XXXX:repeated_errors` | LPD-P1-01a |
| Circular dependency | Cycle detected | `TASK_BLOCKED_XXXX:circular_dependency` | DEP-P0-01 |

**Authoritative rules**: See context-check.md for CTX-P0-01/CTX-P1-01 details. At >90% context, NO further tool calls are permitted.

**Enforcement**: Monitor counters; trigger stop condition when threshold reached.

</rule>

---

## TDD Phase Management Reference

| Phase | Primary Agent | Must NOT Emit | Must Emit (with task ID suffix `_XXXX`) |
|-------|---------------|----------------|------------|
| RED | Tester | `TASK_COMPLETE_XXXX` | `HANDOFF_READY_FOR_DEV_XXXX` |
| GREEN | Developer | `TASK_COMPLETE_XXXX` | `HANDOFF_READY_FOR_TEST_XXXX` |
| VALIDATE | Tester | — | `TASK_COMPLETE_XXXX` or `HANDOFF_DEFECT_FOUND_XXXX` |
| REFACTOR | Developer | `TASK_COMPLETE_XXXX` | `HANDOFF_READY_FOR_TEST_REFACTOR_XXXX` |
| SAFETY_CHECK | Tester | — | `TASK_COMPLETE_XXXX` or `HANDOFF_DEFECT_FOUND_XXXX` |
| DONE | Manager | — | `TASK_COMPLETE_XXXX` |

**Note**: `XXXX` = 4-digit task ID with leading zeros (SIG-P0-02). All HANDOFF_* signals are in the TDD phase signal namespace (SIG-P1-04) — see signals.md for details.

---

## Compliance Checkpoint (TDD-CP-01)

**Invoke at**: pre-response (MANDATORY for Developer, Tester, Manager)

<checkpoint id="TDD-CP-01" trigger="pre-response">

### For Developer

- [ ] TDD-P0-01: Operating within role boundaries (not writing tests, not marking complete)
- [ ] TDD-P0-02: Will NOT emit TASK_COMPLETE (will handoff to Tester instead)
- [ ] TDD-P1-01: Current phase allows Developer action
- [ ] TDD-P1-02: Transition to next state is valid per transition table

### For Tester

- [ ] TDD-P0-01: Operating within role boundaries (not modifying production code)
- [ ] TDD-P0-03: Only test code changes — no production code modifications
- [ ] TDD-P1-01: Current phase allows Tester action
- [ ] TDD-P1-02: Transition to next state is valid per transition table

### For Manager

- [ ] TDD-P0-01: Operating within role boundaries (not implementing features or writing tests)
- [ ] TDD-P1-03: Verification chain satisfied before marking complete (all 5 checks)
- [ ] TDD-P1-03: Final signal came from Tester (not Developer)
- [ ] TDD-P1-03: All defects resolved if any were found

</checkpoint>

**[P0 REINFORCEMENT — verify before EVERY response]**
```
TDD-P0-02: Developer? → MUST NOT emit TASK_COMPLETE
TDD-P0-03: Tester? → MUST NOT modify production code
TDD-P0-01: Acting within role boundaries?
Confirm role and current phase before proceeding.
```

---

## Using This Rule File

### TODO Integration

Add these items to your TODO at start of turn:

```
TODO:
- [ ] Review relevant P0 rules for current role (TDD-P0-01, TDD-P0-02 or TDD-P0-03)
- [ ] Identify current TDD phase (RED/GREEN/VALIDATE/REFACTOR/SAFETY_CHECK/DONE)
- [ ] Check TDD phase transition is valid (TDD-P1-02 table)
- [ ] Run TDD-CP-01 compliance checkpoint before response
```

### At Start of Turn

- [ ] Identify current TDD phase from activity.md
- [ ] Check P0 rules for your role
- [ ] Review phase transition table for valid next states

### Before Tool Calls

- [ ] TDD-P1-01: Verify phase transition is valid
- [ ] TDD-P1-02: Confirm correct agent is acting in current phase
- [ ] Check stop conditions (TDD-P2-01) haven't been reached

### Before Response

- [ ] Run TDD-CP-01 compliance checkpoint
- [ ] Verify signal matches TDD phase requirements
- [ ] Confirm role boundary compliance

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **SIG-P1-04**: TDD phase signals (see: signals.md)
- **HOF-P1-04**: TDD handoff patterns (see: handoff.md)
- **CTX-P0-01**: Context hard stop at 90% (see: context-check.md)
- **CTX-P1-01**: Context thresholds 60/80/90% (see: context-check.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
