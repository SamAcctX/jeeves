# Ralph Loop Skills Directory

This directory contains reusable skills for the Ralph Loop autonomous AI task execution framework.

## Purpose

Skills are modular, reusable components that:
- Provide specialized functionality for the Ralph Loop
- Can be invoked by agents during task execution
- Follow a standardized format with SKILL.md metadata
- Include scripts, tests, and documentation

## Directory Structure

```
jeeves/Ralph/skills/
├── dependency-tracking/         # Dependency management utilities
├── git-automation/             # Git workflow automation
└── system-prompt-compliance/   # System prompt compliance checking
```

## Key Skills

### dependency-tracking
Comprehensive dependency management for Ralph Loop:
- Dependency graph parsing
- Circular dependency detection
- Unblocked task selection
- Runtime dependency updates
- Transitive dependency resolution

**Documentation**: `dependency-tracking/README.md`
**Metadata**: `dependency-tracking/SKILL.md`
**Scripts**: `dependency-tracking/scripts/`
**Tests**: `dependency-tracking/tests/`

### git-automation
Git workflow automation for task lifecycle management:
- Repository context detection
- Branch creation and management
- Commit message generation
- Squash merge operations
- Conflict detection and resolution

**Documentation**: `git-automation/README.md`
**Metadata**: `git-automation/SKILL.md`
**Scripts**: `git-automation/scripts/`
**References**: `git-automation/references/`

### system-prompt-compliance
System prompt compliance verification:
- Pre-action checklist
- Critical warning inclusion
- State file read requirements
- Signal format validation

**Documentation**: `system-prompt-compliance/README.md`
**Metadata**: `system-prompt-compliance/SKILL.md`

## Usage

Skills are typically invoked by the Manager or Worker agents:

```bash
# Example: Using dependency tracking to find next task
source /proj/jeeves/Ralph/skills/dependency-tracking/scripts/deps-select.sh
next_task=$(deps_select_next_task)
```

## Skill Format

Each skill follows a standard format:
- `SKILL.md` - Metadata and documentation (required)
- `scripts/` - Bash scripts with reusable functions
- `tests/` - Test scripts and fixtures
- `references/` - Reference documentation

## Installation

Skills are installed with Ralph Loop:
```bash
ralph-init.sh  # Initializes skills in project
install-skills.sh  # Installs skills from templates
```

## Dependencies

Skills may require external tools:
- `yq` - YAML processing
- `git` - Version control operations
- `bash` - Script execution
- `standard Unix tools` - grep, sed, awk, etc.
