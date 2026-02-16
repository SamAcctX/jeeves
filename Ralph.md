# Ralph Loop Implementation Guide

## Executive Summary

The Ralph Loop is an autonomous AI development methodology based on continuous iteration with fresh context. Named after the persistent Ralph Wiggum character from The Simpsons, it embodies the philosophy that **iteration beats perfection**. 

This implementation provides a generalized framework for autonomous task execution using OpenCode or Claude Code. The core principle is maintaining **zero context accumulation** between tasks—each iteration starts with a clean slate, preventing the context bloat and token burn that plague long-running AI sessions.

This implementation uses a **Manager-Worker architecture** with a lightweight bash wrapper:
- **Manager Agent**: Spawned fresh each iteration; reads TODO.md (+ dependency tracker); selects a dependency-unblocked task; invokes a subagent synchronously via the selected tool; waits; updates state; emits stdout signals; and exits.
- **Worker Agent**: A subagent process started with clean context. It rehydrates via task files (`TASK.md`, `attempts.md`, `activity.md`); executes work; and returns a status string to the Manager using canonical `TASK_*_XXXX` signals.
- **Bash Wrapper**: Simple loop that spawns Manager, waits for completion, repeats

This maintains the core Ralph principle of **fresh context per iteration** while adding orchestration intelligence. Tasks are organized into fine-grained units with comprehensive file-based tracking, git integration for successful completions, and a robust signaling system for completion, failure, and human intervention requests.

The framework supports **specialized agents** for different task types (architecture, UI, testing, etc.) with **configurable model mapping** to optimize performance and cost for each agent type.

---

## Detailed Topics

### 1. Ralph Loop Fundamentals

**Key Points:**
- Ralph Loop = "a bash loop" (Geoffrey Huntley's core insight)
- Bash loop spawns consistent Manager agent each iteration: `while :; do opencode --agent manager; done`
- Manager handles orchestration then exits, maintaining fresh context principle
- Each iteration spawns fresh AI instances with clean context
- Context window reset to zero prevents degradation over time
- Failures become data for the next iteration
- Eventual consistency through repeated attempts

**Decisions Made:**
- Use pure bash loop that spawns Manager agent (not persistent orchestrator)
- Manager is the "consistent prompt" invoked each iteration
- Manager spawns Worker subagents for task execution
- Fresh context per iteration (both Manager and Worker)
- No conversation history carried between iterations
- File-based state persistence between iterations
- Environment persistence: The loop runs in a long-lived Docker container with volume mounts; installations made during one iteration (npm/pip/etc.) persist into subsequent iterations

**Open Questions:**
- None - approach is fully validated

### 2. Agent Specialization & Task Types

**Key Points:**
- Different task types benefit from specialized agents
- Architecture tasks need models strong at system design
- UI/UX tasks need models with visual/design capabilities
- Testing tasks need models good at edge case detection
- Development tasks need models proficient at coding patterns
- Research tasks need models with broad knowledge

**Decisions Made:**
- Support multiple specialized agents within a single loop
- Agent selection can be manual (task metadata) or automatic (task content analysis)
- Each agent type has recommended default models but can be overridden
- Agent configuration stored in YAML for readability

**Agent Types Defined:**
- `architect` - System design, API design, database schema, patterns
- `developer` - Code implementation, refactoring, bug fixes
- `ui-designer` - User interface, user experience, visual design
- `tester` - Test cases, edge cases, validation, QA
- `researcher` - Investigation, documentation, analysis, summarization
- `writer` - Documentation, content creation, copy editing
- `decomposer` - Task decomposition, TODO management, agent coordination, delegation

**Agent Selection:**
- **Automatic**: Analyzes task description for keywords (e.g., "design API" → architect, "write tests" → tester)
- **Explicit**: Task instructions can specify agent directly when description is ambiguous
- **Multi-disciplinary**: Either decompose further (single agent per sub-task) or use higher-level agent (e.g., architect for UI+API)

**Unmapped Task Types (Runtime Resolution):**
No agent type is pre-assigned during Phase 2 decomposition. At runtime:

1. **Manager Analysis**: Manager agent reads task and determines best agent from available pool
2. **Skill Discovery**: If no suitable agent exists:
   - Manager invokes `skills-finder` to locate appropriate skill
   - Manager installs skill via standard skill installation
   - Manager exits, loop restarts with new skill available
   - Single retry on install failure; if fails again → TASK_BLOCKED
3. **Dynamic Assignment**: Manager always picks best assignee from **currently available** agents/skills

**Note:** Agent self-discovery toolkit may be explored in future. For now, skills-finder is the primary mechanism for handling unmapped task types.

**Decisions Made:**
- No agent pre-assignment during decomposition
- Runtime selection by Manager based on task content
- Skills-finder as fallback for unmapped types
- Install-on-demand pattern for new capabilities

**Open Questions:**
- None - agent selection methodology is clear

### 3. Model-to-Agent Mapping Configuration

**Configuration File:** `.ralph/config/agents.yaml`

**Purpose:** Map specific LLM models to agent types for optimal performance and cost efficiency. Different models excel at different tasks.

**Example Configuration:**
```yaml
# Agent Model Configuration
# Maps agent types to specific models per tool
# NOTE: Model names are examples based on current availability (early 2026)
# User is responsible for updating model names as providers change

agents:
  architect:
    description: "System design and architecture tasks"
    preferred_models:
      opencode: gpt-5.2
      claude: claude-opus-4.5
    fallback_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5

  developer:
    description: "Code implementation and debugging"
    preferred_models:
      opencode: grok-4.1
      claude: claude-sonnet-4.5
    fallback_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5

  ui-designer:
    description: "UI/UX design and implementation"
    preferred_models:
      opencode: gpt-5.2
      claude: claude-opus-4.5
    fallback_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5

  tester:
    description: "Testing and quality assurance"
    preferred_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5
    fallback_models:
      opencode: grok-4.1
      claude: claude-sonnet-4.5

  researcher:
    description: "Research, analysis, and documentation"
    preferred_models:
      opencode: gpt-5.2
      claude: claude-opus-4.5
    fallback_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5

  writer:
    description: "Documentation and content creation"
    preferred_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5
    fallback_models:
      opencode: grok-4.1
      claude: claude-sonnet-4.5

  decomposer:
    description: "Task decomposition, TODO management, agent coordination"
    preferred_models:
      opencode: gpt-5.2
      claude: claude-opus-4.5
    fallback_models:
      opencode: gemini-3.0-flash
      claude: claude-sonnet-4.5
```

**Decisions Made:**
- YAML format for human readability
- One model per agent per tool (simple, future-flexible)
- User responsible for updating model names as providers change
- No auto-detection (user manages configuration)
- Bash scripts parse via `yq` or simple grep/awk

**Open Questions:**
- None - configuration approach is clear

### 3.5 Configuration Sync (sync-agents)

**Purpose:**
Synchronize agent model configuration from `agents.yaml` to agent definition files before loop execution.

**When It Runs:**
- Once at startup of `ralph-loop.sh`, before entering the main while loop
- Updates agent.md files with correct `model:` frontmatter from agents.yaml

**Agent.md Locations:**
- **Project-specific**:
  - `.ralph/agents/*.md` (if exists - project customizations)
  - `.opencode/agents/*.md` (if exists - `opencode` project-specific)
  - `.claude/agents/*.md` (if exists - `claude` project-specific)
- **User-global**:
  - `opencode`: `~/.config/opencode/agents/*.md`
  - `claude`: `~/.claude/agents/*.md` (or equivalent)

**Sync Process:**
```bash
# sync-agents script (Python or bash)
# 1. Read .ralph/config/agents.yaml
# 2. For each agent type in agents.yaml:
#    - Find corresponding agent.md file
#    - Update frontmatter 'model:' field to match preferred_models for current tool
#    - Preserve all other content
# 3. Log sync results to activity.md or stdout
```

**Why This Matters:**
- Subagent calls (e.g., `@architect`) automatically use the model defined in their agent.md
- No runtime YAML parsing needed during loop execution
- Single source of truth (agents.yaml) drives all agent configurations

**Implementation Notes:**
- Implemented in bash with `yq` for YAML parsing (preferred for simplicity)
- Python acceptable if YAML frontmatter manipulation proves unreliable in bash
- Must handle both `opencode` and `claude` agent file locations
- Should be idempotent (safe to run multiple times)
- Detailed specification in Section 15.3 (Bash Utilities Specification)

**Decisions Made:**
- Run once before loop, not every iteration
- Update both project and global agent files
- Language: Bash with yq preferred, Python acceptable for reliability
- Pre-installed tools: yq, jq available in container

**Open Questions:**
- None - sync approach is clear

### 4. Three-Phase Architecture

**Phase 1: PRD Generation** (Completed)
- Create comprehensive PRD for the target project
- Define requirements, technical specs, success criteria

**Phase 2: Decomposition** (User-invoked with specialized agent)
- User invokes `decomposer` agent specialized in decomposition
- Agent breaks PRD into atomic, fine-grained tasks
- User reviews output and provides feedback
- **Iterative refinement**: Multiple passes allowed until task list is satisfactory
- Agent creates task folders with full definitions
- Agent generates master TODO.md checklist
- Agent performs dependency analysis (see below)
- Agent does NOT assign agents during decomposition (all assignment happens at runtime by Manager)

**Dependency Analysis During Decomposition:**
- As each task is created, agent checks previous tasks for dependencies
- Dependencies logged in `.ralph/tasks/deps-tracker.yaml`
- Final dependency check performed once all tasks created
- Circular dependency detection and resolution
- Task ordering determined by dependency graph

**Phase 3: Execution** (Ralph Loop)
- Bash loop spawns Manager agent with fresh context
- Manager reads TODO.md and deps-tracker.yaml
- Manager determines which incomplete task to work on next
- Manager delegates task to appropriate Worker agent (subagent call)
- Worker executes task with fresh context, maintains activity.md/attempts.md
- Worker reports result back to Manager
- Manager handles cleanup (updates TODO.md, moves folders if complete)
- Manager exits, bash loop repeats with fresh Manager
- Exponential backoff between iterations
- Global iteration cap checked on each loop
- **For detailed execution cycle, see Section 5.5**

**Decisions Made:**
- Strict separation: PRD → Tasks → Execution
- **Phase 2 is user-invoked with decomposer agent** (not fully automated)
- Iterative decomposition supported (multiple refinement passes)
- Dependency tracking performed during decomposition phase
- Serial task execution (not parallel in main loop)
- Tasks can use parallel subagents internally
- **No agent assignment during decomposition** - Manager assigns agents at runtime based on current availability and task analysis

**Open Questions:**
- None - decomposition approach is clear

### 5. Context Management Strategy

**Key Points:**
- Standard AI coding = single pass, context accumulates
- Ralph Loop = multi-pass, context reset each iteration
- "Smart zone" = first 40-60% of context window
- By resetting, every task gets full smart zone

**Decisions Made:**
- Hard reset between every task iteration
- No conversation history in context
- Task-specific files (attempts.md, activity.md) provide context
- Main loop script handles orchestration, not the LLM

**Open Questions:**
- None - approach is core to Ralph philosophy

### 5.5 Manager-Worker Architecture (7-Step Execution Cycle)

**Overview:**
The Ralph Loop uses a Manager-Worker pattern to balance orchestration intelligence with fresh context principles:

**The 7-Step Cycle:**

1) **Loop Start**: `ralph-loop.sh` starts a new iteration.

