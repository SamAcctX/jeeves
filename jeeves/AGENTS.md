# Agent Guide for Jeeves Agent Templates

## Overview
This directory contains AI agent templates for OpenCode and Claude Code platforms.

## Directory Structure
```
jeeves/
├── PRD/                    # PRD Creator agent
│   ├── prd-creator-opencode-template.md
│   ├── prd-creator-claude-template.md
│   ├── prd-creator-prompt.md
│   └── README-PRD.md
└── Deepest-Thinking/       # Research agent
    ├── deepest-thinking-opencode-template.md
    ├── deepest-thinking-claude-template.md
    ├── deepest-thinking-prompt.md
    └── README-Deepest-Thinking.md
```

## Agent Template Format

### OpenCode Format (Key-Value Boolean Tools)
```yaml
---
description: "Professional product manager assistant that helps beginner developers..."
mode: subagent

permission:
  write: ask      # ask | allow | deny
  bash: ask       # ask | allow | deny
  webfetch: allow # ask | allow | deny
  edit: deny      # ask | allow | deny
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

### Claude Code Format (Comma-Separated Tools)
```yaml
---
name: prd-creator
description: "Professional product manager assistant..."
mode: subagent

permission:
  write: ask
  bash: ask
  webfetch: allow
  edit: deny
tools: Read, Write, Grep, Glob, Bash, Web, SequentialThinking, Question
model: inherit
---
```

## Frontmatter Fields

### Required Fields
- **description**: Clear description of agent's purpose
- **mode**: Always `subagent`
- **tools**: List of available tools

### Optional Fields
- **temperature**: 0.1-0.3 (focused) or 0.7-0.9 (creative)
- **permission**: Tool permission levels (ask/allow/deny)
  - `write`: ask | allow | deny
  - `bash`: ask | allow | deny
  - `webfetch`: ask | allow | deny
  - `edit`: ask | allow | deny
- **name**: Agent identifier (Claude only)
- **model**: Model to use, typically `inherit` (Claude only)

## Tool Options

Available tools for both platforms:
- `read` / `Read` - File reading
- `write` / `Write` - File writing
- `grep` / `Grep` - Text search
- `glob` / `Glob` - File pattern matching
- `bash` / `Bash` - Shell commands
- `webfetch` / `Web` - Web content fetching
- `question` / `Question` - Interactive questioning
- `sequentialthinking` / `SequentialThinking` - Structured reasoning

## Code Style Guidelines

### Template Content Structure
```markdown
---
[YAML frontmatter]
---

# Agent Name

## Role and Identity
[Clear description of persona]

## Conversation Approach
- Bullet points for approach
- Tone and style guidelines

## Core Structure
### 1. Phase Name [STOP POINT]
- Step-by-step instructions
- Expected outputs

## Tool Usage
- When to use each tool
- Tool-specific guidelines

## Error Handling
- How to handle common errors
- Recovery procedures
```

### Formatting Rules
- **No comments** unless user explicitly requests them
- **No emojis** unless user explicitly requests them
- Use clear headings (H1, H2, H3)
- Use bullet points for lists
- Use code blocks for examples
- Keep line length reasonable (80-100 chars)

### YAML Frontmatter Rules
- Use 2-space indentation
- Use lowercase for OpenCode tools (key-value pairs)
- Use PascalCase for Claude tools (comma-separated string)
- Quote strings containing special characters
- Boolean values: `true`/`false` (lowercase)

## Installation

Agents are installed via `install-agents.sh`:

```bash
# Project scope (default)
./install-agents.sh
# Installs to: /proj/.claude/agents/ and /proj/.opencode/agents/

# Global scope
./install-agents.sh --global
# Installs to: ~/.claude/agents/ and ~/.opencode/agents/

# Deepest-Thinking only
./install-agents.sh --deepest
```

## Usage

After installation, invoke agents with:

```bash
# OpenCode
@prd-creator
@deepest-thinking

# Claude Code
@prd-creator
@deepest-thinking
```

## Testing Templates

### Syntax Validation
```bash
# Check YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('template.md'))"

# Check JSON configuration
cat opencode.json | python3 -m json.tool > /dev/null && echo "Valid JSON"
```

### Manual Testing
1. Install agent: `./install-agents.sh`
2. Invoke agent: `@agent-name`
3. Test conversation flow
4. Verify tool permissions work correctly
5. Check stop points function as intended

## Common Patterns

### Conversation Stop Points
Use `[STOP POINT]` markers to pause for user input:
```markdown
### 1. Initial Engagement [STOP POINT ONE]
- Ask clarifying questions
- Wait for user response before proceeding
```

### Tool Configuration
```markdown
## Tool Configuration
- SearxNG Web Search: Use for broad context with max_results=20
- Sequential Thinking: Maintain minimum 5 thoughts per analysis
```

### Context Maintenance
```markdown
## Context Maintenance
- Store key findings between tool transitions
- Reference previous results in subsequent analyses
- Maintain state across phase transitions
```

## Platform Differences

| Feature | OpenCode | Claude Code |
|---------|----------|-------------|
| Tools format | Key-value booleans | Comma-separated string |
| Config file | opencode.json | .mcp.json / ~/.claude.json |
| MCP key | `.mcp` | `.mcpServers` |
| Name field | Not used | Required |
| Model field | Not used | Optional (`inherit`) |

## No Comments Policy
Do not add comments to agent templates unless the user explicitly requests them. The YAML frontmatter and markdown content should be self-documenting.
