# Ralph Loop Implementation - Task Breakdown

## Summary
- **Total Tasks**: 95
- **Categories**: 10
- **Complexity Distribution**: XS (15), S (35), M (35), L (10)

---

## Category 1: Project Structure & Infrastructure (0001-0010)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0001 | Create Jeeves Ralph directory structure | Infrastructure | XS | None | Create `/proj/jeeves/Ralph/` directory tree: `templates/agents/`, `templates/config/`, `templates/prompts/`, `docs/` |
| 0002 | Create bin directory for utilities | Infrastructure | XS | None | Create `/proj/jeeves/bin/` directory for bash utilities |
| 0003 | Set up Dockerfile staging configuration | Infrastructure | S | 0001, 0002 | Add COPY commands to Dockerfile.jeeves to stage Ralph templates to `/opt/jeeves/Ralph/` and scripts to `/usr/local/bin/` |
| 0004 | Create .gitignore template for Ralph projects | Infrastructure | XS | 0001 | Create template that excludes `.ralph/tasks/` and includes patterns for ephemeral task data |
| 0005 | Create directory structure documentation | Documentation | XS | 0001 | Document the expected `.ralph/` folder structure and its purpose |
| 0006 | Implement path detection utilities | Infrastructure | S | 0002 | Create helper functions for detecting project root, Ralph directory, and agent file locations |
| 0007 | Create validation utilities | Infrastructure | S | 0002 | Implement validation functions for task IDs (4-digit format), YAML syntax, and file existence checks |
| 0008 | Set up pre-installed tools check | Infrastructure | XS | 0002 | Verify yq, jq, git availability in container environment |
| 0009 | Create error handling library | Infrastructure | S | 0002 | Standardized error functions with colorized output (print_error, print_warning, print_success, print_info) |
| 0010 | Create logging utilities | Infrastructure | S | 0009 | Standardized logging functions for consistent output across all scripts |

---

## Category 2: Bash Utilities - Core Scripts (0011-0030)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0011 | Implement ralph-init.sh - basic structure | Bash Utils | M | 0002, 0006, 0007, 0009 | Main initialization script that creates `.ralph/` scaffolding in a project |
| 0012 | Implement ralph-init.sh - template copying | Bash Utils | M | 0011 | Copy templates from `/opt/jeeves/Ralph/templates/` to project `.ralph/` directory |
| 0013 | Implement ralph-init.sh - RULES.md handling | Bash Utils | S | 0011 | Check for existing RULES.md and create from template if not present |
| 0014 | Implement ralph-init.sh - git integration | Bash Utils | S | 0011 | Initialize git branch detection and create `.gitignore` entries |
| 0015 | Implement ralph-init.sh - idempotency | Bash Utils | S | 0011 | Add checks to detect existing Ralph installation and prompt before overwriting |
| 0016 | Implement ralph-loop.sh - basic loop structure | Bash Utils | L | 0002, 0006, 0009 | Main orchestration loop with while loop and iteration counter |
| 0017 | Implement ralph-loop.sh - tool selection | Bash Utils | M | 0016 | Support `--tool` CLI flag and `RALPH_TOOL` environment variable (opencode/claude) |
| 0018 | Implement ralph-loop.sh - Manager invocation | Bash Utils | M | 0016 | Invoke Manager agent with appropriate prompt based on selected tool |
| 0019 | Implement ralph-loop.sh - signal parsing | Bash Utils | M | 0016 | Parse stdout for TASK_* signals and TODO.md ABORT/completion lines |
| 0020 | Implement ralph-loop.sh - iteration limits | Bash Utils | S | 0016 | Check `RALPH_MAX_ITERATIONS` and exit when limit reached |
| 0021 | Implement ralph-loop.sh - exponential backoff | Bash Utils | S | 0016 | Add exponential backoff with jitter between iterations (base 5s, max 60s) |
| 0022 | Implement ralph-loop.sh - pre-loop sync | Bash Utils | S | 0016, 0032 | Call sync-agents before entering main loop |
| 0023 | Implement ralph-loop.sh - conflict detection | Bash Utils | S | 0016 | Check for git merge conflicts in TODO.md and deps-tracker.yaml at iteration start |
| 0024 | Implement task-create.sh | Bash Utils | M | 0002, 0006, 0007 | Find next available 4-digit task ID, create folder structure, generate task files |
| 0025 | Implement task-complete.sh | Bash Utils | M | 0002, 0006 | Move task folder to done/, perform git squash merge, delete task branch, update TODO.md |
| 0026 | Implement sync-agents - YAML parsing | Bash Utils | M | 0002, 0008 | Parse agents.yaml using yq to extract agent types and model mappings |
| 0027 | Implement sync-agents - agent file discovery | Bash Utils | M | 0026 | Find agent.md files in project-specific and user-global locations |
| 0028 | Implement sync-agents - frontmatter update | Bash Utils | M | 0026 | Update `model:` field in agent.md frontmatter while preserving other content |
| 0029 | Implement sync-agents - multi-tool support | Bash Utils | S | 0026 | Handle both opencode and claude agent file locations |
| 0030 | Implement sync-agents - idempotency | Bash Utils | XS | 0026 | Ensure script is safe to run multiple times without side effects |

