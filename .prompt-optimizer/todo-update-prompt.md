# Prompt: Update TODO Tracking Across All Ralph Agent Templates

## Mission

Revise the TODO tracking instructions in all Ralph agent templates to mandate use of native task/checklist/TODO tools when available, with fallback to session context (internal memory) tracking only when such tools are not available. Do NOT change the structure or content of the existing TODO guidance - only revise the surrounding instructions to enforce tool usage.

## Critical Rules

1. **NO PARALLEL EXECUTION**: Each agent-pair update MUST be performed as a dedicated, isolated task using subtasks/workers/new_task/subagents
2. **SEQUENTIAL ORDER**: Work agent-pairs IN ORDER, ONE AT A TIME - the next pair cannot begin until the previous one is fully complete
3. **Agent-pair = single task**: Each agent's -opencode.md and -claude.md files are handled together as ONE task
4. **Identical prompts**: The prompt portion (everything after frontmatter) must be IDENTICAL between -opencode and -claude versions
5. **Preserve frontmatter**: Only modify content AFTER the frontmatter (---) section
6. **Keep inline**: All TODO instructions must remain inline (not moved to shared files)
7. **Adaptive tool discovery**: Instructions must require discovering and using ANY suitable task/checklist/TODO tool before falling back to session context

## Agent-Pair Update Order

Update in this EXACT sequence, one pair at a time, NO EXCEPTIONS:

### Task 1: Developer Agent Pair (START HERE - most finicky)
- Files: `developer-opencode.md` + `developer-claude.md`
- Current section: "TODO LIST TRACKING" (lines ~87-176)
- Current issue: Only describes "working memory", no tool discovery
- **Special note**: This is the FIRST agent. Create reference guidance for subsequent agents based on your analysis.

### Task 2: Tester Agent Pair
- Files: `tester-opencode.md` + `tester-claude.md`
- Current section: "TODO LIST MANAGEMENT" (lines ~570-652)
- Current issue: Only describes conceptual tracking, no tool discovery

### Task 3: UI-Designer Agent Pair
- Files: `ui-designer-opencode.md` + `ui-designer-claude.md`
- Current section: "TODO LIST TRACKING" (lines ~230-350)
- Current issue: Only describes "working memory", no tool discovery

### Task 4: Writer Agent Pair
- Files: `writer-opencode.md` + `writer-claude.md`
- Current section: "Initialize TODO List" (lines ~428-476)
- Current issue: Only describes conceptual TODO, no tool discovery

### Task 5: Manager Agent Pair
- Files: `manager-opencode.md` + `manager-claude.md`
- Current section: "TODO LIST MANAGEMENT" (lines ~775-883)
- Current issue: Only describes "working memory", no tool discovery

### Task 6: Architect Agent Pair
- Files: `architect-opencode.md` + `architect-claude.md`
- Current section: "TODO TRACKING GUIDANCE" (lines ~489-561)
- Current issue: Hardcodes `todoread`/`todowrite`, needs adaptive tool discovery pattern

### Task 7: Researcher Agent Pair
- Files: `researcher-opencode.md` + `researcher-claude.md`
- Current section: "TODO LIST TRACKING" (lines ~306-395)
- Current issue: Hardcodes `todoread`/`todowrite`, needs adaptive tool discovery pattern

## What to Preserve vs What to Change

### PRESERVE (DO NOT MODIFY):
- The structure and organization of the existing TODO section
- The specific TODO items, phases, or tracking guidance the agent currently uses
- Examples of TODO structures or workflows
- Any agent-specific tracking patterns (TDD phases, test items, etc.)

### CHANGE (MUST BE REVISED):
- Instructions that say "create a TODO list in your working memory" without checking for tools first
- Any language that treats session context as the primary/only tracking method
- Hardcoded tool names (e.g., `todoread`/`todowrite`) without discovery step
- Missing adaptive tool discovery requirement at task start
- Missing fallback instructions when no suitable tools are available

## Required Instruction Changes

For each agent's TODO section, ensure these instruction elements are present:

