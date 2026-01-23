# Jeeves Toolkit Expansion - Analysis & Requirements Document

## Document Information

| Attribute | Value |
|-----------|-------|
| **Version** | 1.0 |
| **Date** | 2026-01-21 |
| **Status** | Analysis Complete |
| **Author** | Jeeves Development Team |
| **Mode** | Build Mode - Requirements Definition |

---

## Executive Summary

This document captures the requirements for expanding the Jeeves toolkit to include autonomous agent loop capabilities, deep thinking workflows, and structured product development methodologies. The expansion targets compatibility with both Anthropic's Claude Code and OpenCode CLI tools, providing a unified development environment that supports long-running autonomous tasks, systematic research protocols, and comprehensive product requirements documentation.

The Jeeves toolkit currently consists of a PowerShell management script (`jeeves.ps1`) and a Dockerfile (`Dockerfile.jeeves`) that provisions a containerized development environment with OpenCode CLI, Claude Code, tmux, and essential development tools. The proposed expansion adds scaffolding, configuration files, and documentation to enable advanced workflows that leverage these existing tools within a structured framework.

The core value proposition centers on providing developers with "handy extras" that can be initialized into any project mounted at `/workspace`, transforming Jeeves from a simple container management tool into a comprehensive AI-assisted development environment. This analysis documents the verbatim request, examines the referenced resources, identifies integration requirements, and establishes acceptance criteria for successful implementation.

---

## Section 1: Request Documentation

### 1.1 Verbatim Request

The user provided the following request for expanding the Jeeves toolkit:

> "I want to expand my jeeves toolkit to have some handy extras that I can initialize into a given project (/workspace, pulled from a mapped volume mount).
>
> 1. The ralph loop as implemented here - mainly the loop and scaffolding: https://github.com/JamesPaynter/efficient-ralph-loop
> 2. The ralph loop as described here: https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md
> 3. The deep-thinking described here: https://github.com/JeredBlu/custom-instructions/blob/main/Deepest-Thinking.md
> 4. The PRD methodology described here: https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md
>
> Additional notes:
> * What you do should be compatible with both claude and opencode - no other AI CLI is necessary. If you must pick one AI CLI, use opencode.
> * Should additional tools (such as MCP servers or the like) be needed, document what they are, why they are needed, and how to install them
> * A readme.md should be created documenting all of the above including setup, usage, recommendations, etc."

### 1.2 Constraints and Non-Requirements

The request establishes clear boundaries for the implementation:

**Constraints:**
- Must be compatible with both Claude Code and OpenCode CLI
- If a single AI CLI must be chosen, OpenCode takes precedence
- All extras must initialize into `/workspace` from a mapped volume mount
- Additional tools must be documented with installation instructions
- A comprehensive README.md must accompany the implementation

**Non-Requirements:**
- No additional AI CLI tools beyond Claude Code and OpenCode are required
- The Jeeves base container (jeeves.ps1 and Dockerfile.jeeves) is not to be modified
- Integration with external services beyond MCP servers is not in scope

---

## Section 2: Source Material Analysis

### 2.1 Efficient Ralph Loop (JamesPaynter/efficient-ralph-loop)

The efficient-ralph-loop repository provides a structured implementation of the "Ralph loop" pattern for running AI coding agents autonomously. This implementation addresses common pitfalls of naive loop approaches by introducing systematic task management, verification, and checkpoint mechanisms.

**Core Components Identified:**

The repository structure includes a Dockerfile for building an `agent-loop` image containing Node 20, OpenAI Codex, and Claude Code. The loop scripts (`loop-codex.sh` and `loop-claude.sh`) mount a project directory, execute agent commands, and poll for completion markers. The `YOUR_PROJECT/` directory contains scaffold templates demonstrating the expected file structure and bootstrap mechanism.

**Key Concepts Extracted:**

