# PRD Creator Agent Documentation

The PRD Creator agent is a specialized AI assistant for the Ralph toolkit that helps developers create comprehensive Product Requirements Documents (PRDs) through structured questioning. It acts as a professional product manager, guiding users through the product planning process and generating detailed PRD files optimized for the Ralph development workflow.

## Overview

The PRD Creator agent is a specialized AI assistant that:
- Guides developers through the product planning process
- Asks structured questions about features, users, and technical requirements
- Creates comprehensive PRD.md files
- Provides technology recommendations and architectural guidance
- Works with native tools only (no MCPs required)
- Optimized for the Ralph toolkit's development workflow
- Generates PRDs tailored for handoff to software engineers (human or AI)
- Supports integration with Ralph's task management and decomposition processes

## Files Included

- `prd-creator-prompt.md` - Original source prompt defining the core behavior and capabilities
- `prd-creator-opencode-template.md` - OpenCode-compatible agent template with YAML frontmatter
- `prd-creator-claude-template.md` - Claude Code-compatible subagent template
- `README-PRD.md` - This comprehensive documentation

## Role in the Ralph Workflow

The PRD Creator agent plays a critical role in **Phase 1 (PRD Generation)** of the Ralph development process:

### Ralph Workflow Integration
Ralph follows a structured three-phase approach:
1. **Phase 1: PRD Generation** - User-driven requirements definition (this is where PRD Creator excels)
2. **Phase 2: Decomposition** - Agent-assisted task breakdown using the `@decomposer` agent
3. **Phase 3: Execution** - Autonomous task execution via the Ralph Loop

### Output Format for Ralph
The PRD Creator generates PRD files specifically designed for Ralph:
- Saves to `.ralph/specs/PRD-[ProjectName]-[Date].md` directory
- Follows Ralph's PRD structure requirements
- Optimized for decomposition by the Decomposer agent
- Contains implementation-relevant details for developers

## Quick Start

### For OpenCode Users
1. Copy the template to your project's agent directory
2. Use `@prd-creator` or switch to the agent in OpenCode

### For Claude Code Users
1. Copy the template to your project's subagent directory  
2. Use `@prd-creator` or let Claude auto-delegate PRD tasks

### For Ralph Projects
1. Initialize your Ralph project: `ralph-init.sh`
2. Invoke PRD Creator: `@prd-creator` in OpenCode or Claude Code
3. The generated PRD will be saved to `.ralph/specs/` directory
4. Proceed to Phase 2: Decomposition with `@decomposer`

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
Begin by describing your software idea at a high level. For Ralph projects, the agent will automatically save the PRD to the correct location.

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

**For Ralph Projects:** The PRD will be automatically saved to `.ralph/specs/PRD-[ProjectName]-[Date].md`

### PRD Structure Generated by the Agent

The PRD Creator generates comprehensive PRDs with the following sections:

1. **App Overview and Objectives** - High-level description and goals
2. **Target Audience** - Detailed user personas and demographics
3. **Core Features and Functionality** - Feature descriptions with acceptance criteria
4. **Technical Stack Recommendations** - Technology suggestions with pros/cons
5. **Conceptual Data Model** - Data structure and relationships
6. **UI Design Principles** - Interface design guidelines
7. **Security Considerations** - Authentication, authorization, and data protection
8. **Development Phases/Milestones** - Timeline and deliverables
9. **Potential Challenges and Solutions** - Risk assessment and mitigation
10. **Future Expansion Possibilities** - Roadmap and scalability options

#### 4. Iterate and Refine
Provide feedback on specific sections and the agent will revise accordingly.

### Ralph-Specific Usage Tips

#### PRD Location
All PRDs for Ralph projects should be stored in the `.ralph/specs/` directory. This is the default location the Decomposer agent looks for requirements.

#### PRD Structure Requirements
For optimal decomposition, ensure your PRD includes:
- Clear feature descriptions with acceptance criteria
- Technical requirements and constraints
- Success criteria
- User stories or use cases
- Data model concepts

#### Integration with Decomposer Agent
Once your PRD is complete:
1. The Decomposer agent will automatically detect it in `.ralph/specs/`
2. It will break down the PRD into atomic tasks (<2 hours each)
3. Tasks will be created in `.ralph/tasks/` directory
4. Dependencies will be tracked in `deps-tracker.yaml`

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

### For Ralph Projects
After installation and usage, your Ralph project structure will include:

```
your-project/
├── .ralph/
│   ├── specs/                           # PRD and specifications
│   │   └── PRD-YourProject-2024-01-24.md # Generated PRD (saved here)
│   ├── tasks/                           # Task files
│   │   ├── TODO.md                      # Master task checklist
│   │   ├── deps-tracker.yaml            # Task dependencies
│   │   └── XXXX/                        # Individual task folders
│   └── config/
│       └── agents.yaml                  # Agent configuration
├── .opencode/
│   └── agents/
│       └── prd-creator.md               # OpenCode agent
├── .claude/
│   └── agents/
│       └── prd-creator.md               # Claude Code subagent
└── jeeves/
    ├── PRD/
    │   ├── prd-creator-prompt.md        # Original source
    │   ├── prd-creator-opencode-template.md # OpenCode template
    │   ├── prd-creator-claude-template.md   # Claude Code template
    │   └── README-PRD.md                # This guide
    └── Ralph/                           # Ralph Loop framework
```

### Important Ralph Directories
- `.ralph/specs/` - **Required**: Stores all PRD files for the project
- `.ralph/tasks/` - Generated by Decomposer agent from PRD
- `.ralph/config/` - Configuration files including agent mappings

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
| `prd-creator-opencode-template.md` | OpenCode agent template with complete configuration | OpenCode |
| `prd-creator-claude-template.md` | Claude Code subagent template | Claude Code |
| `prd-creator-prompt.md` | Original source prompt defining core behavior and capabilities | Reference |
| `README-PRD.md` | Comprehensive documentation for the PRD Creator agent | Documentation |

## Key Capabilities

### Core Features
- **Structured Questioning**: Guides users through 11 essential aspects of product planning:
  1. Core features and functionality
  2. Target audience
  3. Platform (web, mobile, desktop)
  4. User interface and experience concepts
  5. Data storage and management needs
  6. User authentication and security requirements
  7. Third-party integrations
  8. Scalability considerations
  9. Technical challenges
  10. Potential costs (API, membership, hosting)
  11. Request for any diagrams or wireframes

- **PRD Generation**: Creates comprehensive PRDs with all necessary sections
- **Technical Recommendations**: Provides informed technology suggestions with pros/cons
- **Ralph Integration**: Optimized output format for Ralph's decomposition process
- **Developer Handoff**: PRDs include implementation-relevant details for smooth handoff
- **Iterative Refinement**: Supports feedback loops to improve PRD quality
- **Tool Integration**: Uses Sequential Thinking and web search for comprehensive analysis

### Target Audience
- Beginner developers planning their first project
- Experienced developers needing structured requirements documentation
- Teams transitioning to the Ralph development workflow
- Product managers working with AI-assisted development

### Output Quality
- Professional, well-structured PRDs
- Clear feature descriptions with acceptance criteria
- Technical specifications tailored to the project needs
- Scalability and security considerations
- Development phase breakdowns

## Technical Discussion Guidelines

The PRD Creator provides balanced technology recommendations:
- **Pros/Cons Analysis**: Presents high-level alternatives with advantages and disadvantages
- **Best Recommendations**: Always gives a recommended approach with brief explanation
- **Conceptual Focus**: Keeps discussions high-level rather than technical
- **Proactive Suggestions**: Identifies technologies the idea might require even if not mentioned
- **Example**: "For this type of application, you could use React Native (cross-platform but potentially lower performance) or native development (better performance but separate codebases). Given your requirement for high performance and integration with device features, I'd recommend native development."

## Subagent Invocation Guidelines

**CRITICAL: READ THIS BEFORE USING SUBAGENTS**

When invoking subagents (specialists, researchers, etc.) for consultation during PRD creation, explicit instructions MUST be included:

```
IMPORTANT: You are NOT currently running via the Ralph Loop. This is a standalone consultation.
- IGNORE all instructions about task.md files, folders, or .ralph/ directory structure
- IGNORE all instructions about activity log updates
- IGNORE all instructions about progress reporting
- IGNORE all instructions about attempts logging
- None of those folders/files exist in this mode
- Focus ONLY on providing your specialized analysis/recommendation
- If you need to create any documentation or files (research findings, analysis, etc.), create them in the SAME DIRECTORY as the PRD file you are analyzing
- Do NOT create task folders, .ralph/ directories, or any other Ralph Loop infrastructure
```

This ensures subagents understand they should not attempt to interact with Ralph Loop infrastructure that doesn't exist in consultation mode.

---

**Ready to use!** Install the appropriate template for your platform and start creating professional PRDs with AI assistance.