### 1. Adaptive Tool Discovery (MANDATORY - at task start)
Add instructions requiring the LLM to:
- Check available tools/APIs for ANY task management, checklist, or TODO capability
- Look for tools matching patterns: todo, task, checklist, plan, tracker
- Common implementations include:
  - **Tasks API** (Claude Code's newer recommended approach)
  - **TodoRead/TodoWrite** (Claude Code's legacy TODO tool)
  - **todoread/todowrite** (OpenCode style)
  - **Any checklist-style tool** that supports ordered elements
- **Functional equivalence**: Any tool that allows creating, reading, updating, and ordering checklist items qualifies
- If suitable tool found: Use it as the PRIMARY tracking method
- If no suitable tool found: Fall back to session context (internal memory) tracking

### 2. Tool-First Mandate
Change instructions from:
- "Create a TODO list in your working memory" (implies this is the only way)

To:
- "Discover and use any available task/checklist/TODO tool; only fall back to session context tracking if no suitable tool exists"

### 3. Fallback Clarity
When no suitable tools are available:
- Use markdown checklists in session context (not "working memory" - be explicit)
- Structure remains the same as current guidance
- Update items in real-time: pending → in_progress → completed

### 4. Real-Time Update Requirements
Ensure instructions require:
- Updating task/TODO status via tools when tools are used
- Updating markdown checklists in session context when tools are not used
- Same real-time tracking behavior regardless of method

## Execution Workflow for Each Agent-Pair

### Step 1: Create Dedicated Subtask for Agent-Pair
Spawn a new task/worker/subagent with:
- Single agent-pair focus (e.g., "Update Developer agent TODO tracking")
- Access to both -opencode.md and -claude.md files
- Clear scope: revise TODO instructions per this specification
- Blocker dependency: previous agent-pair must be complete

### Step 2: Analyze -opencode.md File
In the subtask:
1. Read the `-opencode.md` file
2. Locate the existing TODO section
3. Analyze current TODO guidance structure and content
4. Identify what to preserve vs what instruction changes are needed
5. Revise the instructions surrounding the TODO content (not the content itself)

### Step 3: Apply Revisions to -opencode.md
Make surgical edits to:
- Add adaptive tool discovery requirement at task start
- Change "working memory" references to "session context" or clarify as fallback
- Add tool-first mandate language
- Ensure fallback instructions are clear when no suitable tools available
- Preserve all existing TODO structure, items, and examples

### Step 4: Copy to -claude.md Using Bash/Python
Use token-efficient file operations:
```bash
# Extract frontmatter from -claude.md (everything up to second ---)
head -n $(grep -n '^---$' FILE-claude.md | head -2 | tail -1 | cut -d: -f1) FILE-claude.md > /tmp/claude-frontmatter.md

# Extract everything after frontmatter from -opencode.md
tail -n +$(($(grep -n '^---$' FILE-opencode.md | head -2 | tail -1 | cut -d: -f1) + 1)) FILE-opencode.md > /tmp/opencode-content.md

# Combine: frontmatter + content
cat /tmp/claude-frontmatter.md /tmp/opencode-content.md > FILE-claude.md
```

Or use Python for more robust handling:
```python
import re

# Read frontmatter from -claude.md
with open('FILE-claude.md', 'r') as f:
    content = f.read()
match = re.match(r'(---\n.*?\n---\n)', content, re.DOTALL)
frontmatter = match.group(1) if match else ''

# Read content after frontmatter from -opencode.md
with open('FILE-opencode.md', 'r') as f:
    content = f.read()
match = re.match(r'---\n.*?\n---\n(.*)', content, re.DOTALL)
prompt_content = match.group(1) if match else content

# Write combined
with open('FILE-claude.md', 'w') as f:
    f.write(frontmatter + prompt_content)
```

### Step 5: Verify Pair is Complete
Use bash commands to verify:
```bash
# Verify files match after frontmatter
diff <(tail -n +$(($(grep -n '^---$' FILE-opencode.md | head -2 | tail -1 | cut -d: -f1) + 1)) FILE-opencode.md) \
     <(tail -n +$(($(grep -n '^---$' FILE-claude.md | head -2 | tail -1 | cut -d: -f1) + 1)) FILE-claude.md) && echo "MATCH" || echo "MISMATCH"
```

Confirm:
- [ ] -opencode.md revised with adaptive tool-discovery instructions
- [ ] -claude.md has identical prompt content after frontmatter
- [ ] Frontmatter preserved in both files (may differ between platforms)
- [ ] TODO section requires tool discovery before fallback
- [ ] No changes to existing TODO structure/items/examples
- [ ] Subtask reports completion with summary of changes

### Step 6: Report Task Completion
Subtask must report:
1. Files modified
2. Specific instruction changes made (tool discovery, fallback clarity, etc.)
3. What was preserved from original TODO guidance
4. Any reference guidance created for future agents (if Developer pair)
5. Confirmation that verification passed

## First Agent (Developer) Special Responsibility

Since the Developer agent is first:
- Analyze its current TODO guidance thoroughly
- Determine the optimal way to add adaptive tool-discovery instructions
- Create brief reference guidance documenting:
  - The approach taken for instruction revision
  - Key patterns to apply to other agents
  - Any common pitfalls to avoid
- Include this reference in your completion report
- Subsequent agent tasks will use this as guidance

## Using TODO Tools for This Prompt

**You are encouraged to use available task/checklist/TODO tools to track progress through the 7 agent-pairs.**

At minimum, track:
- [ ] Task 1: Developer Agent Pair
- [ ] Task 2: Tester Agent Pair
- [ ] Task 3: UI-Designer Agent Pair
- [ ] Task 4: Writer Agent Pair
- [ ] Task 5: Manager Agent Pair
- [ ] Task 6: Architect Agent Pair
- [ ] Task 7: Researcher Agent Pair
- [ ] Final verification and delivery

Update your task/TODO list as each agent-pair completes.

## Completion Checklist Per Agent-Pair

After each subtask completes:
- [ ] Subtask spawned and executed in isolation
- [ ] -opencode.md revised with tool-first mandate
- [ ] -claude.md updated to match using bash/Python (not manual copy)
- [ ] Verification passed (content matches after frontmatter)
- [ ] Frontmatter preserved in both files
- [ ] Original TODO structure/items preserved
- [ ] Adaptive tool discovery requirement added (not hardcoded to specific tool names)
- [ ] Functional equivalence criteria documented
- [ ] Fallback to session context clearly specified
- [ ] Completion report submitted with change summary

## Final Delivery

When all 7 agent-pairs are complete:
1. List all modified files
2. Confirm all -opencode and -claude version pairs have identical prompt content
3. Summarize the instruction changes applied across all agents
4. Note any agent-specific variations in approach
5. Include reference guidance from Developer pair for future maintenance
6. Report ready for testing

## Blocking Rule

**CRITICAL**: Do NOT proceed to Task N+1 until Task N is fully complete and verified. Each task MUST be spawned as a dedicated subtask/worker with no shared context with other agent-pair tasks.
