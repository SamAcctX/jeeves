# Deepest-Thinking Agent Setup Guide

This guide walks you through setting up the Deepest-Thinking agent for both OpenCode and Claude Code platforms. The Deepest-Thinking agent provides comprehensive research capabilities through systematic investigation using multiple tools.

## Overview

The Deepest-Thinking agent is a specialized AI assistant that:
- Conducts exhaustive investigations through required research cycles
- Uses SearxNG Web Search for broad context and deep dives
- Applies Sequential Thinking for systematic analysis
- Produces academic-style research reports
- Follows a structured three-stop research process

## Files Included

- `deepest-thinking-prompt.md` - Original source prompt with Deep Research Protocol
- `deepest-thinking-opencode-template.md` - OpenCode-compatible template
- `deepest-thinking-claude-template.md` - Claude Code-compatible template
- `README-Deepest-Thinking.md` - This setup guide

## Quick Start

### For OpenCode Users
1. Copy the template to your project's agent directory
2. Use `@deepest-thinking` or switch to the agent in OpenCode

### For Claude Code Users
1. Copy the template to your project's subagent directory
2. Use `@deepest-thinking` or let Claude auto-delegate research tasks

## Installation Guide

### OpenCode Installation

#### Project-Level Installation
Install for a specific project/repo:

```bash
# Create the agents directory if it doesn't exist
mkdir -p /path/to/your/project/.opencode/agents

# Copy the OpenCode template
cp /path/to/proj/Deepest-Thinking/deepest-thinking-opencode-template.md /path/to/your/project/.opencode/agents/deepest-thinking.md
```

#### Global Installation (Recommended for frequent use)
Install for all projects:

```bash
# Create the global agents directory
mkdir -p ~/.config/opencode/agents

# Copy the OpenCode template
cp /path/to/proj/Deepest-Thinking/deepest-thinking-opencode-template.md ~/.config/opencode/agents/deepest-thinking.md
```

### Claude Code Installation

#### Project-Level Installation
Install for a specific project/repo:

```bash
# Create the agents directory if it doesn't exist
mkdir -p /path/to/your/project/.claude/agents

# Copy the Claude Code template
cp /path/to/proj/Deepest-Thinking/deepest-thinking-claude-template.md /path/to/your/project/.claude/agents/deepest-thinking.md
```

#### Global Installation (Recommended for frequent use)
Install for all projects:

```bash
# Create the global agents directory
mkdir -p ~/.claude/agents

# Copy the Claude Code template
cp /path/to/proj/Deepest-Thinking/deepest-thinking-claude-template.md ~/.claude/agents/deepest-thinking.md
```

## Configuration Details

### OpenCode Agent Configuration

The OpenCode template includes:
- **Description**: Methodical research assistant who conducts exhaustive investigations through required research cycles
- **Mode**: `subagent` (specialized task)
- **Temperature**: `0.3` (focused, analytical responses)
- **Tools**: Read, write, search, and analysis tools including SearxNG Web Search and Sequential Thinking
- **Permissions**: Safe defaults with approval for sensitive operations

```yaml
---
description: Methodical research assistant who conducts exhaustive investigations through required research cycles
mode: subagent

permission:
  write: ask      # User approval for file operations
  bash: ask       # User approval for terminal commands
  webfetch: allow  # Auto-allow web research
  edit: deny       # No editing needed for research workflow
tools:
  read: true               # Read existing documentation
  write: true              # Save research reports
  grep: true               # Search content
  glob: true               # Find files
  bash: true               # Terminal operations
  webfetch: true           # Web research
  question: true            # Interactive questioning
  sequentialthinking: true    # Structured analysis
---
```

### Claude Code Subagent Configuration

The Claude Code template includes:
- **Name**: `deepest-thinking`
- **Description**: Optimized for automatic delegation when deep research is needed
- **Tools**: Complete toolset for research workflow
- **Model**: Inherit from parent conversation

