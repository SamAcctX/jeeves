# Shared Rules Quick Reference

<!-- version: 1.0.0 | last_updated: 2026-02-25 | canonical: INDEX -->

**Purpose**: High-level index of all shared rule files, rule IDs, and cross-file dependencies.
**Scope**: Universal (all agents)

---

## File Index

| File | Description | Primary Priority | Key Rules |
|------|-------------|-----------------|-----------|
| `signals.md` | Signal format, types, regex validator, first-token discipline | P0 | SIG-P0-01 through SIG-P1-05 |
| `secrets.md` | Secrets protection, detection patterns, exposure protocol | P0 | SEC-P0-01, SEC-P1-01 |
| `context-check.md` | Context window thresholds, hard stop, recovery protocol | P0/P1 | CTX-P0-01, CTX-P1-01 through CTX-P3-01 |
| `handoff.md` | Handoff limits, loop prevention, TDD handoff patterns | P0/P1 | HOF-P0-01, HOF-P0-02, HOF-P1-01 through HOF-P2-01 |
| `tdd-phases.md` | TDD state machine, SOD enforcement, role boundaries | P0/P1 | TDD-P0-01 through TDD-P2-01 |
| `dependency.md` | Dependency discovery, circular detection, blocking rules | P0/P1 | DEP-P0-01, DEP-P1-01 |
| `loop-detection.md` | Error loop limits, warning signs, exit sequence | P1 | LPD-P1-01, LPD-P1-02, LPD-P2-01 |
| `activity-format.md` | Activity.md structure, attempt headers, handoff records | P1 | ACT-P1-12 |
| `rules-lookup.md` | RULES.md discovery hierarchy, precedence rules | P1 | RUL-P1-01, RUL-P1-02 |

---

## All Rule IDs — Quick Lookup

### P0 Rules (Must-Never-Break)

| Rule ID | File | One-Line Summary |
|---------|------|-----------------|
| SIG-P0-01 | signals.md | Signal MUST be FIRST TOKEN — no prefix/preamble |
| SIG-P0-02 | signals.md | Task ID MUST be exactly 4 digits with leading zeros |
| SIG-P0-03 | signals.md | Signal types: COMPLETE/INCOMPLETE/FAILED/BLOCKED — message rules |
| SIG-P0-04 | signals.md | Exactly ONE signal per execution (highest severity wins) |
| SEC-P0-01 | secrets.md | NEVER write secrets to repository files |
| CTX-P0-01 | context-check.md | Context >90% → HARD STOP, no further tool calls |
| HOF-P0-01 | handoff.md | Maximum 8 Worker subagent invocations per task |
| HOF-P0-02 | handoff.md | Cannot handoff back to same agent that just handed off to you |
| TDD-P0-01 | tdd-phases.md | Role boundary enforcement — SOD strictly enforced |
| TDD-P0-02 | tdd-phases.md | Developer MUST NEVER emit TASK_COMPLETE |
| TDD-P0-03 | tdd-phases.md | Tester MUST NEVER modify production code |
| DEP-P0-01 | dependency.md | Circular dependency → STOP, signal TASK_BLOCKED |

### P1 Rules (Must-Follow)

| Rule ID | File | One-Line Summary |
|---------|------|-----------------|
| SIG-P1-01 | signals.md | Validate signal format before emission |
| SIG-P1-02 | signals.md | Response content follows signal on subsequent lines |
| SIG-P1-03 | signals.md | Handoff signal format: `TASK_INCOMPLETE_XXXX:handoff_to:AGENT:see_activity_md` |
| SIG-P1-04 | signals.md | TDD phase signals (HANDOFF_*) — separate namespace, parsed by Manager |
| SIG-P1-05 | signals.md | System error signals use Task ID 0000 |
| SEC-P1-01 | secrets.md | Secret exposure response protocol (rotate, remove, document) |
| CTX-P1-01 | context-check.md | Context thresholds: >60% prep, >80% signal+checkpoint, >90% STOP |
| CTX-P1-02 | context-check.md | Context limit response — create resumption checkpoint |
| CTX-P1-03 | context-check.md | Context recovery — read checkpoint before continuing |
| HOF-P1-01 | handoff.md | Handoff count details — 1 initial + up to 7 handoffs |
| HOF-P1-02 | handoff.md | Handoff signal format + valid target agents list |
| HOF-P1-03 | handoff.md | Handoff process — update activity.md, signal, Manager verifies |
| HOF-P1-04 | handoff.md | TDD handoff patterns — READY_FOR_DEV/TEST/REFACTOR, DEFECT_FOUND |
| HOF-P1-05 | handoff.md | Pre-handoff compliance checkpoint (HOF-CP-01) |
| TDD-P1-01 | tdd-phases.md | TDD phase state machine (RED→GREEN→VALIDATE→REFACTOR→SAFETY_CHECK→DONE) |
| TDD-P1-02 | tdd-phases.md | Phase transitions — valid from/to/trigger/agent table |
| TDD-P1-03 | tdd-phases.md | Verification chain — 5-point check before marking complete |
| DEP-P1-01 | dependency.md | Dependency detection procedure — hard vs soft dependencies |
| LPD-P1-01 | loop-detection.md | Error loop limits (a: 3 same issue, b: 3 cross-iteration, c: 5 different, d: 10 total) |
| LPD-P1-02 | loop-detection.md | Circular pattern response — mandatory exit sequence |
| ACT-P1-12 | activity-format.md | Activity.md update requirements — attempt headers, handoff records |
| RUL-P1-01 | rules-lookup.md | Hierarchical RULES.md discovery — walk directory tree |
| RUL-P1-02 | rules-lookup.md | Document applied rules in activity.md |

