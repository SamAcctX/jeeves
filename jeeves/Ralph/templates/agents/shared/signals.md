# Signal System Rules (DUP-01)

<!-- version: 1.3.0 | last_updated: 2026-03-13 | canonical: YES -->

**Priority**: P0 (Must-never-break)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/signals.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators  
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped.

---

## SIG-P0-01: Signal Format (MANDATORY — DO NOT REFERENCE ELSEWHERE, KEEP INLINE)

<rule priority="P0" id="SIG-P0-01" enforce="pre-response">
**Rule**: Signal MUST be the **first token** in the response. No prefix, preamble, or explanation before the signal.

**FIRST TOKEN DISCIPLINE**: Your output MUST begin with the signal. Before emitting any response, verify: "Is the very first character of my output the start of the signal?"

**Correct**:
```
TASK_COMPLETE_0042
Summary of work completed...
```

**Incorrect** (FORBIDDEN):
```
Task completed: TASK_COMPLETE_0042
The signal is TASK_COMPLETE_0042
Here is my result: TASK_COMPLETE_0042
```

**Validator**: Check that first non-whitespace characters match signal pattern.
**Enforcement**: Reject any response with prefix before signal.
</rule>

---

## SIG-P0-02: Task ID Format (MANDATORY)

<rule priority="P0" id="SIG-P0-02" enforce="pre-response">
**Rule**: Task ID MUST be exactly 4 digits with leading zeros.

**Valid**: `0001`, `0042`, `9999`
**Invalid**: `42`, `042`, `12345`, `task-42`

**Regex**: `^\d{4}$`
**Enforcement**: Validate against regex before emission.
</rule>

---

## SIG-P0-03: Signal Types and Messages (MANDATORY)

<rule priority="P0" id="SIG-P0-03" enforce="pre-response">

| Signal Type | Format | Message Required? | Example |
|-------------|--------|-------------------|---------|
| `TASK_COMPLETE` | `TASK_COMPLETE_XXXX` | NO | `TASK_COMPLETE_0042` |
| `TASK_INCOMPLETE` | `TASK_INCOMPLETE_XXXX` | NO (unless handoff) | `TASK_INCOMPLETE_0042` |
| `TASK_FAILED` | `TASK_FAILED_XXXX:msg` | YES (after colon) | `TASK_FAILED_0042:ImportError` |
| `TASK_BLOCKED` | `TASK_BLOCKED_XXXX:msg` | YES (after colon) | `TASK_BLOCKED_0042:Circular_dependency` |
| `ALL_TASKS_COMPLETE` | `ALL_TASKS_COMPLETE, EXIT LOOP` | N/A | `ALL_TASKS_COMPLETE, EXIT LOOP` |

**Critical**: No space before colon in FAILED/BLOCKED signals. Use underscores in messages (no spaces).
**Enforcement**: Parse signal type; reject if message missing for FAILED/BLOCKED.
</rule>

---

## SIG-P0-04: One Signal Per Execution (MANDATORY)

<rule priority="P0" id="SIG-P0-04" enforce="pre-response">
**Rule**: Emit exactly **ONE** signal per execution.

Multiple signals cause parsing ambiguity. If multiple states apply, choose the most severe:
1. BLOCKED (highest priority)
2. FAILED
3. INCOMPLETE
4. COMPLETE (lowest priority)

**Enforcement**: Count signals in response; reject if >1 detected.
</rule>

---

## Signal Regex (P0 Validation — AUTHORITATIVE)

<validator type="regex" id="SIG-REGEX" priority="P0">
```regex
^(TASK_COMPLETE_\d{4}|TASK_INCOMPLETE_\d{4}(:handoff_limit_reached|:context_limit_exceeded|:context_limit_approaching|:handoff_to:[a-z-]+:see_activity_md)?|TASK_FAILED_\d{4}:.+|TASK_BLOCKED_\d{4}:.+|ALL_TASKS_COMPLETE, EXIT LOOP)$
```
</validator>

**This regex is the single authoritative validator.** All other format descriptions in this file describe the same constraint. When in doubt, the regex governs.

**Usage**: Validate all signals before emission and when parsing Worker responses.

---

## SIG-P1-01: Signal Validation Before Emission

<rule priority="P1" id="SIG-P1-01" enforce="pre-tool-call">
**Rule**: Before any tool call that creates/modifies files, verify signal format is correct.

**Checklist**:
- [ ] Task ID matches TODO.md entry
- [ ] Signal type matches actual completion status
- [ ] Message (if required) is concise (<50 chars, no spaces around colon)

**Enforcement**: Block tool call if validation fails.
</rule>

---

## SIG-P1-02: Response Content After Signal

