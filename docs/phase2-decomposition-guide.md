# Phase 2 Decomposition Guide

This guide explains how to use the Decomposer agent to transform your Product Requirements Document (PRD) into an actionable task list. Phase 2 is where your PRD transforms into atomic, well-defined tasks that the Ralph Loop can execute autonomously.

For command usage, see [commands.md](commands.md). For configuration details, see [configuration.md](configuration.md). For troubleshooting, see [troubleshooting.md](troubleshooting.md).

---

## Three-Phase Recap

Ralph Loop uses a three-phase workflow:

1. **Phase 1**: Create PRD (manual user work)
2. **Phase 2**: Decompose PRD into tasks (user invokes Decomposer agent)
3. **Phase 3**: Execute tasks autonomously (ralph-loop.sh)

Phase 2 sits between requirements definition and autonomous execution. It converts high-level requirements into specific, actionable tasks that the Ralph Loop can execute.

## Prerequisites

### Before Starting Phase 2

Ensure these prerequisites are met:

- [ ] Phase 1 complete: PRD written and saved to `.ralph/specs/`
- [ ] Ralph initialized: `ralph-init.sh` has been run
- [ ] Git initialized and initial commit made
- [ ] PRD is clear, specific, and testable

### PRD Quality Checklist

Before decomposition, verify your PRD meets these quality standards:

- Clear overview and goals
- Specific features listed
- Technical requirements specified
- Acceptance criteria defined
- Edge cases considered

A well-written PRD produces better task decompositions. If your PRD is vague, the resulting tasks will be vague.

## Starting Phase 2 Decomposition

### Step 1: Prepare Environment

Navigate to your project directory and verify the Ralph structure:

```bash
cd /proj/my-project

ls -la .ralph/

ls .ralph/specs/
```

The `.ralph/` directory should contain:

- `config/` - Agent and dependency configurations
- `specs/` - Your PRD files
- `tasks/` - Where task folders will be created

### Step 2: Invoke the Decomposer Agent

The Decomposer agent reads your PRD and generates the task structure. Invoke it with your PRD content:

```bash
cat .ralph/specs/PRD-*.md | opencode --agent decomposer --prompt \
  "Decompose this PRD into atomic tasks following Ralph conventions"
```

Or if using Claude Code:

```bash
@decomposer
```

### Specialized Decomposer Variants

The Decomposer agent can invoke two specialized sub-assistants for consultation during decomposition:

**Decomposer-Architect** -- Use when the PRD involves complex system architecture:
- Microservices or distributed system design
- Integration patterns between components
- Technology stack decisions that affect task boundaries
- Design pattern guidance for well-bounded tasks

**Decomposer-Researcher** -- Use when the PRD references unfamiliar territory:
- Technologies or libraries that need investigation before task planning
- Comparing implementation approaches before committing to a structure
- External API documentation review for accurate task definitions
- Factual grounding needed before estimating complexity or dependencies

The Decomposer decides when to consult these sub-assistants. They return structured analysis but cannot create project files or manage state directly.

### What Happens During Decomposition

When you invoke the Decomposer agent, these steps occur:

1. **Agent reads the PRD content**
2. **Analyzes requirements and features**
3. **Identifies major work areas**
4. **Consults sub-assistants if needed** (decomposer-architect, decomposer-researcher)
5. **Breaks down into atomic tasks**
6. **Creates task folders and files**
7. **Generates TODO.md**
8. **Analyzes and records dependencies**

The agent produces complete Phase 2 artifacts ready for execution.

## Task Granularity Guidelines

### The 2-Hour Rule

Every task must be completable by a reasonably-competent human in **less than 2 hours**.

**Why the 2-hour limit?**

- AI success rate drops significantly on longer tasks
- Smaller tasks = clearer acceptance criteria
- Easier to recover from failures
- Better parallelization potential

Tasks exceeding 2 hours (XL size) must be decomposed further into smaller pieces.

### T-Shirt Sizing