---

## Category 3: Templates - Configuration (0031-0040)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0031 | Create agents.yaml.template | Templates | S | 0001 | YAML template with all 7 agent types (architect, developer, tester, ui-designer, researcher, writer, decomposer) and model mappings |
| 0032 | Create agents.yaml - OpenCode models | Templates | XS | 0031 | Define preferred and fallback models for OpenCode tool per agent type |
| 0033 | Create agents.yaml - Claude models | Templates | XS | 0031 | Define preferred and fallback models for Claude tool per agent type |
| 0034 | Create deps-tracker.yaml.template | Templates | S | 0001 | YAML template for dependency tracking with tasks, depends_on, and blocks fields |
| 0035 | Create retry_policy.yaml.template | Templates | XS | 0001 | YAML template for retry policy configuration (exponential backoff settings) |
| 0036 | Create TODO.md.template | Templates | S | 0001 | Markdown template with strict grammar: task lines, abort lines, completion sentinel, group headers |
| 0037 | Create TASK.md.template | Templates | M | 0001 | Comprehensive task template with sections: description, acceptance criteria, agent type, max_attempts, dependencies |
| 0038 | Create attempts.md.template | Templates | XS | 0001 | Template for tracking task attempts with timestamp, iteration count, approach, and result |
| 0039 | Create activity.md.template | Templates | XS | 0001 | Template for narrative activity log with sections for progress, errors, and lessons learned |
| 0040 | Create ralph-prompt.md.template | Templates | M | 0001 | Manager agent prompt template with instructions for task selection, subagent invocation, and signal emission |

---

## Category 4: Templates - Agent Definitions (0041-0055)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0041 | Create manager.md agent definition | Agents | M | 0001 | Manager agent with orchestration instructions: read TODO.md, select task, spawn Worker, handle signals |
| 0042 | Create developer.md agent definition | Agents | S | 0001 | Developer agent for code implementation, refactoring, and bug fixes |
| 0043 | Create tester.md agent definition | Agents | S | 0001 | Tester agent for test cases, edge case detection, and QA validation |
| 0044 | Create architect.md agent definition | Agents | S | 0001 | Architect agent for system design, API design, and database schema |
| 0045 | Create ui-designer.md agent definition | Agents | S | 0001 | UI/UX agent for user interface and visual design tasks |
| 0046 | Create researcher.md agent definition | Agents | S | 0001 | Researcher agent for investigation, documentation, and analysis |
| 0047 | Create writer.md agent definition | Agents | S | 0001 | Writer agent for documentation and content creation |
| 0048 | Create decomposer.md agent definition | Agents | M | 0001 | Decomposer agent for Phase 2 decomposition: task breakdown, dependency analysis, TODO generation |
| 0049 | Add using-superpowers reminder to all agents | Agents | XS | 0041-0048 | Ensure all agent prompts remind LLM to invoke using-superpowers skill |
| 0050 | Add secrets protection constraints to agents | Agents | XS | 0041-0048 | Add behavioral constraints prohibiting writing secrets to repository files |
| 0051 | Add TDD verification requirements to agents | Agents | S | 0041-0048 | Define test types and verification gates per agent type |
| 0052 | Add infinite loop detection to worker agents | Agents | S | 0042-0048 | Instructions for checking activity.md for circular patterns and signaling TASK_BLOCKED |
| 0053 | Add signal format specifications to agents | Agents | XS | 0041-0048 | Document TASK_COMPLETE_XXXX, TASK_INCOMPLETE_XXXX, TASK_FAILED_XXXX, TASK_BLOCKED_XXXX formats |
| 0054 | Add RULES.md lookup instructions to agents | Agents | S | 0041-0048 | Instructions for discovering and reading hierarchical RULES.md files |
| 0055 | Add dependency discovery instructions to agents | Agents | S | 0041-0048 | Instructions for runtime dependency discovery and reporting to Manager |

