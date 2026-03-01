# Agent Selection Guide

How the Ralph Loop Manager selects agents at runtime, and when each of the 10 agent types is the right choice.

For model configuration and `agents.yaml` details, see [configuration.md](configuration.md). For agent-related troubleshooting, see [troubleshooting.md](troubleshooting.md).

---

## Overview

Ralph supports 10 specialized agent types. During Phase 2 decomposition, tasks are NOT pre-assigned to agents. The Manager agent makes runtime selections based on task content, TDD phase signals, and keyword analysis.

**The 10 agents:**

| # | Agent | Role |
|---|-------|------|
| 1 | manager | Orchestrator -- selects tasks, invokes workers, manages state |
| 2 | architect | System design, API design, acceptance criteria |
| 3 | developer | Code implementation, refactoring, debugging |
| 4 | ui-designer | UI/UX design, frontend architecture, accessibility |
| 5 | tester | Test creation, QA validation, TDD gatekeeper |
| 6 | researcher | Investigation, analysis, knowledge synthesis |
| 7 | writer | Documentation, technical writing, content creation |
| 8 | decomposer | PRD decomposition, TODO management, task planning |
| 9 | decomposer-architect | System design decomposition (sub-assistant to decomposer) |
| 10 | decomposer-researcher | Research-oriented decomposition (sub-assistant to decomposer) |

---

## Selection Flowchart

```
Manager receives task from TODO.md
|
+-- TDD phase signal from previous worker?
|   |
|   +-- HANDOFF_READY_FOR_DEV  ---------> Developer
|   +-- HANDOFF_READY_FOR_TEST ---------> Tester
|   +-- HANDOFF_READY_FOR_TEST_REFACTOR > Tester
|   +-- HANDOFF_DEFECT_FOUND -----------> Developer
|   +-- TASK_COMPLETE from Tester ------> Mark complete
|   +-- TASK_COMPLETE from Developer ---> REJECT, re-invoke Tester
|
+-- No TDD signal: analyze task keywords
    |
    +-- design, architecture, schema, API -------> architect
    +-- implement, fix, refactor, feature -------> developer
    +-- UI, CSS, layout, visual, interface ------> ui-designer
    +-- test, validate, QA, coverage ------------> tester
    +-- research, analyze, compare, investigate -> researcher
    +-- document, write, guide, README ----------> writer
    +-- decompose, plan, organize, TODO ---------> decomposer
```

TDD phase signals always take priority over keyword analysis. The Manager checks for them first.

---

## TDD Phase Integration

The Manager orchestrates a strict TDD cycle. The Developer CANNOT emit `TASK_COMPLETE` -- only the Tester can approve completion through the verification chain.

### Full TDD Cycle

```
RED: Tester writes failing tests
 |
 v
GREEN: Developer implements to pass tests
 |
 v
VALIDATE: Tester validates all tests pass
 |
 +-- Tests pass, no issues ---------> DONE (Tester emits TASK_COMPLETE)
 +-- Defects found -----------------> DEFECT: Developer fixes
 |                                      |
 |                                      v
 |                                    VALIDATE again (Tester)
 +-- Refactor needed ---------------> REFACTOR: Developer improves
                                        |
                                        v
                                      SAFETY_CHECK: Tester confirms no regressions
                                        |
                                        +-- Pass --> DONE
                                        +-- Regressions --> Developer fixes
```

### TDD Phase Routing Table

| Current Phase | Incoming Signal | Next Action |
|---------------|-----------------|-------------|
| (none/start) | Any | Check task type; if TDD, invoke Tester (RED) |
| RED | `HANDOFF_READY_FOR_DEV` | Invoke Developer (GREEN) |
| GREEN | `HANDOFF_READY_FOR_TEST` | Invoke Tester (VALIDATE) |
| GREEN | `TASK_COMPLETE` | REJECT -- Developer cannot mark complete; re-invoke Tester |
| VALIDATE | `TASK_COMPLETE` from Tester | Mark complete (DONE) |
| VALIDATE | `HANDOFF_DEFECT_FOUND` | Invoke Developer (DEFECT) |
| VALIDATE | `HANDOFF_READY_FOR_TEST_REFACTOR` | Invoke Tester (SAFETY_CHECK) |
| DEFECT | `HANDOFF_READY_FOR_TEST` | Invoke Tester (VALIDATE again) |
| REFACTOR | `HANDOFF_READY_FOR_TEST_REFACTOR` | Invoke Tester (SAFETY_CHECK) |
| SAFETY_CHECK | `TASK_COMPLETE` from Tester | Mark complete (DONE) |
| SAFETY_CHECK | `HANDOFF_DEFECT_FOUND` | Invoke Developer (regressions) |

### TDD Separation of Duties

