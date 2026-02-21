# RULES.md Lookup (DUP-03)

**File ID**: RULES-LOOKUP-01  
**Priority**: P1 (Must-follow)  
**Scope**: Universal (all agents)  
**Location**: `.prompt-optimizer/shared/rules-lookup.md`  
**Last Updated**: 2026-02-20  

---

<rule id="P1-13" priority="P1" scope="universal" enforcement="checkpoint">
<name>Hierarchical Rules Discovery</name>

**Lookup Procedure**:
1. Walk up directory tree from working directory to root
2. Collect all RULES.md files found
3. Stop if IGNORE_PARENT_RULES encountered
4. Read files in root-to-leaf order
5. Apply rules with later files overriding earlier

**Enforcement Mechanism**: Compliance checkpoint at reference point
</rule>

---

## RULES.md Application

<rule id="P1-14" priority="P1" scope="universal" enforcement="documentation">
<name>Rules Documentation in Activity Log</name>

**Documentation Format** (from activity.md):
```markdown
## Attempt {N} [{timestamp}]
RULES.md Applied:
- /proj/RULES.md
- /proj/src/RULES.md
```

**Precedence Rule**: Deepest rules take precedence over parent rules.

**Enforcement Mechanism**: Must be logged in activity.md for each attempt
</rule>

---

<checkpoint id="CP-01" trigger="reference">
<name>Compliance Checkpoint</name>

**Invoke at**: reference

- [ ] P1-13: Walked directory tree from working directory to root
- [ ] P1-13: Collected all RULES.md files found
- [ ] P1-13: Stopped at IGNORE_PARENT_RULES if encountered
- [ ] P1-13: Read files in root-to-leaf order
- [ ] P1-13: Applied rules with later files overriding earlier
- [ ] P1-14: Documented applied rules in activity.md
</checkpoint>

---

## Using This Rule File

This file provides centralized lookup rules for RULES.md discovery and application. All agents MUST integrate these rules into their workflow via TODO checkpoints.

### TODO Integration Guidance

#### At Start of Turn
- Read this file to refresh rule context
- Check for any P0/P1 rules relevant to current task

#### Before Tool Calls
- Verify P1 workflow gates (P1-13, P1-14) are satisfied
- Ensure rules documentation is up-to-date

#### Before Response
- Run compliance checkpoint (CP-01)
- Confirm all checklist items completed

### Example TODO Items for RULES.md Lookup

```markdown
TODO:
- [ ] P1-13: Walk directory tree to find all RULES.md files
- [ ] P1-13: Stop if IGNORE_PARENT_RULES found
- [ ] P1-13: Read RULES.md files in precedence order
- [ ] P1-14: Document applied rules in activity.md
- [ ] CP-01: Run compliance checkpoint before response
```

### Rule Priority Reference

| Priority | Description | Action |
|----------|-------------|--------|
| P0 | Must-never-break (safety, forbidden actions) | STOP immediately if violated |
| P1 | Must-follow (workflow gates, required steps) | Complete before proceeding |
| P2 | Should (best practices) | Apply when applicable |
| P3 | Guidance (tone, optional advice) | Consider but not required |

### XML Tag Reference

| Tag | Purpose |
|-----|---------|
| `<rule>` | Defines a rule with id, priority, scope, enforcement attributes |
| `<checkpoint>` | Defines a compliance checkpoint with trigger conditions |
| `<priority>` | P0/P1/P2/P3 classification |
| `<scope>` | universal, agent-specific, or workflow-specific |
| `<enforcement>` | How the rule is enforced (checkpoint, documentation, stop) |

---

**Related Files**:
- `.prompt-optimizer/manifest.md` - File inventory
- `.prompt-optimizer/report.md` - Instruction map and analysis
- `.prompt-optimizer/changes.md` - Change log