---

## Category 5: Signal System Implementation (0056-0065)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0056 | Define TASK_COMPLETE_XXXX signal behavior | Signals | S | None | Signal emitted when task succeeds: Manager marks TODO complete, moves folder to done/, emits to stdout |
| 0057 | Define TASK_INCOMPLETE_XXXX signal behavior | Signals | S | None | Signal emitted when task needs more work: Manager emits to stdout, loop continues |
| 0058 | Define TASK_FAILED_XXXX signal behavior | Signals | S | None | Signal emitted on error with message: Manager emits to stdout, loop continues for retry |
| 0059 | Define TASK_BLOCKED_XXXX signal behavior | Signals | M | None | Signal emitted when human intervention needed: Manager updates TODO.md with ABORT line, emits to stdout, loop terminates |
| 0060 | Implement signal emission in Manager | Signals | S | 0041 | Manager emits appropriate signal to stdout after receiving Worker response |
| 0061 | Implement signal parsing in ralph-loop.sh | Signals | S | 0016 | Parse stdout for TASK_* signals to determine loop continuation |
| 0062 | Implement ABORT line detection | Signals | S | 0016 | Check TODO.md for `ABORT: HELP NEEDED FOR TASK XXXX:` lines and halt loop |
| 0063 | Implement completion sentinel detection | Signals | XS | 0016 | Check TODO.md for `ALL TASKS COMPLETE, EXIT LOOP` line |
| 0064 | Create signal handling documentation | Documentation | XS | 0056-0059 | Document all signals, their semantics, and handling procedures |
| 0065 | Add signal examples to agent prompts | Documentation | XS | 0053 | Include signal format examples in agent definition files |

---

## Category 6: Git Integration & Workflow (0066-0075)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0066 | Implement primary branch detection | Git | S | 0002 | Detect current branch at decomposition start; create new branch if on main/master |
| 0067 | Implement task branch creation | Git | S | 0002 | Create dedicated task branches (task-XXX) when task starts: `git checkout -b task-XXX` |
| 0068 | Implement squash merge workflow | Git | M | 0002, 0067 | Squash merge task branch to primary branch on completion with conventional commit format |
| 0069 | Implement task branch cleanup | Git | S | 0068 | Delete task branch after successful merge to primary branch |
| 0070 | Implement conventional commit format | Git | S | 0002 | Follow format: `type(scope): subject` with types feat, fix, docs, test, refactor, chore |
| 0071 | Implement git conflict detection | Git | S | 0002 | Check for merge conflicts in TODO.md and deps-tracker.yaml using `git status` |
| 0072 | Implement conflict abort behavior | Git | S | 0071 | On conflict detection, emit error and TASK_BLOCKED signal for human resolution |
| 0073 | Implement gitignore configuration | Git | XS | 0004 | Ensure `.ralph/tasks/` is excluded from version control while optionally including `.ralph/tasks/done/` |
| 0074 | Implement git failure handling | Git | S | 0002 | Log git errors but continue loop; don't block on git issues |
| 0075 | Create git workflow documentation | Documentation | S | 0066-0074 | Document branch strategy, commit standards, and merge procedures |

---

