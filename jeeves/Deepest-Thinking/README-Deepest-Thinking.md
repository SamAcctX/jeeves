# Deepest-Thinking Agent

Deepest-Thinking is a research subagent that conducts exhaustive investigations through structured research cycles. It combines SearxNG web search with Sequential Thinking to produce academic-style research reports.

## Files in This Directory

| File | Description |
|------|-------------|
| `README-Deepest-Thinking.md` | This file |
| `deepest-thinking-opencode-template.md` | Agent template for OpenCode |
| `deepest-thinking-claude-template.md` | Agent template for Claude Code |

3 files total.

## Installation

```bash
install-agents.sh --deepest
```

This installs the Deepest-Thinking agent to OpenCode (`~/.config/opencode/agents/`). The template runs in `subagent` mode.

## Usage

In OpenCode, invoke the agent:

```
@deepest-thinking
```

Describe your research topic. The agent follows a three-stop protocol:

1. **Initial Engagement** -- asks 2-3 clarifying questions to scope the research
2. **Research Planning** -- presents 3-5 themes with an execution plan; waits for approval
3. **Execution and Report** -- runs at least two research cycles per theme (SearxNG search + Sequential Thinking), then delivers a final report covering knowledge development, comprehensive analysis, and practical implications

## Further Reading

- Agent template details: see the individual template files
- Workflow guide: `docs/guide.md`
- Command reference: `docs/reference.md`
