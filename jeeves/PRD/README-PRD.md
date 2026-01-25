# PRD Creator Agent Setup Guide

This guide walks you through setting up the PRD Creator agent for both OpenCode and Claude Code platforms. The PRD Creator helps beginner developers create comprehensive Product Requirements Documents (PRDs) through structured questioning.

## Overview

The PRD Creator agent is a specialized AI assistant that:
- Guides beginners through the product planning process
- Asks structured questions about features, users, technical requirements
- Creates comprehensive PRD.md files
- Provides technology recommendations and architectural guidance
- Works with native tools only (no MCPs required)

## Files Included

- `PRD/prd-creator-prompt.md` - Original source prompt
- `PRD/prd-creator-opencode-template.md` - OpenCode-compatible template
- `PRD/prd-creator-claude-template.md` - Claude Code-compatible template
- `PRD/README-PRD.md` - This setup guide

## Quick Start

### For OpenCode Users
1. Copy the template to your project's agent directory
2. Use `@prd-creator` or switch to the agent in OpenCode

### For Claude Code Users
1. Copy the template to your project's subagent directory  
2. Use `@prd-creator` or let Claude auto-delegate PRD tasks

## Installation Guide

### OpenCode Installation

#### Project-Level Installation
Install for a specific project/repo:

```bash
# Create the agents directory if it doesn't exist
mkdir -p /path/to/your/project/.opencode/agents

# Copy the OpenCode template
cp /path/to/proj/PRD/prd-creator-opencode-template.md /path/to/your/project/.opencode/agents/prd-creator.md
```

#### Global Installation (Recommended for frequent use)
Install for all projects:

```bash
# Create the global agents directory
mkdir -p ~/.config/opencode/agents

# Copy the OpenCode template  
cp /path/to/proj/PRD/prd-creator-opencode-template.md ~/.config/opencode/agents/prd-creator.md
```

### Claude Code Installation

#### Project-Level Installation
Install for a specific project/repo:

```bash
# Create the agents directory if it doesn't exist
mkdir -p /path/to/your/project/.claude/agents

# Copy the Claude Code template
cp /path/to/proj/PRD/prd-creator-claude-template.md /path/to/your/project/.claude/agents/prd-creator.md
```

#### Global Installation (Recommended for frequent use)
Install for all projects:

```bash
# Create the global agents directory
mkdir -p ~/.claude/agents

# Copy the Claude Code template
cp /path/to/proj/PRD/prd-creator-claude-template.md ~/.claude/agents/prd-creator.md
```

## Configuration Details

### OpenCode Agent Configuration

The OpenCode template includes:
- **Description**: Professional product manager assistant for PRD creation
- **Mode**: `subagent` (specialized task)
- **Temperature**: `0.3` (balanced responses)
- **Tools**: Read, write, search, and analysis tools
- **Permissions**: Safe defaults with approval for sensitive operations

