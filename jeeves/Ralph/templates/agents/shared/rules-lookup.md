# RULES.md Lookup (DUP-03)

<!-- version: 1.2.0 | last_updated: 2026-02-25 | canonical: YES -->

**File ID**: RUL-LOOKUP-01
**Priority**: P1 (Must-follow)
**Scope**: Universal (all agents)
**Location**: `jeeves/Ralph/templates/agents/shared/rules-lookup.md`

---

## Rule Precedence (Tie-break order)

1. P0 Safety & forbidden actions
2. P0 Output format & validators
3. P1 Workflow/state-machine steps
4. P2/P3 Style guidance

If any lower-priority rule conflicts with a higher-priority rule, the lower-priority rule is dropped. For the full priority definitions table, see: activity-format.md.

---

<rule id="RUL-P1-01" priority="P1" scope="universal" enforcement="checkpoint">
<name>Hierarchical Rules Discovery</name>

**Lookup Procedure**:
1. Walk up directory tree from working directory to root
2. Collect all RULES.md files found
3. Stop if file named `IGNORE_PARENT_RULES` is encountered in any directory
4. Read files in root-to-leaf order
5. Apply rules with later (deeper) files overriding earlier (shallower) files

**Edge Case — No RULES.md found**: If no RULES.md files are found in any directory from working directory to root, proceed with shared rules only. Document "No RULES.md files found" in activity.md. This is not an error — the shared rules in this directory are always in effect.

**Enforcement**: Compliance checkpoint at reference point.
</rule>

---

## RULES.md Application

<rule id="RUL-P1-02" priority="P1" scope="universal" enforcement="documentation">
<name>Rules Documentation in Activity Log</name>

**Documentation Format** (in activity.md):
```markdown
## Attempt {N} [{timestamp}]
RULES.md Applied:
- /proj/RULES.md
- /proj/src/RULES.md
```

**Precedence Rule**: Deepest (most specific) rules take precedence over parent (more general) rules.

**Enforcement**: Must be logged in activity.md for each attempt.
</rule>

---

## Compliance Checkpoint (RUL-CP-01)

**Invoke at**: reference (when starting work in a new directory context)

<checkpoint id="RUL-CP-01" trigger="reference">
- [ ] RUL-P1-01: Walked directory tree from working directory to root
- [ ] RUL-P1-01: Collected all RULES.md files found
- [ ] RUL-P1-01: Stopped at IGNORE_PARENT_RULES if encountered
- [ ] RUL-P1-01: Read files in root-to-leaf order (parent first, child overrides)
- [ ] RUL-P1-01: Applied rules with deeper files overriding shallower files
- [ ] RUL-P1-02: Documented applied rules in activity.md
</checkpoint>

---

## Using This Rule File

This file provides centralized lookup rules for RULES.md discovery and application. All agents MUST integrate these rules into their workflow via TODO checkpoints.

### TODO Integration Guidance

**At Start of Turn**:
- [ ] RUL-P1-01: Walk directory tree to find all RULES.md files
- [ ] RUL-P1-01: Stop if IGNORE_PARENT_RULES found in any directory
- [ ] RUL-P1-02: Document discovered rules in activity.md

**Before Tool Calls**:
- [ ] Verify P1 workflow gates (RUL-P1-01, RUL-P1-02) are satisfied
- [ ] Ensure rules documentation is up-to-date in activity.md

**Before Response**:
- [ ] Run compliance checkpoint (RUL-CP-01) — all 6 items

### Example TODO Items

```markdown
TODO:
- [ ] RUL-P1-01: Walk directory tree to find all RULES.md files
- [ ] RUL-P1-01: Stop if IGNORE_PARENT_RULES found
- [ ] RUL-P1-01: Read RULES.md files in precedence order (root → leaf)
- [ ] RUL-P1-02: Document applied rules in activity.md
- [ ] RUL-CP-01: Run compliance checkpoint before response
```

### XML Tag Reference

| Tag | Purpose |
|-----|---------|
| `<rule>` | Defines a rule with id, priority, scope, enforcement attributes |
| `<checkpoint>` | Defines a compliance checkpoint with trigger conditions |
| `<priority>` | P0/P1/P2/P3 classification |
| `<scope>` | universal, agent-specific, or workflow-specific |
| `<enforcement>` | How the rule is enforced (checkpoint, documentation, stop) |

---

## Related Rules

- **ACT-P1-12**: Activity.md updates (see: activity-format.md)
- **SIG-P0-01**: Signal format (see: signals.md)
