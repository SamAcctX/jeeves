# System Prompt Compliance Skill

## Overview

Enforces system prompt compliance at defined checkpoints across all Ralph Loop agents. Covers TODO tool usage, mid-process activity logging, signal format verification, state file reads, and rationalization defense integration.

## Purpose

Provides a single-invocation compliance checklist that agents memorize and apply throughout their session. Addresses three key failure modes:
1. Agents not tracking work via TODO tools
2. Worker sessions with 50+ tool calls and no activity.md updates until the end
3. Agents rationalizing their way past P0 rules

## Key Features

### 1. TODO Tool Usage (Mandatory)
- Initialize TODO list at task start
- Update on every work item transition
- Review every 10 tool calls
- Verify completeness before signal emission

### 2. Mid-Process Activity Logging (Mandatory for Workers)
- Log progress checkpoints every 15-20 tool calls
- Log after each major milestone
- Log on any error or unexpected result
- Prevents blind spots in long-running sessions

### 3. Signal Format Verification (P0)
- First-token discipline
- 4-digit task ID
- Canonical regex validation
- Single-signal enforcement

### 4. Pre-Signal Compliance Gate
- TODO list review
- Activity.md verification
- Signal format check
- Role boundary check
- Rationalization defense (links to rationalization-defense skill)

### 5. Periodic Reinforcement
- Every ~15 tool calls
- Role boundary check
- TODO currency
- Activity.md freshness
- Context usage
- Tool loop detection

## Changes from v1.0.0

| v1.0.0 | v2.0.0 |
|--------|--------|
| Fake alarm warning at prompt start | Removed (did not improve compliance) |
| skills-discovery check | Removed (not used in practice) |
| Signal format only | Full TODO + activity logging + signal + rationalization |
| No periodic reinforcement | Reinforcement every 15 tool calls |
| No mid-process logging | Mandatory progress checkpoints |

## Usage

Invoke once at session start:
```
skill system-prompt-compliance
```

Then apply from memory for the rest of the session. Pair with:
```
skill rationalization-defense
```

## File Structure

```
jeeves/Ralph/skills/system-prompt-compliance/
├── SKILL.md    # Skill content and metadata
└── README.md   # This file
```

## Version History

- **2.0.0** - Major rewrite: removed alarm and skills-discovery, added TODO enforcement, mid-process activity logging, periodic reinforcement, rationalization defense integration
- **1.0.0** - Initial release with compliance checklist
