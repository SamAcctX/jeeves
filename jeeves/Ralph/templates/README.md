# Ralph Loop Templates Directory

This directory contains template files for initializing Ralph Loop projects, providing standardized structures for configuration, agents, tasks, and prompts.

## Purpose

Templates serve as the foundation for Ralph Loop projects by providing:
- Starter files for Ralph Loop configuration
- Agent definitions for different AI platforms (OpenCode and Claude Code)
- Project structure scaffolding
- Task and prompt templates with standardized formats
- Rules system templates for maintaining code quality and consistency

## Directory Structure

```
jeeves/Ralph/templates/
├── agents/       # Agent templates for OpenCode and Claude Code
├── config/       # Configuration file templates
├── prompts/      # Prompt templates and optimizers
├── task/         # Task-related file templates
└── RULES.md.template  # Project rules template
```

## Agent Templates (agents/)

Agent templates define specialized AI agents for different roles in the software development process. Each agent has platform-specific versions for OpenCode (`-opencode.md`) and Claude Code (`-claude.md`), plus shared templates used by all agents.

### Available Agents

| Agent Type | Purpose | Key Responsibilities |
|------------|---------|---------------------|
| `architect-*.md` | System design and architecture | API design, database schema, system architecture, design patterns |
| `developer-*.md` | Implementation and debugging | Coding, refactoring, debugging, feature implementation |
| `tester-*.md` | Quality assurance and testing | Test creation, validation, defect reporting, spec-anchored workflow compliance |
| `ui-designer-*.md` | UI/UX design and implementation | Interface design, responsive layout, accessibility, visual design |
| `researcher-*.md` | Research and analysis | Technical research, documentation analysis, knowledge synthesis |
| `writer-*.md` | Documentation and content creation | Content creation, editing, technical writing, documentation structure |
| `manager-*.md` | Task orchestration | Task selection, Worker invocation, state management, handoffs |
| `decomposer-*.md` | Task decomposition | PRD analysis, task breakdown, dependency mapping, TODO management |
| `decomposer-architect-*.md` | Specialized decomposition for architecture | System design decomposition, integration design, best practices |
| `decomposer-researcher-*.md` | Specialized decomposition for research | Documentation analysis, knowledge synthesis, investigation |

### Shared Agent Templates (agents/shared/)

These templates are included by all agents and contain standardized information:

| File | Purpose |
|------|---------|
| `activity-format.md` | Standard format for activity logs |
| `context-check.md` | Context management and resumption guidelines |
| `dependency.md` | Dependency tracking and management |
| `handoff.md` | Agent handoff protocols and state transitions |
| `loop-detection.md` | Loop detection and prevention techniques |
| `quick-reference.md` | Quick reference guide for agents |
| `rules-lookup.md` | Rules system lookup and compliance |
| `secrets.md` | Secrets management and security guidelines |
| `signals.md` | Signal format specifications and handling |
| `workflow-phases.md` | Spec-anchored workflow phase tracking |

## Configuration Templates (config/)

Configuration templates define the initial settings for Ralph Loop projects.

| File | Purpose | Details |
|------|---------|---------|
| `agents.yaml.template` | Agent model mapping configuration | Maps agent types to specific LLM models per tool (OpenCode/Claude). Defines preferred and fallback models for each agent role. |
| `deps-tracker.yaml.template` | Dependency tracker configuration | Tracks task dependencies in YAML format. Manager uses this to determine unblocked tasks. Supports `depends_on` and `blocks` fields for bidirectional tracking. |
| `TODO.md.template` | Task checklist template | Master task checklist with strict grammar. Supports incomplete/complete tasks, abort signals, and completion sentinel. |
| `.gitignore.template` | Gitignore configuration template | Excludes Ralph Loop ephemeral files from version control. Ignores task data, logs, temporary files, and agent session files. |

## Prompt Templates (prompts/)

Prompt templates provide standardized prompt structures for the Ralph Loop system.

