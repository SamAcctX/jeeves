# Guide

Workflow guide for using Jeeves and Ralph Loop.

Ralph is an autonomous AI task execution framework. Instead of completing an entire project in one long AI session (where context degrades and errors compound), Ralph breaks work into small tasks and tackles each one with a fresh context window. A Manager agent reads a task list, selects the next unblocked task, dispatches it to a specialized worker agent, interprets the result, and loops.

For command and configuration details, see [reference.md](reference.md). For diagnosing problems, see [troubleshooting.md](troubleshooting.md).

---

## Getting Started

From your host machine, build and enter the Jeeves container:

```powershell
./jeeves.ps1 build        # Build the Docker image
./jeeves.ps1 start        # Start the container
./jeeves.ps1 shell        # Attach an interactive shell
```

Inside the container, initialize Ralph in your project:

```bash
ralph-init.sh
```

This creates the `.ralph/` directory structure, installs agent templates to OpenCode, configures the five MCP servers, and sets up skills. The init script also runs `install-agents.sh`, `install-mcp-servers.sh`, and `install-skill-deps.sh` automatically. One important detail: `agents.yaml` is never overwritten by init, even with `--force`, protecting your model configuration from accidental resets.

The OpenCode Web UI is available at `http://localhost:3333` once the container is running. Running `opencode` with no arguments from the container shell auto-attaches the TUI to the running web server session.

See the [root README](../README.md) for the full quick start and prerequisites.

---

## Ralph Workflow

Ralph operates in three phases. Each phase completes before the next begins.

### Phase 1: PRD Creation

A Product Requirements Document defines what you want to build. It is the input to Phase 2 decomposition.

Invoke the `@prd-creator` agent interactively:

```
@prd-creator
```

The agent guides you through a conversational process -- asking about your project, its users, and technical constraints -- then generates a comprehensive PRD saved to `.ralph/specs/PRD-<name>.md`.

Behind the scenes, the PRD Creator uses a pipeline of specialized sub-agents:

1. **Creator** -- Drives the conversation, detects project type, tracks coverage areas
2. **Domain Advisor** -- One of five domain-specific advisors (api, cli, data, library, ui) provides targeted guidance based on your project type. Hybrid projects invoke multiple advisors.
3. **Researcher** -- Investigates unfamiliar technologies, compares approaches, and validates recommendations with current sources when the Creator or Advisors need factual grounding.

You can also write a PRD manually as a markdown file in `.ralph/specs/`. The quality of your PRD directly determines the quality of the task decomposition -- specific, testable requirements produce clear tasks.

### Phase 2: Decomposition

Phase 2 transforms your PRD into an actionable task list. Invoke the `@decomposer` agent:

```
@decomposer

Decompose the PRD at .ralph/specs/PRD-my-project.md into atomic tasks.
```

The Decomposer reads the PRD and generates three artifacts:

**TODO.md** (`.ralph/tasks/TODO.md`) -- The master task checklist with grouped sections and checkbox items like `- [ ] 0001: Initialize project structure`.

**deps-tracker.yaml** (`.ralph/tasks/deps-tracker.yaml`) -- The dependency graph. Each task has a `depends_on` list (what must finish first) and a `blocks` list (what is waiting on it). The Manager uses this graph at runtime to select unblocked tasks.

```yaml
tasks:
  "0001":
    depends_on: []
    blocks: ["0002", "0003"]
  "0002":
    depends_on: ["0001"]
    blocks: ["0004", "0005"]
```

**Task folders** (`.ralph/tasks/XXXX/`) -- One folder per task containing `TASK.md` (description, acceptance criteria, complexity estimate), `activity.md` (execution log), and `attempts.md` (attempt history).

#### Decomposition Patterns

The Decomposer uses several strategies depending on the PRD:

- **Feature decomposition** -- Break a large feature into its component parts. "Build user authentication" becomes: create User model, implement password hashing, create login endpoint, create logout endpoint, implement JWT generation, write auth middleware.
- **Layer decomposition** -- Break work by architectural layer. "Implement API endpoint" becomes: design request/response schema, create database migration, implement repository layer, implement service layer, create controller, add validation, write tests.
- **Workflow decomposition** -- Break user-facing features into workflow steps. "Add image upload" becomes: research storage options, set up upload middleware, implement validation, create storage service, add image processing, create upload endpoint.
- **Testing pyramid** -- Always include testing tasks at appropriate levels: unit tests, integration tests, end-to-end tests, and documentation.

#### Decomposer Variants

For complex system architecture (microservices, distributed systems), the Decomposer can consult `@decomposer-architect` as a sub-assistant. For research-heavy projects needing investigation before task planning, it can consult `@decomposer-researcher`. These are consultants that return structured analysis -- they do not create project files directly.

