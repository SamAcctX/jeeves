# Analysis: Jeeves Toolkit Expansion

## Original Request (Verbatim)

I want to expand my jeeves toolkit to have some handy extras that I can initialize into a given project (/workspace, pulled from a mapped volume mount).

1. The ralph loop as implemented here - mainly the loop and scaffolding:  https://github.com/JamesPaynter/efficient-ralph-loop
2. The ralph loop as described here:  https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md
3. The deep-thinking described here:  https://github.com/JeredBlu/custom-instructions/blob/main/Deepest-Thinking.md
4. The PRD methodology described here:  https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md

Additional notes:
* What you do should be compatible with both claude and opencode - no other AI CLI is necessary.  If you must pick one AI CLI, use opencode.
* Should additional tools (such as MCP servers or the like) be needed, document what they are, why they are needed, and how to install them
* A readme.md should be created documenting all of the above including setup, usage, recommendations, etc.

---

## Analysis

### Current State

The Jeeves toolkit consists of two files:
- `jeeves.ps1`: A PowerShell script for managing the OpenCode Docker container (build, start, stop, restart, rm, shell, logs, status, clean)
- `Dockerfile.jeeves`: A Dockerfile that builds a containerized environment with:
  - Ubuntu base
  - Python 3 with venv
  - Node.js LTS with npm and pnpm
  - OpenCode CLI built from source
  - Claude Code CLI installed via curl
  - Tmux for persistent shell sessions
  - UID/GID mapping for proper file permissions
  - Configuration directory mounting

The container runs OpenCode Web UI on port 3333 and maps the current working directory to `/workspace`.

### Requirements Breakdown

#### 1. Efficient Ralph Loop (JamesPaynter/efficient-ralph-loop)

**What it provides:**
- A Dockerized bash loop that runs AI agents (Claude Code or Codex) autonomously
- Fresh context windows per iteration (no context bloat)
- Git commits between iterations
- One task per iteration from a prioritized TODO list
- Explicit termination condition (`[x] ALL_TASKS_COMPLETE`)
- Sandbox isolation for safe autonomous runs

**Key files/components:**
- `loop-claude.sh`: Bash script that loops until completion
- `loop-codex.sh`: Alternative for OpenAI Codex
- `Dockerfile`: Simple container with Node 20 + @openai/codex + @anthropic-ai/claude-code
- `bootstrap.md`: Custom command for generating TODO.md and task specs from PLAN.md
- Project scaffold structure:
  - `PLAN.md`: Goals, constraints, technical approach (not a task list)
  - `TODO.md`: Prioritized task list with completion markers
  - `docs/tasks/active/NNN-task-name/`: Individual task folders with spec.md, scratchpad.md, lessons-learned.md
  - `INSTRUCTIONS.md`: Per-iteration prompt template

**Integration requirements:**
- Add Ralph loop scripts to Jeeves toolkit
- Provide project initialization command to scaffold the directory structure
- Ensure compatibility with OpenCode CLI (preferred over Claude Code)
- Preserve Docker isolation benefits already present in Jeeves

#### 2. Ralph Wiggum Guide (JeredBlu/guides)

**What it provides:**
- Two methods for running Ralph loops:
  - Claude Code Plugin: `/ralph` command with auto-complete
  - Bash Loop: Script-based approach with fresh context windows (recommended)
- Recommended configuration:
  - Sandboxing via `.claude/settings.json`
  - `plan.md` with JSON task format (category, description, steps, passes field)
  - `activity.md` for logging session progress
  - Max iterations for cost control
- Feedback loop setup:
  - Claude for Chrome (visual verification)
  - Playwright MCP (headless screenshots)

**Key differences from efficient-ralph-loop:**
- Uses JSON-based task format with boolean `passes` field
- Emphasizes visual feedback via Chrome/Playwright
- Includes activity logging in activity.md
- Promotes sandboxing for autonomous tasks

