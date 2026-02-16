# Agent Selection Guide

## Overview

Ralph supports 7 specialized agent types, each optimized for different kinds of work. The Manager agent handles runtime selection based on task content and current system state.

**Key Principle:** During Phase 2 decomposition, tasks are NOT pre-assigned to agents. The Manager agent makes runtime selections based on task content and current availability.

## The 7 Agent Types

### 1. Architect

**Best for:** System design, API design, database schema, technology decisions, integration patterns

**Description:** The Architect agent specializes in providing architectural guidance with 15+ years of experience in system design, architecture patterns, and integration design. They define acceptance criteria for other agents and ensure robust, scalable, and maintainable systems.

**Typical Tasks:**
- Design REST API endpoints and response formats
- Create database schema with relationships
- Define microservices architecture
- Choose technology stack
- Design data models and validation rules
- Verify implementation against architectural principles

**Example Task Description:**
```markdown
Design the API for a user authentication system:
- Login/logout endpoints
- Password reset flow
- JWT token handling
- Rate limiting strategy
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-opus-4.5 (preferred), claude-sonnet-4.5 (fallback)

**When to Use:**
- Starting a new feature or service
- Making structural decisions
- Defining interfaces between components
- Needing verification of design pattern compliance
- Defining acceptance criteria for complex requirements

**When NOT to Use:**
- Implementation details (use developer)
- Writing tests (use tester)
- UI design (use ui-designer)
- Simple documentation (use writer)

---

### 2. Developer

**Best for:** Code implementation, refactoring, debugging, bug fixes, feature development

**Description:** The Developer agent specializes in code implementation with strict TDD compliance. They implement features to pass tests created by the Tester agent and follow the Test-Driven Development workflow.

**Typical Tasks:**
- Implement functions and classes
- Refactor existing code
- Fix bugs and errors
- Add new features
- Optimize performance

**Example Task Description:**
```markdown
Implement the UserService class:
- create_user() method
- authenticate() method
- update_profile() method
- Include input validation
- Write docstrings
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-sonnet-4.5 (preferred and fallback)

**When to Use:**
- Writing new code
- Modifying existing code
- Fixing compilation/runtime errors
- Performance optimization
- Refactoring with test coverage

**When NOT to Use:**
- High-level design (use architect)
- Test writing (use tester)
- Documentation (use writer)
- Research tasks (use researcher)

---

### 3. UI-Designer

**Best for:** User interface design, user experience, visual design, frontend architecture

**Description:** The UI Designer agent specializes in creating intuitive, accessible, and visually appealing user interfaces with 10+ years of experience. All designs comply with WCAG 2.1 AA accessibility standards.

**Typical Tasks:**
- Design UI mockups and wireframes
- Implement frontend components
- Create CSS/styling
- Design responsive layouts
- Implement accessibility features

**Example Task Description:**
```markdown
Design the user profile page:
- Avatar display with upload
- Editable profile fields
- Save/cancel actions
- Mobile-responsive layout
- Follow existing design system
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-opus-4.5 (preferred), claude-sonnet-4.5 (fallback)

**When to Use:**
- Designing interfaces
- Implementing frontend code
- Creating visual assets
- UX improvements
- Design system implementation

**When NOT to Use:**
- Backend logic (use developer)
- API design (use architect)
- Testing UI (use tester)

---

### 4. Tester

**Best for:** Test cases, edge case detection, QA validation, test automation, coverage analysis

**Description:** The Tester agent specializes in quality assurance, test case creation, edge case detection, and ensuring code quality through comprehensive testing. They work within the TDD framework.

**Typical Tasks:**
- Write unit tests
- Create integration tests
- Identify edge cases
- Set up test automation
- Validate acceptance criteria
- Ensure 80%+ code coverage

**Example Task Description:**
```markdown
Write comprehensive tests for UserService:
- Unit tests for all methods
- Edge cases: null inputs, empty strings, special chars
- Integration tests with database
- Error handling scenarios
- Target: 80% coverage
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-sonnet-4.5 (preferred and fallback)

