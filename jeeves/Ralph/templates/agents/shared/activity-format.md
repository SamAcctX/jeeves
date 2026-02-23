# Activity.md Format (DUP-09)

**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/activity-format.md`

---

## Rule ID: ACT-P1-12

### Activity.md Update Requirements

**Location**: `.ralph/tasks/{id}/activity.md`

<rule id="ACT-P1-12" priority="P1" scope="universal" trigger="start_of_turn">
  <requirement>At start: Document current attempt</requirement>
  <requirement>During work: Log progress and decisions</requirement>
  <requirement>Before handoff: Create handoff record</requirement>
  <requirement>Before signal: Document results</requirement>
  <enforcement>
    <checkpoint trigger="pre_response">
      - [ ] ACT-P1-12: activity.md updated with results
      - [ ] Handoff documented (if applicable)
      - [ ] State consistent with signal
    </checkpoint>
  </enforcement>
</rule>

---

## Standard Sections

### Attempt Header
```markdown
## Attempt {N} [{timestamp}]
Iteration: {number}
Status: {in_progress|completed|blocked}
```

### Work Completed
```markdown
### Work Completed
- [item 1]
- [item 2]
```

### Handoff Record
```markdown
### Handoff Record
**From**: {agent}
**To**: {agent}
**State**: {state}
**Context**: [summary]
```

### Context Resumption Checkpoint
```markdown
### Context Resumption Checkpoint
**Work Completed**: [summary]
**Work Remaining**: [what's left]
**Files In Progress**: [list]
**Next Steps**: [ordered list]
**Critical Context**: [key state]
```

---

## Priority Definitions

| Priority | Description | Examples |
|----------|-------------|----------|
| P0 | Must-never-break (safety, format validators) | Signal format, forbidden actions |
| P1 | Must-follow (workflow gates) | Activity.md updates, handoff rules |
| P2 | Should (best practices) | Detailed logging, context summaries |
| P3 | Guidance (tone, optional) | Style preferences |

---

## Compliance Checkpoint

**Invoke at**: pre-response

<validator type="checkpoint" trigger="pre_response">
  - [ ] ACT-P1-12: activity.md updated with results
  - [ ] Handoff documented (if applicable)
  - [ ] State consistent with signal
</validator>

---

## Using This Rule File

### TODO Integration Guidance

Use the following TODO checkpoints when working with activity.md:

#### At Start of Turn
- [ ] Check ACT-P1-12: Verify activity.md exists for current task
- [ ] Review previous attempt status before starting work
- [ ] Verify context resumption checkpoint if resuming

#### Before Tool Calls
- [ ] Log current progress to activity.md before long-running operations
- [ ] Update status to "in_progress" when starting significant work

#### Before Response
- [ ] Run ACT-P1-12 compliance checkpoint
- [ ] Verify handoff record complete if transferring to another agent
- [ ] Ensure signal readiness (document results per ACT-P1-12)

### Example TODO Items for Activity.md Updates

```
TODO: Update activity.md with attempt {N} header
TODO: Log work completed to activity.md
TODO: Create handoff record before transferring
TODO: Document results before sending signal
TODO: Verify context resumption checkpoint completeness
TODO: Validate activity.md state matches signal output
```

### Drift Prevention

- **Trigger**: Every pre-response checkpoint
- **Check**: ACT-P1-12 compliance list
- **Fail condition**: Missing required sections or incomplete handoff
- **Recovery**: Prompt for missing documentation before proceeding

---

## Related Rules

- **SIG-P0-01**: Signal format (see: signals.md)
- **HOF-P1-03**: Handoff process (see: handoff.md)
- **CTX-P1-02**: Context resumption protocol (see: context-check.md)