The "efficient" approach differs from naive Ralph loops in several critical ways. First, it enforces one task per iteration, preventing scope creep and multi-task confusion that plagues simpler implementations. Each task operates from a prioritized TODO list with explicit acceptance criteria and verification steps. Second, the loop provides fresh context for each iteration, preventing context pollution and maintaining reasoning quality while reducing token usage. Third, it mandates git commits between iterations, preserving intermediate progress and enabling regression identification. Fourth, termination is explicit and controlled, occurring only when TODO.md contains `[x] ALL_TASKS_COMPLETE`. Finally, Docker isolation provides safety guarantees, ensuring agents cannot affect host systems outside the mounted project directory.

**File Structure Requirements:**

The loop expects projects to contain: PLAN.md (goals, constraints, technical approach), INSTRUCTIONS.md (per-iteration prompt template), TODO.md (generated by bootstrap command, contains task list), docs/tasks/active/ directory for individual task specifications, and bootstrap command files (.codex/skills/bootstrap/SKILL.md and/or .claude/commands/bootstrap.md).

### 2.2 Ralph Wiggum Guide (JeredBlu/guides)

The Ralph Wiggum Guide provides a comprehensive tutorial for setting up and running autonomous agent loops, comparing the official Claude Code plugin method against the original bash loop approach. The guide emphasizes safety, efficiency, and proper feedback mechanisms.

**Method Comparison:**

The guide recommends the bash loop method over the Claude Code plugin for several reasons. The plugin runs everything in a single context window, leading to context bloat, increased hallucination risk, and the need for manual context compaction. The bash loop starts a fresh context window for each iteration, fundamentally better for long-running tasks. The guide explicitly states: "Each iteration runs in a fresh context window, which means no context bloat, reduced hallucination risk, cleaner separation between tasks, and better matches Anthropic's recommended approach."

**Required Components:**

The guide specifies these components for bash loop implementation: sandbox configuration in `.claude/settings.json`, a PRD for initial planning, plan.md with JSON-formatted tasks and passes fields, activity.md for logging agent progress, PROMPT.md containing the iteration prompt template, ralph.sh as the bash loop script, and Playwright MCP for headless visual verification.

**Sandboxing Configuration:**

The guide provides an example `.claude/settings.json` with environment variables for cache directories, allow/deny/ask permission rules, and sandbox configuration options. The sandbox settings include enabled=true, autoAllowBashIfSandboxed=true, allowUnsandboxedCommands=false, and network.allowLocalBinding=true.

**Feedback Loop Mechanisms:**

Two options exist for visual feedback. Claude for Chrome MCP enables the agent to open URLs, take screenshots, and check console logs. Playwright MCP provides headless browser automation with screenshot capabilities. The guide recommends Playwright for bash loop scenarios.

### 2.3 Deepest Thinking Protocol (JeredBlu/custom-instructions)

The Deepest-Thinking.md file defines a comprehensive research protocol that combines multiple MCP servers (Brave Search, Tavily Search, Sequential Thinking) to achieve Deep Research-like capabilities. This protocol is designed for systematic investigation with structured phases.

**Three-Phase Structure:**

The protocol mandates three stop points for user interaction. Phase One (Initial Engagement) involves asking 2-3 essential clarifying questions and waiting for user response. Phase Two (Research Planning) requires presenting a complete research plan including major themes, specific questions, tool assignments, and order of investigation, then waiting for user approval. Phase Three (Mandated Research Cycles) runs without stops, completing all research steps for each theme.

**Research Cycle Requirements:**

For each major theme identified, the protocol requires: Initial Landscape Analysis using Brave Search followed by Sequential Thinking to extract patterns, identify trends, map knowledge, form hypotheses, and note uncertainties; Deep Investigation using Tavily Search targeting identified gaps followed by Sequential Thinking to test hypotheses, challenge assumptions, find contradictions, and build connections; and Knowledge Integration connecting findings across sources, identifying patterns, challenging contradictions, mapping relationships, and forming unified understanding.

