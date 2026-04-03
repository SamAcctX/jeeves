# Activity.md Format (DUP-09)

<!-- version: 1.3.0 | last_updated: 2026-03-13 | canonical: YES -->

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/activity-format.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## Priority Definitions (CANONICAL — Referenced by all shared files)

| Priority | Description | Examples |
|----------|-------------|----------|
| P0 | Must-never-break (safety, format validators, forbidden actions) | Signal format, secrets prohibition, context hard stop |
| P1 | Must-follow (workflow gates, required steps) | Activity.md updates, handoff rules, dependency checks |
| P2 | Should (best practices, quality improvements) | Detailed logging, context summaries |
| P3 | Guidance (tone, optional advice) | Style preferences, estimation guidelines |

---

## ACT-P1-12: Activity.md Update Requirements

**Location**: `.ralph/tasks/{id}/activity.md`

<rule id="ACT-P1-12" priority="P1" scope="universal" trigger="start-of-turn">
  <requirement>At start: Document current attempt header</requirement>
  <requirement>During work: Log progress and key decisions</requirement>
  <requirement>Before handoff: Create handoff record</requirement>
  <requirement>Before signal: Document results</requirement>
  <enforcement>
    <checkpoint trigger="pre_response">
      - [ ] ACT-P1-12: activity.md updated with results
      - [ ] Handoff documented (if applicable)
      - [ ] State consistent with signal being emitted
    </checkpoint>
  </enforcement>
</rule>

---

## Standard Sections

### Attempt Header (MANDATORY — every attempt must start with this)

```markdown
## Attempt {N} [{timestamp}]
Iteration: {number}
Status: {in_progress|completed|blocked|failed}
```

**Field Requirements**:
| Field | Required | Valid Values |
|-------|----------|-------------|
| N | YES | Integer, 1-indexed, monotonically increasing |
| timestamp | YES | ISO 8601 or human-readable timestamp |
| Iteration | YES | Integer matching current iteration count |
| Status | YES | `in_progress`, `completed`, `blocked`, `failed` |

**Status must match signal**: `completed` → TASK_COMPLETE, `blocked` → TASK_BLOCKED, `failed` → TASK_FAILED, `in_progress` → work ongoing or TASK_INCOMPLETE.

### Work Completed (MANDATORY — log all work done)

```markdown
### Work Completed
- [item 1]
- [item 2]
```

**Requirement**: At least one bullet item. Empty "Work Completed" sections are a compliance violation — if no work was done, state why (e.g., "Blocked by dependency YYYY").

### Handoff Record (MANDATORY when transferring to another agent)

```markdown
### Handoff Record
**From**: {agent}
**To**: {agent}
**State**: {state}
**Context**: [summary]
```

**Field Requirements**:
| Field | Required | Valid Values |
|-------|----------|-------------|
| From | YES | Current agent role (developer, tester, architect, etc.) |
| To | YES | Target agent role (must be in valid agent list per HOF-P1-02) |
| State | YES | `READY_FOR_REVIEW`, `READY_FOR_FINAL_REVIEW`, `DEFECT_FOUND`, `REVIEW_COMPLETE` |
| Context | YES | Non-empty summary of work done and what remains |

### Context Resumption Checkpoint (MANDATORY when context >80%)

```markdown
### Context Resumption Checkpoint
**Work Completed**: [summary]
**Work Remaining**: [what's left]
**Files In Progress**: [list]
**Next Steps**: [ordered list]
**Critical Context**: [key state]
```

**Field Requirements**: All 5 fields are MANDATORY. An incomplete checkpoint prevents proper resumption. See CTX-P1-02 in context-check.md for protocol details.

---

## Compliance Checkpoint (ACT-CP-01)

**Invoke at**: pre-response

<checkpoint id="ACT-CP-01" trigger="pre_response">
- [ ] ACT-P1-12: activity.md updated with results for this attempt
- [ ] ACT-P1-12: Attempt header present with timestamp and status
- [ ] Handoff record documented (if transferring to another agent)
- [ ] Context resumption checkpoint included (if context >80%)
- [ ] State in activity.md is consistent with the signal being emitted
</checkpoint>

---

## Using This Rule File

### TODO Items for Activity.md Updates

```
TODO: Update activity.md with attempt {N} header
TODO: Log work completed to activity.md
TODO: Create handoff record before transferring
TODO: Document results before sending signal
TODO: Verify context resumption checkpoint completeness (if >80% context)
TODO: Validate activity.md state matches signal output
```

### At Start of Turn

- [ ] Check ACT-P1-12: Verify activity.md exists for current task
- [ ] Review previous attempt status before starting work
- [ ] Verify context resumption checkpoint if resuming after context limit

### Before Tool Calls

- [ ] Log current progress to activity.md before long-running operations
- [ ] Update status to "in_progress" when starting significant work

### Before Response

- [ ] Run ACT-CP-01 compliance checkpoint (all 5 items)
- [ ] Verify handoff record complete if transferring to another agent
- [ ] Ensure signal readiness (document results per ACT-P1-12)

### Drift Prevention

| Trigger | Check | Fail Condition | Recovery |
|---------|-------|----------------|----------|
| Every pre-response | ACT-CP-01 | Missing required sections or incomplete handoff | Prompt for missing documentation before proceeding |
| Every handoff | Handoff record | No handoff record in activity.md | Create handoff record before signaling |
| After context >80% | Context resumption checkpoint | Missing checkpoint | Create checkpoint immediately |

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **HOF-P1-03**: Handoff process (see: handoff.md)
- **CTX-P1-02**: Context resumption protocol (see: context-check.md)
