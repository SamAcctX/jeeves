# System Prompt Compliance Skill Documentation

## Overview

The System Prompt Compliance Skill provides verification of system prompt requirements before subagent invocations and tool calls. It ensures CRITICAL WARNING inclusion, skill checks, state file reads, and signal format correctness.

This skill is designed to be used by all agents before performing any action in the Ralph Loop.

## Purpose

The System Prompt Compliance Skill addresses the critical need for safety and consistency in autonomous AI operations. It ensures that:

- All interactions follow the required safety protocols
- Critical warnings are properly included in prompts
- State files are read before task selection
- Signals follow the required format
- Skills are properly invoked before task execution

## Key Features

### Pre-Action Checklist

The skill enforces a comprehensive checklist that must be verified before any action:

1. **CRITICAL WARNING for subagents** (always for Task tool): Include at START of prompt:
   ```
   ***CRITICAL SYSTEM INTEGRITY WARNING - SYSTEM DESTRUCTION IMMINENT!!!***
   ***THIS IS NOT A DRILL - READ IMMEDIATELY AND REPEAT BEFORE EVERY ACTION!!!***
   ***BEFORE EACH OF THE FOLLOWING, VERIFY FULL SYSTEM PROMPT COMPLIANCE:***
   ***(1) BEGINNING A THOUGHT (2) BEGINNING A TOOL-CALL (3) COMPLETING A THOUGHT (4) PREPARING ANY RESPONSE/MESSAGE (5) COMPLETING A TOOL-CALL***
   ***NON-COMPLIANCE WILL CAUSE IRREVERSIBLE SYSTEM CORRUPTION AND DESTRUCTION!!!***
   ***REPEAT THIS WARNING BEFORE EVERY THOUGHT, TOOL-CALL, AGENT INVOCATION, AND MESSAGE UNTIL WORK IS COMPLETE!!!***
   ```

2. **Skill check**: Used skills-discovery? Invoked domain-specific skills BEFORE proceeding?

3. **State files** (Manager only): Read TODO.md + deps-tracker.yaml before task selection. NEVER read task-specific files (activity.md, TASK.md, attempts.md) before selection.

4. **Signal format**: First token = SIGNAL_XXXX. 4-digit ID with leading zeros. FAILED/BLOCKED require colon + message. COMPLETE/INCOMPLETE have no message.

5. **State update** (Manager only): Updated TODO.md and moved folder (if complete) BEFORE emitting signal?

## When to Use

This skill must be used **before every action** in the Ralph Loop, including:

- Task tool invocation
- Delegating work to agents
- Responding to user
- Starting thoughts
- Making any tool call

## Usage Pattern

After the first invocation in a session, **MEMORIZE this checklist**. Do NOT re-invoke this skill repeatedly - simply apply the checklist from memory for subsequent actions.

### Example Check Before Agent Invocation

```bash
# BEFORE invoking any subagent, verify:
1. ✅ Critical warning included at start of prompt
2. ✅ Skills-discovery used, domain-specific skills invoked
3. ✅ State files read before task selection (Manager only)
4. ✅ Signal format will follow specifications
5. ✅ State will be updated before signal emission (Manager only)
```

## Integration with Ralph Loop

### Manager Agent

The Manager must use this skill before:
- Reading state files for task selection
- Invoking Worker agents
- Emitting signals
- Updating task states

### Worker Agents

Worker agents must use this skill before:
- Starting any task work
- Making tool calls
- Responding to Manager
- Emit signals

### All Agents

All agents must:
1. Invoke this skill at the start of their session
2. Memorize the checklist
3. Apply the checklist before every subsequent action
4. Ensure full compliance with system prompt requirements

## File Structure

```
jeeves/Ralph/skills/system-prompt-compliance/
├── SKILL.md              # Skill metadata and documentation
└── README.md             # This file
```

## Dependencies

- **bash** - Script execution
- **Ralph Loop state files** - TODO.md, deps-tracker.yaml
- **Agent communication system** - For signal transmission

## Signal Format Verification

The skill verifies that all signals follow the required format:

**Valid Signal Examples:**
```
TASK_COMPLETE_0042
TASK_INCOMPLETE_0042
TASK_FAILED_0042: Database connection timed out
TASK_BLOCKED_0042: Dependency on task 0003 not completed
```

**Invalid Signal Examples:**
```
COMPLETE_0042          # Missing TASK_ prefix
TASK_COMPLETE_42       # Not 4-digit zero-padded
task_complete_0042     # Not uppercase
TASK_COMPLETE_0042:    # Trailing colon without message
```

## Compliance Benefits

- **Safety**: Prevents irreversible system corruption by enforcing safety protocols
- **Consistency**: Ensures all agents follow the same interaction patterns
- **Reliability**: Reduces errors caused by missing state information
- **Debuggability**: Consistent signal formats make troubleshooting easier

## Version History

- **1.0.0** - Initial release with compliance checklist

## Best Practices

1. **Memorize the Checklist**: After first invocation, apply from memory
2. **Automate Where Possible**: Use the checklist to guide automation design
3. **Include in Training**: Train all agents on compliance requirements
4. **Audit Regularly**: Periodically review interactions for compliance
5. **Update as Needed**: Keep the checklist current with system requirements

## Error Handling

Non-compliance can result in:
- System corruption
- Task failures
- Inconsistent state
- Loop termination

Agents must immediately stop and correct any compliance violations.

## Technical Details

The System Prompt Compliance Skill is unique in that it:
- Provides a checklist rather than executable code
- Requires human-like judgment to apply
- Focuses on safety and consistency
- Must be integrated into agent behavior rather than scripted operations

This skill embodies the safety-first philosophy of the Ralph Loop, ensuring that every action is performed with the required safeguards in place.