| File | Purpose | Details |
|------|---------|---------|
| `ralph-prompt.md.template` | Base prompt for Ralph Loop Manager | Core loop orchestration prompt. Defines P0 rules, iteration kickoff process, task selection, signal handling, and state management. |
| `prompt-optimizer.md` | Prompt optimization guide | Expert prompt optimizer for refactoring large instruction-heavy prompts. Focuses on compliance, consistency, and drift mitigation in multi-turn workflows. |

## Task Templates (task/)

Task templates define the structure for individual task files created in `.ralph/tasks/XXXX/` directories.

| File | Purpose | Details |
|------|---------|---------|
| `TASK.md.template` | Task definition template | Individual task description with acceptance criteria, implementation notes, files to modify, technical details, validation steps, dependencies, and metadata. |
| `activity.md.template` | Task activity log template | Comprehensive activity log with workflow phase tracking, handoff history, defect reports, progress log, errors/issues, decisions made, lessons learned, and resources/references. |
| `attempts.md.template` | Task attempt history template | Detailed attempt log for each task iteration. Tracks approach, actions taken, results, errors encountered, and lessons learned per attempt. |

## Rules System Template (RULES.md.template)

The RULES.md.template establishes a hierarchical learning system for project-specific rules, patterns, and behaviors.

Key features:
- **IGNORE_PARENT_RULES token**: Prevents inheriting rules from parent directories
- **Rule creation guidelines**: Defines thresholds for creating new RULES.md files (2+ unique patterns, 3+ parent overrides, 10+ files, or 3+ cross-task occurrences)
- **Rule inheritance**: Child rules override parent rules (deepest rules take precedence)
- **Pattern documentation**: Sections for code patterns, common pitfalls, standard approaches, and auto-discovered patterns
- **Auto-discovered patterns**: Format specification for machine-readable pattern documentation

## Usage in Ralph Loop

Templates are used during project initialization via `ralph-init.sh` which copies select templates to the project directory. The initialization process:

1. Validates required tools (yq, jq, git)
2. Creates Ralph directory structure (`.ralph/config/`, `.ralph/tasks/`, `.ralph/specs/`)
3. Copies configuration templates to `.ralph/config/` and `.ralph/tasks/TODO.md`
4. Copies agent templates to `.opencode/agents/` and `.claude/agents/`
5. Copies shared agent templates to both platforms
6. Creates RULES.md from template
7. Configures git integration

Task templates (`TASK.md`, `activity.md`, `attempts.md`) and prompt templates (`ralph-prompt.md`) are **not** copied to the workspace. Task templates are created per-task by the Decomposer agent directly from source. The prompt template is read directly from `/opt/jeeves/Ralph/templates/prompts/` at runtime.

## Customization

You can customize templates by:
1. Modifying the existing template files in `jeeves/Ralph/templates/`
2. Adding new templates following the existing structure
3. Running `ralph-init.sh --force` to apply changes to existing projects
4. For RULES.md, use `ralph-init.sh --rules` to force creation

## Platform Support

Templates are available for:
- **OpenCode**: Files ending with `-opencode.md`
- **Claude Code**: Files ending with `-claude.md`
- **Both platforms**: Shared templates in `agents/shared/`

## Integration with Ralph Loop

Templates are used at various stages:

1. **Initialization**: `ralph-init.sh` copies config and agent templates to project
2. **Decomposition**: Decomposer agent creates per-task files from source templates (`/opt/jeeves/Ralph/templates/task/`)
3. **Execution**: Manager reads prompt template directly from source; Worker agents use copied agent templates
4. **State Management**: Per-task files (`TASK.md`, `activity.md`, `attempts.md`) track progress and history
5. **Learning**: RULES.md.template captures project patterns

## Template Lifecycle

1. **Template Creation**: Initial templates provided in the repository
2. **Customization**: Users modify source templates for their specific needs
3. **Initialization**: Config and agent templates copied to project during `ralph-init.sh`
4. **Execution**: Task and prompt templates read from source at runtime
5. **Evolution**: Project-specific patterns added to RULES.md

By following this template system, Ralph Loop ensures consistency, reproducibility, and efficient knowledge capture across projects.