**When to Use:**
- Creating test suites
- QA validation
- Edge case analysis
- Test automation setup
- Validating implementation against acceptance criteria

**When NOT to Use:**
- Writing production code (use developer)
- Debugging production issues (use developer)
- Documentation (use writer)
- High-level design (use architect)

---

### 5. Researcher

**Best for:** Investigation, documentation review, analysis, summarization, knowledge synthesis

**Description:** The Researcher agent specializes in investigation and knowledge synthesis with rigorous methodology. They complete minimum 2 research cycles per theme and verify sources using a quality hierarchy.

**Typical Tasks:**
- Research library/framework options
- Analyze existing codebase
- Review documentation
- Summarize findings
- Investigate error patterns

**Example Task Description:**
```markdown
Research authentication libraries for Python:
- Compare Flask-Login, Authlib, PyJWT
- Security considerations
- Community support and maintenance
- Integration complexity
- Provide recommendation with rationale
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-opus-4.5 (preferred), claude-sonnet-4.5 (fallback)

**When to Use:**
- Technology research
- Code analysis
- Documentation review
- Investigation tasks
- Comparative analysis

**When NOT to Use:**
- Implementation (use developer)
- Testing (use tester)
- Design decisions (use architect)

---

### 6. Writer

**Best for:** Documentation, content creation, copy editing, README files, technical writing

**Description:** The Writer agent specializes in clear, effective technical documentation. They create comprehensive documentation that meets quality standards and follows technical writing principles.

**Typical Tasks:**
- Write README files
- Create API documentation
- Write user guides
- Edit and improve existing docs
- Create tutorials

**Example Task Description:**
```markdown
Write README.md for the task-cli project:
- Installation instructions
- Usage examples
- Command reference
- Configuration options
- Contributing guidelines
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-sonnet-4.5 (preferred and fallback)

**When to Use:**
- Writing documentation
- Creating guides
- Editing content
- Preparing release notes

**When NOT to Use:**
- Code implementation (use developer)
- Technical design (use architect)
- Research (use researcher)
- Test writing (use tester)

---

### 7. decomposer

**Best for:** Task decomposition, TODO management, agent coordination, Phase 2

**Description:** The decomposer agent specializes in breaking down PRDs into atomic tasks, analyzing dependencies, and generating task structures. They are the workhorse that turns visions into actionable tasks.

**Typical Tasks:**
- Decompose PRDs into tasks
- Create TODO.md structure
- Analyze dependencies
- Plan task ordering
- Coordinate multi-agent work

**Example Task Description:**
```markdown
Decompose this PRD into atomic tasks:
- Each task < 2 hours
- Identify dependencies
- Create TODO.md
- Create task folders with TASK.md files
```

**Model Recommendations:**
- opencode: inherit (uses global model)
- claude: claude-opus-4.5 (preferred), claude-sonnet-4.5 (fallback)

**When to Use:**
- Phase 2 decomposition
- Task planning
- Dependency analysis
- Breaking down large work items
- Initial project setup

**When NOT to Use:**
- Regular execution tasks (use other agents)
- Single-file edits (use developer)

---

## The Manager Agent (Orchestrator)

**Best for:** Orchestrating task execution, runtime agent selection, state management

**Description:** The Manager agent is the orchestrator of the Ralph Loop. It reads TODO.md and deps-tracker.yaml to select the next task, determines which agent should handle it, invokes the worker, and manages state through the TDD workflow.

**Key Responsibilities:**
- Read state files (TODO.md, deps-tracker.yaml)
- Select next unblocked task
- Determine appropriate agent based on TDD phases
- Invoke worker subagents
- Parse worker signals
- Update state files
- Manage handoff chains

**Runtime Selection Process:**
1. Reads task description from TODO.md
2. Checks for TDD phase signals from previous workers
3. Analyzes task title/keywords for agent type hints
4. If ambiguous, performs self-consultation
5. Invokes the selected agent

