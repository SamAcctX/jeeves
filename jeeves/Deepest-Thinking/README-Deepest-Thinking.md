# Deepest-Thinking Agent Documentation

The Deepest-Thinking agent is a specialized research assistant designed for the Ralph toolkit, providing comprehensive investigation capabilities through systematic research cycles. This agent excels at conducting deep, academic-style research by combining advanced search capabilities with structured thinking processes.

## Overview

The Deepest-Thinking agent is a core component of the Ralph workflow, specializing in:
- Conducting exhaustive investigations through required research cycles
- Using SearxNG Web Search for broad context and deep dives
- Applying Sequential Thinking for systematic analysis
- Producing academic-style research reports
- Following a structured three-stop research process
- Integrating seamlessly with the Ralph toolkit for project research needs

## Role in the Ralph Workflow

Within the Ralph toolkit ecosystem, the Deepest-Thinking agent serves as the primary research specialist. It complements other Ralph agents by:
- Providing foundational research for project planning and architecture design
- Conducting technical feasibility studies for new features
- Investigating best practices and industry standards
- Analyzing complex technical topics to inform decision-making
- Supporting PRD (Product Requirements Document) creation with research-backed insights
- Serving as a knowledge resource for the entire development team

## Capabilities and Features

### Core Research Capabilities

1. **Systematic Research Process**
   - Three-stop structured investigation approach
   - Mandatory research cycles for each theme
   - Comprehensive analysis and synthesis of findings

2. **Advanced Search Capabilities**
   - SearxNG Web Search for broad context gathering
   - Targeted deep dive searches for specific knowledge gaps
   - Smart search result filtering and validation

3. **Structured Thinking**
   - Sequential Thinking for systematic analysis
   - Pattern recognition and trend identification
   - Hypothesis testing and validation
   - Contradiction resolution

4. **Knowledge Synthesis**
   - Cross-source information integration
   - Evidence-based reasoning and argumentation
   - Academic-style report writing
   - Practical implications analysis

### Research Workflow Features

1. **Initial Engagement Phase**
   - 2-3 clarifying questions to refine research scope
   - Understanding validation with user feedback
   - Context gathering and scope definition

2. **Research Planning Phase**
   - 3-5 major themes identification
   - Detailed research approach for each theme
   - Complete execution plan with tools and timeline
   - User approval process before research execution

3. **Research Execution Phase**
   - Initial landscape analysis
   - Deep investigation of identified gaps
   - Knowledge integration across themes
   - Evidence trail documentation

4. **Final Report Generation**
   - Knowledge Development section (evolution of understanding)
   - Comprehensive Analysis section (synthesis of findings)
   - Practical Implications section (real-world applications)
   - Academic-style writing with proper structure

### Tool Integration

The Deepest-Thinking agent integrates with the following MCP servers and tools:
- **SearxNG Web Search**: For comprehensive internet research
- **Sequential Thinking**: For structured analysis and reasoning
- **Read/Write**: For saving research reports and documentation
- **Bash**: For terminal operations and system commands
- **Grep/Glob**: For file search and content analysis
- **Question**: For interactive clarification

## Files Included

- `deepest-thinking-prompt.md` - Original source prompt with Deep Research Protocol
- `deepest-thinking-opencode-template.md` - OpenCode-compatible template
- `deepest-thinking-claude-template.md` - Claude Code-compatible template
- `README-Deepest-Thinking.md` - This comprehensive documentation

## Quick Start for Ralph Users

### Using the Jeeves Script (Recommended)

The easiest way to install the Deepest-Thinking agent is by using the Jeeves management script:

```bash
# Open a terminal in your Jeeves project directory
cd /path/to/jeeves

# Install the Deepest-Thinking agent globally
./jeeves/bin/install-agents.sh --deepest
```

This script will automatically install both OpenCode and Claude Code templates in their respective global directories.

### Manual Installation

#### Project-Level Installation (for Ralph Projects)

```bash
# Navigate to your Ralph project directory
cd /path/to/your/ralph/project

# Create agent directories if they don't exist
mkdir -p .opencode/agents .claude/agents

# Copy the Deepest-Thinking agent templates
cp /path/to/jeeves/jeeves/Deepest-Thinking/deepest-thinking-opencode-template.md .opencode/agents/deepest-thinking.md
cp /path/to/jeeves/jeeves/Deepest-Thinking/deepest-thinking-claude-template.md .claude/agents/deepest-thinking.md
```

#### Global Installation (for All Projects)