Assign complexity estimates to each task:

| Size | Human Time | AI Context | When to Use |
|------|------------|------------|--------------|
| XS | 0-15 min | Trivial | Small fixes, config changes |
| S | 15-30 min | Simple | Single function, minor additions |
| M | 30-60 min | Moderate | Standard feature implementation |
| L | 1-2 hours | Complex | Multi-component integrations |
| XL | >2 hours | Too large | **Must decompose further** |

The Decomposer agent assigns these sizes during decomposition. Review them to ensure no XL tasks remain.

### When to Decompose Further

If a task is marked XL, break it down:

**Example of decomposition:**

```
Original: "Build user authentication system" (XL)

Decomposed:
- Create User model with auth fields (M)
- Implement password hashing (S)
- Create login endpoint (M)
- Create logout endpoint (S)
- Implement JWT token generation (M)
- Add token refresh mechanism (M)
- Write auth middleware (M)
```

## Decomposition Patterns

Use these patterns when breaking down requirements:

### Pattern 1: Feature Decomposition

Break large features into individual feature components:

```
Original: "Build user authentication system"

Decomposed:
- Create User model with auth fields
- Implement password hashing
- Create login endpoint
- Create logout endpoint
- Implement JWT token generation
- Add token refresh mechanism
- Write auth middleware
```

### Pattern 2: Layer Decomposition

Break work by architectural layer:

```
Original: "Implement API endpoint"

Decomposed:
- Design request/response schema
- Create database migration
- Implement repository layer
- Implement service layer
- Create controller/handler
- Add validation logic
- Write tests
```

### Pattern 3: Workflow Decomposition

Break user-facing features into workflow steps:

```
Original: "Add image upload feature"

Decomposed:
- Research image storage options
- Set up file upload middleware
- Implement image validation
- Create storage service
- Add image processing (resize)
- Update database schema
- Create upload endpoint
- Write frontend upload component
```

### Pattern 4: Testing Pyramid

Always include testing tasks:

```
Original: "Add payment processing"

Decomposed:
- [features...]
- Write unit tests for payment service
- Write integration tests for payment API
- Add end-to-end payment flow test
- Create payment documentation
```

## The Decomposition Process

### What the Decomposer Agent Does

The Decomposer agent follows a systematic workflow:

#### 1. Requirement Analysis

- Reads PRD thoroughly
- Identifies functional requirements
- Notes technical constraints
- Extracts acceptance criteria

#### 2. Work Breakdown

- Groups related functionality
- Identifies natural boundaries
- Estimates complexity (T-shirt sizing)
- Decomposes XL tasks further

#### 3. Task Structure Creation

For each task, the agent creates:

```
.ralph/tasks/XXXX/
├── TASK.md         # Description, criteria, implementation notes
├── attempts.md     # Empty template for attempt tracking
└── activity.md     # Empty template for activity logging
```

#### 4. Dependency Identification

- Determines task relationships
- Identifies blockers
- Creates execution order
- Records in deps-tracker.yaml

#### 5. TODO.md Generation

- Lists all tasks with checkboxes
- Groups by phase/category
- Includes task IDs and titles
- Ready for Phase 3 execution

## Example Decomposition Session

### Input PRD (Simplified)

```markdown
# PRD: Simple Blog API

## Features
1. Create blog posts with title, content, author
2. List all posts with pagination
3. Get single post by ID
4. Update existing posts
5. Delete posts

## Technical
- Python Flask
- PostgreSQL database
- RESTful JSON API
```

### Agent Process

```
[Decomposer] Reading PRD...
[Decomposer] Identifying work areas:
  - Database schema
  - API endpoints (5 operations)
  - Data models
  - Validation
  - Error handling

[Decomposer] Creating tasks:
  - 0001: Set up Flask project structure
  - 0002: Create database schema
  - 0003: Implement Post model
  - 0004: Implement create post endpoint
  - 0005: Implement list posts endpoint
  - 0006: Implement get post endpoint
  - 0007: Implement update post endpoint
  - 0008: Implement delete post endpoint
  - 0009: Add input validation
  - 0010: Add error handling
  - 0011: Write API tests
  - 0012: Create API documentation

[Decomposer] Analyzing dependencies...
[Decomposer] Creating task folders...
[Decomposer] Writing TODO.md...
[Decomposer] Phase 2 complete
```