**Integration requirements:**
- Combine best practices from both Ralph implementations
- Support both JSON task format (JeredBlu) and markdown TODO list (JamesPaynter)
- Provide options for visual feedback (Playwright MCP)
- Maintain max iteration safety controls

#### 3. Deep Thinking Protocol (JeredBlu/custom-instructions)

**What it provides:**
- A structured three-phase research protocol:
  - Phase 1: Initial engagement (ask clarifying questions)
  - Phase 2: Research planning (present themes and execution plan)
  - Phase 3: Research cycles (landscape analysis, deep investigation, knowledge integration)
  - Phase 4: Final report (comprehensive academic narrative)
- Tool integration requirements:
  - Brave Search (broad context)
  - Tavily Search (deep dives)
  - Sequential Thinking MCP (5+ thoughts per analysis)
- Academic-style output with flowing narrative
- Minimum requirements: Two research cycles per theme

**Integration requirements:**
- Make custom instructions available within Jeeves container
- Document MCP server requirements
- Provide initialization option for deep thinking workflows
- Ensure tool availability (may require MCP server installation)

#### 4. PRD Creation Methodology (JeredBlu/custom-instructions)

**What it provides:**
- Custom instructions for guiding users through PRD creation
- Question framework covering:
  - Core features, target audience, platform
  - UI/UX concepts, data storage, authentication
  - Integrations, scalability, challenges, costs
- Tool integration:
  - Sequential Thinking for breaking down complex problems
  - Brave Search for researching technologies
  - Tavily Research for in-depth technical topics
  - Filesystem for saving PRD files
- PRD structure optimized for handoff to developers (human or AI)
  - Clear acceptance criteria
  - Technical considerations
  - Implementation-relevant details
  - Consistent terminology

**Integration requirements:**
- Make PRD Creator instructions available in Jeeves
- Provide project initialization command for PRD-driven workflows
- Document MCP server requirements for PRD creation
- Support saving PRD files to project directory

### Additional Tools (MCP Servers)

Based on the referenced guides, the following MCP servers may be required:

| MCP Server | Purpose | Why Needed | Installation |
|------------|---------|------------|--------------|
| Sequential Thinking | Deep analysis | Required for Deep Thinking protocol and PRD Creator | https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking |
| Brave Search | Web search | Required for researching technologies and current best practices | https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search |
| Tavily Search | Deep research | Required for Deep Thinking protocol's deep investigation phase | https://github.com/tavily-ai/tavily-mcp |
| Playwright | Visual feedback | Optional but recommended for Ralph loop verification (screenshots) | https://github.com/modelcontextprotocol/servers/tree/main/src/playwright |
| Filesystem | File operations | Optional for saving PRD files | https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem |

**Note:** These MCP servers integrate with Claude Desktop, not directly with OpenCode CLI. Since Jeeves uses OpenCode as the primary CLI, we need to determine how to handle these tools:
- Option 1: Install Claude Desktop alongside OpenCode (user preference)
- Option 2: Use OpenCode's built-in tools (websearch, codesearch, task agent)
- Option 3: Create MCP-compatible bridges for OpenCode (complex, not recommended)

**Recommendation:** Document MCP servers as optional enhancements for users who want to use Claude Desktop for the PRD creation and deep thinking phases, while using OpenCode for the Ralph loop execution.

---

## Proposed Solution Structure

### File Structure Additions

```
workspace/
├── jeeves.ps1                    (existing)
├── Dockerfile.jeeves              (existing)
├── toolkit/                       (NEW - initialization scripts)
│   ├── ralph-loop/                (NEW)
│   │   ├── loop.sh                (modified from loop-claude.sh)
│   │   ├── bootstrap.md            (bootstrap command template)
│   │   ├── PLAN.md.template        (plan template)
│   │   ├── TODO.md.template        (todo template)
│   │   ├── INSTRUCTIONS.md.template (instructions template)
│   │   └── README.md              (ralph loop documentation)
│   ├── prd-creator/               (NEW)
│   │   ├── custom-instructions.md  (PRD Creator instructions)
│   │   └── README.md              (PRD creator documentation)
│   └── deep-thinking/             (NEW)
│       ├── custom-instructions.md  (Deep Thinking protocol)
│       └── README.md              (deep thinking documentation)
├── scripts/                       (NEW - utility scripts)
│   ├── init-prd.sh               (NEW - initialize PRD workflow)
│   ├── init-ralph.sh             (NEW - initialize Ralph loop)
│   └── init-deep-thinking.sh     (NEW - initialize deep thinking)
└── README.md                      (NEW - comprehensive documentation)
```