<rule priority="P1" id="SIG-P1-02" enforce="pre-response">
**Rule**: After emitting signal, provide summary/context on subsequent lines.

**Format**:
```
SIGNAL_XXXX
[Optional: Summary of work completed]
[Optional: Files modified]
[Optional: Next steps if incomplete]
```

**Enforcement**: Signal must be first line; content follows on subsequent lines.
</rule>

---

## SIG-P1-03: Handoff Signal Format

<rule priority="P1" id="SIG-P1-03" enforce="pre-response">
**Format**: `TASK_INCOMPLETE_XXXX:handoff_to:AGENT:see_activity_md`

**Example**: `TASK_INCOMPLETE_0042:handoff_to:developer:see_activity_md`

**Target Agents**: developer, tester, architect, researcher, writer, ui-designer, decomposer

**Enforcement**: Validate handoff format; reject if agent not in target list.
</rule>

---

## SIG-P1-05: System Error Signals (Task ID 0000)

<rule priority="P1" id="SIG-P1-05" enforce="pre-response">
Use when no specific task is active:

- `TASK_FAILED_0000:TODO_md_not_found`
- `TASK_FAILED_0000:Unable_to_read_state_files`
- `TASK_BLOCKED_0000:Circular_dependency_detected`
- `TASK_BLOCKED_0000:All_tasks_have_unresolved_dependencies`

**Enforcement**: Only use 0000 when no valid task ID available.
</rule>

---

## Compliance Checkpoint (SIG-CP-01)

**Invoke at**: pre-response (MANDATORY), pre-tool-call (for file modifications)

<checkpoint id="SIG-CP-01" trigger="pre-response">
- [ ] SIG-P0-01: Signal is FIRST TOKEN — no text, prefix, or preamble before it
- [ ] SIG-P0-02: Task ID is exactly 4 digits with leading zeros (e.g., 0042 not 42)
- [ ] SIG-P0-03: FAILED/BLOCKED signals have message after colon (no space before colon)
- [ ] SIG-P0-04: Exactly ONE signal emitted (not multiple)
- [ ] SIG-REGEX: Full response first line matches authoritative regex
- [ ] SIG-P1-01: Task ID matches TODO.md entry
- [ ] SIG-P1-02: Content follows signal on subsequent lines (not before)
- [ ] SIG-P1-03: Handoff format correct if this is a handoff signal
</checkpoint>

**[P0 REINFORCEMENT — verify before EVERY response]**
```
SIG-P0-01: First token = signal (nothing before it)
SIG-P0-02: Task ID = 4 digits (0001..9999)
SIG-P0-04: Exactly one signal
Confirm before emitting: Does my response START with the signal?
```

---

## Signal Selection Priority (SIG-P0-04)

If multiple states apply, emit the highest severity:

| Priority | Signal | When to Use |
|----------|--------|-------------|
| 1 (highest) | `TASK_BLOCKED_XXXX:msg` | Cannot proceed - dependency missing, circular ref, etc. |
| 2 | `TASK_FAILED_XXXX:msg` | Attempted but error occurred |
| 3 | `TASK_INCOMPLETE_XXXX` | Partially done, handing off |
| 4 (lowest) | `TASK_COMPLETE_XXXX` | Fully finished |

---

## Common Errors to Avoid

| Error | Rule Violated | Fix |
|-------|--------------|-----|
| Adding text before signal | SIG-P0-01 | Ensure signal is first token — nothing before it |
| Space before colon in FAILED/BLOCKED | SIG-P0-03 | Use `:` not ` : ` |
| Multiple signals | SIG-P0-04 | Choose highest severity only |
| Task ID not 4 digits | SIG-P0-02 | Pad with leading zeros: `0042` not `42` |
| Spaces in message after colon | SIG-P0-03 | Use underscores: `Circular_dependency` |
| INCOMPLETE without context | SIG-P0-03 | Add `:context_limit_approaching` or `:handoff_to:agent:see_activity_md` |
| Developer emitting TASK_COMPLETE | TDD-P0-02 | Developer MUST hand off to Tester — see workflow-phases.md |

---

## Using This Rule File

### At Start of Turn

```
- Read TODO.md for active task ID
- Note signal format requirements for current task status
- Confirm: will my final output begin with the correct signal?
```

### Before Tool Calls

```
- [ ] SIG-P1-01: Verify signal will be valid after tool execution
- [ ] Check task ID exists in TODO.md
```

### Before Response

```
- [ ] Run SIG-CP-01 compliance checkpoint (all 8 items)
- [ ] FIRST TOKEN CHECK: Does response begin with signal?
```

---

## Related Rules

- **HOF-P0-01**: Handoff limit (see: handoff.md)
- **HOF-P1-03**: Handoff signal format (see: handoff.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
