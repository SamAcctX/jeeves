# RULES.md Lookup (DUP-03)

<!-- version: 1.3.0 | last_updated: 2026-03-25 | canonical: YES -->

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

## Gotcha and Anti-Pattern Capture

<rule id="RUL-P1-03" priority="P1" scope="universal" enforcement="checkpoint">
<name>Capture Learned Rules to RULES.md</name>

**When to Capture**: Any time you encounter a repeatable problem, anti-pattern, or non-obvious gotcha during implementation, testing, or debugging that would waste time if hit again.

**Trigger Conditions**:
- A test fails repeatedly for a non-obvious, environment-specific reason
- A tool or framework has undocumented behavior that caused wasted effort
- A workaround was needed for a known limitation
- A configuration choice prevents a class of errors
- A dependency has version-specific quirks
- An anti-pattern caused flaky tests, timeouts, or silent failures

**Capture Format** (append to nearest RULES.md, or create one):
```markdown
## Rule: [short-name]
**Problem**: What goes wrong (1-2 sentences, concrete symptom)
**Root Cause**: Why it happens (technical explanation)
**Detection**: How to recognize this issue is occurring
**Prevention**: Correct pattern to use instead (with code example if applicable)
**Severity**: Critical | High | Medium
```

**Example**:
```markdown
## Rule: no-networkidle-with-vite
**Problem**: `waitForLoadState('networkidle')` hangs for 30-60s then times out in Playwright tests
**Root Cause**: Vite HMR keeps a WebSocket connection open permanently, which Playwright interprets as ongoing network activity
**Detection**: E2E tests timeout on page load despite the page being visually ready
**Prevention**: Use `waitForSelector('[data-testid="..."]', { timeout: 5000 })` instead of `waitForLoadState('networkidle')`
**Severity**: Critical
```

**Where to Write**:
1. If a RULES.md exists in the working directory or a parent, append to the most specific (deepest) one
2. If no RULES.md exists, create one at the project root (`/proj/RULES.md`)
3. If the rule is specific to a subdirectory (e.g., `tests/e2e/`), create RULES.md there

**What NOT to Capture**:
- One-off bugs specific to this task (use activity.md instead)
- General programming best practices (only project/stack-specific gotchas)
- Rules that duplicate what is already in RULES.md

**Enforcement**: Before emitting any completion signal, check whether any repeatable gotchas were encountered during this session. If yes, capture them per this rule before signaling.
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
- [ ] RUL-P1-03: Any repeatable gotchas encountered this session? If yes, captured in RULES.md
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
- [ ] Run compliance checkpoint (RUL-CP-01) — all 7 items

**Pre-Signal (before emitting any completion signal)**:
- [ ] RUL-P1-03: Were any repeatable gotchas or anti-patterns encountered?
- [ ] RUL-P1-03: If yes, captured in RULES.md before signaling

### Example TODO Items

```markdown
TODO:
- [ ] RUL-P1-01: Walk directory tree to find all RULES.md files
- [ ] RUL-P1-01: Stop if IGNORE_PARENT_RULES found
- [ ] RUL-P1-01: Read RULES.md files in precedence order (root → leaf)
- [ ] RUL-P1-02: Document applied rules in activity.md
- [ ] RUL-P1-03: Capture any gotchas/anti-patterns to RULES.md before signal
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