2) **Manager Spawn**: Wrapper invokes the selected tool's Manager agent (example: `opencode --agent manager`; if `--tool claude` then `claude --agent manager`).

3) **Task Selection**: Manager reads `TODO.md` and dependency tracker; picks next priority task that is dependency-unblocked.

4) **Subagent Invocation**: Manager calls the Worker via a tool call (fresh context) and waits for completion.

5) **Execution**: Worker reads:
   - `.ralph/tasks/{id}/TASK.md`
   - `.ralph/tasks/{id}/activity.md`
   - `.ralph/tasks/{id}/attempts.md`
   Worker performs the work, then:
   - Updates `activity.md` and `attempts.md` with execution details
   - Returns response to Manager with signal and optional message

**Worker Response Format:**
```
TASK_COMPLETE_XXXX
TASK_INCOMPLETE_XXXX  
TASK_FAILED_XXXX: <brief error description>
TASK_BLOCKED_XXXX: <reason for blockage>
```

The signal is always on the first token position. For FAILED and BLOCKED states, a colon follows with a terse message explaining the situation. Manager receives this response and uses it to determine next actions (update TODO.md, update deps-tracker.yaml, emit signals to bash wrapper).

6) **State Update**: Manager updates `TODO.md`; if `TASK_COMPLETE_XXXX`, Manager moves the folder from `.ralph/tasks/{id}/` to `.ralph/tasks/done/{id}/`; Manager emits grep-friendly stdout tokens.

7) **Loop Decision**: Wrapper parses **stdout** to decide continue vs exit (stdout is authoritative), using `TASK_*` tokens and/or the presence of `ALL TASKS COMPLETE, EXIT LOOP`.

**Bash Wrapper (ralph-loop.sh):**
```bash
# Pre-loop setup
sync-agents  # Update agent.md files from agents.yaml

# Main loop
while true; do
  # Spawn fresh Manager agent
  opencode --agent manager --prompt "Select and delegate next task"
  
  # Manager handles everything internally:
  # - Reads TODO.md
  # - Picks task based on dependencies
  # - Spawns Worker subagent synchronously
  # - Waits for Worker completion
  # - Updates files on completion
  # - Emits stdout signals
  # - Exits when done
  
  # Check global iteration cap
  if [ $global_iterations -ge $max_global ]; then
    echo "GLOBAL_ATTEMPT_CAP_REACHED"
    break
  fi
  
  sleep 5  # Exponential backoff with jitter
 done
```

**Key Principles:**
- **Fresh context preserved**: Both Manager and Worker get clean slate each iteration
- **No state accumulation**: Manager doesn't remember previous iterations
- **Synchronous Manager Model**: Manager invokes subagent, waits for result, updates state, emits signals, exits
- **Dynamic task selection**: Manager can pick any incomplete task, not just next in list
- **Dependency-aware**: Manager reads deps-tracker.yaml to inform selection
- **Stdout-first ingestion**: Scripts should prefer stdout for loop control; activity.md remains narrative log
- **Manager context**: Manager has no context of task activity.md files - it is the worker agent's job to report a status back to the manager via the subagent's response

**Why Not Pure Bash?**
Pure bash loop (while :; do agent; done) requires the agent to handle orchestration. By adding a Manager agent that spawns fresh each iteration, we get:
- Intelligent task selection based on current state
- Skill/agent discovery and installation
- Better error handling and coordination
- While maintaining the core Ralph principle: fresh context every time

**Decisions Made:**
- Manager spawned fresh each iteration (not persistent)
- Manager uses decomposer agent type from agents.yaml
- Worker agents are task-type specific (developer, tester, etc.)
- One task per iteration (serial execution)
- Signals emitted to stdout for programmatic triggers (activity.md is secondary/narrative)
- Future: Can enable parallel by modifying Manager prompt to delegate multiple tasks

**Open Questions:**
- None - architecture is clear

### 6. Task Organization & Granularity

**Key Points:**
- Fine-grained tasks preferred for smaller context windows
- Allows use of capable local LLMs vs cloud models
- Slower but more reliable for autonomous execution
- Each task should be completable in one context window

**Task Size Guideline:**
- Tasks should be completable by a reasonably-competent human in **less than 2 hours**
- If estimated completion time exceeds 2 hours, decompose further
- No arbitrary limit on total number of tasks
- Bite-size chunks enable better tracking and recovery

**Task Estimation (T-Shirt Sizing):**
During Phase 2 (Decomposition), the decomposer agent estimates task complexity using T-shirt sizing:

| Size | Human Time | Complexity |
|------|-----------|------------|
| XS | 0-15 min | Trivial (fix typo, add comment) |
| S | 15-30 min | Simple (add test, refactor function) |
| M | 30-60 min | Moderate (implement endpoint, add validation) |
| L | 1-2 hours | Complex (implement feature, integrate API) |
| XL | >2 hours | **Must decompose** - too large for reliable completion |

**Sizing Process:**
1. Agent analyzes each task during decomposition
2. Assigns size based on files to modify, dependencies, test requirements
3. XL tasks are immediately decomposed before entering TODO.md
4. Initial estimate can be adjusted by task agent if discovered to be incorrect

**Rationale:** AI success rates drop precipitously on longer tasks (100% on <4 min tasks, <10% on >4 hour tasks per METR research). Keeping tasks under 2 hours balances throughput with reliability.

**Task Ordering:**
- **TODO.md order is fixed once created** - tasks are not reordered
- **Dynamic selection**: Manager agent picks any incomplete task each iteration based on:
  - Dependency information from deps-tracker.yaml
  - Task priority and complexity
  - Current project state
- Manager has freedom to choose the "most important" task to work on next
- Task order in TODO.md is informational only, not prescriptive

**Dependency Tracking:**
- **File:** `.ralph/tasks/deps-tracker.yaml`
- **Format:** Each task lists its dependencies and what it blocks
- **Example:**
  ```yaml
  # .ralph/tasks/deps-tracker.yaml
  tasks:
    0001:
      depends_on: []
      blocks: [0003]           # Tasks that depend on this one
    0002:
      depends_on: []
      blocks: [0003]
    0003:
      depends_on: [0001, 0002]
      blocks: [0004]
    0004:
      depends_on: [0003]
      blocks: []
    0005:
      depends_on: []
      blocks: []
  ```
- **Note:** This models direct dependencies only. Manager agent uses YAML parsing and graph mapping to detect circular dependencies and evaluate transitive relationships.
- **Phase 2 (Decomposition)**: decomposer agent performs initial dependency analysis and creates first-pass deps-tracker.yaml
- **Runtime Discovery** (Primary mechanism): Dependencies are largely discovered dynamically during execution:
  1. Worker attempts task, discovers it requires output from another task
  2. Worker reports back INCOMPLETE or FAILED with message explaining dependency (e.g., "Task 0005 needs XYZ from task 0003")
  3. Manager receives message, has full context of TODO.md (knows which tasks are complete)
  4. Manager identifies related task(s), updates deps-tracker.yaml with new dependency relationship
  5. Manager exits, next iteration uses updated dependency information
- **Manager Context**: Manager reads complete TODO.md each iteration and knows task completion status, so it can determine if dependencies are met (COMPLETE tasks unblock dependents, INCOMPLETE/FAILED/BLOCKED tasks keep dependents blocked)
- **Circular Dependency Detection:**
  - Phase 2: Flagged during decomposition for human intervention
  - Runtime: Manager detects and immediately signals TASK_BLOCKED_XXXX with dependency chain

**Strict Naming Convention:**
- Task folders use **4-digit zero-padded IDs**: `tasks/0001/`, `tasks/0002/`, ..., `tasks/9999/`
- **Maximum 9999 tasks per project** (sufficient for most projects)
- If decomposition needs >9999 tasks, project is too large and should be broken into phases
- Decomposition helper script enforces this format when creating task folders
- Non-compliant folder names (e.g., `tasks/1/`, `tasks/01/`, `tasks/001/`) cause error requiring manual fix

**Task Count:**
- **Maximum 9999 tasks** (4-digit limit)
- **Only constraint:** Each task must meet the Task Size Guideline (<2 hours)
- Continue decomposing until all tasks are bite-sized and fit within 9999 task limit
- If decomposition needs >9999 tasks, project is too large and should be broken into phases

**TODO.md Strict Grammar (only these line types are allowed):**
- Task line: `- [ ] 0001: <title...>` or `- [x] 0001: <title...>`
- Abort line: `ABORT: HELP NEEDED FOR TASK 0001: <free text...>` (task ID suffix optional)
- Completion sentinel: `ALL TASKS COMPLETE, EXIT LOOP`
- Group header comment: `# <group title...>` (grouping only; no commentary)

**Current Task (canonical):**
- "Current task" means the task ID selected by the Manager for the current iteration.
- The Manager may select any incomplete task that is unblocked by dependencies (see deps-tracker.yaml).
- TODO.md is the checklist + optional grouping only; its order is informational and not a selector.

**Decisions Made:**
- Simple incrementing IDs: 0001, 0002, 0003 (no phase prefixes)
- Each task gets its own folder: .ralph/tasks/0001/
- Three files per task: TASK.md, attempts.md, activity.md
- Completed tasks moved to: .ralph/tasks/done/0001/
- Master TODO.md is simple checklist only (strict grammar enforced)
- No agent assignment during decomposition (Manager assigns at runtime)
- Dependency tracking via deps-tracker.yaml
- No limit on total task count (only size constraint)
- Current task is Manager-selected, not determined by TODO.md order

**Open Questions:**
- None - task organization approach is clear

### 6.5 Verification & Test-Driven Development

**Key Points:**
- Every task must have testable acceptance criteria
- Tasks are not complete until all tests pass (strict TDD approach)
- "Tests" are broadly defined - not just code tests

**TDD for All Tasks:**
```markdown
## In TASK.md - Acceptance Criteria
- [ ] Criterion 1: Specific requirement
- [ ] Criterion 2: Specific requirement
- [ ] All tests pass (defined per task type)
- [ ] No scope creep (only what was requested)
```

**Test Types by Agent:**
- **developer**: Unit tests, integration tests, coverage >80%
- **tester**: Test cases validate, edge cases covered, regression tests pass
- **ui-designer**: Visual tests, accessibility checks, responsive validation
- **writer**: Review agent checks for gaps/errors in documentation
- **architect**: Design validation, pattern compliance review
- **researcher**: Source verification, accuracy checks
- **decomposer**: Task completeness validation, dependency verification