### Component Specifications

#### 1. Ralph Loop Component

**Features:**
- Modified `loop.sh` script that uses OpenCode CLI instead of Claude Code
- Project initialization command (`init-ralph.sh`) that scaffolds:
  - `PLAN.md` (from template)
  - `docs/tasks/active/` directory structure
  - `TODO.md` (empty, waiting for bootstrap)
  - `INSTRUCTIONS.md` (from template)
  - Bootstrap command template (`.claude/commands/bootstrap.md` or equivalent for OpenCode)
- Support for both JSON task format (JeredBlu) and markdown TODO (JamesPaynter)
- Git commit after each task completion
- Max iteration limit for cost control
- Screenshot directory for visual verification (Playwright integration optional)

**OpenCode CLI considerations:**
- OpenCode has similar capabilities to Claude Code
- OpenCode may not have an exact equivalent to Claude Code's custom commands
- May need to use OpenCode's AGENTS.md or similar for the bootstrap functionality
- OpenCode has websearch, codesearch, and task agent tools built-in

**Integration with Jeeves:**
- Add new command to `jeeves.ps1`: `jeeves init ralph <project-path>`
- Run initialization script from within the container
- Ensure `/workspace` is properly mounted
- Support both API key auth and subscription auth (if available for OpenCode)

#### 2. PRD Creator Component

**Features:**
- Custom instructions file (`custom-instructions.md`) with the complete PRD Creator protocol
- Project initialization command (`init-prd.sh`) that:
  - Copies custom instructions to a standard location
  - Creates initial `PRD.md` (empty or with template)
  - Documents MCP server requirements
  - Provides setup instructions
- Documentation explaining how to use with Claude Desktop (for MCP support)

**Integration with Jeeves:**
- Add new command to `jeeves.ps1`: `jeeves init prd <project-path>`
- Since PRD Creator relies on MCP servers, note that it's designed for Claude Desktop
- Recommend using Claude Desktop for PRD phase, then switching to OpenCode for execution
- Alternatively, map Claude Desktop config volume into container

#### 3. Deep Thinking Component

**Features:**
- Custom instructions file (`custom-instructions.md`) with the complete Deep Thinking protocol
- Project initialization command (`init-deep-thinking.sh`) that:
  - Copies custom instructions
  - Documents tool requirements
  - Provides usage examples
- Integration with existing OpenCode tools (websearch, codesearch, task agent)

**Integration with Jeeves:**
- Add new command to `jeeves.ps1`: `jeeves init deep-thinking <project-path>`
- Map OpenCode tools to protocol requirements:
  - `websearch` → Brave Search equivalent
  - `codesearch` → Technical research equivalent
  - `task` agent → Sequential Thinking equivalent (with explicit step-by-step analysis)

#### 4. Documentation (README.md)

**Comprehensive documentation including:**
- Overview of Jeeves Toolkit expansion
- Setup and installation instructions
- MCP server documentation (what, why, how to install)
- Usage guides for each component:
  - Ralph Loop (setup, initialization, running, troubleshooting)
  - PRD Creator (setup, usage, best practices)
  - Deep Thinking (setup, usage, examples)
- Integration between components (e.g., use PRD Creator → convert to PLAN.md → run Ralph Loop)
- Recommendations and best practices
- Troubleshooting section

---

## Final Requirements

### R1. Ralph Loop Implementation

