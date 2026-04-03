# PRD Creator Agent

The PRD Creator is a subagent that guides developers through structured product planning and generates comprehensive Product Requirements Documents. It acts as a professional product manager, asking targeted questions about features, users, and technical requirements, then producing a PRD optimized for the Ralph development workflow.

## PRD Pipeline

The PRD Creator orchestrates a multi-agent pipeline:

1. **Creator** (`@prd-creator`) -- conducts the interview and drafts the PRD
2. **Domain Advisor** -- one of five specialists reviews the draft:
   - API advisor
   - CLI advisor
   - Data advisor
   - Library advisor
   - UI advisor
3. **Researcher** (`@prd-researcher`) -- validates claims and fills knowledge gaps

PRDs are saved to `.ralph/specs/PRD-[ProjectName]-[Date].md`.

## Files in This Directory

| File | Description |
|------|-------------|
| `README-PRD.md` | This file |
| `prd-creator-opencode-template.md` | Creator agent for OpenCode |
| `prd-creator-claude-template.md` | Creator agent for Claude Code |
| `prd-researcher-opencode-template.md` | Researcher agent for OpenCode |
| `prd-researcher-claude-template.md` | Researcher agent for Claude Code |
| `prd-advisor-api-opencode-template.md` | API advisor for OpenCode |
| `prd-advisor-api-claude-template.md` | API advisor for Claude Code |
| `prd-advisor-cli-opencode-template.md` | CLI advisor for OpenCode |
| `prd-advisor-cli-claude-template.md` | CLI advisor for Claude Code |
| `prd-advisor-data-opencode-template.md` | Data advisor for OpenCode |
| `prd-advisor-data-claude-template.md` | Data advisor for Claude Code |
| `prd-advisor-library-opencode-template.md` | Library advisor for OpenCode |
| `prd-advisor-library-claude-template.md` | Library advisor for Claude Code |
| `prd-advisor-ui-opencode-template.md` | UI advisor for OpenCode |
| `prd-advisor-ui-claude-template.md` | UI advisor for Claude Code |

15 files total (1 README + 14 templates).

## Installation

```bash
install-agents.sh --global
```

This installs all PRD pipeline agents to OpenCode (`~/.config/opencode/agents/`). Each template runs in `subagent` mode.

## Usage

In OpenCode, invoke the creator:

```
@prd-creator
```

Describe your software idea. The agent asks structured questions, then generates a PRD and saves it to `.ralph/specs/`.

## Further Reading

- Agent template details: see the individual template files
- Workflow guide: `docs/guide.md`
- Command reference: `docs/reference.md`