**Verification Flow:**
1. Agent reads acceptance criteria from TASK.md
2. Implements solution
3. Runs appropriate verification (tests, lint, typecheck, review)
4. All criteria must be checked before TASK_COMPLETE_XXXX signal
5. Agent writes brief reflection in activity.md explaining how work meets criteria

**Failure Handling:**
- Verification failure → TASK_INCOMPLETE_XXXX → log failure → next iteration
- Same agent retries with fresh context
- No partial credit - all gates must pass

**Decisions Made:**
- TDD approach: write/define tests first, then implement
- Broad definition of "test" (review agents count as tests)
- Per-task acceptance criteria in TASK.md (self-contained)
- Same agent retries on failure (no handoff)
- All gates must pass before completion signal

**Open Questions:**
- None - verification approach is clear

### 7. State Tracking & Git Integration

**Key Points:**
- Git provides natural state management via commits
- Each successful task = one commit
- Failed attempts tracked in files (not git)
- Current task is the task ID selected by the Manager for the current iteration (not determined by TODO.md order)

**Git Workflow:**

**Branch Management:**
- At decomposition phase start, check current git branch
- If on `master` or `main`, create new branch for the work effort
- If on any other branch, assume current branch is intended for this work
- The branch current when decomposition completes becomes the **primary branch** for this effort
- Each task works in a **dedicated branch**: `task-001`, `task-002`, etc.
- When task starts: `git checkout -b task-XXX` from primary branch
- When task completes: merge back to primary branch using **squash commit**

**Commit Standards:**
- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Format: `type(scope): subject`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, etc.
- Commit messages are **arbitrary but meaningful** - no strict template
- Examples:
  - `feat(parser): implement YAML frontmatter extraction`
  - `fix(installer): handle pip extras syntax correctly`
  - `test(apt): add error handling for missing packages`

**Squash Merge:**
- Each task branch is squash-merged into primary branch
- Single commit per task on primary branch
- Task branch deleted after successful merge (cleanup)

**Branch Cleanup:**
- Task branches are deleted after merge to primary branch
- History preserved via squash commit on primary branch
- No long-lived task branches (transient only)

**Note:** The `.gitignore` file should exclude `.ralph/tasks/` to prevent ephemeral task execution data from being committed. Completed tasks in `.ralph/tasks/done/` can optionally be included in version control for historical record, or excluded based on team preference.

**Decisions Made:**
- File-based tracking for active/in-progress work
- Git commits only for fully successful tasks
- New branch per task created at task start
- Squash merge to primary branch on completion
- Conventional Commits format (but flexible)
- Primary branch determined at decomposition completion
- Task branches deleted after merge (no archiving)
- No tags on commits (not necessary)

**Open Questions:**
- None - git workflow is clear

### 7.5 Git Conflict Handling

**Key Points:**
- Conflicts can occur if TODO.md or deps-tracker.yaml are edited while loop is running
- Manager must detect and handle conflicts gracefully
- Safety-first approach: abort rather than auto-resolve incorrectly

**Conflict Detection:**
Manager checks for git merge conflicts at loop iteration start:
```bash
# Check for merge conflicts in critical files
if git status | grep -E "(TODO.md|deps-tracker.yaml)" | grep -q "both modified"; then
  echo "ERROR: Git conflict detected in Ralph state files"
  echo "TASK_BLOCKED: Git merge conflict requires human resolution"
  exit 1
fi
```

**Handling Strategy:**
When Manager detects conflicts in TODO.md or deps-tracker.yaml:
1. Manager emits error message to stdout
2. Manager exits with TASK_BLOCKED signal
3. Bash wrapper terminates loop
4. Human must manually resolve conflicts:
   - Review both versions
   - Decide which changes to keep
   - Mark conflicts as resolved: `git add TODO.md`
   - Restart loop: `./ralph-loop.sh`

**Why Abort Instead of Auto-Resolve:**
- TODO.md and deps-tracker.yaml are critical orchestration state
- Incorrect auto-resolution could cause loop to skip tasks or create circular dependencies
- Human judgment needed to reconcile parallel edits
- Simple, predictable behavior (no magic)

**Prevention:**
- Don't edit TODO.md or deps-tracker.yaml while loop is running
- Use Ctrl+C to stop loop before making manual edits
- Restart loop after edits complete

**Recovery from Corruption:**
If TODO.md or deps-tracker.yaml become corrupted (invalid syntax, missing entries):
- Human uses git to revert: `git checkout HEAD -- TODO.md`
- Or regenerates from task folders manually
- No automated recovery utility needed (git provides this)