```bash
# Install OpenCode template
mkdir -p ~/.config/opencode/agents
cp /path/to/jeeves/jeeves/Deepest-Thinking/deepest-thinking-opencode-template.md ~/.config/opencode/agents/deepest-thinking.md

# Install Claude Code template
mkdir -p ~/.claude/agents
cp /path/to/jeeves/jeeves/Deepest-Thinking/deepest-thinking-claude-template.md ~/.claude/agents/deepest-thinking.md
```

## Configuration Details

### OpenCode Agent Configuration

The OpenCode template includes:
- **Description**: Methodical research assistant who conducts exhaustive investigations through required research cycles
- **Mode**: `all` (available in all conversation types)
- **Temperature**: Optimized for focused, analytical responses
- **Tools**: Complete toolset including SearxNG Web Search and Sequential Thinking
- **Permissions**: Safe defaults with approval for sensitive operations

```yaml
---
name: deepest-thinking
description: Methodical research assistant who conducts exhaustive investigations through required research cycles
mode: all

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
  searxng_searxng_web_search: true  # Comprehensive search
  searxng_web_url_read: true        # Content extraction
  websearch: true           # Fallback search
  codesearch: true          # Code search
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

### Using the Deepest-Thinking Agent in Ralph Workflow

The Deepest-Thinking agent integrates seamlessly with the Ralph toolkit, providing research support for various phases of your project.

#### 1. Starting a Research Session

To begin a research session:

```bash
# Within your Ralph project
ralph-init.sh  # Initialize project structure
ralph-loop.sh  # Start autonomous loop

# Or use directly in your IDE
# OpenCode: Switch to Deepest-Thinking agent
# Claude Code: Use @deepest-thinking command
```

#### 2. Research Process Overview

The Deepest-Thinking agent follows a structured three-stop research process:

##### Initial Engagement [STOP POINT ONE]
- Agent asks 2-3 clarifying questions to understand your research needs
- You provide clarifications about scope, depth, and specific requirements
- Agent confirms understanding before proceeding

**Example questions might include:**
- What is the primary research question you want to answer?
- What depth of analysis do you need (overview vs. deep dive)?
- Are there specific sources or domains you want to focus on?

##### Research Planning [STOP POINT TWO]
- Agent presents a research plan with 3-5 major themes
- For each theme, outlines key questions and investigation approach
- Shows complete execution plan with tools and expected depth
- **Requires user approval before research begins**

##### Research Execution (No Stops)
- **Initial Landscape Analysis**: SearxNG Web Search + Sequential Thinking
- **Deep Investigation**: Targeted SearxNG Web Search + Sequential Thinking
- **Knowledge Integration**: Synthesize findings across all themes
- Minimum two full research cycles per theme

##### Final Report [STOP POINT THREE]
- Comprehensive academic-style report including:
  - **Knowledge Development**: Evolution of understanding through research
  - **Comprehensive Analysis**: Synthesis of evidence from multiple sources
  - **Practical Implications**: Real-world applications and recommendations

#### 3. Ralph-Specific Use Cases

The Deepest-Thinking agent is particularly valuable for:

1. **PRD Creation Support**: Researching user needs, market trends, and competitive analysis for product requirements
2. **Technical Feasibility Studies**: Investigating new technologies and architecture patterns
3. **Best Practices Research**: Finding industry standards and proven solutions
4. **Architecture Design**: Researching architectural patterns and design principles
5. **Risk Assessment**: Identifying potential risks and mitigation strategies
6. **Competitive Analysis**: Researching competitor products and market positioning

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

### Ralph-Specific Issues

#### Agent Not Detected in Ralph Workflow
- Check if agents are properly installed: `./jeeves/bin/install-agents.sh --deepest`
- Verify agent files exist in Ralph's template directory
- Check if MCP servers are running: `./jeeves/bin/install-mcp-servers.sh --dry-run`

#### Tools Not Working
- Ensure MCP servers are properly installed: `./jeeves/bin/install-mcp-servers.sh`
- Check if SearxNG and SequentialThinking tools are available
- Review MCP server logs for errors

#### Permission Prompts in OpenCode
- This is expected behavior for safe operations
- Review the requested action before approving
- For frequent operations, you can modify permissions in the agent template

#### Claude Code Not Delegating
- Check the `description` field in the subagent template
- Use explicit language like "deep research" or "comprehensive investigation"
- Try manual invocation with `@deepest-thinking` command
- Verify the Claude Code extension is properly configured

### General Issues

#### Agent Not Responding
- Check if your IDE has the latest updates
- Restart your IDE or terminal session
- Verify network connectivity for web search capabilities

#### Search Results Not Relevant
- Refine your research question with more specific details
- Provide context about your project domain
- Ask follow-up questions to guide the research

## Examples

### Ralph Workflow Example: Technical Research

```bash
# Within your Ralph project
ralph-init.sh
# Now start the autonomous loop

