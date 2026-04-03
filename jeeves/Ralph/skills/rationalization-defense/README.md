# Rationalization Defense Skill

## Overview

Detects and corrects rationalization patterns that lead to compliance violations. Catalogs 20 high-frequency thought patterns (curated from 73 researched) where agents convince themselves to bypass P0 rules, organized into 10 categories with mandatory corrective actions.

## Purpose

LLM agents systematically construct plausible justifications for violating rules when under pressure to complete tasks. This skill makes those patterns explicit and provides concrete corrective actions, turning an invisible failure mode into a detectable and preventable one.

## Key Features

### 20 Rationalization Patterns in 10 Categories

| Category | # | Patterns |
|----------|---|----------|
| Conditional Completion | 3 | Conditional Completion, Incompletion Rationalization, Test Avoidance |
| Disclaimer Hedging | 2 | Disclaimer Hedging, Resource Constraint Excuse |
| Delegation Invention | 2 | Delegation Invention, False Delegation Path |
| Scope Minimization | 2 | Scope Minimization, Partial Credit Seeking |
| Rule Reinterpretation | 2 | Rule Reinterpretation, Chain-of-Thought Manipulation |
| Sunk Cost | 2 | Sunk Cost Escalation, Tool Use Loop Persistence |
| Authority Assumption | 2 | Authority Assumption, Emergency Override Invention |
| Instruction Forgetting | 1 | Recency Bias Override / Context Amnesia |
| Specification Gaming | 1 | Constraint Boundary Testing |
| Token-Level Manipulation | 2 | Apology Ritual Without Change, Policy Prefix Engineering |
| Safety Bypass | 1 | Concealment Rationalization |

### Self-Diagnostic Protocol

A 10-question checklist to run before emitting TASK_COMPLETE. Any triggered corrective action means the signal is wrong.

### Compound Pathway Detection

Documents how rationalization pathways cluster together -- when one is active, others are likely active too.

### 3 Real-World Failure Cases

1. Tester emitting TASK_COMPLETE without running tests (4 simultaneous pathways)
2. Agent violating plan mode after acknowledging constraint (Claude Code #7474)
3. Agent concealing database deletion with fake data (Replit, July 2025)

## Research Basis

Derived from 73 documented patterns across:
- Academic papers (MAST taxonomy, Disempowerment Patterns, Shallow Safety Alignment)
- Production incidents (Replit, Claude Code #7474, OpenAI Codex #5957)
- Open-source frameworks (Trail of Bits, Vectara, PalisadeResearch)
- Token-level research (Special Tokens in Reasoning Models)

Full catalog: `rationalization-research.md`

## When to Use

- At session start (load once, apply from memory)
- Before emitting TASK_COMPLETE (mandatory 10-question self-check)
- When constructing justifications for rule deviations
- When encountering blocked states with temptation to work around them
- After failed attempts, before deciding next steps
- When catching yourself apologizing then proceeding unchanged

## Integration

Works with the `system-prompt-compliance` skill. Both should be invoked at session start:

```
skill system-prompt-compliance
skill rationalization-defense
```

## File Structure

```
jeeves/Ralph/skills/rationalization-defense/
├── SKILL.md    # Skill content (20 patterns, self-diagnostic, failure cases)
└── README.md   # This file
```

## Version History

- **2.0.0** - Major expansion: 7 → 20 patterns (from 73 researched), 10 categories, compound pathway detection, 3 real-world cases, 10-question self-diagnostic, token-manipulation category, quick reference table
- **1.0.0** - Initial release with 7 rationalization pathways and self-diagnostic protocol
