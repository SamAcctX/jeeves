---
name: system-prompt-compliance
description: Verify requirements before subagent invocations and tool calls. Ensures CRITICAL WARNING inclusion, skill checks, state file reads, and signal format correctness. Use before: Task tool invocation, delegating work to agents, responding to user, starting thoughts, making any tool call.
license: MIT
metadata:
  version: "1.0.0"
  author: Ralph Loop Team
---

# Compliance Checklist

**IMPORTANT**: After first invocation in a session, MEMORIZE this checklist. Do NOT re-invoke this skill repeatedly - simply apply the checklist from memory for subsequent actions.

Before any action, verify:

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