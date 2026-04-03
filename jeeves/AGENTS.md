# Agent Guide for Jeeves Agent Templates

## Overview
This directory contains AI agent templates for OpenCode and Claude Code platforms.

## Directory Structure
```
jeeves/
├── PRD/                    # PRD Creator agent pipeline
│   ├── README-PRD.md
│   ├── prd-creator-{opencode,claude}-template.md
│   ├── prd-researcher-{opencode,claude}-template.md
│   └── prd-advisor-{api,cli,data,library,ui}-{opencode,claude}-template.md
├── Deepest-Thinking/       # Research agent
│   ├── README-Deepest-Thinking.md
│   ├── deepest-thinking-opencode-template.md
│   └── deepest-thinking-claude-template.md
└── Ralph/
    └── templates/
        └── agents/         # Ralph agent templates ({role}-{platform}.md)
            ├── shared/     # 10 shared rule files included by all agent templates
            ├── architect-{opencode,claude}.md
            ├── decomposer-{opencode,claude}.md
            ├── decomposer-architect-{opencode,claude}.md
            ├── decomposer-researcher-{opencode,claude}.md
            ├── decomposer-task-handler-opencode.md
            ├── developer-{opencode,claude}.md
            ├── manager-{opencode,claude}.md
            ├── researcher-{opencode,claude}.md
            ├── tester-{opencode,claude}.md
            ├── ui-designer-{opencode,claude}.md
            └── writer-{opencode,claude}.md
```

The `shared/` directory contains 10 rule files (signals, dependency tracking, secrets, loop detection, etc.) that are included by all agent templates to enforce consistent behavior across roles.

## Agent Template Format

### OpenCode Format (Key-Value Boolean Tools)
```yaml
---
name: agent-name
description: "Agent description here"
mode: subagent
model: ""

permission:
  write: ask
  bash: ask
  webfetch: allow
  edit: deny
tools:
  read: true
  write: true
  grep: true
  glob: true
  bash: true
  webfetch: true
  question: true
  sequentialthinking: true
---
```

### Claude Code Format (Comma-Separated Tools String)
```yaml
---
name: agent-name
description: "Agent description here"
tools: Read, Write, Grep, Glob, Bash, Web, SequentialThinking, Question
model: inherit
---
```

## Frontmatter Fields

### Required Fields
- **name**: Agent identifier (both platforms)
- **description**: Clear description of agent's purpose
- **mode**: `subagent` (most agents) or `all` (manager, decomposer) -- OpenCode only
- **model**: `""` (empty string) for OpenCode, `inherit` for Claude
- **permission**: Tool permission levels (OpenCode only)
- **tools**: Available tools -- key-value boolean map for OpenCode, comma-separated string for Claude

### Optional Fields
- **temperature**: 0.1-0.3 (focused) or 0.7-0.9 (creative)

## Platform Differences

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Tools format | Key-value booleans | Comma-separated string |
| Config file | opencode.json (`.mcp` key) | .mcp.json / ~/.claude.json (`.mcpServers` key) |
| Permission block | Required (ask/allow/deny) | Not used |
| Name field | Required | Required |
| Model field | `""` (empty string) | Optional (`inherit`) |
| Mode field | `subagent` or `all` | Not used |
| Environment key (MCP) | `environment` | `env` |

## Testing Templates

### Syntax Validation
```bash
# Extract and validate YAML frontmatter from a template
head -n $(grep -n '^---$' template.md | sed -n '2p' | cut -d: -f1) template.md \
  | tail -n +2 \
  | python3 -c "import yaml,sys; yaml.safe_load(sys.stdin)"

# Check JSON configuration
python3 -m json.tool < opencode.json > /dev/null && echo "Valid JSON"
```

### Manual Testing
1. Install agent: `./install-agents.sh`
2. Invoke agent: `@agent-name`
3. Test conversation flow
4. Verify tool permissions work correctly
5. Check stop points function as intended

## YAML Frontmatter Rules
- Use 2-space indentation
- Use lowercase for OpenCode tool keys
- Use PascalCase for Claude tool names
- Quote strings containing special characters
- Boolean values: `true`/`false` (lowercase)

## Formatting Rules
- **No comments** unless user explicitly requests them
- **No emojis** unless user explicitly requests them
- Use clear headings (H1, H2, H3)
- Use bullet points for lists
- Use code blocks for examples
