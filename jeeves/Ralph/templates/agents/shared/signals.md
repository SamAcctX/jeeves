# Signal System Rules (DUP-01)

**Priority**: P0 (Must-never-break)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/signals.md`

---

## SIG-P0-01: Signal Format (MANDATORY)

<rule priority="P0" id="SIG-P0-01" enforce="pre-response">
**Rule**: Signal MUST be the **first token** in the response.

**Correct**:
```
TASK_COMPLETE_0042
Summary of work completed...
```

**Incorrect**:
```
Task completed: TASK_COMPLETE_0042
The signal is TASK_COMPLETE_0042
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

**Critical**: No space before colon in FAILED/BLOCKED signals. Use underscores in messages.
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

## SIG-P1-04: TDD Phase Signals

<rule priority="P1" id="SIG-P1-04" enforce="parsing">
| Phase | Signal Format | Next Agent |
|-------|---------------|------------|
| Ready for Dev | `HANDOFF_READY_FOR_DEV_XXXX` | Developer |
| Ready for Test | `HANDOFF_READY_FOR_TEST_XXXX` | Tester |
| Ready for Refactor | `HANDOFF_READY_FOR_TEST_REFACTOR_XXXX` | Tester |
| Defect Found | `HANDOFF_DEFECT_FOUND_XXXX` | Developer |

**Note**: TDD phase signals are parsed from Worker responses, not emitted as output signals.
**Enforcement**: Parse incoming Worker responses for these patterns.
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

## Signal Regex (P0 Validation)

<validator type="regex" id="SIG-REGEX">
```regex
^(TASK_COMPLETE_\d{4}|TASK_INCOMPLETE_\d{4}(:handoff_limit_reached|:handoff_to:\w+:.+)?|TASK_FAILED_\d{4}:.+|TASK_BLOCKED_\d{4}:.+|ALL_TASKS_COMPLETE, EXIT LOOP)$
```
</validator>

**Usage**: Validate all signals before emission and when parsing Worker responses.

---

## Compliance Checkpoint

<trigger when="pre-response">
<checkpoint id="SIG-CP-01">
- [ ] SIG-P0-01: Signal is first token (no prefix)
- [ ] SIG-P0-02: Task ID is 4 digits with leading zeros
- [ ] SIG-P0-03: FAILED/BLOCKED have message after colon (no space before colon)
- [ ] SIG-P0-04: Only one signal emitted
- [ ] SIG-P1-01: Task ID matches TODO.md entry
- [ ] SIG-P1-02: Content follows signal on subsequent lines
- [ ] SIG-P1-03: Handoff format correct (if applicable)
</checkpoint>
</trigger>

---

## Using This Rule File

<integration_guide>

### At Start of Turn

```
- Read TODO.md for active task ID
- Note signal format requirements for current task status
```

### Before Tool Calls

```
- [ ] SIG-P1-01: Verify signal will be valid after tool execution
- [ ] Check task ID exists in TODO.md
```

### Before Response

```
- [ ] Run SIG-CP-01 compliance checkpoint
- [ ] Verify SIG-P0-01: Signal is first token
- [ ] Verify SIG-P0-02: Task ID format (4 digits)
- [ ] Verify SIG-P0-03: Signal type correct with required message
- [ ] Verify SIG-P0-04: Exactly one signal
```

### Signal Selection Priority (SIG-P0-04)

If multiple states apply, emit the highest severity:

| Priority | Signal | When to Use |
|----------|--------|-------------|
| 1 (highest) | `TASK_BLOCKED_XXXX:msg` | Cannot proceed - dependency missing, circular ref, etc. |
| 2 | `TASK_FAILED_XXXX:msg` | Attempted but error occurred |
| 3 | `TASK_INCOMPLETE_XXXX` | Partially done, handing off |
| 4 (lowest) | `TASK_COMPLETE_XXXX` | Fully finished |

### Common Errors to Avoid

| Error | Fix |
|-------|-----|
| Adding text before signal | Ensure signal is first token |
| Space before colon in FAILED/BLOCKED | Use `:` not ` : ` |
| Multiple signals | Choose highest severity only |
| Task ID not 4 digits | Pad with leading zeros: `0042` |
| Spaces in message | Use underscores: `Circular_dependency` |

</integration_guide>

---

## Related Rules

- **HOF-P0-01**: Handoff limit (see: handoff.md)
- **HOF-P1-03**: Handoff signal format (see: handoff.md)
- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