## Category 7: Dependency Tracking System (0076-0085)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|-------------|
| 0076 | Implement deps-tracker.yaml format | Dependencies | S | 0001 | YAML format with tasks, depends_on, and blocks fields for each task |
| 0077 | Implement dependency graph parsing | Dependencies | M | 0076 | Parse deps-tracker.yaml to build dependency graph using yq |
| 0078 | Implement circular dependency detection | Dependencies | M | 0077 | Detect circular dependencies in graph and signal TASK_BLOCKED for human intervention |
| 0079 | Implement unblocked task selection | Dependencies | M | 0077 | Manager selects next task that has no incomplete dependencies |
| 0080 | Implement runtime dependency discovery | Dependencies | S | 0077 | Handle Worker-reported dependencies: update deps-tracker.yaml with new relationships |
| 0081 | Implement transitive dependency resolution | Dependencies | M | 0077 | Calculate transitive closure to determine if dependencies are satisfied |
| 0082 | Add dependency analysis to decomposer agent | Dependencies | S | 0048 | Instructions for performing initial dependency analysis during Phase 2 decomposition |
| 0083 | Create dependency visualization helper | Dependencies | S | 0077 | Optional utility to visualize dependency graph for debugging |
| 0084 | Document dependency tracking workflow | Documentation | XS | 0076-0083 | Document format, runtime discovery, and circular dependency handling |
| 0085 | Add dependency examples to templates | Templates | XS | 0076 | Include example dependency configurations in deps-tracker.yaml.template |

---

## Category 8: RULES.md Hierarchical Learning System (0086-0095)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|
| 0086 | Create RULES.md template | RULES.md | S | 0001 | Template with standard sections: Code Patterns, Common Pitfalls, Standard Approaches, Auto-Discovered Patterns, Proposals to Parent Rules |
| 0087 | Implement RULES.md lookup algorithm | RULES.md | M | 0002 | Walk up directory tree collecting all RULES.md paths, stopping on IGNORE_PARENT_RULES |
| 0088 | Implement hierarchical rule application | RULES.md | M | 0087 | Read collected files in root-to-leaf order, with deepest rules taking precedence on conflicts |
| 0089 | Implement IGNORE_PARENT_RULES support | RULES.md | S | 0087 | Detect IGNORE_PARENT_RULES token and stop collecting parent rules |
| 0090 | Define auto-discovery rule criteria | RULES.md | S | None | Criteria: repetition threshold (2+ times), clear generalization, no contradiction, rate limit (1 rule per task) |
| 0091 | Implement auto-rule format | RULES.md | XS | 0090 | Format: `AUTO [YYYY-MM-DD][task-XXX]:` with Context and Rule lines |
| 0092 | Implement proposal format | RULES.md | XS | 0090 | Format: `PROPOSAL [YYYY-MM-DD][task-XXX]:` with Target and Suggestion lines |
| 0093 | Define new RULES.md creation criteria | RULES.md | S | None | Create when: 2+ unique patterns, 3+ parent overrides, 10+ files, or 3+ cross-task occurrences |
| 0094 | Add RULES.md instructions to agents | Agents | S | 0054 | Update all agent definitions with instructions for reading and updating nearest RULES.md |
| 0095 | Create RULES.md system documentation | Documentation | M | 0086-0094 | Comprehensive documentation of hierarchy, lookup algorithm, and modification rules |

---

## Category 9: Documentation & Examples (0096-0105)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|
| 0096 | Create README-Ralph.md | Documentation | M | All above | Installation and usage guide for Ralph Loop |
| 0097 | Create commands.md documentation | Documentation | S | 0011-0030 | Document all Ralph CLI commands and their usage |
| 0098 | Create configuration.md documentation | Documentation | S | 0031-0040 | Document agents.yaml, retry_policy.yaml, and other configuration files |
| 0099 | Create troubleshooting.md documentation | Documentation | S | All above | Common issues, debugging tips, and recovery procedures |
| 0100 | Create example project walkthrough | Documentation | M | All above | Step-by-step example of initializing Ralph and running the loop |
| 0101 | Create agent selection guide | Documentation | S | 0041-0048 | Guide for choosing appropriate agent types for different tasks |
| 0102 | Create Phase 2 decomposition guide | Documentation | S | 0048 | Guide for using decomposer agent to decompose PRDs into tasks |
| 0103 | Create model mapping guide | Documentation | XS | 0031 | Guide for configuring and updating agent-to-model mappings |
| 0104 | Create migration guide from existing tools | Documentation | S | All above | Guide for migrating from Mycelium, Smart Ralph, or ai-dev-tasks |
| 0105 | Create advanced customization guide | Documentation | M | All above | Guide for adding custom agents, tools, and extending Ralph |