**Minimum Standards:**

The protocol establishes these minimums: two full research cycles per theme, evidence trail for each conclusion, multiple sources per claim, documentation of contradictions, and analysis of limitations. Sequential Thinking requires minimum 5 thoughts per analysis. All tool usage must be explicitly connected to previous findings.

**Final Report Requirements:**

The final report must contain at least 6-8 substantial paragraphs per major section. Every key assertion must cite multiple sources. All aspects must be thoroughly explored with academic rigor. Writing style requires flowing narrative, no bullet points or lists in final output, and integrated evidence within prose.

### 2.4 PRD Creator v2.5 (JeredBlu/custom-instructions)

The prd-creator-3-25.md file defines a methodology for creating comprehensive Product Requirements Documents using MCP servers and Claude's thinking capabilities. This transforms the PRD creation process into a structured conversation.

**Conversation Framework:**

The PRD Creator begins with a brief introduction explaining the process, then asks questions one at a time in a conversational manner. The focus is 70% on understanding the concept and 30% on educating about available options. The tone remains friendly and supportive with plain language avoiding unnecessary technical jargon.

**Question Categories:**

Essential aspects covered through questioning include: core features and functionality, target audience, platform (web, mobile, desktop), UI/UX concepts, data storage and management, authentication and security, third-party integrations, scalability considerations, technical challenges, potential costs, and request for any existing diagrams or wireframes.

**Technology Discussion:**

When discussing technical options, the methodology provides high-level alternatives with pros/cons, always giving a best recommendation with explanation. Discussions remain conceptual rather than technical. The assistant is proactive about technologies the idea might require.

**PRD Output Structure:**

Generated PRDs include: app overview and objectives, target audience, core features and functionality, technical stack recommendations, conceptual data model, UI design principles, security considerations, development phases/milestones, potential challenges and solutions, and future expansion possibilities.

**Developer Handoff Optimization:**

The methodology optimizes PRDs for handoff to software engineers (human or AI) by including implementation-relevant details without prescriptive code solutions, clear acceptance criteria for each feature, consistent terminology mapping to code components, structured data models with explicit fields/types/relationships, technical constraints and specific API integration points, feature groupings logical for sprint planning, pseudocode or algorithm descriptions where helpful, links to relevant technology documentation, and diagrams or pattern references where applicable.

**Required MCP Servers:**

PRD Creator requires: Sequential Thinking, Brave Search, Tavily, File System, and optionally Fetch. These tools enable structured analysis, current information research, in-depth technical investigation, and file persistence.

---

## Section 3: Requirements Analysis

### 3.1 Functional Requirements

**FR1: Ralph Loop Integration**

The Jeeves toolkit must provide infrastructure for running autonomous agent loops compatible with both Claude Code and OpenCode CLI. This includes scaffolding files that can be initialized into any project at `/workspace`.

**Sub-requirements:**
- FR1.1: Create PLAN.md template for defining project goals, constraints, and technical approach
- FR1.2: Create INSTRUCTIONS.md template for per-iteration prompts
- FR1.3: Create TODO.md structure with task format and completion marker (`[x] ALL_TASKS_COMPLETE`)
- FR1.4: Create bootstrap command files for both Claude Code and OpenCode
- FR1.5: Create ralph loop bash script compatible with OpenCode CLI
- FR1.6: Create activity.md template for logging iteration progress

**FR2: Deep Thinking Protocol Integration**

The toolkit must enable systematic research workflows using the Deepest-Thinking protocol, requiring integration with Brave Search and Tavily MCP servers.

**Sub-requirements:**
- FR2.1: Create Deepest-Thinking custom instructions compatible with OpenCode
- FR2.2: Document MCP server configuration for Brave Search
- FR2.3: Document MCP server configuration for Tavily
- FR2.4: Create research prompt templates for each protocol phase
- FR2.5: Document final report template with required sections