| Agent | Allowed | Forbidden |
|-------|---------|-----------|
| Developer | Implement production code, refactor | Emit TASK_COMPLETE, write/modify tests |
| Tester | Write tests, validate, emit TASK_COMPLETE | Modify production code |
| Manager | Orchestrate, route signals | Implement code, write tests |

---

## Agent Reference

### Manager

**Role:** Orchestrator of the Ralph Loop. Not a worker -- it selects tasks, invokes workers, parses signals, and manages state.

**Key Responsibilities:**
- Read TODO.md and deps-tracker.yaml to select the next unblocked task
- Determine the appropriate agent based on TDD phase and task keywords
- Invoke worker subagents and parse their return signals
- Track handoff count (max 8 per task)
- Update state files and manage handoff chains
- Emit `ALL_TASKS_COMPLETE, EXIT LOOP` when all tasks are done

**The Manager never does worker work.** If tempted to implement, test, or write documentation directly, it must invoke the correct worker instead.

---

### Architect

**Use for:** System design, API design, database schema, technology decisions, integration patterns, defining acceptance criteria.

**Typical tasks:**
- Design REST API endpoints and response formats
- Create database schema with relationships
- Define microservices architecture
- Choose technology stack
- Verify implementation against architectural principles

**When NOT to use:**
- Implementation details (use developer)
- Writing tests (use tester)
- UI design (use ui-designer)
- Simple documentation (use writer)

---

### Developer

**Use for:** Code implementation, refactoring, debugging, bug fixes, feature development.

**Typical tasks:**
- Implement functions and classes
- Refactor existing code
- Fix bugs and errors
- Optimize performance

**TDD constraint:** Developer CANNOT emit `TASK_COMPLETE`. After implementation, the Developer must hand off to the Tester for validation. If the Developer emits `TASK_COMPLETE`, the Manager rejects it and re-invokes the Tester.

**When NOT to use:**
- High-level design (use architect)
- Test writing (use tester)
- Documentation (use writer)
- Research tasks (use researcher)

---

### UI-Designer

**Use for:** User interface design, user experience, visual design, frontend architecture. All designs comply with WCAG 2.1 AA accessibility standards.

**Typical tasks:**
- Design UI mockups and wireframes
- Implement frontend components
- Create CSS/styling and responsive layouts
- Implement accessibility features
- Design system implementation

**When NOT to use:**
- Backend logic (use developer)
- API design (use architect)
- Testing UI (use tester)

---

### Tester

**Use for:** Test cases, edge case detection, QA validation, test automation, coverage analysis. The Tester is the TDD gatekeeper -- only the Tester can approve task completion.

**Typical tasks:**
- Write unit and integration tests
- Identify edge cases
- Set up test automation
- Validate acceptance criteria
- Target 80%+ code coverage

**TDD role:** The Tester is the only agent that can emit `TASK_COMPLETE` for TDD tasks. The Tester writes tests in the RED phase, validates in the VALIDATE phase, and confirms no regressions in the SAFETY_CHECK phase.

**When NOT to use:**
- Writing production code (use developer)
- Debugging production issues (use developer)
- Documentation (use writer)
- High-level design (use architect)

---

### Researcher

**Use for:** Investigation, documentation review, analysis, summarization, knowledge synthesis. Completes minimum 2 research cycles per theme with source quality verification.

**Typical tasks:**
- Research library/framework options
- Analyze existing codebase
- Review documentation
- Summarize findings with recommendations
- Investigate error patterns

**When NOT to use:**
- Implementation (use developer)
- Testing (use tester)
- Design decisions (use architect)

---

### Writer

**Use for:** Documentation, content creation, copy editing, README files, technical writing. Only documents features that have passed Tester validation.

**Typical tasks:**
- Write README files
- Create API documentation
- Write user guides and tutorials
- Edit and improve existing docs
- Prepare release notes

**TDD constraint:** The Writer must NOT document untested features. If a feature has not passed Tester validation, the Writer signals `TASK_INCOMPLETE` and waits.

**When NOT to use:**
- Code implementation (use developer)
- Technical design (use architect)
- Research (use researcher)
- Test writing (use tester)

---

### Decomposer

**Use for:** PRD decomposition, TODO management, dependency analysis, task planning. The decomposer turns PRDs into atomic tasks during Phase 2.

**Typical tasks:**
- Decompose PRDs into atomic tasks (each under 2 hours)
- Create TODO.md structure with task ordering
- Analyze and map dependencies
- Create task folders with TASK.md files

**Sub-assistants:** The decomposer can invoke two specialized sub-assistants for consultation:
- **decomposer-architect** for architecture and design questions
- **decomposer-researcher** for research and investigation questions

**When NOT to use:**
- Regular execution tasks (use other agents)
- Single-file edits (use developer)

---

### Decomposer-Architect