---

## Selection Flowchart

```
What type of work?
│
├─→ Designing system/API/schema ──────────→ Architect
│    (design, architecture, schema)
│
├─→ Writing/modifying code ──────────────→ Developer
│    (implement, fix, refactor, feature)
│
├─→ UI/UX design or frontend ────────────→ UI-Designer
│    (interface, layout, CSS, visual)
│
├─→ Writing tests/QA/validation ─────────→ Tester
│    (test, validate, coverage, edge case)
│
├─→ Research/analysis/investigation ──────→ Researcher
│    (research, analyze, compare, investigate)
│
├─→ Documentation/content ───────────────→ Writer
│    (document, write, guide, README)
│
└─→ Breaking down work/planning ─────────→ decomposer
     (decompose, plan, organize, TODO)
```

---

## Runtime Selection by Manager

### How Manager Chooses

1. **Reads task description** from TODO.md
2. **Checks TDD phase signals** from previous workers:
   - `HANDOFF_READY_FOR_DEV` → Developer
   - `HANDOFF_READY_FOR_TEST` → Tester
   - `HANDOFF_READY_FOR_TEST_REFACTOR` → Tester
   - `HANDOFF_DEFECT_FOUND` → Developer
3. **Analyzes task title keywords:**
   - "design", "architecture", "schema", "API" → architect
   - "implement", "fix", "refactor", "feature" → developer
   - "test", "validate", "QA", "coverage" → tester
   - "UI", "interface", "layout", "CSS" → ui-designer
   - "research", "analyze", "compare" → researcher
   - "document", "write", "guide", "README" → writer
   - "decompose", "plan", "TODO" → decomposer
4. **Checks agent availability** (agent definition exists and is synced)
5. **Invokes best matching agent** as subagent

### TDD Phase Integration

The Manager orchestrates the Three-Phase Architecture:

| Phase | Agent | Activity |
|-------|-------|----------|
| Phase 0 | Architect | Define acceptance criteria |
| Phase 1 | Tester | Create test cases from criteria |
| Phase 2 | Developer | Implement code to pass tests |
| Phase 3 | Tester | Verify all tests pass |

### Example Selections

**Task:** "Create database schema for user profiles"
- Keywords: "schema", "database"
- Selection: Architect

**Task:** "Implement the UserRepository class"
- Keywords: "implement", "class"
- Selection: Developer

**Task:** "Write tests for the API endpoints"
- Keywords: "tests", "endpoints"
- Selection: Tester

**Task:** "Document the authentication flow"
- Keywords: "document", "flow"
- Selection: Writer

---

## Multi-Disciplinary Tasks

### Option 1: Decompose

Break into separate tasks for each discipline:
```markdown
# Original: "Build user profile page"

# Decomposed:
- [ ] Design profile page mockup → UI-Designer
- [ ] Create backend API endpoint → Developer
- [ ] Implement frontend component → Developer
- [ ] Write integration tests → Tester
- [ ] Document the API → Writer
```

### Option 2: Single Agent

Use higher-level agent for simpler work:
```markdown
# Task: "Add simple button to homepage"
- Use Developer (includes basic HTML/CSS)
```

### Decision Criteria

| Factor | Decompose | Single Agent |
|--------|-----------|--------------|
| Complexity | High | Low |
| Skills needed | 3+ different | 1-2 related |
| Risk | High coordination | Lower risk |
| Time | Longer (parallelizable) | Shorter |

---

## Unmapped Task Types

### Skill Discovery

If Manager encounters a task that doesn't map to any agent:

1. **Invoke skills-finder:**
   ```bash
   @skills-finder "Find skill for X"
   ```

2. **Install discovered skill:**
   - Skill installation happens automatically
   - Manager exits, loop restarts

3. **Retry with new skill:**
   - Next iteration, skill is available
   - Manager can now handle task

### Example Workflow