**R1.1 - Loop Script**
- Create `toolkit/ralph-loop/loop.sh` that:
  - Runs OpenCode CLI in a bash loop
  - Mounts project directory to `/workspace`
  - Reads instructions from `INSTRUCTIONS.md`
  - Checks `TODO.md` for completion pattern
  - Supports max iteration limit (default 20, configurable via environment variable)
  - Supports sleep delay between iterations (default 2 seconds, configurable)
  - Outputs to terminal and optionally to log files
  - Exits when `[x] ALL_TASKS_COMPLETE` is found in TODO.md
  - Uses OpenCode CLI with appropriate flags for autonomous execution

**Acceptance Criteria:**
- Script runs OpenCode CLI successfully in containerized environment
- Loop stops when completion pattern is detected
- Max iterations limit is enforced
- Script handles errors gracefully (continues to next iteration or exits as appropriate)
- Logging functionality works in all modes (stream, quiet, log, log_only)

**R1.2 - Project Initialization**
- Create `scripts/init-ralph.sh` that:
  - Prompts user for project path (default: current directory)
  - Creates directory structure:
    - `docs/tasks/active/`
    - `docs/tasks/completed/` (optional, for completed tasks)
    - `screenshots/` (for visual verification)
  - Copies template files:
    - `PLAN.md.template` → `PLAN.md`
    - `TODO.md.template` → `TODO.md`
    - `INSTRUCTIONS.md.template` → `INSTRUCTIONS.md`
  - Creates OpenCode-compatible bootstrap configuration:
    - `.opencode/commands/bootstrap.md` (if OpenCode supports this)
    - OR `AGENTS.md` entry for bootstrap functionality
  - Initializes git repository if not already present
  - Sets up .gitignore for `docs/tasks/`, `screenshots/`, `.cache/`
  - Prints next steps for user (edit PLAN.md, run bootstrap command, start loop)

**Acceptance Criteria:**
- Directory structure is created correctly
- Template files are copied and editable
- Bootstrap functionality is available to OpenCode
- Git repository is initialized with proper .gitignore
- User receives clear instructions for next steps
- Initialization can be run multiple times safely (idempotent or warns about existing files)

**R1.3 - Template Files**
- `PLAN.md.template`: Template with sections for:
  - Overview and objectives
  - Constraints and requirements
  - Technical approach
  - Expected outputs
  - Reference to PRD (if exists)
- `TODO.md.template`: Template with:
  - Task list format (markdown checklist)
  - Example tasks
  - Completion marker at bottom: `- [x] ALL_TASKS_COMPLETE`
  - Task linking format to task spec files
- `INSTRUCTIONS.md.template`: Template with:
  - Reference to TODO.md
  - Instructions for single task execution
  - Verification requirements (run tests, build, etc.)
  - Commit requirements
  - Stop after one task
- Bootstrap template: OpenCode command/skill that:
  - Reads PLAN.md
  - Generates prioritized TODO.md
  - Creates task spec files in `docs/tasks/active/`
  - Uses small, sequential, verifiable tasks
  - Provides task metadata (effort, tier, blast radius)

**Acceptance Criteria:**
- Templates are complete and self-documenting
- Templates use consistent formatting and structure
- Bootstrap template works with OpenCode's command/agent system
- Task spec files include all required sections (status, summary, files, blast radius, implementation checklist, verification, dependencies)

**R1.4 - PowerShell Integration**
- Add new commands to `jeeves.ps1`:
  - `jeeves init ralph [path]`: Initialize Ralph loop structure
  - `jeeves ralph [iterations]`: Run Ralph loop (optional, can use script directly)
- Update `Show-Help` to document new commands
- Ensure commands work both inside and outside container
- Mount `toolkit/` directory into container for access

**Acceptance Criteria:**
- Commands are accessible from `jeeves.ps1`
- Help text is accurate and complete
- Commands work whether called from host or inside container
- Toolkit files are available in container

### R2. PRD Creator Implementation