**FR3: PRD Creation Capability**

The toolkit must enable structured PRD creation using the prd-creator methodology.

**Sub-requirements:**
- FR3.1: Create PRD Creator custom instructions compatible with OpenCode
- FR3.2: Document MCP server configuration for Sequential Thinking
- FR3.3: Create conversation prompt templates for each PRD section
- FR3.4: Create PRD output template with all required sections
- FR3.5: Document feedback and iteration process

**FR4: Initialization Mechanism**

All extras must be initializable into a project at `/workspace` from a mapped volume mount.

**Sub-requirements:**
- FR4.1: Create initialization script that scaffolds all required files
- FR4.2: Support selective initialization (user chooses which components to enable)
- FR4.3: Preserve existing files during initialization (no overwrites)
- FR4.4: Provide configuration options for API keys and MCP servers

**FR5: Documentation**

Comprehensive documentation must accompany all features.

**Sub-requirements:**
- FR5.1: Create README.md documenting all features, setup, and usage
- FR5.2: Document MCP server installation procedures
- FR5.3: Provide usage examples for each workflow type
- FR5.4: Document compatibility between Claude Code and OpenCode

### 3.2 Non-Functional Requirements

**NFR1: Compatibility**

All features must work with both Claude Code and OpenCode CLI. When conflicts exist, OpenCode takes precedence.

**NFR2: Safety**

Autonomous loops must run safely within the Jeeves container environment. Docker isolation must prevent host system access beyond mounted directories.

**NFR3: Documentation Quality**

All documentation must be clear, actionable, and include troubleshooting guidance.

**NFR4: Maintainability**

File structures must be consistent and modular to enable future expansion.

**NFR5: Performance**

Autonomous loops must use fresh context per iteration to prevent context pollution and token bloat.

### 3.3 Integration Requirements

**IR1: MCP Server Integration**

Additional MCP servers required beyond existing Jeeves provisioning:

- **Sequential Thinking**: Required for PRD Creator and Deepest-Thinking protocols. Installation requires Node.js and npm. Server maintained by MCP organization.
- **Brave Search**: Required for web research capabilities in Deepest-Thinking. Requires Brave API key (free tier available). Server maintained by MCP organization.
- **Tavily**: Required for deep investigation in Deepest-Thinking. Requires Tavily API key. Server maintained by Tavily AI.
- **Playwright**: Optional but recommended for headless browser verification in Ralph loops. Installed via npx. Server maintained by Playwright organization.

**IR2: API Key Management**

Required API keys for full functionality:

- Anthropic API Key (or Claude subscription for macOS keychain integration)
- Brave Search API Key
- Tavily API Key

All keys must be configurable via environment variables or configuration files mounted into the container.

**IR3: Directory Structure**

Proposed structure for `/workspace` initialization:

```
/workspace/
  PLAN.md                    # Project goals and approach
  INSTRUCTIONS.md            # Per-iteration prompt template
  TODO.md                    # Task list with completion status
  activity.md                # Iteration progress log
  PROMPT.md                  # Ralph loop prompt template
  ralph.sh                   # Bash loop script
  .mcp.json                  # MCP server configuration
  docs/
    tasks/
      active/                # Individual task specifications
      completed/             # Completed task archives
  screenshots/               # Visual verification screenshots
  prd/                       # PRD creation workspace
    conversations/           # Conversation history
    drafts/                  # PRD draft versions
```

---

## Section 4: Acceptance Criteria

### 4.1 Ralph Loop Criteria

**AC-RL-1:** Initialization script creates PLAN.md template with goals, constraints, and technical approach sections.

**AC-RL-2:** Initialization script creates INSTRUCTIONS.md template with per-iteration prompt structure and verification commands.

**AC-RL-3:** Initialization script creates TODO.md with task list format including checkboxes and `[x] ALL_TASKS_COMPLETE` termination marker.