#### Task Sizing

Every task must be completable in under 2 hours of human-equivalent work. The Decomposer assigns T-shirt sizes:

| Size | Time | Example |
|------|------|---------|
| XS | 0-15 min | Config change, copy operation |
| S | 15-30 min | Single function, simple script |
| M | 30-60 min | Standard feature implementation |
| L | 1-2 hours | Multi-component integration |
| XL | >2 hours | **Must be decomposed further** |

If the Decomposer produces an XL task, ask it to refine. Review the output and iterate until satisfied.

#### Key Principles

- **Atomic tasks.** Each task should do one thing with clear acceptance criteria. "Implement the feature" is not testable. "Endpoint returns 201 with the created resource ID" is.
- **Honest dependencies.** Only declare actual technical dependencies, not sequential ordering preferences. Over-connecting the graph serializes work that could run in parallel.
- **No agent pre-assignment.** Do not assign agents to tasks during decomposition. The Manager selects agents at runtime based on task keywords and TDD phase signals. Use clear action verbs in task titles (implement, design, test, document).
- **Include testing tasks.** Always include unit, integration, and documentation tasks in the plan. Do not skip the testing pyramid.
- **Review before proceeding.** Check that all PRD requirements are covered, no XL tasks remain, dependencies make logical sense, and acceptance criteria are specific and testable. This is your last chance to adjust before autonomous execution.

#### Common Mistakes

| Mistake | Fix |
|---------|-----|
| Tasks too large ("Build auth system") | Break into model, hashing, login, logout, JWT, middleware |
| Vague descriptions ("Fix bugs") | Be specific: "Fix null pointer in UserService.create() when email is missing" |
| Missing acceptance criteria | Every task needs testable criteria with checkboxes |
| Over-connected dependencies | Only real technical dependencies, not "everything depends on everything" |
| No testing tasks | Include unit, integration, and E2E test tasks |

#### Post-Decomposition Checklist

Before starting Phase 3:

- [ ] TODO.md covers all PRD requirements
- [ ] No XL tasks remain
- [ ] Dependencies make logical sense
- [ ] Acceptance criteria are testable
- [ ] Commit Phase 2 output: `git add .ralph/ && git commit -m "docs: task decomposition"`

### Phase 3: Execution

Start the autonomous loop:

```bash
ralph-loop.sh
```

Common variations:

```bash
ralph-loop.sh --tool claude --max-iterations 50   # Use Claude Code, cap at 50
ralph-loop.sh --no-delay --skip-sync              # Fast mode: no backoff, skip agent sync
ralph-loop.sh --dry-run                           # Preview without executing
```

Each iteration follows this sequence:

1. **Sync agents** -- Propagate model configurations from `agents.yaml` to agent templates (skippable with `--skip-sync`).
2. **Read state** -- Parse `TODO.md` and `deps-tracker.yaml` to find incomplete, unblocked tasks.
3. **Select task** -- Pick the next unblocked task based on the dependency graph.
4. **Invoke worker** -- The Manager dispatches the task to the appropriate agent based on task keywords and TDD phase signals.
5. **Parse signal** -- The worker emits a signal indicating the result.
6. **Update state** -- Mark tasks complete, record activity, handle failures.
7. **Repeat** -- Loop back to step 2.

Environment variables can also control behavior:

```bash
export RALPH_TOOL=claude
export RALPH_MAX_ITERATIONS=200
ralph-loop.sh
```

#### Signals

Workers communicate results through four signals:

| Signal | Meaning |
|--------|---------|
| `TASK_COMPLETE_0042` | Task finished, all criteria met |
| `TASK_INCOMPLETE_0042` | Partial progress, will retry |
| `TASK_FAILED_0042: error msg` | Error encountered, will retry |
| `TASK_BLOCKED_0042: reason` | Needs human intervention |

When all tasks are complete, the Manager writes `ALL TASKS COMPLETE, EXIT LOOP` to TODO.md. When a task signals BLOCKED, the Manager writes an `ABORT:` line and the loop stops.

#### TDD Enforcement

For implementation tasks, the loop enforces a strict Test-Driven Development cycle:

```
RED:       Tester writes failing tests
GREEN:     Developer implements code to pass tests
VALIDATE:  Tester verifies all tests pass
DONE:      Tester emits TASK_COMPLETE
```

The critical constraint: **Developers cannot emit TASK_COMPLETE.** If a Developer tries, the Manager rejects it and re-invokes the Tester. Only the Tester can approve task completion.

#### Monitoring

While the loop runs, you have several monitoring options:

```bash
ralph-peek.sh           # Attach to the active session via TUI
ralph-peek.sh --web     # Print the Web UI URL
cat .ralph/tasks/TODO.md                  # Overall progress
cat .ralph/tasks/0042/activity.md         # Specific task log
ralph-filter-output.sh --signals output.json   # Show only signals (post-run)
```

#### When the Loop Stops

| Condition | What Happens |
|-----------|--------------|
| All tasks complete | Manager writes sentinel to TODO.md, loop exits |
| TASK_BLOCKED signal | Manager writes ABORT line, loop stops |
| Max iterations reached | Loop exits with a warning |
| Ctrl+C | Graceful shutdown (safe to restart) |

To recover from a stopped loop:

1. Read the reason: `cat .ralph/tasks/XXXX/activity.md`
2. Fix the underlying issue manually
3. Remove the `ABORT:` line from TODO.md
4. Restart: `ralph-loop.sh`

The loop is always safe to restart. It reads state from files, not memory. A `TASK_FAILED` signal triggers automatic retry with exponential backoff -- the next attempt has the failure context in activity.md. Only `TASK_BLOCKED` requires human intervention.

---

## Agent Types

Ralph uses 10 specialized agent types in the loop, plus 2 standalone agents.

### Ralph Loop Agents

| Agent | Role | Key Keywords |
|-------|------|--------------|
| manager | Orchestrates the loop -- selects tasks, invokes workers, manages state | N/A (not keyword-selected) |
| architect | System design, API design, schema, technology decisions | design, schema, API, architecture |
| developer | Code implementation, refactoring, debugging | implement, fix, refactor, feature |
| ui-designer | UI/UX design, frontend architecture, accessibility (WCAG 2.1 AA) | UI, CSS, layout, visual |
| tester | Test creation, QA validation, TDD gatekeeper -- only agent that can emit TASK_COMPLETE for TDD tasks | test, validate, QA, coverage |
| researcher | Investigation, analysis, knowledge synthesis | research, analyze, compare |
| writer | Documentation, technical writing -- only documents validated features | document, write, guide, README |
| decomposer | PRD decomposition, task planning, dependency analysis | decompose, plan, organize, TODO |
| decomposer-architect | Architecture consulting during decomposition (sub-assistant to decomposer) | N/A (invoked by decomposer) |
| decomposer-researcher | Research consulting during decomposition (sub-assistant to decomposer) | N/A (invoked by decomposer) |

The Manager selects agents at runtime. TDD phase signals (handoffs between Developer and Tester) always take priority over keyword matching.

#### TDD Separation of Duties

The TDD cycle enforces strict boundaries between agents:

| Agent | Allowed | Forbidden |
|-------|---------|-----------|
| Developer | Implement production code, refactor | Emit TASK_COMPLETE, write/modify tests |
| Tester | Write tests, validate, emit TASK_COMPLETE | Modify production code |
| Manager | Orchestrate, route signals | Implement code, write tests |
| Writer | Document validated features | Document untested features |

When a task involves implementation, the typical handoff chain is:

```
Tester (RED: writes failing tests)
  -> Developer (GREEN: implements to pass)
    -> Tester (VALIDATE: confirms all pass)
      -> TASK_COMPLETE (only Tester can emit this)
```

If the Tester finds defects during validation, it hands back to the Developer with `HANDOFF_DEFECT_FOUND`. If refactoring is needed, the Developer hands back with `HANDOFF_READY_FOR_TEST_REFACTOR` for a safety check. The cycle continues until the Tester is satisfied.

#### Multi-Disciplinary Tasks

When a task requires multiple agent types, decompose it into discipline-specific tasks rather than assigning one agent to do everything. For example, "Build user profile page" becomes separate tasks for UI design, backend API, frontend implementation, integration tests, and API documentation -- each routed to the appropriate agent.

For simple work that spans disciplines (like "Add a button to the homepage"), a single Developer can handle it.

### Standalone Agents

| Agent | Purpose |
|-------|---------|
| `@prd-creator` | Interactive PRD generation with domain advisors and researcher (Phase 1) |
| `@deepest-thinking` | Deep research with systematic multi-cycle investigation and source verification |

These are invoked directly by the user and do not participate in the Ralph Loop.

### Model Configuration

Map agents to LLM models in `.ralph/config/agents.yaml`. The file maps each agent type to preferred and fallback models for both OpenCode and Claude Code:

```yaml
agents:
  manager:
    description: "Loop orchestrator - selects tasks, invokes workers, manages state"
    preferred:
      opencode: ""          # Empty string = use default model
      claude: claude-opus-4.5
    fallback:
      opencode: ""
      claude: claude-sonnet-4.5
```