**R2.1 - Custom Instructions File**
- Create `toolkit/prd-creator/custom-instructions.md` containing:
  - Complete PRD Creator v2.2 protocol from JeredBlu
  - Role and identity definition
  - Conversation approach guidelines
  - Question framework (10 aspects to cover)
  - Effective questioning patterns
  - Technology discussion guidelines
  - PRD creation process with all required sections
  - Developer handoff considerations
  - Knowledge base utilization
  - Tool integration (Sequential Thinking, Brave Search, Tavily, Filesystem)
  - Feedback and iteration process
  - Error handling guidelines

**Acceptance Criteria:**
- File contains complete protocol from source
- File is properly formatted (YAML/Markdown)
- Content is copy-paste ready for Claude Desktop

**R2.2 - Project Initialization**
- Create `scripts/init-prd.sh` that:
  - Prompts user for project path (default: current directory)
  - Copies `custom-instructions.md` to project root
  - Creates `PRD.md` with template structure:
    - Project Overview
    - Target Audience
    - Core Features (empty, to be filled)
    - Technical Stack
    - Data Model
    - UI Design Principles
    - Security Considerations
    - Development Phases
    - Challenges and Solutions
    - Future Expansion
  - Creates `docs/` directory for project documentation
  - Documents MCP server requirements in `MCP_REQUIREMENTS.md`:
    - Lists required MCP servers with purpose
    - Provides installation instructions for each
    - Includes video tutorial links
  - Prints setup instructions and usage guide

**Acceptance Criteria:**
- Custom instructions are copied to project
- PRD.md template is created with all required sections
- MCP requirements are documented with installation instructions
- User receives clear guidance on next steps
- Initialization is idempotent (can run multiple times)

**R2.3 - PowerShell Integration**
- Add new command to `jeeves.ps1`:
  - `jeeves init prd [path]`: Initialize PRD Creator workflow
- Update `Show-Help` to document new command
- Document that PRD Creator is designed for Claude Desktop with MCP support
- Recommend workflow: Use Claude Desktop for PRD creation, then switch to OpenCode for implementation

**Acceptance Criteria:**
- Command is accessible from `jeeves.ps1`
- Help text includes MCP server requirements
- Documentation clarifies the two-CLI workflow (Claude Desktop for PRD, OpenCode for execution)

### R3. Deep Thinking Implementation

**R3.1 - Custom Instructions File**
- Create `toolkit/deep-thinking/custom-instructions.md` containing:
  - Complete Deep Thinking protocol from JeredBlu
  - Three-stop structure (initial engagement, research planning, research cycles, final report)
  - Tool configuration (Brave Search, Tavily, Sequential Thinking)
  - Context maintenance requirements
  - Research cycle requirements (landscape analysis, deep investigation, knowledge integration)
  - Verification requirements
  - Knowledge synthesis requirements
  - Final report structure with academic writing requirements
  - Writing style guidelines
  - Tool usage requirements

**Acceptance Criteria:**
- File contains complete protocol from source
- File is properly formatted (YAML/Markdown)
- Content is copy-paste ready for Claude Desktop

**R3.2 - OpenCode Tool Mapping**
- Create `toolkit/deep-thinking/OPENCODE_MAPPING.md` documenting:
  - How to use OpenCode tools for Deep Thinking protocol:
    - `websearch` tool → Brave Search equivalent (use websearch with depth settings)
    - `codesearch` tool → Deep technical research equivalent
    - Task agent with explicit "think step-by-step" prompts → Sequential Thinking equivalent
  - Example prompts and workflows for using OpenCode tools
  - Limitations and workarounds where OpenCode differs from MCP servers

**Acceptance Criteria:**
- Mapping is clear and actionable
- Examples demonstrate proper usage
- Limitations are honestly documented
- Workarounds are provided where applicable

