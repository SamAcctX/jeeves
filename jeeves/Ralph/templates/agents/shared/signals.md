# Signal System Rules (DUP-01)

**Priority**: P0 (Must-never-break)
**Scope**: Universal (all agents)
**Location**: `.prompt-optimizer/shared/signals.md`

---

## P0-01: Signal Format (MANDATORY)

<rule priority="P0" id="P0-01" enforce="pre-response">
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

## P0-02: Task ID Format (MANDATORY)

<rule priority="P0" id="P0-02" enforce="pre-response">
**Rule**: Task ID MUST be exactly 4 digits with leading zeros.

**Valid**: `0001`, `0042`, `9999`
**Invalid**: `42`, `042`, `12345`, `task-42`

**Regex**: `^\d{4}$`
**Enforcement**: Validate against regex before emission.
</rule>

---

## P0-03: Signal Types and Messages (MANDATORY)

<rule priority="P0" id="P0-03" enforce="pre-response">

| Signal Type | Format | Message Required? | Example |
|-------------|--------|-------------------|---------|
| `TASK_COMPLETE` | `TASK_COMPLETE_XXXX` | NO | `TASK_COMPLETE_0042` |
| `TASK_INCOMPLETE` | `TASK_INCOMPLETE_XXXX` | NO (unless handoff) | `TASK_INCOMPLETE_0042` |
| `TASK_FAILED` | `TASK_FAILED_XXXX:msg` | YES (after colon) | `TASK_FAILED_0042:ImportError` |
| `TASK_BLOCKED` | `TASK_BLOCKED_XXXX:msg` | YES (after colon) | `TASK_BLOCKED_0042:Circular dependency` |
| `ALL_TASKS_COMPLETE` | `ALL_TASKS_COMPLETE, EXIT LOOP` | N/A | `ALL_TASKS_COMPLETE, EXIT LOOP` |

**Critical**: No space before colon in FAILED/BLOCKED signals.
**Enforcement**: Parse signal type; reject if message missing for FAILED/BLOCKED.
</rule>

---

## P0-04: One Signal Per Execution (MANDATORY)

<rule priority="P0" id="P0-04" enforce="pre-response">
**Rule**: Emit exactly **ONE** signal per execution.

Multiple signals cause parsing ambiguity. If multiple states apply, choose the most severe:
1. BLOCKED (highest priority)
2. FAILED
3. INCOMPLETE
4. COMPLETE (lowest priority)

**Enforcement**: Count signals in response; reject if >1 detected.
</rule>

---

## P1-01: Signal Emission Timing

<rule priority="P1" id="P1-01" enforce="pre-response">
**Rule**: Signal MUST be emitted at the **end** of the response, after all content.

**Rationale**: Allows agent to provide context before signaling final state.
**Enforcement**: Verify signal appears as last non-empty line.
</rule>

---

## P1-02: Signal Validation Before Emission

<rule priority="P1" id="P1-02" enforce="pre-tool-call">
**Rule**: Before any tool call that creates/modifies files, verify signal format is correct.

**Checklist**:
- [ ] Task ID matches TODO.md entry
- [ ] Signal type matches actual completion status
- [ ] Message (if required) is concise (<50 chars)
**Enforcement**: Block tool call if validation fails.
</rule>

---

## P1-03: Response Content After Signal

<rule priority="P1" id="P1-03" enforce="pre-response">
**Rule**: After emitting signal, do NOT add additional content.

**Rationale**: Signal must be terminal. Additional content causes ambiguity.
**Enforcement**: Treat any text after signal as error.
</rule>

---

## P1-04: Handoff Signal Format

<rule priority="P1" id="P1-04" enforce="pre-response">
**Format**: `TASK_INCOMPLETE_XXXX:handoff_to:AGENT:see_activity_md`

**Example**: `TASK_INCOMPLETE_0042:handoff_to:developer:see_activity_md`

**Target Agents**: developer, tester, architect, researcher, writer, ui-designer, decomposer

**Enforcement**: Validate handoff format; reject if agent not in target list.
</rule>

---

## P1-05: TDD Phase Signals

<rule priority="P1" id="P1-05" enforce="parsing">
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

## P1-06: System Error Signals (Task ID 0000)

<rule priority="P1" id="P1-06" enforce="pre-response">
Use when no specific task is active:

- `TASK_FAILED_0000:TODO.md not found`
- `TASK_FAILED_0000:Unable to read state files`
- `TASK_BLOCKED_0000:Circular dependency detected: [chain]`
- `TASK_BLOCKED_0000:All tasks have unresolved dependencies`

**Enforcement**: Only use 0000 when no valid task ID available.
</rule>

---

## Signal Regex (P0 Validation)

<validator type="regex" id="SIGNAL-REGEX">
```regex
^(TASK_COMPLETE_\d{4}|TASK_INCOMPLETE_\d{4}(:handoff_limit_reached|:handoff_to:\w+:.+)?|TASK_FAILED_\d{4}:.+|TASK_BLOCKED_\d{4}:.+|ALL_TASKS_COMPLETE, EXIT LOOP)$
```
</validator>

**Usage**: Validate all signals before emission and when parsing Worker responses.

---

## Compliance Checkpoint

<trigger when="pre-response">
<checkpoint id="SIGNAL-CP-01">
- [ ] P0-01: Signal is first token (no prefix)
- [ ] P0-02: Task ID is 4 digits with leading zeros
- [ ] P0-03: FAILED/BLOCKED have message after colon (no space before colon)
- [ ] P0-04: Only one signal emitted
- [ ] P1-01: Signal is last line of response
- [ ] P1-03: No content after signal
- [ ] P1-04: Handoff format correct (if applicable)
</checkpoint>
</trigger>

---

## Using This Rule File

<integration_guide>

### TODO Integration

Add these items to your TODO at start of turn:

```
TODO:
- [ ] Check P0 signal format rules (P0-01 through P0-04)
- [ ] Verify task ID matches TODO.md before signaling
- [ ] Run compliance checkpoint before response
```

### At Start of Turn

```
- Read TODO.md for active task ID
- Note signal format requirements for current task status
```

### Before Tool Calls

```
- [ ] P1-02: Verify signal will be valid after tool execution
- [ ] Check task ID exists in TODO.md
```

### Before Response

```
- [ ] Run SIGNAL-CP-01 compliance checkpoint
- [ ] Verify P0-01: Signal is first token
- [ ] Verify P0-02: Task ID format (4 digits)
- [ ] Verify P0-03: Signal type correct with required message
- [ ] Verify P0-04: Exactly one signal
- [ ] Verify P1-01: Signal is last line
- [ ] Verify P1-03: No content after signal
```

### Signal Selection Priority (P0-04)

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
| Content after signal | Signal must be terminal |

</integration_guide>
