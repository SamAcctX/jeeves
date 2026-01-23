# Jeeves Toolkit - PRD Creator

A comprehensive Product Requirements Document (PRD) creation toolkit integrated into your Jeeves development environment. This toolkit helps you plan and document software products effectively using AI coding assistants (opencode or Claude).

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Understanding the PRD Methodology](#understanding-the-prd-methodology)
4. [Usage Instructions](#usage-instructions)
5. [AI Tool Compatibility](#ai-tool-compatibility)
6. [MCP Server Integration](#mcp-server-integration)
7. [Advanced Features](#advanced-features)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [FAQ](#faq)

---

## Overview

The PRD Creator is a prompt-based system that guides you through creating detailed Product Requirements Documents. It's designed for:

- **Beginner developers** learning to structure software projects
- **Experienced engineers** wanting systematic planning processes
- **Product managers** needing comprehensive documentation
- **AI-assisted development** workflows with opencode or Claude

### Key Features

- **Guided questioning** - Conversational approach that asks relevant questions
- **Educational focus** - Teaches you about technology options while learning your needs
- **Comprehensive output** - Generates PRDs optimized for developer handoff
- **MCP-enhanced** (optional) - Uses research tools for current best practices
- **Tool-agnostic** - Works with both opencode and Claude

---

## Quick Start

### For Green Developers (New to PRDs)

1. **Start the conversation:**
   ```bash
   prd-creator save-prompt
   ```
   
2. **Copy the prompt content** from the generated `PRD-CREATOR-PROMPT.md` file

3. **Paste it into your AI coding assistant** (opencode or Claude)

4. **Describe your app idea** in simple terms - e.g., "I want to build a to-do list app that helps people organize their daily tasks"

5. **Answer the questions** the AI asks you

6. **Review your PRD** when it's generated

### For Senior Engineers

1. **Initialize the prompt:**
   ```bash
   prd-creator save-prompt
   ```

2. **Paste into your AI assistant** and start describing your system

3. **The AI will ask targeted questions** about architecture, scalability, security, etc.

4. **Use the generated PRD** as a blueprint for implementation or team handoff

---

## Understanding the PRD Methodology

The PRD Creator uses a structured approach based on the methodology from [JeredBlu's PRD Creator](https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md).

### The Conversation Approach

The AI assistant will:

1. **Begin with a brief introduction** explaining the process
2. **Ask questions one at a time** in a conversational manner
3. **Focus 70% on understanding** your concept and 30% on educating about options
4. **Use plain language** avoiding unnecessary technical jargon

### Questions Covered

The AI will systematically explore:

1. **Core features** - What your app actually does
2. **Target audience** - Who will use it
3. **Platform** - Web, mobile, desktop
4. **UI/UX concepts** - How it should look and feel
5. **Data storage** - What data needs to be stored and how
6. **Authentication/security** - User accounts, data protection
7. **Third-party integrations** - External services needed
8. **Scalability** - How it will grow with users
9. **Technical challenges** - Anticipated difficulties
10. **Cost considerations** - API fees, hosting, etc.
11. **Visual materials** - Any diagrams or wireframes you have

### The Output Structure

The generated PRD includes:

- **App overview and objectives** - High-level summary
- **Target audience** - User personas and needs
- **Core features** - Detailed functionality with acceptance criteria
- **Technical stack recommendations** - Suggested technologies
- **Conceptual data model** - Database structure
- **UI design principles** - Design guidelines
- **Security considerations** - Security requirements and measures
- **Development phases** - Milestones and timeline
- **Potential challenges** - Anticipated issues and solutions
- **Future expansion** - Growth opportunities

---

## Usage Instructions

### Command Line Tool

The `prd-creator` command provides installation and management functions:

```bash
# Installation Commands
prd-creator install              # Install as global agent with MCP configuration
prd-creator install --global   # Force install as global agent with MCP configuration
prd-creator install --project    # Force install as project-level agent with MCP configuration
prd-creator install --skip-mcp  # Install without configuring MCP servers

# Management Commands  
prd-creator-uninstall global              # Remove global agent
prd-creator-uninstall project             # Remove project agent
prd-creator-uninstall all                 # Remove both agents
prd-creator-uninstall all --include-mcp   # Remove agents and deconfigure MCP servers

# Utility Commands
prd-creator init                   # Show quick start guide
prd-creator save-prompt            # Save agent to workspace
prd-creator show-readme             # Show full documentation
prd-creator check-mcp              # View MCP configuration
prd-creator help                   # Show this help message

# Global Options
--force                           # Skip confirmation prompts
--dry-run                         # Show what would be removed without actually removing
```

**Agent Installation Options:**

- **Global** (`--global`): Installs to `~/.config/opencode/agent/` - available in all projects
- **Project** (`--project`): Installs to `.opencode/agent/` in current workspace - project-specific
- **Auto-detect**: If no flag specified, automatically detects project context and installs accordingly
- **Skip MCP** (`--skip-mcp`): Install without automatically configuring MCP servers

**MCP Server Configuration:**

By default, `prd-creator install` automatically configures Sequential Thinking and File System MCP servers in OpenCode's configuration. These servers will install via `npx` when first used. Use `--skip-mcp` to disable this automatic configuration.

### Step-by-Step Workflow

#### Step 1: Prepare the Prompt

```bash
# Save the PRD creator prompt to your workspace
prd-creator save-prompt

# This creates: /workspace/PRD-CREATOR-PROMPT.md
```

#### Step 2: Start the Conversation

Open your AI coding assistant (opencode or Claude) and:

1. **Paste the entire prompt** from `PRD-CREATOR-PROMPT.md`
2. **Wait for the AI to introduce itself**
3. **Begin describing your idea**

#### Step 3: Answer Questions

The AI will ask questions one at a time. Answer them with as much detail as you have. Don't worry if you don't know technical details - the AI will help you understand your options.

#### Step 4: Review the PRD

When the AI has gathered enough information, it will generate a PRD. Review it carefully and:

- Ask for clarification on anything unclear
- Request changes to better reflect your vision
- Add missing information
- Remove anything that doesn't apply

#### Step 5: Save Your PRD

The AI can save the PRD to your file system if the Filesystem MCP is configured (see MCP Server Integration). Otherwise, copy the PRD content and save it manually as `PRD-[ProjectName]-[Date].md`.

---

## AI Tool Compatibility

### OpenCode

OpenCode is the primary target for this toolkit.

**Best practices for opencode:**

1. **Install the agent** using `prd-creator install`
2. **Restart opencode** to recognize the new agent
3. **Select 'PRD Creator'** from the agents menu (or use `@prd-creator`)
4. **Describe your project** - The agent will guide you through PRD creation

**OpenCode advantages:**

- Built-in file system access (no MCP needed for saving files)
- Native tool integration
- Designed for software development workflows
- Agent YAML format with proper tool permissions
- Modular prompt references (separate markdown file)

**Limitations:**

- Some MCP tools may require additional configuration

### Claude Desktop

Claude Desktop works with the PRD Creator prompt (agent format is opencode-specific).

**Best practices for Claude:**

1. **Save the prompt** using `prd-creator save-prompt`
2. **Copy and paste** into your Claude conversation
3. **Ensure MCP servers** are configured for enhanced functionality

**Claude advantages:**

- Rich MCP server ecosystem
- Strong reasoning capabilities
- Excellent for iterative refinement

**Limitations:**

- Requires MCP configuration for file system access
- Some features depend on specific MCP servers

### Web Interfaces (Claude.ai, etc.)

The PRD Creator prompt works in web interfaces, but:

- **File saving** - You'll need to manually copy/save the PRD
- **MCP servers** - Not available in web interfaces
- **Best used for** - Initial exploration and refinement, then switch to desktop/CLI for final output

---

## MCP Server Integration

MCP (Model Context Protocol) servers enhance the PRD Creator with additional capabilities. They are **optional** but recommended for best results.

### Required vs Optional MCP Servers

**None are strictly required** - the PRD Creator works perfectly with just the base prompt.

**Automatically Configured (when using `prd-creator install`):**

1. **Sequential Thinking** - Helps break down complex problems
2. **File System** - Saves PRDs directly to your project

These two are automatically added to OpenCode's MCP configuration during installation and will install via `npx` when first used.

**Optional (requires manual API key setup):**

3. **Brave Search** - Researches current best practices (requires BRAVE_API_KEY)
4. **Tavily Research** - Deep technical research (requires TAVILY_API_KEY)
5. **Fetch** - Web content fetching (optional)

### MCP Server Configuration

#### Sequential Thinking

No API key required. Add to your MCP config:

```json
{
  "mcpServers": {
    "sequentialthinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

#### File System

No API key required. Add to your MCP config:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

#### Brave Search

Requires a free API key from [Brave Search API](https://api.search.brave.com/).

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "your-brave-api-key-here"
      }
    }
  }
}
```

Set the environment variable in your shell:

```bash
export BRAVE_API_KEY="your-brave-api-key-here"
```

#### Tavily Research

Requires an API key from [Tavily](https://tavily.com/).

```json
{
  "mcpServers": {
    "tavily-research": {
      "command": "npx",
      "args": ["-y", "@tavily/mcp-server"],
      "env": {
        "TAVILY_API_KEY": "your-tavily-api-key-here"
      }
    }
  }
}
```

Set the environment variable:

```bash
export TAVILY_API_KEY="your-tavily-api-key-here"
```

#### Fetch (Optional)

No API key required:

```json
{
  "mcpServers": {
    "fetch": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch"]
    }
  }
}
```

### Configuring MCP Servers

#### For OpenCode

1. Open the opencode config directory: `~/.config/opencode/`
2. Find or create the MCP configuration file
3. Add the server configurations above
4. Restart opencode

#### For Claude Desktop

1. Open Claude Desktop
2. Go to **Settings** > **Developer** > **MCP Servers**
3. Add the server configurations
4. Restart Claude Desktop

### Checking Your MCP Configuration

Run the built-in check command:

```bash
prd-creator check-mcp
```

This will:
- List recommended MCP servers
- Show configuration examples
- Check if API keys are set in your environment

---

## Advanced Features

### Using with Knowledge Bases

If your AI tool supports knowledge bases (document repositories):

1. **Upload relevant documents** about your project:
   - Existing requirements
   - Technical specifications
   - Design documents
   - Previous project notes

2. **The PRD Creator will** reference these documents when making recommendations

3. **Citations appear** like: "According to your [Document Name], ..."

### Iterative Refinement

After generating the initial PRD:

1. **Ask specific questions** about sections
   - "Does the technical stack align with our team's expertise?"
   - "Can we add more detail about the authentication flow?"

2. **Request specific changes**
   - "Update the security section to include GDPR compliance"
   - "Add a subsection about mobile-specific features"

3. **Generate multiple versions**
   - "Create a simplified version for stakeholders"
   - "Generate a technical version for the dev team"

### Integrating with Development Workflows

#### Before Sprint Planning

Generate a PRD to:
- Define scope for the upcoming sprint
- Identify dependencies
- Estimate technical complexity

#### Before Hiring/Onboarding

Use the PRD to:
- Clearly communicate project goals
- Help new team members understand the system
- Set expectations for features and timeline

#### For Client Communication

Generate a simplified PRD for:
- Client presentations
- Scope discussions
- Change request justifications

---

## Troubleshooting

### Common Issues

**Issue: Prompt file not found**

```
Error: PRD prompt file not found at: /opt/jeeves/prd-creator/prd-creator-prompt.md
```

**Solution:**
- Ensure the Docker image was built correctly with the PRD Creator files
- Check that `/opt/jeeves/prd-creator/` exists in the container

**Issue: AI doesn't save the PRD file**

**Possible causes:**
1. Filesystem MCP not configured
2. Permission issues with workspace directory

**Solutions:**
1. Configure the Filesystem MCP (see MCP Server Integration)
2. Ensure your workspace directory has write permissions
3. Manually copy and save the PRD if MCP is unavailable

**Issue: Claude/opencode doesn't recognize MCP tools**

**Solutions:**
1. Verify MCP configuration syntax
2. Restart the AI tool after configuration
3. Check for typos in server names or paths
4. Verify API keys are set as environment variables

**Issue: Questions feel too basic or too technical**

**Solutions:**
1. Tell the AI your experience level
2. Ask for simpler or more technical explanations
3. Be specific about what you don't understand

### Getting Help

1. **Run the init command** for quick reference: `prd-creator init`
2. **Check the full README**: `prd-creator show-readme`
3. **Verify MCP config**: `prd-creator check-mcp`

---

## Best Practices

### For Beginners

1. **Be honest about your knowledge** - The AI adapts to your level
2. **Answer in your own words** - No need to use technical terms
3. **Ask questions** - The AI will explain anything unclear
4. **Start simple** - You can iterate and add detail later
5. **Save early and often** - Keep copies of your PRD versions

### For Experienced Developers

1. **Focus on architecture** - The AI can explore alternatives you haven't considered
2. **Leverage the research tools** - Let MCP servers find current best practices
3. **Use the iterative approach** - Refine based on team feedback
4. **Map PRD sections to sprints** - The output is organized for development phases
5. **Document trade-offs** - Capture why certain decisions were made

### For Product Managers

1. **Bring stakeholders into the conversation** - Share PRD drafts for feedback
2. **Use the cost analysis section** - Helps with budget planning
3. **Leverage the target audience section** - Refine user personas
4. **Track the development phases** - Use as a roadmap reference
5. **Keep PRDs versioned** - Maintain history as requirements evolve

### General Tips

1. **One idea per PRD** - Keep each document focused
2. **Version your PRDs** - Include dates in filenames
3. **Store in version control** - Track PRD changes alongside code
4. **Review regularly** - Update as the project evolves
5. **Use as living documents** - Don't just file them away

---

## FAQ

### Q: Do I need to install MCP servers?

**A:** No, they're optional. The PRD Creator works perfectly without them. MCP servers just add enhanced research and file-saving capabilities. At minimum, consider the Sequential Thinking and File System MCPs since they don't require API keys.

### Q: Can I use this without any AI coding tool?

**A:** No, this is designed specifically for use with AI coding assistants like opencode or Claude. However, you could manually read through the prompt structure and answer the questions yourself to create a PRD template.

### Q: How long does it take to create a PRD?

**A:** Depends on complexity:
- Simple app: 15-30 minutes of conversation
- Medium complexity: 30-60 minutes
- Complex system: 1-2 hours or more

### Q: What if I don't know the answer to a question?

**A:** Just say so! The AI will either:
- Suggest reasonable defaults based on similar applications
- Explain the concepts so you can make an informed decision
- Mark it as "to be determined" for later

### Q: Can I use the PRD for non-software projects?

**A:** The prompt is optimized for software, but you could adapt it. Focus on the conceptual parts (overview, objectives, audience) and modify the technical sections.

### Q: How do I update an existing PRD?

**A:** Load the PRD into your AI assistant and ask for updates:
- "Update this PRD to include a new feature: [describe feature]"
- "Refine the security section based on these new requirements: [describe]"
- "Generate version 2 of this PRD with these changes: [describe changes]"

### Q: Can multiple people work on a PRD?

**A:** Yes! Here's a workflow:
1. One person starts the PRD creation
2. Share the PRD document with stakeholders
3. Collect feedback
4. Paste the PRD back into the AI with the feedback
5. Ask the AI to incorporate the changes

### Q: What's the difference between this PRD Creator and just asking Claude to "write a PRD"?

**A:** This approach is structured and comprehensive:
- **Systematic questioning** ensures nothing is missed
- **Educational focus** teaches you about options
- **Developer-optimized output** includes acceptance criteria and implementation details
- **Iterative refinement** encourages feedback and changes
- **Research-enhanced** (with MCPs) uses current best practices

### Q: Will this work with future versions of Claude/opencode?

**A:** The prompt is designed to be tool-agnostic and should work with:
- Any AI assistant that accepts custom instructions
- Future versions of Claude and opencode
- Other AI coding tools with similar capabilities

### Q: Can I customize the prompt?

**A:** Absolutely! The prompt template is in `/opt/jeeves/prd-creator/prd-creator-prompt.md`. You can:
- Add company-specific requirements
- Remove sections you don't need
- Modify the question framework
- Add your own guidelines

---

## Additional Resources

### Original Source

Based on [JeredBlu's PRD Creator v2.2](https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md)

### Learning Resources

- **Product Requirements Documents** - [Atlassian Guide](https://www.atlassian.com/agile/project-management/requirements)
- **Technical Writing for Developers** - [Google's Technical Writing Course](https://developers.google.com/tech-writing)
- **Agile Planning** - [Scrum.org Resources](https://www.scrum.org/resources)

### MCP Server Documentation

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Server Repository](https://github.com/modelcontextprotocol/servers)
- [OpenCode Documentation](https://opencode.ai/)

### Video Tutorials

- [Creating PRDs with Claude MCP](https://youtu.be/0seaP5YjXVM)
- [AI Dictation (Vibing) for Product Ideas](https://youtu.be/qXPU2hsuiHk)

---

## Version History

- **v1.0** - Initial Jeeves Toolkit integration
  - Adapted PRD Creator v2.2 for containerized environment
  - Added command-line helper tool
  - Comprehensive documentation

---

## Contributing

This toolkit is based on open-source methodologies. To adapt or improve:

1. Modify the prompt template at `/opt/jeeves/prd-creator/prd-creator-prompt.md`
2. Update helper scripts in `/workspace/jeeves/`
3. Rebuild the Docker image

---

## License

This documentation and the PRD Creator methodology are based on work by [JeredBlu](https://github.com/JeredBlu). Please refer to the original repository for licensing information.

---

*Built for the Jeeves Development Environment*