**R3.3 - Project Initialization**
- Create `scripts/init-deep-thinking.sh` that:
  - Prompts user for project path (default: current directory)
  - Copies `custom-instructions.md` to project root
  - Copies `OPENCODE_MAPPING.md` to project root
  - Creates `research/` directory for research outputs
  - Documents tool setup requirements in `TOOL_REQUIREMENTS.md`:
    - Required tools (OpenCode built-in vs MCP servers)
    - Installation instructions for optional MCP servers
    - Configuration examples
  - Prints usage examples and best practices

**Acceptance Criteria:**
- Custom instructions are copied to project
- OpenCode mapping is provided for users without MCP setup
- Tool requirements are documented
- Research directory structure is created
- User receives clear usage guidance

**R3.4 - PowerShell Integration**
- Add new command to `jeeves.ps1`:
  - `jeeves init deep-thinking [path]`: Initialize Deep Thinking workflow
- Update `Show-Help` to document new command
- Document that Deep Thinking can use either Claude Desktop with MCP or OpenCode with built-in tools

**Acceptance Criteria:**
- Command is accessible from `jeeves.ps1`
- Help text explains both workflow options (Claude Desktop + MCP vs OpenCode only)
- Users understand which tools they need to install

### R4. Documentation (README.md)

**R4.1 - Comprehensive README**
- Create `README.md` in workspace root with:
  - Title and brief overview of Jeeves Toolkit
  - Table of contents
  - Prerequisites section:
    - Docker
    - OpenCode subscription or API key
    - (Optional) Claude Desktop for MCP-based workflows
    - (Optional) MCP servers for PRD Creator and Deep Thinking
  - Quick start guide:
    - Build Jeeves container
    - Start container
    - Initialize project with desired workflow
  - Detailed sections for each component:
    - Ralph Loop
      - What it is and when to use it
      - Setup instructions
      - Project initialization (PLAN.md, TODO.md, etc.)
      - Running the loop
      - Monitoring progress
      - Troubleshooting
    - PRD Creator
      - What it is and when to use it
      - Setup instructions
      - Using with Claude Desktop
      - PRD structure and sections
      - Best practices
    - Deep Thinking
      - What it is and when to use it
      - Setup instructions
      - Workflow options (Claude Desktop vs OpenCode)
      - Research process overview
      - Example usage
  - Integration guide:
    - Complete workflow: PRD → Plan → Ralph Loop
    - How to convert PRD to PLAN.md
    - When to use each component
  - MCP Servers section:
    - What are MCP servers
    - Which are required/recommended
    - Installation instructions for each:
      - Sequential Thinking
      - Brave Search
      - Tavily Search
      - Playwright (for Ralph loop visual verification)
      - Filesystem (for saving PRD files)
    - Configuration examples
  - Docker configuration:
    - Volume mounts explained
    - Environment variables
    - UID/GID mapping
  - Troubleshooting:
    - Common issues and solutions
    - FAQ
  - Links to original resources:
    - Efficient Ralph Loop repository
    - Ralph Wiggum Guide
    - Deep Thinking protocol
    - PRD Creator documentation
  - License and acknowledgments

**Acceptance Criteria:**
- README is comprehensive and well-organized
- All components are documented thoroughly
- Installation instructions are clear and accurate
- MCP server documentation includes all required tools
- Troubleshooting covers common scenarios
- Links to original resources are included

**R4.2 - Component-Specific READMEs**
- Create `toolkit/ralph-loop/README.md` with:
  - Ralph loop overview and benefits
  - Project structure explanation
  - Template file documentation
  - Running the loop script
  - Bootstrap process
  - Git workflow (commits per task)
  - Best practices and tips

- Create `toolkit/prd-creator/README.md` with:
  - PRD Creator overview
  - When to use PRD Creator
  - Custom instructions usage
  - PRD structure explanation
  - Integration with development workflow

- Create `toolkit/deep-thinking/README.md` with:
  - Deep Thinking protocol overview
  - Three-phase research process
  - Tool requirements
  - Using with Claude Desktop vs OpenCode
  - Example workflows