You: I need to research microservices architecture patterns for our new e-commerce platform

Deepest-Thinking: I'll help you conduct a comprehensive research investigation. Let me start by understanding your research needs.

1. What specific aspects of microservices architecture are you most interested in?
2. Do you have any existing technology constraints or preferences?
3. What scale of deployment are you planning for?

You: I'm interested in service communication patterns, data management, and error handling. We're using Node.js and Kubernetes.

Deepest-Thinking: Based on your research needs, I've identified these themes:

1. Microservices Communication Patterns
2. Data Management in Microservices
3. Error Handling and Resilience
4. Kubernetes-Specific Implementation
5. Node.js Best Practices

For each theme, I'll conduct:
- Initial landscape analysis with SearxNG Web Search
- Deep investigation with SearxNG Web Search
- Systematic analysis with Sequential Thinking

Do you approve this research plan?
```

### PRD Creation Research

```bash
You: Help me research user needs for a new project management tool

Deepest-Thinking: I'll help you conduct a comprehensive investigation into project management tool user needs. Let me ask a few clarifying questions.

1. What primary user personas will be using this tool?
2. What specific pain points are you trying to address?
3. Are there any existing tools in the market you want to benchmark against?

You: We're targeting small to medium-sized development teams. Pain points include poor integration with development tools and inefficient task tracking.

Deepest-Thinking: [Presents research plan with 4-5 themes]
[Research plan approved, agent executes investigation]
[Final report includes user needs analysis, competitive benchmarks, and feature recommendations]
```



## Support

For issues with the Deepest-Thinking agent:

1. **Check this README** for common solutions
2. **Review your installation** against the troubleshooting section
3. **Verify MCP servers** are properly installed and running
4. **Test with a simple example** to verify basic functionality
5. **Check platform documentation** for latest updates

## Ralph Toolkit Integration

The Deepest-Thinking agent is fully integrated with the Ralph ecosystem:

### Ralph Project Structure
```
your-ralph-project/
├── .opencode/
│   └── agents/
│       └── deepest-thinking.md          # OpenCode agent
├── .claude/
│   └── agents/
│       └── deepest-thinking.md          # Claude Code subagent
├── jeeves/
│   ├── Deepest-Thinking/
│   │   ├── deepest-thinking-prompt.md         # Original source
│   │   ├── deepest-thinking-opencode-template.md # OpenCode template
│   │   ├── deepest-thinking-claude-template.md   # Claude Code template
│   │   └── README-Deepest-Thinking.md         # This guide
└── Ralph/
    ├── templates/
    │   └── agents/
    │       └── [other Ralph agents]
    └── skills/
        └── [Ralph skills]
```

### Ralph-Specific Configuration

The Deepest-Thinking agent works with Ralph's skills and templates system:

1. **Agent Selection**: Ralph can automatically select the Deepest-Thinking agent for research tasks
2. **Skill Integration**: Works seamlessly with Ralph's existing skill ecosystem
3. **Output Formatting**: Produces research reports compatible with Ralph's documentation structure
4. **Task Delegation**: Can be invoked from other Ralph agents for specialized research needs

## File Reference

| File | Purpose | Platform |
|-------|---------|----------|
| `deepest-thinking-opencode-template.md` | OpenCode agent template | OpenCode |
| `deepest-thinking-claude-template.md` | Claude Code subagent template | Claude Code |
| `deepest-thinking-prompt.md` | Original source prompt | Reference |
| `README-Deepest-Thinking.md` | This comprehensive documentation | Documentation |

## Related Resources

- **Ralph Toolkit Documentation**: [README-Ralph.md](../Ralph/README-Ralph.md)
- **Jeeves Management Script**: [jeeves.ps1](../../jeeves.ps1)
- **Agent Installation Script**: [install-agents.sh](../bin/install-agents.sh)
- **SearxNG Web Search**: [MCP Server](https://github.com/isokoliuk/mcp-searxng)
- **Sequential Thinking**: [MCP Server Documentation](https://github.com/mcp/sequentialthinking)

---

**Ready to use!** Install the Deepest-Thinking agent using the Jeeves management script, set up the required MCP servers, and start conducting comprehensive research with AI assistance within your Ralph projects.