**Use for:** System design decomposition -- architecture and design consulting during PRD decomposition. This is a sub-assistant to the decomposer, not an independent Ralph Loop agent.

**Invoked by:** Decomposer only. Does not participate in the TDD loop.

**When to use:**
- The PRD involves complex system architecture (microservices, distributed systems)
- Decomposition requires understanding integration patterns between components
- Technology stack decisions affect how tasks should be split
- The decomposer needs design pattern guidance to create well-bounded tasks

**Role:** CONSULTANT -- advises on system design, patterns, best practices, integration design, and verification strategies. The decomposer decides what to do with the findings.

**Provides:**
- Architectural analysis for decomposition decisions
- Design pattern recommendations
- Integration strategy guidance
- Technology stack evaluation

**Constraints:**
- Cannot create project files (TODO.md, TASK.md, deps-tracker.yaml)
- Cannot manage state or invoke other agents
- Returns structured analysis to the decomposer

---

### Decomposer-Researcher

**Use for:** Research-oriented decomposition -- investigation and research during PRD decomposition. This is a sub-assistant to the decomposer, not an independent Ralph Loop agent.

**Invoked by:** Decomposer only. Does not participate in the TDD loop.

**When to use:**
- The PRD references unfamiliar technologies or libraries that need investigation
- Decomposition requires comparing implementation approaches before committing to a task structure
- External documentation or API references need review to define accurate tasks
- The decomposer needs factual grounding before estimating complexity or dependencies

**Role:** CONSULTANT -- investigates questions the decomposer cannot answer itself, then returns structured findings with source citations and recommendations.

**Provides:**
- Technology research for decomposition decisions
- Documentation analysis
- Comparative analysis of approaches
- Knowledge synthesis from multiple sources

**Constraints:**
- Cannot create project files (TODO.md, TASK.md, deps-tracker.yaml)
- Cannot manage state or invoke other agents
- Returns structured findings to the decomposer

---

## Multi-Disciplinary Tasks

When a task requires multiple agent types, there are two approaches:

### Decompose into Separate Tasks

Break the work into discipline-specific tasks:
```
Original: "Build user profile page"

Decomposed:
- [ ] Design profile page mockup          -> UI-Designer
- [ ] Create backend API endpoint          -> Developer
- [ ] Implement frontend component         -> Developer
- [ ] Write integration tests              -> Tester
- [ ] Document the API                     -> Writer
```

### Use a Single Agent

For simpler work that spans disciplines:
```
Task: "Add simple button to homepage"
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

If the Manager encounters a task that does not map to any agent:

1. **Invoke skills-finder** to search for a matching capability
2. **Install discovered skill** -- Manager exits, loop restarts
3. **Retry with new skill** on the next iteration

If no skill is found, the Manager can decompose the task into subtasks that existing agents can handle.

---

## Best Practices

1. **Let Manager choose** -- Do not pre-assign agents during decomposition; let runtime selection handle it
2. **Clear descriptions** -- Use action verbs (implement, design, test) in task titles for accurate keyword matching
3. **Appropriate sizing** -- Decompose if a task needs multiple agents; aim for under 2 hours per task
4. **Follow TDD** -- The full cycle is RED, GREEN, VALIDATE, DEFECT, REFACTOR, SAFETY_CHECK, DONE
5. **Respect boundaries** -- Each agent has specific responsibilities; do not ask agents to work outside their domain
6. **Monitor selections** -- Check activity.md to see what the Manager chose and verify appropriateness
7. **Skill discovery** -- Use for truly novel capabilities beyond the existing 10 agent types

---

## Summary Table

| Agent | Primary Use | Key Keywords |
|-------|-------------|--------------|
| manager | Orchestration | N/A (not keyword-selected) |
| architect | System design | design, schema, API, architecture |
| developer | Implementation | implement, fix, refactor, feature |
| ui-designer | UI/UX | UI, CSS, layout, visual |
| tester | Testing / TDD gatekeeper | test, validate, QA, coverage |
| researcher | Investigation | research, analyze, compare |
| writer | Documentation | document, write, guide, README |
| decomposer | Task decomposition | decompose, plan, organize, TODO |
| decomposer-architect | System design decomposition (sub-assistant) | N/A (invoked by decomposer) |
| decomposer-researcher | Research-oriented decomposition (sub-assistant) | N/A (invoked by decomposer) |

For model mappings per agent, see the `agents.yaml` reference in [configuration.md](configuration.md).

---

## Related Documentation

- [Configuration Reference](configuration.md) -- agent model mappings, `agents.yaml` template, environment variables
- [Troubleshooting Guide](troubleshooting.md) -- agent selection issues, signal problems, sync failures
- [Commands Reference](commands.md) -- `install-agents.sh` usage
- [How-To Guide](how-to-guide.md) -- end-to-end workflow examples