```yaml
---
description: Professional product manager assistant that helps beginner developers create comprehensive PRDs through structured questioning and planning
mode: subagent
temperature: 0.3
permission:
  write: ask      # User approval for file operations
  bash: ask       # User approval for terminal commands
  webfetch: allow  # Auto-allow web research
  edit: deny       # No editing needed for PRD creation
tools:
  read: true               # Read existing documentation
  write: true              # Save PRD files
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
- **Name**: `prd-creator`
- **Description**: Optimized for automatic delegation when PRD creation is needed
- **Tools**: Complete toolset for PRD workflow
- **Model**: Inherit from parent conversation

```yaml
---
name: prd-creator
description: Professional product manager assistant that helps beginner developers create comprehensive PRDs through structured questioning and planning. Use when user wants to plan a software project, create specifications, or document requirements.
tools: Read, Write, Web, SequentialThinking, Question, Grep, Glob, Bash
model: inherit
---
```

## Usage Guide

### Using the PRD Creator

#### 1. Start a Conversation
Begin by describing your software idea at a high level.

#### 2. Answer Structured Questions
The agent will ask questions about:
- Core features and functionality
- Target audience and user needs
- Platform requirements (web, mobile, desktop)
- UI/UX concepts
- Data storage and management
- Authentication and security needs
- Third-party integrations
- Scalability considerations
- Technical challenges
- Potential costs and API requirements

#### 3. Review Generated PRD
The agent will create a comprehensive PRD with:
- App overview and objectives
- Target audience definition
- Core feature specifications
- Technical stack recommendations
- Data model concepts
- UI design principles
- Security considerations
- Development phases and milestones
- Potential challenges and solutions
- Future expansion possibilities

#### 4. Iterate and Refine
Provide feedback on specific sections and the agent will revise accordingly.

### Platform-Specific Usage

#### OpenCode
- Switch agents using **Tab** key or your configured `switch_agent` keybind
- Or invoke directly with `@prd-creator`
- Agent may prompt for approval on file writes or bash commands

#### Claude Code
- Claude will automatically delegate PRD creation tasks to the subagent
- Or invoke manually with `@prd-creator`
- Subagent runs in separate context window
- Can run in background with **Ctrl+B**

## Tool Permissions

### OpenCode Permission Model
- **ask**: Prompts for user approval before running
- **allow**: Runs automatically without approval  
- **deny**: Blocks the tool entirely

The PRD creator uses:
- `write: ask` - Safely saves PRD files with your approval
- `bash: ask` - Runs terminal commands with your approval
- `webfetch: allow` - Automatic web research for recommendations
- `edit: deny` - Not needed for PRD creation workflow

### Claude Code Permission Model
Uses inherited permissions from the main conversation. The subagent has access to:
- Read, Write, Grep, Glob (file operations)
- Bash (terminal commands)
- Web (internet research)
- SequentialThinking (structured analysis)
- Question (interactive dialogue)

## MCP Integration (Future Enhancement)

### Recommended MCPs for Advanced Features

The agent works with native tools, but these MCPs would enhance functionality:

#### **browser** - Advanced Web Research
- Advanced web browsing beyond basic fetch
- Interactive web sessions for complex research
- Better handling of modern web applications

#### **database** - Existing Product Data
- Query existing product databases for context
- Pull information from Jira, Confluence, etc.
- Access historical product metrics and requirements

#### **figma** - Design Integration
- Access existing design mockups and wireframes
- Pull UI specifications directly from designs
- Generate requirements from visual assets

#### **github** - Repository Context
- Analyze existing code repositories
- Understand technical constraints from current codebase
- Generate requirements based on current architecture

#### **jira** - Project Management
- Access existing project requirements
- Pull in current tickets and feature requests
- Align new PRD with existing backlog

#### **slack** - Team Communication
- Access team discussions and decisions
- Reference previous requirements discussions
- Understand team constraints and priorities

### MCP Integration Steps (When Ready)
1. Install the desired MCP servers
2. Update agent templates to reference MCP tools
3. Test integration with specific use cases
4. Update permissions as needed

## Directory Structure

After installation, your directory structure should look like:

```
your-project/
├── .opencode/
│   └── agents/
│       └── prd-creator.md          # OpenCode agent
├── .claude/
│   └── agents/
│       └── prd-creator.md          # Claude Code subagent
├── jeeves/
│   ├── PRD/prd-creator-prompt.md         # Original source
│   ├── PRD/prd-creator-opencode-template.md # OpenCode template
│   ├── PRD/prd-creator-claude-template.md   # Claude Code template
│   └── PRD/README-PRD.md                 # This guide
└── PRD-YourProject-2024-01-24.md   # Generated PRD example
```

## Troubleshooting

### Agent Not Detected
- Verify file is in correct directory (`.opencode/agents/` or `.claude/agents/`)
- Check file permissions
- Restart your IDE or terminal session

### Tools Not Working
- OpenCode: Check permission settings in your `opencode.json`
- Claude Code: Verify MCP server status and permissions
- Ensure platform is up to date

### Permission Prompts
- OpenCode: This is expected behavior for safe operations
- Review the requested action before approving
- Use global config to change default permissions

### Claude Code Not Delegating
- Check the `description` field in the subagent
- Use more explicit language like "create PRD" or "plan requirements"
- Try manual invocation with `@prd-creator`

## Examples

### Basic Web App PRD
```
You: I want to create a task management app for small teams

Agent: I'll help you create a comprehensive PRD for your task management app. Let me start by understanding your idea at a high level.

What problem does this task management app solve for small teams?
```

### Mobile App PRD
```
You: I'm thinking about a fitness tracking app for personal use

Agent: I'll help you plan your fitness tracking app. Let me start with some clarifying questions.

What are the core features that would make this fitness app valuable to users?
```

### Complex System PRD
```
You: We need a PRD for an e-commerce platform with inventory management

Agent: I'll help you create a comprehensive PRD for your e-commerce platform. Let me use Sequential Thinking to analyze this systematically.

[Agent proceeds through structured questioning about features, users, technical requirements, etc.]
```

## Support

For issues with the PRD Creator agent:

1. **Check this README** for common solutions
2. **Review your installation** against the troubleshooting section
3. **Test with a simple example** to verify basic functionality
4. **Check platform documentation** for latest updates

## File Reference

| File | Purpose | Platform |
|-------|---------|----------|
| `PRD/prd-creator-opencode-template.md` | OpenCode agent template | OpenCode |
| `PRD/prd-creator-claude-template.md` | Claude Code subagent template | Claude Code |
| `PRD/prd-creator-prompt.md` | Original source prompt | Reference |
| `PRD/README-PRD.md` | This setup guide | Documentation |

---

**Ready to use!** Install the appropriate template for your platform and start creating professional PRDs with AI assistance.