---

## Category 10: Testing & Validation (0106-0115)

| ID | Title | Component | Complexity | Dependencies | Description |
|----|-------|-----------|------------|--------------|
| 0106 | Create ralph-init.sh test cases | Testing | M | 0011-0015 | Test initialization in new project, existing project, and idempotency scenarios |
| 0107 | Create ralph-loop.sh test cases | Testing | L | 0016-0023 | Test loop iteration, signal handling, tool selection, and iteration limits |
| 0108 | Create sync-agents test cases | Testing | M | 0026-0030 | Test YAML parsing, agent file discovery, and frontmatter updates |
| 0109 | Create task-create.sh test cases | Testing | S | 0024 | Test task ID generation, folder creation, and template copying |
| 0110 | Create task-complete.sh test cases | Testing | M | 0025 | Test folder movement, git operations, and TODO.md updates |
| 0111 | Create signal system test cases | Testing | S | 0056-0065 | Test all four signal types and their handling |
| 0112 | Create git workflow test cases | Testing | M | 0066-0075 | Test branch creation, squash merge, and conflict detection |
| 0113 | Create dependency tracking test cases | Testing | M | 0076-0085 | Test dependency graph parsing and circular dependency detection |
| 0114 | Create RULES.md test cases | Testing | M | 0086-0095 | Test lookup algorithm, hierarchy, and rule application |
| 0115 | Create end-to-end integration test | Testing | L | All above | Complete workflow test from init through task completion |

---

## Dependency Graph Summary

### Foundation Layer (No Dependencies)
- 0001-0010: Infrastructure
- 0056-0059: Signal definitions
- 0090-0093: RULES.md criteria

### Template Layer (Depends on 0001)
- 0031-0040: Configuration templates
- 0041-0055: Agent definitions
- 0086: RULES.md template

### Utility Layer (Depends on Infrastructure)
- 0011-0015: ralph-init.sh
- 0016-0023: ralph-loop.sh
- 0024: task-create.sh
- 0025: task-complete.sh
- 0026-0030: sync-agents

### Integration Layer (Depends on Utilities + Templates)
- 0060-0065: Signal implementation
- 0066-0075: Git integration
- 0076-0085: Dependency tracking
- 0087-0089: RULES.md lookup

### Documentation Layer (Depends on Everything)
- 0096-0105: Documentation
- 0106-0115: Testing

---

## Implementation Phases

### Phase 1: Foundation (Tasks 0001-0010)
Create directory structure, utilities, and validation functions.

### Phase 2: Templates (Tasks 0031-0055, 0086)
Create all template files for configuration, agents, and RULES.md.

### Phase 3: Core Scripts (Tasks 0011-0030)
Implement the six bash utilities: ralph-init.sh, ralph-loop.sh, sync-agents, task-create.sh, task-complete.sh.

### Phase 4: Integration (Tasks 0056-0095)
Implement signal system, git workflow, dependency tracking, and RULES.md system.

### Phase 5: Documentation (Tasks 0096-0105)
Create comprehensive documentation and guides.

### Phase 6: Testing (Tasks 0106-0115)
Create test cases and validation suite.

---

## Complexity Legend

- **XS** (Extra Small): 0-15 minutes - Simple file creation, copy operations, basic templates
- **S** (Small): 15-30 minutes - Simple scripts with basic logic, straightforward implementations
- **M** (Medium): 30-60 minutes - Multi-function scripts with parsing, moderate complexity
- **L** (Large): 1-2 hours - Complex systems with multiple integrations, extensive logic

---

## Success Criteria per Task

Each task should:
1. Have clear acceptance criteria
2. Follow existing bash/shell conventions from AGENTS.md
3. Include error handling
4. Be idempotent where applicable
5. Include appropriate documentation
6. Pass manual testing checklist

---

## Notes

- Total estimated effort: ~55-60 hours (assuming M = 45 min average)
- Tasks can be parallelized within each phase
- Phase 1-3 can start immediately
- Phase 4 requires completion of Phase 3
- Phase 5-6 should be done after core implementation