**Decisions Made:**
- Abort on conflict detection (don't auto-resolve)
- Human must manually resolve and restart
- Git provides recovery mechanism (no special utility)
- Simple detection via git status check

**Open Questions:**
- None - conflict handling is clear

### 8. Multi-LLM Support

**Tool Selection (canonical):**
- Allowed tool values: `opencode` or `claude` (no aliases).
- CLI flag: `--tool {opencode|claude}`
- Environment variable: `RALPH_TOOL={opencode|claude}`
- Precedence: CLI flag overrides env var.
- Default: `opencode` if neither is set.
- No auto-detection: the tool is explicitly selected (or defaults as above).

**Key Principles:**
- **Only ONE tool per loop** - no mixing within a single project run
- One tool per loop run (no mixing within a single project run)
- Tool selection is explicit; default is `opencode`
- The selected tool may use multiple models internally per agent configuration
- Each tool has slightly different invocation (handled via case statement in bash)
- Pluggable architecture for adding new tools in future
- Model selection handled via agents.yaml (separate from tool selection)

**Tool Invocation in ralph-loop.sh:**
The bash wrapper uses a simple case statement to invoke the selected tool:

```bash
# Determine which tool to use
TOOL="${RALPH_TOOL:-opencode}"  # Default to opencode

# Invoke appropriate tool based on selection
case "$TOOL" in
  opencode)
    cat "$PROMPT_FILE" | opencode --agent manager
    ;;
  claude)
    cat "$PROMPT_FILE" | claude -p --dangerously-skip-permissions --model opus
    ;;
  *)
    echo "ERROR: Unknown tool '$TOOL'. Supported: opencode, claude"
    exit 1
    ;;
esac
```

**Decisions Made:**
- Explicit tool selection via CLI flag or environment variable
- Hardcoded invocation patterns in ralph-loop.sh (simple, explicit, debuggable)
- No config file-based selection mechanism
- No auto-detection from system
- Single tool per project keeps orchestration simple
- Default to `opencode` for common container setup

**Open Questions:**
- None - single tool per project keeps things simple

### 9. Skills Integration

**Key Points:**
- Skills extend AI capabilities for specific domains
- Two skills pre-installed: using-superpowers, skills-finder
- Skills require OpenCode restart to activate
- Since loop restarts each iteration, skills available from iteration 2+

**Auto-Installed Skills:**
- Track all auto-installed skills in **activity.md**
- Log format: "Installed skill: @owner/repo/skill-name via skills-finder"
- Include timestamp and purpose

**Skill Dependencies:**
- If a skill requires external dependencies (apt/pip/npm packages):
  - Invoke `install-skill-deps.sh` script (in PATH)
  - Script attempts automatic dependency resolution
  - If successful, continue with task
  - If fails, treat as task failure and log appropriately
  - Log the dependency installation attempt in activity.md

**Decisions Made:**
- Pre-install using-superpowers and skills-finder globally
- All prompts must remind LLM to use using-superpowers skill
- LLM can search for and install new skills via skills-finder
- Track all skill installations in activity log
- Auto-resolve skill dependencies via install-skill-deps.sh
- No manual skill installation needed during loop

**Open Questions:**
- None - approach is clear

### 10. Signal System

**Canonical Task Status Signals (machine-parseable):**
- TASK_COMPLETE_XXXX
- TASK_INCOMPLETE_XXXX
- TASK_FAILED_XXXX
- TASK_BLOCKED_XXXX
Where XXXX is a 4-digit task ID (0001–9999).

**Signal Semantics:**
- `TASK_COMPLETE_XXXX`: done; Manager marks TODO complete and archives the task folder.
- `TASK_INCOMPLETE_XXXX`: continue; more work needed, but no "hard error."
- `TASK_FAILED_XXXX`: continue; more serious than INCOMPLETE, includes an error summary message.
- `TASK_BLOCKED_XXXX`: stop; requires human intervention and triggers TODO abort line.

**FAILED Message Format (grep-friendly):**
- `TASK_FAILED_XXXX: <short error summary>` (single line; token appears first; summary is free text).
- Example: `TASK_FAILED_0001: ImportError: No module named 'xyz'`

**Stdout-First Ingestion Rule:**
Scripts should prefer stdout for loop control, while `activity.md` remains the narrative log. Signals can appear in activity.md secondarily as audit evidence, but stdout is authoritative for programmatic triggers.

**Four Signals for Task Status:**

**Signal Emission Chain:**
1. **Worker** performs task work
2. **Worker** updates `activity.md` and `attempts.md` with execution details, progress, errors, and lessons learned
3. **Worker** returns response to Manager with signal and optional message (format: `TASK_COMPLETE_XXXX` or `TASK_FAILED_XXXX: <brief description>`)
4. **Manager** receives Worker response, uses it to determine next actions
5. **Manager** updates `TODO.md` as warranted by the signal (mark complete, add ABORT line, etc.)
6. **Manager** updates `deps-tracker.yaml` if Worker reported dependency discovery
7. **Manager** emits signal to stdout (for bash wrapper to parse)
8. **Manager** exits, bash wrapper continues or terminates based on signal

**Completion:**
- Worker writes completion details to `activity.md`
- Worker returns: `TASK_COMPLETE_0001`
- Manager marks checkbox in TODO.md: `- [x] 0001: ...`
- Manager moves task folder to done/
- Manager emits signal to stdout
- Bash script calls task-complete.sh
- Git squash-merge to primary branch with conventional commit

**In Progress (Needs Another Iteration):**
- Worker updates `activity.md` with progress and lessons learned
- Worker returns: `TASK_INCOMPLETE_0001`
- Manager emits signal to stdout
- Bash loop continues, next iteration reads `activity.md`

**Failure (Error Encountered):**
- Worker updates `activity.md` with error details and attempts
- Worker returns: `TASK_FAILED_0001: <error summary>`
- Manager emits signal to stdout
- Bash loop continues for retry

**Blockage (Needs Human Help):**
- Worker determines task is blocked (hard failure, circular dependency, etc.)
- Worker updates `activity.md` with blockage details
- Worker returns: `TASK_BLOCKED_0001`
- Worker provides meaningful error message to Manager for user communication
- Manager updates TODO.md: `ABORT: HELP NEEDED FOR TASK 0001: <reason>`
- Manager emits signal to stdout
- Manager exits, bash loop detects ABORT line and terminates

**TASK_BLOCKED_XXXX Terminal Output:**
When bash loop detects ABORT, it prints:
```
[!] RALPH LOOP HALTED: TASK_BLOCKED_XXXX
Task ID: 0007
Blocked Tasks: 0007, 0012              (if multiple)
Logs: .ralph/tasks/0007/activity.md
      .ralph/tasks/0007/attempts.md
Last Error: ImportError: No module named 'xyz'
Action Required: Fix the issue manually, then remove the ABORT 
                 line from TODO.md and restart the loop.
```

**Output Components:**
- **Task ID**: The specific task(s) that are blocked
- **Logs**: Paths to activity.md and attempts.md for investigation
- **Last Error**: Error message provided by Worker agent (if available)
- **Action Required**: Clear instruction for human to resolve and restart

**Restart Process:**
1. Human investigates logs and fixes issue
2. Human removes `ABORT: HELP NEEDED FOR TASK XXX: <reason>` line from TODO.md
3. Human manually restarts loop: `./ralph-loop.sh`
4. Loop resumes with fresh Manager agent

**Decisions Made:**
- Signals emitted to stdout (primary for programmatic triggers)
- Signals may appear in activity.md as secondary narrative/audit log
- ABORT signal also written to TODO.md (easily visible)
- Completion signal moves files (preserves history)
- All signals unmistakable and deliberate
- Stdout-first ingestion for loop control decisions

**Open Questions:**
- None

### 10.5 Iteration Caps & Safety Limits

**Key Points:**
- Dual-layer protection: per-task limits and global fail-safe
- Prevents infinite resource burn on stuck tasks
- Forces human review when limits exceeded

**Configuration:**
```bash
# Environment variables / CLI flags
RALPH_TASK_MAX_ATTEMPTS=10        # Per-task attempt limit
RALPH_MAX_ITERATIONS=100          # Global loop iteration limit (optional)
```

**Per-Task Cap:**
- Each task may include `max_attempts` field (default: 10)
- Tracked in task's attempts.md or via loop counter
- When `attempts >= max_attempts`:
  1. Mark task as `blocked` in TODO.md
  2. Append `ATTEMPT_CAP_REACHED: <task-id>` to activity.md
  3. Stop further attempts until human review

**Global Iteration Limit:**
- Simple fixed limit set via CLI flag or environment variable
- Limits total number of loop iterations in a single run
- Loop counter is a bash script variable that resets to 0 every time ralph-loop.sh is executed
- When limit reached:
  1. Bash wrapper emits `GLOBAL_ITERATION_LIMIT_REACHED`
  2. Loop terminates
  3. Human must investigate progress and decide whether to continue (restart script)
- Optional: If not set, loop runs indefinitely until all tasks complete or ABORT signal

**Implementation in ralph-loop.sh:**
```bash
ITERATION=0
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-0}  # 0 = unlimited

while true; do
  if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
    echo "GLOBAL_ITERATION_LIMIT_REACHED: $MAX_ITERATIONS iterations"
    break
  fi
  
  # Run Manager iteration
  # ...
  
  ITERATION=$((ITERATION + 1))
done
```

**Cap Interaction:**
- Whichever cap is hit first wins (per-task OR global)
- In practice, per-task cap will usually trigger first
- Both caps serve as circuit breakers, not normal operation limits

**Decisions Made:**
- Per-task default: 10 attempts (configurable per task)
- Global limit: Fixed value via CLI/env var, not calculated from task count
- Loop counter resets to 0 on each script execution
- Hard stops - no automatic reset or bypass
- Human intervention required when any cap hit

**Open Questions:**
- None - iteration cap approach is clear

### 10.6 Secrets Protection — Behavioral Constraint

**Key Points:**
- Agents must never write sensitive data to the repository
- Behavioral constraint enforced through prompts, not automated scanning
- External tools available for detection if needed

**Behavioral Constraint:**
Agents **MUST NOT** write secret values to:
- Repository files (source code, configs)
- Log files (`activity.md`, `attempts.md`, `TODO.md`)
- Commit messages
- Any other project artifacts

**Secrets Include:**
- API keys and tokens
- Passwords and credentials
- Private keys (SSH, TLS, etc.)
- Database connection strings with passwords
- Any high-entropy secret values

**Enforcement:**
- Stated clearly in agent prompts
- Agents self-police based on constraint
- If secrets accidentally committed, human must rotate them immediately
- No automated scanning required (external tools available if desired)

**Decisions Made:**
- Instruction-only constraint (no regex/entropy scanning)
- Clear behavioral rule in all agent prompts
- Human responsible for detection via external tools if needed
- Accidental exposure handled via standard security incident response

**Open Questions:**
- None - secrets protection approach is clear

### 10.7 Retry Strategy & Backoff

**Key Points:**
- Exponential backoff with jitter between iterations
- Distinguish transient vs permanent failures
- Circuit breaker for external dependencies

**Backoff Configuration:**
```yaml
# Default retry behavior
retry_policy:
  strategy: "exponential_backoff"
  base_delay: 5        # seconds
  max_delay: 60        # cap at 1 minute
  jitter: true         # add randomness
# Note: max_iterations handled in Section 10.5 (Iteration Caps)
```

**Failure Classification:**
- **Transient** (retry with backoff): Rate limits, timeouts, connection refused, 503 errors
- **Permanent** (retry immediately): Syntax errors, logic errors, test failures, compilation errors
- **Dependency** (circuit breaker): External service unavailable, dependency failures

**Circuit Breaker Behavior:**
- After 3 consecutive dependency failures, pause and escalate to human
- Log error to task's activity.md and attempts.md
- Loop terminates with ABORT signal
- Human intervention required before resuming

**Retry Control:**
- Bash script (ralph-loop.sh) manages all delays and timing
- No agent-controlled timing (keeps it simple)
- No timeout mechanism - trust the tool (opencode/claude) to handle their own timeouts
- If Worker hangs indefinitely, human must intervene with Ctrl+C
- Immediate exit on SIGTERM/SIGINT (no graceful shutdown needed)

**Decisions Made:**
- Exponential backoff prevents thundering herd problems
- Classification prevents wasting iterations on unrecoverable errors
- Circuit breaker terminates loop for external dependency issues
- Script controls timing, not agents
- Rate limit handling delegated to underlying CLI

**Open Questions:**
- None - retry strategy is clear

### 10.8 Inter-Worker Coordination

**Key Points:**
- Workers can request assistance from other agent types during task execution
- Handoffs use extended TASK_INCOMPLETE signal format with activity.md reference
- Manager tracks handoff state and enforces 5-invoke limit per task
- Coordination preserves fresh context principle while enabling expertise collaboration

**Handoff Signal Format:**
```
TASK_INCOMPLETE_XXXX:handoff_to:agent_type:see_activity_md
```

**Handoff Request Workflow:**
1. **Worker Request**: Original worker needs assistance, updates activity.md with request
2. **Handoff Signal**: Returns handoff signal to Manager
3. **Manager Coordination**: Tracks handoff count, invokes target agent
4. **Delegated Worker**: Reads activity.md, completes request, returns handoff completion
5. **Return to Original**: Manager re-invokes original worker with completed assistance

**5-Invoke Limit:**
- Maximum 5 total subagent invocations per task (original + 4 handoffs)
- Manager tracks `handoff_count` and `current_agent_type` in memory
- If limit reached, Manager returns TASK_INCOMPLETE (no further handoffs)
- Original worker must complete task or return different signal

**Handoff Request Format in activity.md:**
```markdown
## Handoff Request
**To:** target_agent_type
**From:** original_agent_type  
**Request:** specific assistance needed
**Context:** relevant background information
**Return To:** original_agent_type after completion
```

**Handoff Completion Format:**
```markdown
## Handoff Completion
**Requested By:** original_agent_type
**Completed By:** delegated_agent_type
**Request:** summary of original request
**Work Done:** what was accomplished
**Findings:** any discoveries or recommendations
**Return To:** original_agent_type
```

**Common Handoff Scenarios:**
- **developer → tester**: "Create comprehensive tests for implemented code"
- **tester → developer**: "Fix bugs discovered during testing"
- **architect → developer**: "Implement this design specification"
- **developer → architect**: "Review implementation and suggest improvements"
- **ui-designer → developer**: "Implement this design with responsive layout"
- **researcher → writer**: "Create documentation based on research findings"

**Manager Handoff Coordination:**
- Parse `:handoff_to:agent_type:see_activity_md` from TASK_INCOMPLETE signals
- Increment handoff counter for the task
- Select appropriate worker agent type for delegation
- Provide handoff context when invoking delegated agent
- Track return path: `:handoff_complete:returned_to:original_agent_type`
- Enforce 5-invoke limit per task

**Error Handling:**
- **Handoff target unavailable**: Return TASK_INCOMPLETE with "handoff_failed:agent_unavailable"
- **Handoff request unclear**: Return TASK_INCOMPLETE with "handoff_failed:request_unclear"
- **Handoff limit exceeded**: Return TASK_INCOMPLETE (no further coordination)

**Decisions Made:**
- Handoffs use existing TASK_INCOMPLETE signal with extended format
- No new signal types required (preserves 4-signal system)
- Manager tracks handoff state in memory only (no persistent files)
- 5-invoke limit prevents infinite handoff chains
- activity.md serves as coordination context between agents

**Open Questions:**
- None - handoff coordination approach is clear

### 11. Infinite Loop Detection

**Detection Method:**
- At start of each task execution, the **Worker agent** checks its own **activity.md** for patterns
  - Note: Only the Worker agent has access to the task-specific activity.md context
  - Manager agent operates at TODO.md level and does not perform this check
- Look for **circular activity** (repeating the same action without progress)
- Different from healthy backtracking (trying different approaches)

**Circular Pattern Indicators:**
- Same error message appears 3+ times
- Same file modification reverted multiple times
- Attempt count exceeds reasonable threshold (>5 attempts on same issue)
- Activity log shows "Attempt X - same as attempt Y" patterns

**Response to Detected Loop (Worker Agent):**
- Worker agent immediately signals `TASK_BLOCKED_0001`
- Adds `ABORT: HELP NEEDED FOR TASK 0001` to TODO.md
- Documents detected circular pattern in attempts.md
- Loop terminates with message to user

**Iteration Counter Mechanics:**

**Per-Task Counter (Worker Agent):**
- Worker agent logs iteration count in activity.md
- Format: `Iteration: N` in each attempt entry
- Example:
  ```markdown
  ## Attempt 3 [2026-02-02 14:30]
  Iteration: 3
  Tried: Refactored database connection logic
  Result: Connection timeout after 30s
  ```
- Implicit reset: Each new task uses fresh activity.md (or appends to task-specific one)
- When `attempts >= max_attempts` (default 10), Worker signals TASK_BLOCKED

**Global Counter (Bash Script):**
- Bash script maintains simple global iteration counter
- Increments by 1 with each loop iteration
- Two checks before starting each iteration:
  1. Is TODO.md complete? (all tasks done)
  2. Is `loop_counter > max_global_iterations`?
- If either condition true: skip loop, exit script
- No complex cleanup logic needed

**Counter Interaction:**
- Per-task counter tracked by Worker in activity.md
- Global counter tracked by bash script
- Both serve as circuit breakers (whichever hits first)
- In practice, per-task limit usually triggers first

**Decisions Made:**
- Per-task: Worker logs in activity.md
- Global: Bash script simple counter
- Two-layer protection prevents resource burn
- No automatic reset - human intervention required

**Open Questions:**
- None - iteration mechanics are clear

### 12. Comparison with Existing Tools

**Mycelium (JamesPaynter):**
- ✅ Excellent file-based structure inspiration
- ✅ Docker-friendly approach
- ✅ PLAN.md → TODO.md workflow
- ❌ Wrapped in Node app (we prefer pure bash)
- ❌ Uses Docker-in-Docker (we're already in container)
- ❌ Only supports Codex (we need multi-LLM)
- ❌ Complex UI/CLI (we want minimal)
- ❌ Coding-specific (we want general tasks)

**Smart Ralph (tzachbon):**
- ✅ Built for Ralph Loop
- ✅ Fresh context per task
- ✅ Plugin-based orchestration (similar to our Manager-Worker)
- ⚠️ Requires Ralph Loop plugin (we use CLI subagents instead)

**AI Dev Tasks (snarktank):**
- ✅ Simple markdown prompts
- ✅ No plugin dependencies
- ✅ One-shot decomposition
- ⚠️ Not specifically designed for Ralph (but adaptable)

**Agent Task Decomposition (jsegov):**
- ✅ One-shot execution
- ✅ Generates structured output
- ⚠️ Requires skill installation (npx skillfish)

**Our Approach:**
- Take best from all: mycelium's file structure, ai-dev-tasks' simplicity, Ralph's philosophy, Smart Ralph's orchestration
- Pure bash loop with Manager-Worker pattern: `while :; do opencode --agent manager; done`
- Manager is the "consistent prompt" handling orchestration, then exits (fresh context maintained)
- Multi-LLM support (OpenCode primary, extensible)
- General-purpose (not just coding)
- Agent specialization for different task types
- Model-to-agent mapping for optimization
- Dynamic task selection (not locked to TODO.md order)

**Decisions Made:**
- Don't use existing tools directly (too many constraints)
- Create custom implementation inspired by best practices
- Keep it minimal and focused
- Add agent specialization as differentiator

**Open Questions:**
- None - direction is clear

### 13. Architecture Decisions & Trade-offs

**Decision: Pure Bash vs Manager-Worker vs Plugin:**
- Trade-off: Simplicity vs orchestration intelligence vs context accumulation
- **Pure Bash**: Simple, but agent must handle orchestration
- **Manager-Worker**: Bash spawns fresh Manager each iteration, Manager handles orchestration, spawns Worker
- **Plugin**: Persistent orchestrator (accumulates context)
- Winner: Manager-Worker (orchestration intelligence + fresh context per iteration)

**Decision: Markdown vs JSON for tasks:**
- Trade-off: Human readability vs machine parsing
- Winner: Markdown (LLMs are proficient with markdown)

**Decision: Serial vs Parallel Task Execution:**
- Trade-off: Slower completion vs complex coordination
- Winner: Serial tasks (simpler, more predictable)
- Note: Parallel subagents within a task are allowed and encouraged
- Future: May add parallel task execution once dependency detection is mature

**Decision: Fine-grained vs Coarse-grained Tasks:**
- Trade-off: More iterations vs context overflow risk
- Winner: Fine-grained (safer for smaller models)
- Guideline: <2 hours for competent human

**Decision: Git Branches vs Single Branch:**
- Trade-off: Branch management vs clean history
- Winner: Branches (isolation per task)
- Approach: Dedicated task branches + squash merge

**Decision: File-based State vs Database:**
- Trade-off: Simplicity vs queryability
- Winner: Files (Docker-friendly, no deps)

**Decision: Single CLI vs Multiple CLIs:**
- Trade-off: Flexibility vs complexity
- Winner: Single CLI per project (simpler orchestration)
- Note: CLI can use multiple models via agents.yaml

**Decision: YAML vs JSON for Agent Config:**
- Trade-off: Human readability vs parsing simplicity
- Winner: YAML (readable, parseable with yq)

---

## Folder Structure Mockup

**Project Using Ralph (User's Application):**

```
/proj/                           # User's project root (repo root)
├── .ralph/                      # Ralph scaffolding (created by ralph-init.sh)
│   ├── config/
│   │   └── agents.yaml          # Agent-to-model mapping
│   ├── prompts/
│   │   └── ralph-prompt.md      # Loop invocation instructions
│   ├── tasks/
│   │   ├── deps-tracker.yaml    # Dependency tracking (all tasks)
│   │   ├── done/                # Completed tasks (moved here on success)
│   │   │   └── 0001/
│   │   │       ├── TASK.md
│   │   │       ├── attempts.md
│   │   │       └── activity.md
│   │   ├── 0002/                # Active task
│   │   │   ├── TASK.md
│   │   │   ├── attempts.md
│   │   │   └── activity.md
│   │   └── 0003/                # Another active task
│   │       └── ...
│   └── specs/
│       └── PRD-*.md             # Product requirements
├── .opencode/
│   └── agents/                  # Project-scope agent definitions
│       ├── manager.md
│       ├── developer.md
│       ├── tester.md
│       └── ...
├── .claude/
│   └── agents/                  # Project-scope agent definitions
│       └── ...
├── src/                         # User's application code
├── .gitignore                   # Excludes .ralph/tasks/
└── README.md                    # User's project documentation
```

**Key Design Elements:**
- All Ralph files isolated in `.ralph/` directory
- Task folders numbered with 4-digit zero-padding (0001, 0002, ..., 9999)
- Completed tasks moved to `.ralph/tasks/done/` (preserves complete history)
- Agent-to-model mapping via `agents.yaml`
- Project-scope agent customizations in `.opencode/agents/` and `.claude/agents/`
- `.gitignore` should exclude `.ralph/tasks/` to keep ephemeral task data out of version control
- `.ralph/tasks/done/` optionally included or excluded by team preference
- No code in `.ralph/` (data only)

## Ralph Implementation Repository Structure

**Jeeves Repository (Ralph Source Code):**

```
/proj/jeeves/                    # Jeeves implementation repository
├── bin/                         # Top-level utilities (staged to /usr/local/bin)
│   ├── install-agents.sh
│   ├── install-skills.sh
│   ├── ralph-init.sh            # Initialize Ralph in a project
│   ├── ralph-loop.sh            # Main task execution loop
│   ├── task-create.sh           # Create new task
│   ├── task-complete.sh         # Mark task as complete
│   └── ...                      # Other Ralph CLI utilities
├── Ralph/                       # Ralph templates (staged to /opt/jeeves/Ralph)
│   ├── templates/
│   │   ├── agents/              # Default agent definitions
│   │   │   ├── manager.md
│   │   │   ├── developer.md
│   │   │   ├── tester.md
│   │   │   └── ...
│   │   ├── config/
│   │   │   └── agents.yaml.template
│   │   ├── prompts/
│   │   │   └── ralph-prompt.md.template
│   │   ├── TODO.md.template     # Task breakdown template
│   │   └── TASK.md.template     # Individual task template
│   └── README-Ralph.md          # Installation and usage guide
├── Deepest-Thinking/            # Existing Jeeves feature
├── PRD/                         # Existing Jeeves feature
├── docs/
│   ├── commands.md
│   ├── configuration.md
│   └── troubleshooting.md
├── Ralph.md                     # This PRD (at repository root)
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

**Implementation Notes:**
- Bash scripts in `/proj/jeeves/bin/` are staged to `/usr/local/bin/` in container
- Templates in `/proj/jeeves/Ralph/` are staged to `/opt/jeeves/Ralph/` in container
- Follows same pattern as existing Deepest-Thinking and PRD features
- TODO.md.template and TASK.md.template provide scaffolding for new projects

**Dockerfile Staging:**
```dockerfile
# Stage scripts to system PATH
COPY jeeves/bin/* /usr/local/bin/

# Stage templates to standard location
COPY jeeves/Ralph /opt/jeeves/Ralph
```

---

## Additional Crucial Information

### Success Criteria

**For Individual Tasks:**
- All acceptance criteria in TASK.md are met
- Code follows existing project patterns
- No breaking changes to existing functionality
- TASK_COMPLETE_XXXX signal present in activity.md
- Agent-appropriate model was used (per agents.yaml)

**For Full Project:**
- All TODO.md checkboxes marked complete
- ALL TASKS COMPLETE, EXIT LOOP line present
- All task folders in done/
- Git branches created and merged for each task
- Conventional commits on primary branch
- Zero container startup failures from script

**For Ralph Loop Itself:**
- Context reset verified (no accumulation)
- Loop terminates on completion signal
- Loop terminates on abort signal
- Idempotent (safe to run multiple times)
- Defensive (errors don't crash container)

### Failure Modes & Mitigation

**Impossible Task Detection:**
- Task attempts logged in attempts.md
- If same failure pattern repeats 3+ times, LLM should signal TASK_BLOCKED
- Human intervention via ABORT signal

**Infinite Loop Prevention:**
- Agent analyzes activity.md for circular patterns at start
- Circular activity = same error/approach repeating without progress
- Detection triggers immediate TASK_BLOCKED_XXXX signal
- Human intervention via ABORT signal

**Context Overflow (Within a Task):**
- Design tasks to fit in one context window (<2 hours human time)
- If task too large, decompose further
- LLM can signal TASK_BLOCKED_XXXX if task exceeds capacity

**Git Failures:**
- If git commit fails, log error but continue
- Don't block loop on git issues
- Manual recovery possible later

### Extensibility

**Adding New Agents:**
1. Add agent definition to agents.yaml
2. Define preferred_models and fallback
3. Create example task using new agent
4. Test with appropriate CLI

**Adding New Tools:**
1. Add case in ralph-loop.sh switch statement
2. Add tool-specific invocation pattern documentation
3. Add tool-specific overrides in agents.yaml
4. Test with new tool

**Adding New Skills:**
1. Install skill globally (available from iteration 2)
2. Or: LLM installs via skills-finder during loop
3. If skill has external deps, install-skill-deps.sh handles automatically
4. Update prompts to reference new skill
5. Track installation in activity.md

**Generalizing for Other Projects:**
1. Copy .ralph/ structure
2. Replace TODO.md with new project tasks
3. Update agents.yaml for project-specific model preferences
4. Update ralph-instruction.md if needed
5. Run ralph-init.sh

### 14. RULES.md - Hierarchical Learning Capture

**Purpose:** Capture project-wide patterns, preferences, and learnings discovered during Ralph execution. Lives in the actual codebase (outside .ralph/) for visibility and versioning with code.

#### 14.1 File Locations and Scope

- **File name:** Always `RULES.md` (no variants)
- **Scope:** A `RULES.md` applies to its directory and all subdirectories, unless a deeper `RULES.md` contains `IGNORE_PARENT_RULES`
- **Hierarchy:** For any file `PATH`, applicable rules come from the repo root downward to the deepest directory that contains `RULES.md` on the path to `PATH`

**Example Hierarchy:**
```
/proj/
  RULES.md              # project-wide
  src/
    RULES.md            # src-wide
    api/
      RULES.md          # src/api-specific
      handlers/
        user_handler.py
  tests/
    RULES.md
    ui/
      RULES.md
      components/
        button_test.py
```

**Lookup Algorithm:**
1. Compute the directory path of the file being modified
2. Walk upward to the project root collecting all `RULES.md` paths:
   - `tests/ui/components/RULES.md` (if exists)
   - `tests/ui/RULES.md`
   - `tests/RULES.md`
   - `/RULES.md`
3. While walking, if a `RULES.md` contains `IGNORE_PARENT_RULES` (on its own line), stop collecting at that file
4. Read collected files in **root → leaf order** (outermost first, deepest last)
5. On conflicts, deepest file's guidance takes precedence

**IGNORE_PARENT_RULES Behavior:**
- Literal token `IGNORE_PARENT_RULES` on its own line in a RULES.md file
- No parent RULES.md files are loaded for paths under that directory
- Example: If `/tests/ui/RULES.md` contains `IGNORE_PARENT_RULES`, then for files in `tests/ui/` only `/tests/ui/RULES.md` is loaded

#### 14.2 When and How Agents Modify RULES.md

**Where Agents Can Write:**
- Agents may only auto-edit the **nearest RULES.md** for files worked on in that task (deepest in directory tree)
- Agents must NOT auto-edit parent RULES.md files
- To propose parent-level changes, use "Proposals to Parent Rules" section

**Conditions for Auto-Adding a Rule:**
An agent may add a new rule entry only if **all** conditions are met:

1. **Repetition Threshold:**
   - Same issue/pattern appeared in **at least 2 prior attempts** for this task (per `attempts.md`)
   - **OR** same pattern appeared across **2 different tasks** (per their `attempts.md` / `activity.md`)

2. **Clear Generalization:**
   - Rule can be phrased generally, not tied to single file
   - Example: "Use `mktemp` for temporary files in bash scripts" (good)
   - Not: "Fix tmp123.sh like this" (bad)

3. **No Direct Contradiction:**
   - New guidance must not contradict existing rules at same depth
   - If contradiction exists, refine to be more specific or explicitly override

4. **Rate Limiting:**
   - **Maximum 1 new auto-generated rule per task**
   - Prevents RULES.md from exploding with noise

**Rule Format (Auto-Discovered):**
```markdown
## Auto-Discovered Patterns

- AUTO [2026-02-01][task-007]:
  - Context: Repeated failures when creating temp files for bash scripts; collisions in /tmp.
  - Rule: Use `mktemp` to create temporary files in bash scripts instead of fixed filenames.
```

**Required Elements:**
- **Prefix:** `AUTO` to distinguish from curated rules
- **Date and task id:** `[YYYY-MM-DD][task-XXX]` for traceability
- **Context line:** Short explanation of pattern origin
- **Rule line:** General guidance, not file-specific

**Handling Conflicts and Overrides:**
- **Refinement preferred:** Make rule more specific (subdirectory, file type, situation) rather than conflicting
- **Explicit override format:**
  ```markdown
  - AUTO [2026-02-03][task-012]:
    - Overrides: Previous guidance recommending `time.sleep` for retries in API tests.
    - Rule: Use exponential backoff with capped delay instead of fixed `time.sleep` calls.
  ```

**Proposals to Parent Rules:**
- For patterns that should change global behavior, do NOT directly edit parent RULES.md
- Add proposal entry in nearest RULES.md:
  ```markdown
  ## Proposals to Parent Rules
  
  - PROPOSAL [2026-02-05][task-015]:
    - Target: Root RULES.md, section "Code Patterns".
    - Suggestion: Standardize on `black` for Python formatting; local deviations cause frequent diffs.
  ```

#### 14.3 When to Create New RULES.md Files

**Decision Criteria:**
Agents should NOT create RULES.md files in every subdirectory. Use these criteria to determine if a new file is warranted:

**Create New RULES.md When:**

1. **Directory Has Unique Patterns (2+ rules):**
   - At least 2 distinct patterns discovered that are specific to this directory
   - Patterns differ significantly from parent directory conventions
   - Example: `tests/ui/` has specific mocking patterns different from general test rules

2. **Conflicting Guidance with Parent:**
   - Multiple rules would need to override parent RULES.md (3+ overrides)
   - It's cleaner to start fresh with IGNORE_PARENT_RULES than to override extensively
   - Example: Legacy code in `src/legacy/` uses different patterns than modern `src/`

3. **Substantial Code Volume (10+ files):**
   - Directory contains 10 or more files that will be worked on
   - Creating a RULES.md reduces repetition across many files
   - Example: `src/api/handlers/` with 15+ endpoint handlers

4. **Cross-Task Patterns Emerge:**
   - Same pattern seen across 3+ different tasks in this directory
   - Pattern is stable and likely to persist
   - Example: All database migration tasks in `db/migrations/` need same approach

**Do NOT Create New RULES.md When:**

1. **Single File or Small Directory (<5 files):**
   - Just add the rule to the parent RULES.md instead
   - Exception: The file is completely different from siblings (e.g., one shell script in a Python directory)

2. **Pattern Applies Broadly:**
   - Pattern would be useful across the entire project
   - Add to root or immediate parent RULES.md instead

3. **Temporary/Experimental Code:**
   - `wip/`, `scratch/`, `temp/` directories
   - Code that's being actively refactored or moved

4. **Already Adequately Covered:**
   - Parent RULES.md has sufficient guidance
   - No significant deviations discovered

**Directory Depth Guidelines:**
- **Maximum recommended depth:** 3 levels below root (e.g., `/src/api/handlers/`)
- Beyond 3 levels, prefer adding to parent RULES.md unless strong justification exists
- Exception: Large monorepos with distinct subprojects (e.g., `/services/payments/src/`)

**Creation Format:**
When creating a new RULES.md, include minimum viable structure:

```markdown
# [Directory Name] Rules

## Code Patterns
<!-- Add discovered patterns here -->

## Common Pitfalls
<!-- Add directory-specific pitfalls here -->

## Inherited Rules
<!-- Reference to parent rules if not using IGNORE_PARENT_RULES -->
All parent RULES.md guidance applies unless overridden above.

## Auto-Discovered Patterns
<!-- Agents append here -->

## Proposals to Parent Rules
<!-- Agents add cross-cutting suggestions here -->
```

**Decision Flow:**
1. Check if nearest existing RULES.md exists and is adequate
2. If not adequate, check if pattern belongs in parent (broader applicability)
3. If truly directory-specific, check criteria above (2+ rules, 10+ files, etc.)
4. If criteria met, create new RULES.md at appropriate depth
5. If criteria not met, add to existing nearest RULES.md

**Decisions Made:**
- Avoid RULES.md proliferation (not every subfolder gets one)
- Minimum threshold: 2+ unique patterns OR 3+ overrides OR 10+ files OR 3+ cross-task occurrences
- Maximum depth: 3 levels (with exceptions for monorepos)
- Prefer parent rules when pattern is broadly applicable
- Temporary code directories excluded

#### 14.4 Content Structure

**Standard Sections:**
```markdown
# Project Rules

## Code Patterns
- Use snake_case for bash functions
- Always use `set -e` in scripts

## Common Pitfalls
- Docker commands don't work inside container
- File paths outside /proj are not accessible

## Standard Approaches
- Logging: Use print_info, print_success, etc.
- Error handling: Use trap ERR for line numbers

## Auto-Discovered Patterns
<!-- Agents append AUTO entries here when criteria are met -->

## Proposals to Parent Rules
<!-- Agents add PROPOSAL entries here for parent-level suggestions -->
```

**Decisions Made:**
- RULES.md lives in actual codebase (not .ralph/)
- Deterministic lookup algorithm (walk up tree, stop on IGNORE_PARENT_RULES)
- Read order: root → leaf, deepest wins on conflict
- Auto-population restricted to nearest RULES.md only
- Rate limited: max 1 rule per task
- Repetition threshold: must see pattern 2+ times
- Proposals to parents instead of direct parent edits
- Format includes AUTO prefix with date/task for traceability

---

## 15. Bash Utilities Specification

**Key Points:**
- Ralph requires several bash utilities for initialization, orchestration, and state management
- Scripts should be implemented in bash when possible, Python when necessary for reliability
- All scripts staged to `/usr/local/bin/` in container for PATH accessibility
- Tools like `yq` (YAML parser) and `jq` (JSON parser) pre-installed and available

### 15.1 ralph-loop.sh

**Purpose:** Main orchestration loop that spawns Manager agent repeatedly

**Location:** User's project root (created by ralph-init.sh)

**Functionality:**
- Determines tool to use (RALPH_TOOL env var or --tool flag)
- Manages loop iteration counter
- Invokes Manager agent with appropriate prompt
- Checks for completion signals or iteration limits
- Handles exponential backoff between iterations

**Implementation:** Pure bash

**Key Features:**
```bash
#!/bin/bash
# Main Ralph Loop
TOOL="${RALPH_TOOL:-opencode}"
ITERATION=0
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-0}  # 0 = unlimited

while true; do
  # Check iteration limit
  if [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ]; then
    echo "GLOBAL_ITERATION_LIMIT_REACHED"
    break
  fi
  
  # Invoke Manager based on selected tool
  case "$TOOL" in
    opencode) cat PROMPT.md | opencode --agent manager ;;
    claude) cat PROMPT.md | claude -p --dangerously-skip-permissions --model opus ;;
    *) echo "ERROR: Unknown tool '$TOOL'"; exit 1 ;;
  esac
  
  # Check for ABORT signal in TODO.md
  if grep -q "^ABORT:" TODO.md 2>/dev/null; then
    echo "TASK_BLOCKED detected in TODO.md - loop halted"
    break
  fi
  
  # Check for completion
  if grep -q "^ALL TASKS COMPLETE" TODO.md 2>/dev/null; then
    echo "All tasks complete - loop finished"
    break
  fi
  
  ITERATION=$((ITERATION + 1))
  sleep 5  # Simple backoff
done
```

### 15.2 ralph-init.sh

**Purpose:** Initialize Ralph scaffolding in a project

**Location:** `/usr/local/bin/ralph-init.sh` (globally installed)

**Functionality:**
- Creates `.ralph/` directory structure
- Copies template files (agents.yaml, prompts, etc.)
- Creates ralph-loop.sh in project root
- Checks for existing RULES.md (uses if present, creates from template if not)
- Initializes git branch if needed
- Creates initial .gitignore entries for .ralph/tasks/

**Implementation:** Bash preferred, Python acceptable

**Key Features:**
- Idempotent (safe to run multiple times)
- Detects existing Ralph installation and asks before overwriting
- Sources templates from `/opt/jeeves/Ralph/templates/`

### 15.3 sync-agents

**Purpose:** Synchronize agent model configuration from agents.yaml to agent.md files

**Location:** `/usr/local/bin/sync-agents` (globally installed)

**Functionality:**
- Runs once before ralph-loop.sh starts
- Reads `.ralph/config/agents.yaml`
- Updates `model:` frontmatter in agent.md files (project-specific and global)
- Handles both opencode and claude agent file locations
- Preserves all other content in agent files

**Implementation:** 
- Bash with `yq` for YAML parsing (preferred)
- Python if YAML frontmatter manipulation proves unreliable in bash

**Agent File Locations:**
- Project-specific: `.ralph/agents/*.md`, `.opencode/agents/*.md`, `.claude/agents/*.md`
- User-global: `~/.config/opencode/agents/*.md`, `~/.claude/agents/*.md`

**Algorithm:**
```bash
#!/bin/bash
# Read agents.yaml and update agent.md files
AGENTS_YAML=".ralph/config/agents.yaml"
TOOL="${RALPH_TOOL:-opencode}"

# For each agent type in agents.yaml
for agent in $(yq eval '.agents | keys | .[]' "$AGENTS_YAML"); do
  model=$(yq eval ".agents.$agent.preferred_models.$TOOL" "$AGENTS_YAML")
  
  # Update project-specific agent files
  for agent_file in .ralph/agents/$agent.md .opencode/agents/$agent.md .claude/agents/$agent.md; do
    if [ -f "$agent_file" ]; then
      # Update model: field in frontmatter (preserve everything else)
      # Implementation details depend on yq or Python
    fi
  done
done
```

### 15.4 task-create.sh

**Purpose:** Helper to create new task folder with proper structure

**Location:** `/usr/local/bin/task-create.sh` (globally installed)

**Functionality:**
- Finds next available task ID (4-digit zero-padded)
- Creates `.ralph/tasks/XXXX/` folder
- Generates TASK.md, attempts.md, activity.md from templates
- Optionally adds entry to TODO.md

**Implementation:** Pure bash

**Usage:**
```bash
task-create.sh "Implement color extraction API"
# Creates .ralph/tasks/0042/ with template files
```

### 15.5 task-complete.sh

**Purpose:** Handle task completion (called by Manager or manually)

**Location:** `/usr/local/bin/task-complete.sh` (globally installed)

**Functionality:**
- Moves task folder from `.ralph/tasks/XXXX/` to `.ralph/tasks/done/XXXX/`
- Performs git squash merge of task branch to primary branch
- Deletes task branch after successful merge
- Updates TODO.md to mark task complete

**Implementation:** Pure bash

**Usage:**
```bash
task-complete.sh 0042
# Moves folder, performs git operations, updates TODO.md
```

### 15.6 Required Tools (Pre-installed)

The following tools must be available in the container:

- **yq** - YAML parser (for agents.yaml, deps-tracker.yaml)
- **jq** - JSON parser (for any JSON config files)
- **git** - Version control
- **grep, awk, sed** - Text processing
- **bash 4.0+** - Shell scripting

**Installation in Dockerfile:**
```dockerfile
RUN apt-get update && apt-get install -y \
    yq \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*
```

**Decisions Made:**
- Bash preferred for simplicity and alignment with "Ralph is a bash loop"
- Python permitted when YAML/frontmatter manipulation requires reliability
- All utilities staged to /usr/local/bin for global access
- Templates staged to /opt/jeeves/Ralph/templates/
- yq and jq pre-installed for YAML/JSON parsing
- Scripts should be idempotent and defensive

**Open Questions:**
- None - utilities specification is clear

---

## Appendix A: Signal System Specification

This appendix provides detailed specifications for the Ralph Loop signal system. These definitions are foundational and must be strictly followed by all agent implementations.

### A.1 Signal Format

All signals follow the canonical format: `TASK_<STATUS>_<TASKID>`
- `<STATUS>`: One of COMPLETE, INCOMPLETE, FAILED, BLOCKED
- `<TASKID>`: 4-digit zero-padded task identifier (0001-9999)
- Signal must appear as first token in output for grep-friendly parsing

### A.2 TASK_COMPLETE_XXXX

**Purpose:** Indicates successful task completion with all acceptance criteria met.

**Format:** `TASK_COMPLETE_XXXX`

**Emission Chain:**
1. Worker completes all acceptance criteria
2. Worker updates activity.md with completion details
3. Worker returns `TASK_COMPLETE_XXXX` to Manager
4. Manager marks checkbox in TODO.md: `- [x] 0001: ...`
5. Manager moves task folder from `.ralph/tasks/{id}/` to `.ralph/tasks/done/{id}/`
6. Manager emits signal to stdout
7. Bash script calls task-complete.sh for git operations
8. Git squash-merges to primary branch with conventional commit

**Manager Actions:**
- Update TODO.md: mark task complete
- Move task folder to done/
- Emit signal to stdout
- Continue loop

**Examples:**

**Example 1: Clean Task Completion**
```
Worker output:
TASK_COMPLETE_0042

Manager actions:
1. Marks task 0042 complete in TODO.md: "- [x] 0042: ..."
2. Moves folder: .ralph/tasks/0042/ → .ralph/tasks/done/0042/
3. Emits: TASK_COMPLETE_0042
```

**Example 2: Full Emission Chain with Git Operations**
```
Step 1: Worker completes acceptance criteria
  - All 5 checkboxes verified in TASK.md
  - activity.md updated with completion details

Step 2: Worker signals completion
  Worker output: TASK_COMPLETE_0015

Step 3: Manager processes completion
  - TODO.md: "- [x] 0015: Define API endpoints"
  - Folder moved to .ralph/tasks/done/0015/
  - Signal emitted: TASK_COMPLETE_0015

Step 4: Bash wrapper detects signal
  - Calls task-complete.sh 0015

Step 5: Git squash-merge
  - git checkout main
  - git merge --squash task-0015
  - git commit -m "feat(api): define API endpoints for v2"
  - git push origin main

Step 6: Loop continues to next task
```

**Example 3: Completion with activity.md Update**
```
Initial activity.md state:
## Task 0023: Fix login bug
### Attempt 1 (2026-02-04 10:00)
- Identified race condition in auth flow
- Applied mutex fix

Worker signals completion:
TASK_COMPLETE_0023

Updated activity.md after completion:
## Task 0023: Fix login bug
### Attempt 1 (2026-02-04 10:00)
- Identified race condition in auth flow
- Applied mutex fix

### Completion (2026-02-04 10:15)
- Race condition resolved
- All tests passing (23/23)
- Signal: TASK_COMPLETE_0023

Manager actions:
1. Reads completion details from activity.md
2. Marks TODO.md: "- [x] 0023: Fix login bug"
3. Moves folder to done/
4. Emits: TASK_COMPLETE_0023
```

### A.3 TASK_INCOMPLETE_XXXX

**Purpose:** Indicates task needs additional work but has not encountered a hard error.

**Format:** `TASK_INCOMPLETE_XXXX`

**Emission Chain:**
1. Worker makes progress but task is not fully complete
2. Worker updates activity.md with progress and lessons learned
3. Worker returns `TASK_INCOMPLETE_XXXX` to Manager
4. Manager emits signal to stdout
5. Bash loop continues, next iteration reads activity.md

**Manager Actions:**
- Emit signal to stdout
- Continue loop for retry with exponential backoff (see Section 10.7)
  - Base delay: 5 seconds
  - Max delay: 60 seconds
  - With jitter: true
- Do NOT mark task complete

**Use Cases:**
- Task partially completed, needs another iteration
- Worker needs to try different approach
- Dependencies not yet ready

### A.4 TASK_FAILED_XXXX

**Purpose:** Indicates task encountered an error during execution.

**Format:** `TASK_FAILED_XXXX: <error summary>`

**Emission Chain:**
1. Worker encounters error during execution
2. Worker updates activity.md with error details and attempts
3. Worker returns `TASK_FAILED_XXXX: <error summary>` to Manager
4. Manager emits signal to stdout
5. Bash loop continues for retry

**Manager Actions:**
- Emit signal to stdout
- Continue loop for retry with exponential backoff
- Log error for debugging

**Error Summary Guidelines:**
- **Format:** Brief single-line description, maximum 100 characters
- Be specific but concise
- Include error type when possible
- No newlines or special characters
- Examples:
  - `TASK_FAILED_0001: ImportError: No module named 'xyz'`
  - `TASK_FAILED_0002: SyntaxError: invalid syntax at line 42`
  - `TASK_FAILED_0003: Connection timeout after 30s`

**When to Use FAILED vs BLOCKED:**
- **FAILED (recoverable errors):**
  - Test failures
  - Syntax/compilation errors
  - Missing dependencies (installable)
  - Configuration issues
  - Timeout errors (transient)

- **BLOCKED (immediate, unrecoverable):**
  - Circular dependencies
  - Design decisions requiring human approval
  - External services permanently unavailable
  - Same error repeated 3+ times without resolution
  - Security concerns or policy violations

### A.5 TASK_BLOCKED_XXXX

**Purpose:** Indicates task requires human intervention to proceed.

**Format:** `TASK_BLOCKED_XXXX: <reason>`

**Message Format:** Same as FAILED - brief single-line description, maximum 100 characters

**Emission Chain:**
1. Worker determines task is blocked (hard failure, circular dependency, etc.)
2. Worker updates activity.md with blockage details
3. Worker returns `TASK_BLOCKED_XXXX: <reason>` to Manager
4. Manager updates TODO.md: `ABORT: HELP NEEDED FOR TASK 0001: <reason>`
5. Manager emits signal to stdout
6. Manager exits, bash loop detects ABORT line and terminates

**Manager Actions:**
- Update TODO.md with ABORT line
- Emit signal to stdout
- Exit loop (terminal)

**Escalation from FAILED to BLOCKED:**
Workers should monitor for repeated failures and escalate to BLOCKED when:
- Same error message appears 3+ times in attempts.md
- Worker has tried multiple approaches without progress
- Error is clearly unrecoverable (circular dependency, design blocker)

**Best Practice:**
- Signal FAILED immediately for recoverable errors
- Signal BLOCKED immediately for obvious blockers
- If FAILED error repeats 3+ times, escalate to BLOCKED

**Terminal Output Format:**
```
[!] RALPH LOOP HALTED: TASK_BLOCKED_XXXX
Task ID: 0007
Blocked Tasks: 0007, 0012              (if multiple)
Logs: .ralph/tasks/0007/activity.md
      .ralph/tasks/0007/attempts.md
Last Error: ImportError: No module named 'xyz'
Action Required: Fix the issue manually, then remove the ABORT 
                 line from TODO.md and restart the loop.
```

**Blockage Scenarios:**
- Circular dependency detected
- External dependency unavailable (circuit breaker)
- Max attempts exceeded (10 attempts)
- Impossible task (cannot be completed as specified)
- Git merge conflicts in state files
- Skill installation failed after retry

### A.6 Stdout-First Ingestion Rule

Scripts should prefer stdout for loop control, while `activity.md` remains the narrative log. Signals can appear in activity.md secondarily as audit evidence, but stdout is authoritative for programmatic triggers.

### A.7 Invalid Signal Handling

**Purpose:** Define Manager behavior when Worker emits malformed or missing signals.

**Invalid Signal Scenarios:**

1. **Wrong Format**
   - Example: `TASK_COMPLETE_42` (should be `0042`)
   - Example: `task_complete_0001` (wrong case)
   - **Manager Action:** Treat as `TASK_FAILED_XXXX: Invalid signal format`

2. **No Signal Emitted**
   - Worker completes without emitting any signal
   - **Manager Action:** Treat as `TASK_FAILED_XXXX: No signal received from Worker`

3. **Wrong Task ID**
   - Signal emitted for different task than currently executing
   - **Manager Action:** Treat as `TASK_FAILED_XXXX: Signal for wrong task ID`

4. **Multiple Signals**
   - Worker emits multiple conflicting signals
   - **Manager Action:** Use first signal received, ignore subsequent

**General Rule:**
When in doubt, treat invalid signals as **FAILED** (not BLOCKED). This allows the loop to retry with fresh context rather than requiring immediate human intervention.

---

## Appendix B: Auto-Discovery Rule Criteria

This appendix defines the criteria for automatically discovering rules during task execution.

### B.1 Purpose

Auto-discovered rules capture patterns observed during work that meet specific thresholds for repetition and clarity. The criteria balance learning with noise prevention.

### B.2 Criteria

**1. Repetition Threshold (2+ times)**
   - Pattern observed at least twice in attempts.md
   - Same mistake made in different contexts
   - Same solution applied successfully multiple times
   - OR pattern appeared across 2 different tasks

**2. Clear Generalization**
   - Pattern is not specific to one-off situation
   - Can be expressed as general rule (not file-specific)
   - Would help future tasks
   - Examples:
     - GOOD: "Use `mktemp` for temporary files in bash scripts"
     - GOOD: "Always use `yq` for YAML parsing, not sed/awk"
     - GOOD: "Use `set -e` in all bash scripts to exit on error"
     - GOOD: "Prefer early returns over deeply nested conditionals"
     - BAD: "Fix tmp123.sh like this"
     - BAD: "The GitHub API returns 404 for this specific repo"
     - BAD: "Change the color on line 42 to blue"

**3. No Contradiction**
   - Does not conflict with existing rules at same depth
   - If conflict exists, refine to be more specific or use "Overrides" notation
   - Override format:
     ```markdown
     - Overrides: Previous guidance recommending X
     - Rule: Use Y instead
     ```

**4. Rate Limit (1 rule per task maximum)**
   - Maximum one auto-generated rule per task
   - Prevents RULES.md from exploding with noise
   - Forces prioritization of most important patterns

### B.3 Rule Format

```markdown
- AUTO [YYYY-MM-DD][task-XXX]:
  - Context: Short explanation of pattern origin
  - Rule: General guidance, not file-specific
```

**Required Elements:**
- **Prefix:** `AUTO` to distinguish from curated rules
- **Date and task id:** `[YYYY-MM-DD][task-XXX]` for traceability
- **Context line:** Short explanation of pattern origin
- **Rule line:** General guidance, not file-specific

### B.4 Proposals to Parent Rules

For patterns that should change global behavior, do NOT directly edit parent RULES.md. Instead, add proposal entry in nearest RULES.md:

```markdown
## Proposals to Parent Rules

- PROPOSAL [YYYY-MM-DD][task-XXX]:
  - Target: Root RULES.md, section "Code Patterns"
  - Suggestion: Standardize on X instead of Y
```

### B.5 When to Create New RULES.md Files

**Create when:**
- Directory has 2+ unique patterns specific to it
- 3+ overrides needed from parent
- 10+ files in directory
- Pattern seen across 3+ different tasks

**Do NOT create when:**
- Single file or small directory (<5 files)
- Pattern applies broadly (use parent)
- Temporary/experimental code
- Already adequately covered

### B.6 Observation Process

Document what agents should watch for during task execution to identify potential rules.

**Pattern Repetition Indicators:**

- Same error message appearing in attempts.md multiple times
- Similar code changes needed across multiple files
- Repeated use of same command/tool sequence
- Consistent workaround applied to similar problems
- Same correction suggested in code review context

**Common Mistake Patterns:**

- Forgetting to check if file exists before reading
- Using wrong tool for data format (sed for JSON/YAML)
- Missing error handling in bash scripts
- Hardcoding values that should be parameterized
- Not cleaning up temporary resources
- Copy-paste errors in similar code blocks

**Successful Solution Patterns:**

- Approach that resolved issue faster than alternatives
- Technique that prevented common error
- Tool choice that simplified implementation
- Pattern that made code more maintainable
- Method that improved testability

**Anti-Patterns to Avoid:**

- Framework-specific quirks that won't generalize
- Workarounds for temporary bugs
- Project-specific naming conventions
- Version-specific behaviors
- Personal preferences without clear benefit

**When to Document:**

- Immediately when pattern is noticed (mental note)
- At end of task, review attempts.md for repetition
- Before claiming task complete, check if pattern qualifies
- Do NOT interrupt flow mid-task to write rules

### B.7 Validation Process

Document how to verify rule quality before adding to RULES.md.

**Quality Checklist:**

Before adding any auto-discovered rule, verify:

- [ ] Pattern observed at least 2 times (check attempts.md or task history)
- [ ] Rule is generalizable (not specific to one file/situation)
- [ ] No contradiction with existing rules at same depth
- [ ] Rule would help future similar tasks
- [ ] Not a one-time fix or temporary workaround
- [ ] Within rate limit (only 1 rule per task)

**Peer Review Equivalent:**

Since auto-discovery happens during solo work, simulate peer review:

1. **Wait and Reflect:** If pattern just occurred, wait for second occurrence
2. **Explain to Imaginary Peer:** Can you explain the rule without referencing specific files?
3. **Devil's Advocate:** How could this rule be misinterpreted or misapplied?
4. **Counter-Examples:** Can you think of situations where this rule should NOT apply?

**Testing the Rule:**

Validate rule against examples:

1. **Positive Test:** Find 2+ instances where following the rule would have helped
2. **Negative Test:** Ensure rule doesn't encourage bad practices
3. **Edge Cases:** Consider exceptions (when should rule not apply?)
4. **Consistency Check:** Does rule align with existing codebase patterns?

**Criteria Verification:**

| Criterion | Check Method |
|-----------|-------------|
| Repetition (2+) | Count occurrences in attempts.md or task history |
| Clear Generalization | Remove all file specifics, rule still makes sense |
| No Contradiction | Search RULES.md for conflicting guidance |
| Rate Limit | Check if any rule already added this task |

**Rejection Criteria:**

Do NOT create rule if:
- Cannot articulate clear benefit
- Applies to only one specific technology version
- Is personal coding style preference
- Conflicts with established conventions
- Would create more confusion than clarity

---

## References

### Core Philosophy & Inspiration

- **Geoffrey Huntley's Ralph Loop** - Original concept: "Ralph is a Bash loop"
  - https://ghuntley.com/ralph/

- **Ralph Wiggum Technique Explained** (Laracasts)
  - https://laracasts.com/series/leveraging-ai-for-laravel-development/episodes/18

- **The Ralph Wiggum Breakdown** (DEV Community)
  - https://dev.to/ibrahimpima/the-ralf-wiggum-breakdown-3mko

- **How-to Ralph Wiggum** (GitHub Playbook)
  - https://github.com/ghuntley/how-to-ralph-wiggum

- **Ralph Loops - Your Agent Orchestrator Is Too Clever**
  - https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/

### Implementation Patterns & Tools

- **Mycelium** (JamesPaynter) - Docker-based Ralph implementation
  - https://github.com/JamesPaynter/mycelium/tree/ralph
  - Inspiration for file structure and workflow

- **Smart Ralph** (tzachbon) - Spec-driven development plugin
  - https://github.com/tzachbon/smart-ralph
  - Philosophy and workflow patterns

- **AI Dev Tasks** (snarktank) - Task management for AI agents
  - https://github.com/snarktank/ai-dev-tasks
  - Markdown-based task generation approach

- **JeredBlu's Ralph Wiggum Guide**
  - https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md
  - Practical implementation guidance

### Additional Resources

- **Ralph Loop Agent** (Vercel Labs)
  - https://github.com/vercel-labs/ralph-loop-agent
  - Continuous autonomy patterns

- **ai-dev-tasks** - Task generation from PRDs
  - https://github.com/snarktank/ai-dev-tasks
  - generate-tasks.md pattern

- **Ralph Template** - Minimal autonomous loop
  - https://www.reddit.com/r/ClaudeAI/comments/1qgo7v5/ralphtemplate_minimal_autonomous_agent_loop_works/
  - Cross-platform loop implementation

### Skills & Extensions

- **Agent Task Decomposition** (jsegov)
  - https://mcpmarket.com/tools/skills/agent-task-decomposition
  - PRD to structured tasks conversion

- **Claude Skills Registry**
  - https://claude-plugins.dev/skills
  - Discovery of additional skills

### Architecture & Design

- **Context Engineering for AI Agents**
  - https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
  - TODO.md workflow inspiration

- **Equipping Agents with Skills** (Anthropic)
  - https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
  - Skill system architecture

- **Conventional Commits**
  - https://www.conventionalcommits.org/en/v1.0.0/
  - Commit message standard

---

## Document Information

**Version:** 2.7  
**Created:** 2026-02-01  
**Updated:** 2026-02-04  
**Purpose:** Reference guide for Ralph Loop implementation with Manager-Worker architecture, agent specialization, model mapping, task estimation, verification gates, iteration caps, secrets protection, sync-agents, dynamic task selection, hierarchical learning capture, Worker response format, dynamic dependency discovery, git conflict handling, and bash utilities specification  
**Project:** General-purpose Ralph Loop Framework  
**Status:** Implementation specification complete and ready for decomposition

---

*This document captures all decisions, patterns, and specifications for the Ralph Loop implementation. For updates or clarifications, refer to the TODO.md in the .ralph/ directory of the active project.*