**AC-RL-4:** Bootstrap command files are created for both Claude Code (`.claude/commands/bootstrap.md`) and OpenCode equivalent.

**AC-RL-5:** ralph.sh bash script executes OpenCode CLI in loop mode, polling TODO.md for completion marker.

**AC-RL-6:** Each loop iteration runs with fresh context (new CLI process).

**AC-RL-7:** Git commits are created after each completed task.

**AC-RL-8:** activity.md template enables logging of iteration progress.

**AC-RL-9:** Docker isolation prevents agent access outside mounted `/workspace` directory.

### 4.2 Deep Thinking Criteria

**AC-DT-1:** Custom instructions implement three-stop research protocol compatible with OpenCode.

**AC-DT-2:** Phase One prompts user for clarifying questions and waits for response.

**AC-DT-3:** Phase Two presents research plan with themes, questions, tools, and order, then waits for user approval.

**AC-DT-4:** Phase Three executes mandatory research cycles without stops, completing all steps for each theme.

**AC-DT-5:** Sequential Thinking tool is invoked with minimum 5 thoughts per analysis.

**AC-DT-6:** Brave Search and Tavily Search are integrated per protocol requirements.

**AC-DT-7:** Final report template produces flowing narrative with integrated evidence (no bullet points).

**AC-DT-8:** Each major section contains minimum 6-8 substantial paragraphs.

### 4.3 PRD Creator Criteria

**AC-PRD-1:** Custom instructions implement conversational PRD creation workflow.

**AC-PRD-2:** Question framework covers all 11 essential aspects (features, audience, platform, UI, data, auth, integrations, scalability, challenges, costs, diagrams).

**AC-PRD-3:** Output PRD contains all 10 required sections.

**AC-PRD-4:** Acceptance criteria are defined for each feature.

**AC-PRD-5:** Data models include explicit field names, types, and relationships.

**AC-PRD-6:** Sequential Thinking tool is used for planning and analysis.

**AC-PRD-7:** File System tool saves PRD to persistent storage.

**AC-PRD-8:** Feedback and iteration process is documented.

### 4.4 Documentation Criteria

**AC-DOC-1:** README.md documents all features with setup instructions.

**AC-DOC-2:** MCP server installation instructions include all required tools.

**AC-DOC-3:** Usage examples demonstrate each workflow type.

**AC-DOC-4:** Compatibility table shows Claude Code vs OpenCode feature support.

**AC-DOC-5:** Troubleshooting section addresses common issues.

**AC-DOC-6:** Recommendations section provides guidance on tool selection.

### 4.5 Compatibility Criteria

**AC-CMP-1:** All features work with OpenCode CLI without modification.

**AC-CMP-2:** All features work with Claude Code CLI without modification.

**AC-CMP-3:** When conflicts exist, OpenCode behavior is the reference implementation.

**AC-CMP-4:** MCP server configuration is identical for both CLI tools.

**AC-CMP-5:** Prompts use syntax compatible with both Claude Code and OpenCode.

### 4.6 Safety Criteria

**AC-SAF-1:** Ralph loops run inside Docker container with mounted `/workspace` only.

**AC-SAF-2:** Maximum iteration limit is configurable and defaults to finite value.

**AC-SAF-3:** Sandbox configuration prevents destructive operations.

**AC-SAF-4:** API keys are stored in mounted configuration files, not committed to version control.

---

## Section 5: Implementation Recommendations

### 5.1 Architecture Decisions

**File Organization:**

Use a modular approach with separate directories for each feature set:

- `/opt/jeeves/extras/ralph/` - Ralph loop scaffolding and scripts
- `/opt/jeeves/extras/deep-thinking/` - Research protocol templates
- `/opt/jeeves/extras/prd/` - PRD creation templates
- `/opt/jeeves/extras/shared/` - Shared utilities and configuration

**Initialization Approach:**