```yaml
---
name: deepest-thinking
description: Methodical research assistant who conducts exhaustive investigations through required research cycles. Use when user needs comprehensive research, deep analysis, or academic-style investigation.
tools: Read, Write, Web, SequentialThinking, Question, Grep, Glob, Bash
model: inherit
---
```

## Usage Guide

### Using the Deepest-Thinking Agent

#### 1. Start a Conversation
Begin by describing your research topic or question.

#### 2. Initial Engagement [STOP POINT ONE]
The agent will ask 2-3 clarifying questions to understand your research needs.
- Agent asks questions
- You provide clarifications
- Agent confirms understanding

#### 3. Research Planning [STOP POINT TWO]
The agent will present a research plan with:
- 3-5 major themes to investigate
- Key questions for each theme
- Research approach and tools to be used
- Expected depth of analysis

**You must approve the research plan before proceeding.**

#### 4. Research Execution (No Stops)
The agent will conduct mandatory research cycles (minimum two full cycles per theme):
- **Initial Landscape Analysis**: SearxNG Web Search + Sequential Thinking
- **Deep Investigation**: SearxNG Web Search + Sequential Thinking
- **Knowledge Integration**: Synthesize findings across themes

#### 5. Final Report [STOP POINT THREE]
The agent will produce a comprehensive academic-style report including:
- Knowledge Development (evolution of understanding)
- Comprehensive Analysis (synthesis of evidence)
- Practical Implications (real-world applications)

### Platform-Specific Usage

#### OpenCode
- Switch agents using **Tab** key or your configured `switch_agent` keybind
- Or invoke directly with `@deepest-thinking`
- Agent may prompt for approval on file writes or bash commands

#### Claude Code
- Claude will automatically delegate research tasks to the subagent
- Or invoke manually with `@deepest-thinking`
- Subagent runs in separate context window
- Can run in background with **Ctrl+B**

## Tool Permissions

### OpenCode Permission Model
- **ask**: Prompts for user approval before running
- **allow**: Runs automatically without approval
- **deny**: Blocks the tool entirely

The Deepest-Thinking agent uses:
- `write: ask` - Safely saves research reports with your approval
- `bash: ask` - Runs terminal commands with your approval
- `webfetch: allow` - Automatic web research for investigation
- `edit: deny` - Not needed for research workflow

### Claude Code Permission Model
Uses inherited permissions from the main conversation. The subagent has access to:
- Read, Write, Grep, Glob (file operations)
- Bash (terminal commands)
- Web (internet research)
- SequentialThinking (structured analysis)
- Question (interactive dialogue)

## Tool Integration

The Deepest-Thinking agent uses native OpenCode/Claude Code tools:

### Required Native Tools
- **SearxNG Web Search** (`searxng_searxng_web_search`) - Comprehensive search capabilities
- **Sequential Thinking** (`sequentialthinking`) - Structured thinking process
- **Read/Write** - File operations for saving reports
- **Bash** - Terminal commands when needed

### Tool Configuration
- SearxNG Web Search: Use `max_results=20` for comprehensive coverage
- Sequential Thinking: Maintain minimum 5 thoughts per analysis
- Web Search: Preferred over Exa tools as configured in AGENTS.md

## Directory Structure

After installation, your directory structure should look like:

```
your-project/
├── .opencode/
│   └── agents/
│       └── deepest-thinking.md          # OpenCode agent
├── .claude/
│   └── agents/
│       └── deepest-thinking.md          # Claude Code subagent
└── jeeves/
    ├── Deepest-Thinking/
    │   ├── deepest-thinking-prompt.md         # Original source
    │   ├── deepest-thinking-opencode-template.md # OpenCode template
    │   ├── deepest-thinking-claude-template.md   # Claude Code template
    │   └── README-Deepest-Thinking.md         # This guide
```

## Troubleshooting

### Agent Not Detected
- Verify file is in correct directory (`.opencode/agents/` or `.claude/agents/`)
- Check file permissions
- Restart your IDE or terminal session