### Generated Output

**TODO.md:**

```markdown
# Blog API Implementation

## Setup
- [ ] 0001: Set up Flask project structure
- [ ] 0002: Create database schema

## Models
- [ ] 0003: Implement Post model

## Endpoints
- [ ] 0004: Implement create post endpoint
- [ ] 0005: Implement list posts endpoint
- [ ] 0006: Implement get post endpoint
- [ ] 0007: Implement update post endpoint
- [ ] 0008: Implement delete post endpoint

## Polish
- [ ] 0009: Add input validation
- [ ] 0010: Add error handling
- [ ] 0011: Write API tests
- [ ] 0012: Create API documentation
```

**deps-tracker.yaml:**

```yaml
tasks:
  0001:
    depends_on: []
    blocks: [0002, 0003]
  0002:
    depends_on: [0001]
    blocks: [0003]
  0003:
    depends_on: [0001, 0002]
    blocks: [0004, 0005, 0006, 0007, 0008]
  0004:
    depends_on: [0003]
    blocks: [0009, 0010]
  0005:
    depends_on: [0003]
    blocks: [0009, 0010]
  0006:
    depends_on: [0003]
    blocks: [0009, 0010]
  0007:
    depends_on: [0003]
    blocks: [0009, 0010]
  0008:
    depends_on: [0003]
    blocks: [0009, 0010]
  0009:
    depends_on: [0004, 0005, 0006, 0007, 0008]
    blocks: [0011]
  0010:
    depends_on: [0004, 0005, 0006, 0007, 0008]
    blocks: [0011]
  0011:
    depends_on: [0009, 0010]
    blocks: [0012]
  0012:
    depends_on: [0011]
    blocks: []
```

**Sample TASK.md (0004):**

```markdown
# Task 0004: Implement create post endpoint

## Description
Create POST /api/posts endpoint that accepts JSON payload with title, content, and author_id, validates input, creates Post record, and returns 201 Created with post ID.

## Acceptance Criteria
- [ ] Endpoint accepts POST requests at /api/posts
- [ ] Validates required fields (title, content, author_id)
- [ ] Returns 201 with post ID on success
- [ ] Returns 400 with validation errors on invalid input
- [ ] Stores post in database
- [ ] All tests pass
- [ ] No scope creep

## Implementation Notes
- Use Flask Blueprint pattern
- Validate title length (1-200 chars)
- Validate content not empty
- Return JSON: {"id": 123, "title": "...", ...}

## Dependencies
- 0003: Post model must be implemented first

## Estimated Complexity
S (15-30 minutes)

## Agent Type
developer
```

## Dependency Analysis

### Types of Dependencies

**1. Technical Dependencies**

Tasks that require prior work to exist:

```yaml
tasks:
  0003:
    depends_on: [0002]  # Model depends on Schema
```

**2. Data Dependencies**

Tasks that need prior data or operations:

```yaml
tasks:
  0007:
    depends_on: [0006]  # Update needs Create first
```

**3. Infrastructure Dependencies**

Tasks that need infrastructure in place:

```yaml
tasks:
  0004:
    depends_on: [0001]  # Endpoint needs Project setup
```

### Dependency Notation

```yaml
# Simple dependency
depends_on: [0001]

# Multiple dependencies
depends_on: [0001, 0002]

# No dependencies
depends_on: []

# What this task blocks
blocks: [0005, 0006]
```

### Circular Dependency Detection

If the Decomposer detects circular dependencies:

```
[WARNING] Circular dependency detected:
  0005 -> 0006 -> 0007 -> 0005

[SUGGESTION] Break cycle by removing one edge:
  Option 1: Remove 0007 -> 0005 dependency
  Option 2: Merge 0006 and 0007 into single task
```

The agent immediately flags circular dependencies and suggests resolution strategies.

## Iterative Refinement

### When to Refine

Consider refining if:

- Agent created XL tasks that need breaking down
- Dependencies seem incorrect
- Task count feels too low or too high
- You have new insights after review

### Refinement Process

1. Review generated TODO.md
2. Identify issues or gaps
3. Provide feedback to the Decomposer

```bash
cat .ralph/specs/PRD.md | opencode --agent decomposer --prompt \
  "Refine decomposition: [specific feedback]"
```

4. Agent updates tasks and TODO.md

### Example Refinement

**Initial decomposition issues:**

- Task 0004: "Implement all endpoints" (too large)
- Missing: Database migration task
- Unclear: Validation requirements

**Refinement feedback:**

```
Please refine:
1. Break task 0004 into separate endpoints
2. Add database migration task
3. Add validation-specific task
```

**Updated result:**

- 0004: Implement create post endpoint
- 0005: Implement list posts endpoint
- 0006: Implement get post endpoint
- 0007: Implement update post endpoint
- 0008: Implement delete post endpoint
- 0009: Add input validation (across all endpoints)
- 0013: Create database migration

Repeat refinement until satisfied with the decomposition.

## Best Practices

### DO

- Keep tasks under 2 hours
- Write clear, specific descriptions
- Include measurable acceptance criteria
- Identify dependencies during creation
- Group related tasks under headers
- Leave room for runtime discovery
- Iterate until satisfied

### DON'T

- Create catch-all tasks ("misc fixes")
- Skip dependency analysis
- Make tasks too granular (< 5 minutes)
- Pre-assign agents to tasks
- Skip acceptance criteria
- Accept XL-sized tasks

## Common Mistakes

### Mistake 1: Tasks Too Large

**Bad:** "Build authentication system"

**Good:**

- Create User model
- Implement password hashing
- Create login endpoint
- etc.

### Mistake 2: Vague Descriptions

**Bad:** "Fix bugs"

**Good:** "Fix null pointer in UserService.create() when email is missing"

### Mistake 3: Missing Acceptance Criteria

**Bad:** No criteria listed

**Good:**

```markdown
## Acceptance Criteria
- [ ] Feature X implemented
- [ ] Unit tests pass
- [ ] Coverage > 80%
```

### Mistake 4: Over-Engineering Dependencies

**Bad:** Every task depends on everything before it

**Good:** Only actual technical dependencies

### Mistake 5: Skipping Testing Tasks

**Bad:** No testing tasks in the plan

**Good:** Include unit, integration, and E2E tests as separate tasks

## Post-Decomposition Checklist

Before starting Phase 3, verify:

- [ ] Review TODO.md - does it cover all PRD requirements?
- [ ] Check task sizes - any XL tasks remaining?
- [ ] Verify dependencies - do they make sense?
- [ ] Confirm acceptance criteria - are they testable?
- [ ] Count tasks - is scope appropriate?
- [ ] Commit Phase 2 work: `git add . && git commit -m "docs: task decomposition"`

## Next Steps

Once Phase 2 is complete:

1. Review generated tasks
2. Make any final adjustments
3. Start Phase 3: `./ralph-loop.sh`
4. Monitor execution
5. Handle any TASK_BLOCKED signals

## Summary

Phase 2 is your opportunity to plan before execution. Good decomposition:

- Creates clear, actionable tasks
- Identifies dependencies early
- Sets up for autonomous execution
- Can be refined iteratively

**Remember:** Time spent in Phase 2 planning saves time in Phase 3 execution.

---

## Related Documentation

- [Agent Selection Guide](agent-selection-guide.md) - Which agent handles which task type
- [Commands Reference](commands.md) - Ralph command reference
- [Configuration Reference](configuration.md) - Ralph configuration details
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