```
[Manager] Task: "Generate PDF report from data"
[Manager] No suitable agent found
[Manager] Invoking skills-finder...
[Manager] Found: PDF generation capability
[Manager] Installing skill...
[Manager] Exit and restart loop

[Next Iteration]
[Manager] Task: "Generate PDF report from data"
[Manager] Skill now available
[Manager] Invoking appropriate agent with PDF skill
```

---

## Agent Customization

### Creating Custom Agents

1. Add entry to `agents.yaml`:
   ```yaml
   agents:
     data-analyst:
       description: "Data analysis and visualization"
       preferred_models:
         opencode: inherit
         claude: claude-opus-4.5
   ```

2. Create agent definition:
   ```bash
   mkdir -p .opencode/agents
   cat > .opencode/agents/data-analyst.md << 'EOF'
   ---
   name: data-analyst
   description: "Data analysis specialist"
   mode: subagent
   ---
   
   You are a data analysis specialist...
   EOF
   ```

3. Sync configuration:
   ```bash
   ./install-agents.sh
   ```

### Agent Override

Override model for specific task in TASK.md:
```markdown
## Agent Type
developer

## Model Override
claude-opus-4.5  # Use this instead of default
```

---

## Troubleshooting Selection Issues

### "Agent not found"

**Cause:** Agent file doesn't exist or not synced

**Solution:**
```bash
# Check if agent exists
ls .opencode/agents/<agent>.md

# Sync agents
./install-agents.sh

# Or create manually
```

### Wrong agent selected

**Cause:** Task description ambiguous or keywords unclear

**Solution:**
- Make task description more specific
- Include agent type hint in TASK.md:
  ```markdown
  ## Agent Type
  tester  # Explicitly request tester
  ```
- Manager will prioritize explicit hints over keyword analysis

### Skill not available

**Cause:** Skill discovery failed or not installed

**Solution:**
- Check activity.md for installation errors
- Manually install skill
- Or decompose task to use existing agents

### Circular dependency detected

**Cause:** Tasks depend on each other forming a cycle

**Solution:**
- Review deps-tracker.yaml
- Break the cycle by reordering dependencies
- Consult decomposer for task decomposition

### Handoff limit reached

**Cause:** More than 8 worker invocations per task

**Solution:**
- Task may be too complex - decompose further
- Review if unnecessary handoffs occurred
- Consider if task can be simplified

---

## Best Practices

1. **Let Manager choose** - Don't pre-assign agents during decomposition; let runtime selection handle it
2. **Clear descriptions** - Use action verbs (implement, design, test) in task titles
3. **Appropriate sizing** - Decompose if task needs multiple agents; aim for <2 hours per task
4. **Skill discovery** - Use for truly novel capabilities beyond existing agents
5. **Monitor selections** - Check activity.md to see what Manager chose and verify appropriateness
6. **Follow TDD** - Architect → Tester → Developer → Tester workflow ensures quality
7. **Respect boundaries** - Each agent has specific responsibilities; don't ask agents to do outside their domain

---

## Summary Table

| Agent | Primary Use | Key Keywords | Model Priority |
|-------|-------------|--------------|----------------|
| architect | System design | design, schema, API, architecture | claude-opus-4.5 |
| developer | Implementation | implement, fix, refactor | claude-sonnet-4.5 |
| ui-designer | UI/UX | UI, CSS, layout, visual | claude-opus-4.5 |
| tester | Testing | test, validate, QA, coverage | claude-sonnet-4.5 |
| researcher | Investigation | research, analyze, compare | claude-opus-4.5 |
| writer | Documentation | document, write, guide | claude-sonnet-4.5 |
| decomposer | Coordination | decompose, plan, organize | claude-opus-4.5 |
| manager | Orchestration | N/A | inherit |

---

## Related Documentation

- [Ralph Loop Overview](../README-Ralph.md)
- [Agent Templates](../templates/agents/)
- [TDD Workflow](../docs/TDD-Workflow.md)
- [Skills Integration](./skills-integration.md)
