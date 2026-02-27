# Ralph Toolkit Documentation

This directory contains comprehensive documentation for the Ralph Toolkit - an autonomous AI task execution framework that combines containerization, specialized agents, and intelligent task orchestration.

## Purpose

The documentation provides:
- Usage guides for Jeeves container management and Ralph Loop workflow
- Command references for both Jeeves and Ralph tools
- Configuration instructions for Docker, agents, MCP servers, and development environment settings
- Troubleshooting information for common issues
- Best practices for using the Ralph Toolkit effectively

## Documentation Index

### Core Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | This file - Documentation index and overview |
| `commands.md` | Detailed reference for all Jeeves and Ralph commands |
| `configuration.md` | Configuration options for Docker, agents, MCP servers, and Ralph Loop |
| `troubleshooting.md` | Common issues and solutions for both Jeeves and Ralph |
| `how-to-guide.md` | Step-by-step tutorials for various use cases |

### Getting Started

For new users, start with:
1. **README.md (root)** - Project overview and basic introduction
2. `commands.md` - Command reference for Jeeves and Ralph
3. `how-to-guide.md` - Step-by-step tutorials
4. `configuration.md` - Configuration options

For troubleshooting, check:
- `troubleshooting.md` - Common issues and solutions

## Documentation Structure

The documentation is organized into two main sections:

### Jeeves Container Management
- Container lifecycle commands (build, start, stop, etc.)
- Docker configuration and customization
- Container shell access and log viewing
- Environment variables and volume mounts

### Ralph Loop Workflow
- Ralph initialization and project scaffolding
- The three phases of Ralph: PRD Generation → Decomposition → Execution
- Ralph Loop orchestration and management
- Task dependency tracking
- Git integration and branch management
- Specialized AI agents and skills

## Ralph-Specific Documentation

Located in `/proj/jeeves/Ralph/`:

| File | Purpose |
|------|---------|
| `README-Ralph.md` | Comprehensive Ralph Loop documentation |
| `docs/directory-structure.md` | Ralph directory organization |
| `docs/rules-system.md` | RULES.md hierarchical learning system |
| `skills/README.md` | Skills system overview |
| `templates/README.md` | Agent template documentation |

## Agent & PRD Documentation

### PRD Creator
Located in `/proj/jeeves/PRD/`:
- `README-PRD.md` - PRD creation process documentation
- `prd-creator-prompt.md` - PRD creator prompt engineering

### Deepest-Thinking
Located in `/proj/jeeves/Deepest-Thinking/`:
- `README-Deepest-Thinking.md` - Research agent documentation
- `deepest-thinking-prompt.md` - Deepest-Thinking prompt engineering

### Ralph Templates
Located in `/proj/jeeves/Ralph/templates/`:
- Agent templates for various roles (architect, decomposer, developer, manager, researcher, tester, UI designer, writer)
- Task templates for activity tracking and task management
- Configuration templates for Ralph setup

## Skills Documentation

Located in `/proj/jeeves/Ralph/skills/`:

### Dependency Tracking
- `README.md` - Dependency tracking system overview
- `SKILL.md` - Skill implementation details
- `activity.md` - Activity tracking for dependency management
- Scripts for dependency closure, cycle detection, parsing, selection, and update
- Tests for dependency tracking functionality

### Git Automation
- `README.md` - Git automation system overview
- `SKILL.md` - Git automation implementation details
- References for conventional commits, git commands, git workflow, and troubleshooting
- Scripts for branch cleanup, gitignore configuration, commit message handling, conflict resolution, and task branch creation

### System Prompt Compliance
- `README.md` - System prompt compliance system overview
- `SKILL.md` - System prompt compliance implementation details

## Installation & Setup Documentation

Located in `/proj/jeeves/bin/`:
- `README.md` - Binary scripts overview
- `install-agents.sh` - Agent installation instructions
- `install-mcp-servers.sh` - MCP server installation instructions
- `install-skills.sh` - Skills installation instructions
- `ralph-init.sh` - Ralph initialization script
- `ralph-loop.sh` - Ralph Loop orchestration script

## Additional Resources

- [AGENTS.md](../AGENTS.md) - Agent development guidelines
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [LICENSE](../LICENSE) - Project license

## Usage

Documentation is available in the container at:
```
/proj/docs/
```

You can view it directly with:
```bash
cat /proj/docs/commands.md
# Or use a text editor
vi /proj/docs/configuration.md
```

## Support & Community

- **Issues**: [GitHub Issues](https://github.com/SamAcctX/jeeves/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SamAcctX/jeeves/discussions)
- **Documentation**: [Full Docs](https://github.com/SamAcctX/jeeves/tree/main/docs)