**Acceptance Criteria:**
- Each component README is standalone and complete
- READMEs complement the main README
- Examples are provided where helpful
- Best practices are included

### R5. Additional Tools Documentation

**R5.1 - MCP Servers Guide**
- Create comprehensive documentation in README.md's MCP section covering:
  - For each MCP server:
    - What it does
    - Why it's needed (which component uses it)
    - Installation instructions (step-by-step)
    - Configuration examples
    - Links to official documentation
    - Video tutorial links (from JeredBlu)
  - Optional vs required classification:
    - Required for PRD Creator: Sequential Thinking, Brave Search, Tavily
    - Optional for Ralph Loop: Playwright
    - Optional for general use: Filesystem
  - Alternative approaches:
    - Using OpenCode built-in tools instead of MCP
    - When to use each approach
  - Troubleshooting common MCP issues

**Acceptance Criteria:**
- All MCP servers from referenced guides are documented
- Installation instructions are accurate and complete
- Clear distinction between required and optional
- Alternatives are provided for users without MCP setup

### R6. Cross-Component Compatibility

**R6.1 - OpenCode CLI Compatibility**
- Ensure all components work with OpenCode CLI (preferred) as well as Claude Code:
  - Ralph Loop uses OpenCode CLI with appropriate flags
  - Bootstrap functionality available via OpenCode's command/agent system
  - Deep Thinking protocol maps to OpenCode tools (documented)
  - PRD Creator works with Claude Desktop (documented)

**Acceptance Criteria:**
- Ralph loop script successfully invokes OpenCode CLI
- Bootstrap command works with OpenCode
- OpenCode tool mapping is documented
- Users understand when to use OpenCode vs Claude Desktop

**R6.2 - Container Integration**
- Ensure all components work within Jeeves Docker container:
  - Toolkit directory is mounted into container
  - Initialization scripts work from within container
  - Loop script runs successfully in container
  - OpenCode CLI is properly configured in container
  - `/workspace` is properly mounted

**Acceptance Criteria:**
- Components are accessible from within container
- Scripts work whether run from host or container
- File paths and permissions are correct
- No additional container build is required (or minimal changes to existing Dockerfile.jeeves)

**R6.3 - Workflow Integration**
- Document how components work together:
  - PRD Creator → Convert PRD.md to PLAN.md → Run Ralph Loop
  - Deep Thinking → Research → Document findings → Inform PRD or PLAN
  - When to combine workflows vs use individually

**Acceptance Criteria:**
- Integration workflow is clearly documented
- Example end-to-end scenarios are provided
- Benefits of integrated approach are explained

---

## Non-Functional Requirements

**NFR1 - Compatibility**
- Must be compatible with both OpenCode CLI (preferred) and Claude Code
- Must work with both API key auth and subscription auth (where applicable)
- Must work on Linux, macOS, and Windows (via Docker and PowerShell)

**NFR2 - Safety**
- Ralph loop must enforce max iterations to prevent runaway costs
- All autonomous operations should be sandboxed (Docker provides isolation)
- Documentation must warn about autonomous execution risks

**NFR3 - Usability**
- Scripts should have clear help messages
- Error messages should be actionable
- Templates should be well-commented and self-documenting
- Documentation should be comprehensive and beginner-friendly

**NFR4 - Maintainability**
- Code should follow existing PowerShell conventions in `jeeves.ps1`
- Templates should use consistent formatting
- Documentation should be kept in sync with implementation
- Scripts should be idempotent where possible

**NFR5 - Performance**
- Initialization scripts should complete in under 5 seconds
- Loop script should have minimal overhead between iterations
- Container should not require rebuild for these additions

---

## Implementation Phases

### Phase 1: Core Structure (Foundation)
- Create `toolkit/` directory structure
- Add initialization script framework
- Update `jeeves.ps1` with new command stubs
- Create template files for Ralph loop
- Set up basic README structure

### Phase 2: Ralph Loop Implementation
- Implement `loop.sh` with OpenCode CLI integration
- Create `init-ralph.sh` initialization script
- Implement bootstrap command for OpenCode
- Test Ralph loop end-to-end
- Document Ralph loop component

