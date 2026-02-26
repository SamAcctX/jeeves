# Ralph Loop Templates Directory

This directory contains template files for initializing Ralph Loop projects.

## Purpose

Templates provide:
- Starter files for Ralph Loop configuration
- Agent definitions for different AI platforms
- Project structure scaffolding
- Task and prompt templates

## Directory Structure

```
jeeves/Ralph/templates/
├── agents/       # Agent templates for OpenCode and Claude Code
├── config/       # Configuration file templates
├── prompts/      # Prompt templates and optimizers
├── task/         # Task-related file templates
└── RULES.md.template  # Project rules template
```

## Key Files

### Agents
| File | Purpose |
|------|---------|
| `agents/architect-*.md` | Architect agent for system design |
| `agents/developer-*.md` | Developer agent for implementation |
| `agents/tester-*.md` | Tester agent for QA |
| `agents/ui-designer-*.md` | UI designer agent for interface design |
| `agents/researcher-*.md` | Researcher agent for analysis |
| `agents/writer-*.md` | Writer agent for documentation |
| `agents/manager-*.md` | Manager agent for task orchestration |
| `agents/decomposer-*.md` | Decomposer agent for task breakdown |
| `agents/shared/` | Shared templates used by all agents |

### Configuration
| File | Purpose |
|------|---------|
| `config/agents.yaml.template` | Agent model mapping configuration |
| `config/deps-tracker.yaml.template` | Dependency tracker configuration |
| `config/TODO.md.template` | Task checklist template |
| `config/.gitignore.template` | Gitignore configuration template |

### Prompts
| File | Purpose |
|------|---------|
| `prompts/ralph-prompt.md.template` | Base prompt template for Ralph Loop |
| `prompts/prompt-optimizer.md` | Prompt optimization guide |

### Task
| File | Purpose |
|------|---------|
| `task/TASK.md.template` | Individual task definition template |
| `task/activity.md.template` | Task activity log template |
| `task/attempts.md.template` | Task attempt history template |

### Rules
| File | Purpose |
|------|---------|
| `RULES.md.template` | Project rules template for code quality and standards |

## Usage

Templates are used during initialization:

```bash
ralph-init.sh  # Copies templates to project directory
```

## Customization

You can customize templates by:
1. Modifying the existing template files in `jeeves/Ralph/templates/`
2. Adding new templates following the existing structure
3. Running `ralph-init.sh --force` to apply changes to existing projects

## Platform Support

Templates are available for:
- **OpenCode**: Files ending with `-opencode.md`
- **Claude Code**: Files ending with `-claude.md`
- **Both platforms**: Shared templates in `agents/shared/`