### Tools Not Working
- OpenCode: Check permission settings in your `opencode.json`
- Claude Code: Verify MCP server status and permissions
- Ensure MCP servers are properly installed and running

### Permission Prompts
- OpenCode: This is expected behavior for safe operations
- Review the requested action before approving
- Use global config to change default permissions

### Claude Code Not Delegating
- Check the `description` field in the subagent
- Use more explicit language like "deep research" or "comprehensive investigation"
- Try manual invocation with `@deepest-thinking`

### MCP Integration Issues
- Verify MCP servers are installed: `./jeeves/bin/install-mcp-servers.sh`
- Check MCP server logs for errors
- Ensure MCP servers are running in your environment
- Verify tool configuration in platform settings

## Examples

### Basic Research Topic
```
You: I need to research the impact of AI on healthcare

Agent: I'll help you conduct a comprehensive research investigation. Let me start by understanding your research needs.

What specific aspects of AI in healthcare are you most interested in?
```

### Academic Research
```
You: Research the current state of quantum computing applications

Agent: I'll help you conduct a deep investigation into quantum computing applications. Let me ask a few clarifying questions.

What time period are you interested in (recent developments vs. historical context)?
```

### Technical Investigation
```
You: Investigate the security implications of Web3 technologies

Agent: I'll help you conduct a comprehensive investigation into Web3 security. Let me plan the research approach.

What specific areas of Web3 security are you most concerned about?
```

## Research Workflow Example

### Step 1: Initial Engagement
```
Agent: I'll help you conduct a comprehensive investigation. Let me ask a few questions to understand your research needs.

1. What is the primary research question you want to answer?
2. What depth of analysis do you need (overview vs. deep dive)?
3. Are there specific sources or domains you want to focus on?
```

### Step 2: Research Planning
```
Agent: Based on your research needs, I've identified these themes:

1. Current State and Technology
2. Applications and Use Cases
3. Security and Privacy Considerations
4. Future Developments and Trends

For each theme, I'll conduct:
- Initial landscape analysis with SearxNG Web Search
- Deep investigation with SearxNG Web Search
- Systematic analysis with Sequential Thinking

Do you approve this research plan?
```

### Step 3: Research Execution
```
Agent: I'm now conducting the research. Let me start with the initial landscape analysis...

[Agent performs SearxNG Web Search and Sequential Thinking analysis]

[Agent performs SearxNG Web Search and deeper analysis]

[Agent synthesizes findings across themes]
```

### Step 4: Final Report
```
Agent: Here is my comprehensive research report:

# Research Report: [Topic]

## Knowledge Development
[Detailed narrative of how understanding evolved...]

## Comprehensive Analysis
[Synthesis of evidence from multiple sources...]

## Practical Implications
[Real-world applications and implications...]

[Each section contains 6-8 substantial paragraphs with proper academic style]
```

## Support

For issues with the Deepest-Thinking agent:

1. **Check this README** for common solutions
2. **Review your installation** against the troubleshooting section
3. **Verify MCP servers** are properly installed and running
4. **Test with a simple example** to verify basic functionality
5. **Check platform documentation** for latest updates

## File Reference

| File | Purpose | Platform |
|-------|---------|----------|
| `deepest-thinking-opencode-template.md` | OpenCode agent template | OpenCode |
| `deepest-thinking-claude-template.md` | Claude Code subagent template | Claude Code |
| `deepest-thinking-prompt.md` | Original source prompt | Reference |
| `README-Deepest-Thinking.md` | This setup guide | Documentation |

## Related Resources

- **SearxNG Web Search**: [MCP Server](https://github.com/isokoliuk/mcp-searxng)
- **Claude MCP Tips**: [Video](https://youtu.be/0j7nLys-ELo)
- **JeredBlu's Website**: [jeredblu.com](https://jeredblu.com)
- **GitHub Repository**: [Custom Instructions Collection](https://github.com/JeredBlu/custom-instructions)

---

**Ready to use!** Install the appropriate template for your platform, set up the required MCP servers, and start conducting comprehensive research with AI assistance.