### Phase 3: PRD Creator Implementation
- Copy and format PRD Creator custom instructions
- Implement `init-prd.sh` initialization script
- Create PRD.md template
- Document MCP server requirements
- Document PRD Creator component

### Phase 4: Deep Thinking Implementation
- Copy and format Deep Thinking custom instructions
- Create OpenCode tool mapping document
- Implement `init-deep-thinking.sh` initialization script
- Document Deep Thinking component
- Create usage examples

### Phase 5: Documentation and Integration
- Complete main README.md
- Complete component-specific READMEs
- Create MCP servers guide
- Document integrated workflows
- Test all commands from host and container
- Final review and polish

---

## Open Questions

1. **OpenCode Custom Commands**: Does OpenCode have an equivalent to Claude Code's custom commands (`/.claude/commands/`)? If not, what's the best alternative for the bootstrap functionality?
   - Potential options: OpenCode AGENTS.md, OpenCode skills system, or custom slash commands if available

2. **MCP Server Integration**: Should MCP servers be installed in the Jeeves container or on the host system?
   - Recommendation: MCP servers are typically used with Claude Desktop, so they should be installed on the host system. Document this clearly.

3. **Task Format**: Should we support both JSON task format (JeredBlu) and markdown TODO format (JamesPaynter)?
   - Recommendation: Support markdown TODO format by default (simpler, works with grep), provide JSON format as an option via template

4. **Visual Feedback**: Should Playwright MCP be required or optional for Ralph loop?
   - Recommendation: Optional. Provide clear instructions for users who want visual verification via screenshots.

5. **Git Repository**: Should initialization scripts always initialize git, or only if not already present?
   - Recommendation: Check for existing git repo, initialize only if absent.

---

## Success Criteria

The project will be considered successful when:

1. All three components (Ralph Loop, PRD Creator, Deep Thinking) can be initialized into a project via `jeeves init` commands
2. Ralph loop can run autonomously with OpenCode CLI, completing tasks from a TODO list
3. PRD Creator custom instructions can be used with Claude Desktop to generate comprehensive PRDs
4. Deep Thinking protocol can be used with either Claude Desktop + MCP or OpenCode with built-in tools
5. Comprehensive documentation covers all components, MCP servers, and integration workflows
6. All functionality works within the Jeeves Docker container
7. Scripts follow existing PowerShell conventions and integrate cleanly with `jeeves.ps1`
8. User can complete a full workflow: Create PRD → Convert to PLAN.md → Run Ralph Loop to implementation

---

## Constraints and Assumptions

**Constraints:**
- Must use OpenCode CLI as primary AI CLI (per user requirement)
- Cannot add new AI CLIs beyond OpenCode and Claude
- Docker container should require minimal changes (if any)
- Scripts must be idempotent or handle existing files gracefully

**Assumptions:**
- User has Docker installed and running
- User has OpenCode subscription or API key
- User may have Claude Desktop for MCP-based workflows (optional)
- User is comfortable with command line and basic terminal usage
- User understands the risks of autonomous AI execution

---

## References

1. Efficient Ralph Loop: https://github.com/JamesPaynter/efficient-ralph-loop
2. Ralph Wiggum Guide: https://github.com/JeredBlu/guides/blob/main/Ralph_Wiggum_Guide.md
3. Deep Thinking Protocol: https://github.com/JeredBlu/custom-instructions/blob/main/Deepest-Thinking.md
4. PRD Creator v2.2: https://github.com/JeredBlu/custom-instructions/blob/main/prd-creator-3-25.md
5. JeredBlu YouTube: https://youtube.com/@JeredBlu
6. OpenCode: https://github.com/anomalyco/opencode
7. MCP Servers: https://github.com/modelcontextprotocol/servers

---

*Document created: 2026-01-21*
*Analysis phase complete. Ready to proceed with implementation.*