Create a unified `jeeves-init.sh` script that can be run from `/workspace` to scaffold all or selected extras. Interactive prompts allow users to choose which components to install.

**Configuration Management:**

Use `.env.example` files for each feature to document required environment variables. Actual `.env` files are mounted from host to avoid committing secrets.

### 5.2 MCP Server Strategy

**Required Servers (Full Functionality):**

1. **Sequential Thinking** - Core requirement for PRD Creator and Deepest-Thinking
2. **Brave Search** - Required for web research capabilities
3. **Tavily** - Required for deep investigation
4. **Playwright** - Recommended for headless visual verification

**Installation Method:**

Document both container-based and host-based installation options. Container-based simplifies isolation but may impact performance. Host-based provides better integration but requires host configuration.

**Configuration File:**

Create `.mcp.json` template at `/opt/jeeves/extras/.mcp.json` that users can copy to `/workspace/.mcp.json`.

### 5.3 Ralph Loop Implementation

**Prompt Template Strategy:**

Use a hierarchical prompt approach:
- `PROMPT.md` - Base prompt containing iteration instructions
- `@PLAN.md` - File reference to current plan
- `@TODO.md` - File reference to task list
- `@activity.md` - File reference to progress log

**Loop Script:**

```bash
#!/bin/bash
# ralph.sh - OpenCode Ralph Loop
# Usage: ./ralph.sh [max_iterations]

MAX_ITERATIONS=${1:-20}
ITERATION=0

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "=== Iteration $ITERATION of $MAX_ITERATIONS ==="
    
    # Execute OpenCode with prompt, capture output
    opencode -p "$(cat PROMPT.md)" --output-format text > output.txt
    
    # Check for completion marker
    if grep -q "<promise>COMPLETE</promise>" output.txt; then
        echo "All tasks complete!"
        break
    fi
    
    # Log output
    cat output.txt >> activity.md
    
    echo "=== Iteration $ITERATION complete ==="
done
```

### 5.4 Compatibility Approach

**Prompt Syntax:**

Avoid Claude Code-specific syntax like `@file` references if OpenCode doesn't support them. Use standard file reading and include content in prompts.

**Command Equivalents:**

| Feature | Claude Code | OpenCode |
|---------|-------------|----------|
| Interactive prompt | `claude` | `opencode` |
| Piped prompt | `claude -p` | `opencode -p` |
| Command files | `/commands/*.md` | Equivalent mechanism |
| Settings | `.claude/settings.json` | `.config/opencode/` |

**Fallback Strategy:**

When features aren't directly compatible, provide separate scripts or prompts for each CLI tool with clear documentation of differences.

---

## Section 6: Risk Analysis

### 6.1 Identified Risks

**Risk 1: OpenCode CLI Compatibility**

OpenCode CLI may not support all features used in Claude Code prompts. Custom instructions designed for Claude may require modification.

*Mitigation:* Test prompts with OpenCode first. Document any incompatibilities. Provide separate prompts if necessary.

**Risk 2: MCP Server Complexity**

Requiring multiple MCP servers increases setup complexity and potential failure points.

*Mitigation:* Provide clear installation instructions. Use container-based MCP servers where possible. Document troubleshooting steps.

**Risk 3: API Key Management**

Requiring multiple API keys (Anthropic, Brave, Tavily) creates configuration burden.

*Mitigation:* Use environment variables consistently. Provide `.env.example` templates. Document free tier options.

**Risk 4: Resource Consumption**

Ralph loops can consume significant resources (tokens, time) if not properly controlled.

*Mitigation:* Default max iterations to 20. Mandate iteration limits in loop scripts. Document cost management strategies.

**Risk 5: Container Integration**

Jeeves runs in Docker; MCP servers may expect direct host access.

*Mitigation:* Document MCP server configuration for containerized environments. Use npx-based MCP servers where possible.

### 6.2 Dependencies