### P2/P3 Rules (Should/Guidance)

| Rule ID | File | One-Line Summary |
|---------|------|-----------------|
| CTX-P2-01 | context-check.md | Context pressure warning signs (measurable indicators) |
| CTX-P2-02 | context-check.md | Repeated context limit pattern — signal task decomposition |
| CTX-P3-01 | context-check.md | Token cost estimation guidelines |
| HOF-P2-01 | handoff.md | Handoff best practices (DOs and DON'Ts) |
| TDD-P2-01 | tdd-phases.md | TDD stop conditions (context, handoff, loops, dependencies) |
| LPD-P2-01 | loop-detection.md | Early warning signs for loops |

---

## Compliance Checkpoints

| Checkpoint ID | File | Trigger | Items |
|--------------|------|---------|-------|
| SIG-CP-01 | signals.md | pre-response | 8 items — signal format validation |
| SEC-CP-01 | secrets.md | pre-write | 5 items — secrets scan before file writes |
| CTX-CP-01 | context-check.md | start-of-turn, pre-tool-call, pre-response | 6 items — context threshold monitoring |
| HOF-CP-01 | handoff.md | pre-handoff | 7 items — handoff limit and format validation |
| TDD-CP-01 | tdd-phases.md | pre-response | 4 items per role — SOD and phase compliance |
| DEP-CP-01 | dependency.md | start-of-turn | 5 items — dependency and circular detection |
| LPD-CP-01 | loop-detection.md | error-handling, pre-retry | 6 items — loop limit checks |
| ACT-CP-01 | activity-format.md | pre-response | 5 items — activity.md completeness |
| RUL-CP-01 | rules-lookup.md | reference (new directory) | 6 items — RULES.md discovery verification |

---

## Validators (Regex)

| Validator ID | File | Pattern |
|-------------|------|---------|
| SIG-REGEX | signals.md | `^(TASK_COMPLETE_\d{4}\|TASK_INCOMPLETE_\d{4}(...)\|TASK_FAILED_\d{4}:.+\|TASK_BLOCKED_\d{4}:.+\|ALL_TASKS_COMPLETE, EXIT LOOP)$` |
| HOF-SIG-REGEX | handoff.md | `^TASK_INCOMPLETE_\d{4}:handoff_to:[a-z-]+:see_activity_md$` |
| TDD-PHASE-REGEX | signals.md | `^HANDOFF_(READY_FOR_DEV\|READY_FOR_TEST\|READY_FOR_TEST_REFACTOR\|DEFECT_FOUND)_\d{4}$` |

**Note**: SIG-REGEX is the authoritative validator for TASK_* signals. See signals.md for the complete regex. HOF-SIG-REGEX is a subset for handoff-specific validation. TDD-PHASE-REGEX is for Manager parsing of Worker TDD signals only.

---

## Cross-File Dependencies

| Source File | References | Dependency Type |
|------------|-----------|----------------|
| signals.md | handoff.md, tdd-phases.md | Signal format is consumed by handoff and TDD workflows |
| handoff.md | signals.md, activity-format.md, tdd-phases.md, loop-detection.md | Handoff process requires signal format, activity logging, TDD phases |
| tdd-phases.md | signals.md, handoff.md, context-check.md, activity-format.md | TDD phases use signals, handoffs, context limits, activity logging |
| context-check.md | signals.md, activity-format.md, handoff.md, loop-detection.md | Context management triggers signals, activity updates, handoffs |
| dependency.md | signals.md, activity-format.md, loop-detection.md, handoff.md | Dependency detection emits signals, updates activity, may trigger loops |
| loop-detection.md | signals.md, activity-format.md, dependency.md, handoff.md, context-check.md | Loop detection emits signals, updates activity, relates to deps and handoffs |
| activity-format.md | signals.md, handoff.md, context-check.md | Activity format must align with signal types and handoff states |
| secrets.md | signals.md, activity-format.md | Secrets violations emit signals and are documented in activity |
| rules-lookup.md | activity-format.md, signals.md | Rules discovery documented in activity, may affect signal choice |

---

## Priority Precedence (Universal)

All shared files follow this tie-break order (defined canonically in activity-format.md):

1. **P0** Safety & forbidden actions
2. **P0** Output format & validators
3. **P1** Workflow/state-machine steps
4. **P2/P3** Style guidance

If a lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## Trigger-Based Checkpoint Schedule

| Trigger Point | Checkpoints to Run |
|---------------|-------------------|
| **Start of Turn** | CTX-CP-01, DEP-CP-01, RUL-CP-01 (if new directory) |
| **Pre-Tool-Call** | CTX-CP-01, SEC-CP-01 (if writing), LPD-CP-01 (if retrying) |
| **Pre-Handoff** | HOF-CP-01 |
| **Pre-Response** | SIG-CP-01, ACT-CP-01, TDD-CP-01 (if TDD workflow), CTX-CP-01 |
| **Error Handling** | LPD-CP-01 |