General guidance: use stronger models (Opus-tier) for orchestration agents (manager, architect, decomposer) and cost-effective models (Sonnet-tier) for high-volume workers (developer, tester, writer). After editing, run `sync-agents.sh` to propagate changes to agent templates. The sync is idempotent -- running it twice with the same config makes no unnecessary changes.

You can also override per-run with environment variables:

```bash
RALPH_MANAGER_MODEL=opus ralph-loop.sh
```

---

## RULES.md

RULES.md files capture project-specific patterns, conventions, and constraints. Since each Ralph iteration starts with fresh context, RULES.md is how learned patterns persist across iterations.

Agents walk up the directory tree from their working directory, collecting every `RULES.md` they find. Rules apply root-to-leaf: deeper files override shallower ones on conflict. A file containing `IGNORE_PARENT_RULES` stops inheritance from parent directories.

Typical content:

- **Code Patterns** -- Naming conventions, architectural patterns, style rules
- **Common Pitfalls** -- Known issues and how to avoid them
- **Standard Approaches** -- Preferred solutions for recurring problems
- **Auto-Discovered Patterns** -- Patterns agents learn during execution

Agents can add to the "Auto-Discovered Patterns" section as they work, building project knowledge over time.

Example:

```markdown
# Project Rules

## Code Patterns
- Use async/await for all I/O operations
- All API responses use the {data, error, meta} envelope format
- Database queries go through the repository layer, never direct SQL

## Common Pitfalls
- The ORM lazy-loads relationships by default; always use eager loading for list endpoints
- Redis connection pool must be initialized before first request

## Standard Approaches
- Use Pydantic models for request/response validation
- Environment variables for all configuration (no hardcoded values)

## Auto-Discovered Patterns
- [Agents add entries here as they learn project conventions]
```

For the full rules system specification including inheritance mechanics and the `IGNORE_PARENT_RULES` directive, see [rules-system.md](../jeeves/Ralph/docs/rules-system.md).

---

## Skills

Ralph ships with four built-in skills:

| Skill | Purpose |
|-------|---------|
| dependency-tracking | Parses deps-tracker.yaml, detects cycles, selects unblocked tasks, computes transitive closures |
| git-automation | Creates task branches, generates commit messages, resolves state file conflicts, manages branch cleanup |
| rationalization-defense | Detects and corrects 21 rationalization patterns across 11 categories that lead to compliance violations |
| system-prompt-compliance | Pre-action checklist for signal format, state file reads, and safety guidelines |

Optional skill sets can be installed inside the container:

```bash
install-skills.sh --doc-skills    # Document creation (docx, pdf, xlsx, pptx, markitdown)
install-skills.sh --n8n-skills    # n8n workflow automation (7 skills)
install-skills.sh --all           # All available skills
```

Skill dependencies are managed automatically with `install-skill-deps.sh`.

---

## Tips

- **Start small.** Your first Ralph project should have 5-10 tasks. Observe the loop, understand the signals, then scale up.
- **Invest in Phase 2.** Time spent reviewing decomposition saves time in Phase 3. Check task sizes, dependencies, and acceptance criteria before starting the loop.
- **Watch the first few iterations.** Use `ralph-peek.sh` to observe the Manager selecting tasks and dispatching agents. Catch routing issues early.
- **Do not edit state files while the loop is running.** Modifying TODO.md or deps-tracker.yaml during execution causes conflicts. Stop the loop first, make changes, then restart.
- **Trust the retry mechanism.** A `TASK_FAILED` signal is not a crisis. The loop retries with exponential backoff, and the next attempt has the failure context in activity.md.
- **Use RULES.md actively.** When the AI makes the same mistake twice, add a rule. The next iteration will follow it.
- **Commit Phase 2 output before Phase 3.** This gives you a clean baseline to diff against and makes recovery straightforward.
- **Use clear action verbs in task titles.** "Implement," "design," "test," and "document" help the Manager route to the correct agent. Ambiguous titles lead to wrong agent selection.
- **Review completed tasks.** Check `.ralph/tasks/done/` periodically to verify quality. If tasks are passing with low-quality output, tighten the acceptance criteria or add rules.

---

## Related Documentation

| Resource | Content |
|----------|---------|
| [reference.md](reference.md) | Commands, flags, configuration, agents.yaml, environment variables |
| [troubleshooting.md](troubleshooting.md) | Diagnostic procedures, recovery steps, and solutions for container, loop, agent, signal, and dependency issues |
| [rules-system.md](../jeeves/Ralph/docs/rules-system.md) | Full specification of the hierarchical RULES.md system |