**External Dependencies:**

- OpenCode CLI (must be available in Jeeves container)
- Claude Code CLI (must be available in Jeeves container)
- Sequential Thinking MCP server
- Brave Search MCP server
- Tavily MCP server
- Playwright MCP server (optional)

**Version Constraints:**

- OpenCode: Latest version compatible with container
- Claude Code: Latest version compatible with container
- Node.js: 18+ for MCP servers
- MCP servers: Latest stable versions

---

## Section 7: Deliverables Summary

### 7.1 Required Deliverables

| Deliverable | Location | Description |
|-------------|----------|-------------|
| `analysis.md` | `/workspace/analysis.md` | This document - requirements and acceptance criteria |
| `README.md` | `/workspace/README.md` | User-facing documentation |
| Ralph Loop Scaffolding | `/opt/jeeves/extras/ralph/` | PLAN.md, INSTRUCTIONS.md, TODO.md templates |
| Ralph Loop Script | `/opt/jeeves/extras/ralph/ralph.sh` | Bash loop script for OpenCode |
| Bootstrap Commands | `/opt/jeeves/extras/ralph/.claude/` and equivalent for OpenCode |
| Deep-Thinking Protocol | `/opt/jeeves/extras/deep-thinking/` | Custom instructions and templates |
| PRD Creator Protocol | `/opt/jeeves/extras/prd/` | Custom instructions and templates |
| MCP Configuration | `/opt/jeeves/extras/.mcp.json` | MCP server configuration template |
| Initialization Script | `/opt/jeeves/bin/jeeves-init.sh` | Script to scaffold extras into project |
| Environment Templates | `/opt/jeeves/extras/.env.*` | Environment variable templates |

### 7.2 Documentation Deliverables

| Document | Description |
|----------|-------------|
| `README.md` | Main documentation with setup, usage, and troubleshooting |
| `RALPH_LOOP_GUIDE.md` | Ralph loop specific documentation |
| `DEEP_THINKING_GUIDE.md` | Deep Thinking protocol documentation |
| `PRD_CREATOR_GUIDE.md` | PRD creation methodology documentation |
| `MCP_SETUP.md` | MCP server installation and configuration |

---

## Appendix A: Reference Links

**Efficient Ralph Loop:**
- Repository: https://github.com/JamesPaynter/efficient-ralph-loop
- Original Ralph: https://ghuntley.com/ralph/

**Ralph Wiggum Guide:**
- Repository: https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md
- Video: https://youtu.be/eAtvoGlpeRU

**Deepest Thinking:**
- Repository: https://github.com/JeredBlu/custom-instructions/blob/main/Deepest-Thinking.md

**PRD Creator:**
- Repository: https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md
- Video: https://youtu.be/0seaP5YjXVM

**Anthropic Resources:**
- Effective Harnesses for Long-Running Agents: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Claude Code Sandbox: https://code.claude.com/docs/en/sandboxing

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Ralph Loop** | A pattern of running AI coding agents in a continuous loop, checking for completion after each iteration |
| **Ralph Wiggum** | A specific implementation of the Ralph loop pattern popularized by Geoffrey Huntley |
| **MCP Server** | Model Context Protocol server - standardized way for AI tools to access external tools and data sources |
| **Bootstrap** | Initial command that generates TODO.md from PLAN.md by splitting goals into discrete tasks |
| **Fresh Context** | Starting each loop iteration with a new CLI process, avoiding context accumulation |
| **Completion Marker** | Specific text (`[x] ALL_TASKS_COMPLETE` or `<promise>COMPLETE</promise>`) that signals loop termination |
| **PRD** | Product Requirements Document - comprehensive specification of product/feature requirements |
| **Deepest-Thinking** | Systematic research protocol combining multiple tools for exhaustive investigation |

---

*Document generated for Jeeves Toolkit Expansion Project*
*Analysis Mode: Complete*
