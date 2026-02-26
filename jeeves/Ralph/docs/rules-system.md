# RULES.md Hierarchical Learning System

The RULES.md system provides a hierarchical, project-specific knowledge management mechanism that allows AI agents to discover, apply, and extend project conventions across directory structures.

## Overview

### Purpose

RULES.md files capture project-specific rules, patterns, pitfalls, and learned behaviors. Placed in any directory, they automatically apply to that directory and its subdirectories, enabling:

- **Consistency**: Teams and AI agents follow the same conventions
- **Learning**: Patterns discovered during task execution get documented
- **Inheritance**: Rules flow from parent to child directories
- **Override**: Subdirectories can customize or completely isolate themselves

### Philosophy

The system follows three core principles:

1. **Rules accumulate from root to task directory** - Starting from the project root, all RULES.md files in the path are collected
2. **Deeper rules override parent rules** - When conflicts occur, the rule closest to the working directory wins
3. **Auto-discovery prevents repeated mistakes** - Patterns observed multiple times become documented rules

### Benefits

- **Self-documenting projects**: Conventions captured in code, not just people's heads
- **Onboarding**: New team members and AI agents quickly learn project patterns
- **Consistency enforcement**: Automated rule application reduces drift
- **Knowledge transfer**: Lessons learned during development persist

## File Format

### Structure

RULES.md files use markdown with specific section headers:

```markdown
# RULES.md - Project Rules and Patterns

[Optional: Purpose statement]

## IGNORE_PARENT_RULES Token

[Documentation of isolation mechanism]

## RULES.md Creation Guidelines

[When to create new RULES.md files]

## Code Patterns

[Reusable patterns specific to this project]

### Pattern Name
- **Context**: When to use this pattern
- **Rule**: Description
- **Example**: Code example

## Common Pitfalls

[Mistakes to avoid]

### Pitfall Name
- **Context**: When this pitfall occurs
- **Problem**: Description
- **Solution**: How to avoid

## Standard Approaches

[Preferred solutions]

### Approach Name
- **Context**: Problem being solved
- **Approach**: Recommended solution
- **Rationale**: Why this approach

## Auto-Discovered Patterns

[Patterns learned during task execution]

### Section Requirements

| Section | Required | Description |
|---------|----------|-------------|
| IGNORE_PARENT_RULES | No | Isolation mechanism documentation |
| RULES.md Creation Guidelines | No | When to create new RULES.md files |
| Code Patterns | No | Reusable code patterns |
| Common Pitfalls | No | Mistakes to avoid |
| Standard Approaches | No | Preferred solutions |
| Auto-Discovered Patterns | No | Learned patterns |

### File Location

RULES.md files can exist at any directory level:

```
/project/
├── RULES.md              # Root rules - applies to entire project
├── src/
│   ├── RULES.md          # Source-specific rules
│   └── components/
│       └── RULES.md      # Component-specific rules
└── docs/
    └── RULES.md          # Documentation-specific rules
```

## Lookup Algorithm

The lookup algorithm walks from the current directory toward the project root, collecting RULES.md files until reaching a stop condition.

### Implementation

The algorithm is implemented in `/proj/jeeves/bin/find-rules-files.sh`:

```bash
find_rules_files() {
    local current_dir="${1:-$(pwd)}"
    local rules_files=""
    
    while true; do
        if [[ -f "$current_dir/RULES.md" ]]; then
            rules_files="$rules_files $current_dir/RULES.md"
            
            if has_ignore_parent_rules "$current_dir/RULES.md"; then
                break
            fi
        fi
        
        # Stop at .ralph or .git directory (project boundary)
        if [[ -d "$current_dir/.ralph" ]] || [[ -d "$current_dir/.git" ]]; then
            break
        fi
        
        # Move to parent directory
        parent=$(dirname "$current_dir")
        if [[ "$parent" == "$current_dir" ]]; then
            break  # Reached filesystem root
        fi
        current_dir="$parent"
    done
    
    echo "$rules_files"
}
```

### Stop Conditions

The algorithm stops collecting rules when ANY of these conditions is met:

1. **IGNORE_PARENT_RULES found**: Current RULES.md contains the isolation token
2. **Project boundary reached**: Directory contains `.ralph` or `.git` directory
3. **Filesystem root reached**: No parent directory exists

### Collection Order

Rules are collected from root to working directory. For `/project/src/components/button/`:

```
1. /project/RULES.md
2. /project/src/RULES.md
3. /project/src/components/RULES.md
4. /project/src/components/button/RULES.md
```

This order enables later files to override earlier ones during application.

### Example Output

```bash
$ find_rules_files /project/src/components/button
/project/RULES.md /project/src/RULES.md /project/src/components/RULES.md
```

## Hierarchical Application

### Precedence Rules

When multiple RULES.md files exist in the hierarchy:

1. **All rules are collected** - No rule is automatically discarded
2. **Deeper rules take precedence** - Conflicts resolved in favor of the file closest to working directory
3. **Sections are merged** - Code Patterns, Pitfalls, Approaches from all files are combined

### Merge Strategy

The application logic in `/proj/jeeves/bin/apply-rules.sh` uses this strategy:

```bash
# Iterate from deepest to shallowest
for ((i=${#files_array[@]}-1; i>=0; i--)); do
    local rules_file="${files_array[$i]}"
    
    # Extract each section
    patterns=$(extract_section "$rules_file" "Code Patterns")
    pitfalls=$(extract_section "$rules_file" "Common Pitfalls")
    approaches=$(extract_section "$rules_file" "Standard Approaches")
    
    # Newer (deeper) content replaces older
    merged_patterns=$(merge_patterns "$merged_patterns" "$patterns")
    merged_pitfalls=$(merge_pitfalls "$merged_pitfalls" "$pitfalls")
    merged_approaches=$(merge_approaches "$merged_approaches" "$approaches")
done
```

### Precedence Example

Given this hierarchy:

```
/project/RULES.md:
## Code Patterns
- Use 2 spaces for indentation

/project/src/RULES.md:
## Code Patterns  
- Use tabs for indentation
```

When working in `/project/src/`, the effective rule is "Use tabs for indentation" because the deeper rule overrides the parent.

### Complete Override

Child rules completely replace parent rules for the same section type. There is no merging of conflicting rules within a section - the deepest rule wins.

## IGNORE_PARENT_RULES

### Purpose

The `IGNORE_PARENT_RULES` token stops rule inheritance from parent directories. Use it when:

- Subdirectory contains a completely different codebase
- Subdirectory uses a different tech stack with conflicting conventions
- Subdirectory is a third-party library or dependency
- Complete isolation from parent patterns is needed

### Syntax

The token must appear on its own line (whitespace is trimmed):

```
IGNORE_PARENT_RULES
```

### Whitespace Variations

The implementation trims whitespace before matching:

- `IGNORE_PARENT_RULES` - exact match
- `  IGNORE_PARENT_RULES` - leading whitespace
- `IGNORE_PARENT_RULES  ` - trailing whitespace
- `  IGNORE_PARENT_RULES  ` - both

### Commented Token

A commented version does NOT activate isolation:

```markdown
# IGNORE_PARENT_RULES  # This does NOT work
```

The comment is part of the line, so the exact token doesn't exist on its own.

### Usage Example

```markdown
# /project/frontend/RULES.md
IGNORE_PARENT_RULES

## Code Patterns
- Use React hooks
- Use functional components
```

When working in `/project/frontend/`, only the frontend rules apply - parent rules from `/project/RULES.md` are ignored.

### Decision Guide

| Scenario | Use IGNORE_PARENT_RULES? |
|----------|-------------------------|
| Different tech stack (Python vs JavaScript) | Yes |
| Third-party dependencies | Yes |
| Completely separate project | Yes |
| Minor additions to parent rules | No |
| Same project, same stack | No |
| Extending parent patterns | No |

## Auto-Discovery

### Purpose

Auto-discovery captures patterns learned during task execution, preventing repeated mistakes across tasks and team members.

### Criteria

A pattern should be documented as an auto-discovered rule when ALL of these are met:

1. **Pattern observed 2+ times** - Not a one-off occurrence
2. **Clear generalization possible** - The pattern can be expressed as guidance
3. **No contradiction with existing rules** - Doesn't conflict with current rules
4. **Rate limited: 1 rule per task maximum** - Prevents rule explosion

### Process

1. **Observation**: During task execution, note when the same issue appears multiple times
2. **Analysis**: Determine if the pattern can be generalized
3. **Documentation**: Format using auto-rule template
4. **Placement**: Add to the RULES.md in the relevant directory
5. **Verification**: Ensure the rule is grep-friendly for future discovery

### Discovery Workflow

```
Task Execution
      │
      ▼
Pattern Observed (1st time)
      │
      ▼
Document in activity.md
      │
      ▼
Pattern Observed (2nd time)
      │
      ▼
Apply Auto-Discovery Criteria
      │
      ├─ Meets all criteria? ──Yes──► Create AUTO rule in RULES.md
      │
      └─ No ──► Continue observation
```

## Auto-Rule Format

### Template

```markdown
### AUTO [YYYY-MM-DD][task-XXXX]: Rule Name
Context: The situation that led to the discovery
Rule: The actual guidance or pattern to follow
Example: Optional code example (use backticks)
```

### Components

| Component | Required | Description |
|-----------|----------|-------------|
| `AUTO` | Yes | Marker identifying auto-discovered rule |
| `YYYY-MM-DD` | Yes | Date of discovery (ISO format) |
| `task-XXXX` | Yes | Task ID where pattern was discovered |
| Rule Name | Yes | Short descriptive title |
| Context | Yes | Situation that triggered the discovery |
| Rule | Yes | The actual guidance |
| Example | No | Code demonstration |

### Grep-Friendly Design

The format uses consistent prefixes enabling efficient searching:

- `grep "AUTO \[" RULES.md` - Find all auto-rules
- `grep "AUTO \[2026-" RULES.md` - Find rules from 2026
- `grep "AUTO.*task-0087" RULES.md` - Find rules from specific task

### Examples

**Good Example (Complete)**

```markdown
AUTO [2026-02-04][task-0087]:
  Context: Multiple tasks required YAML parsing, each initially used different tools
  Rule: Always use `yq` for YAML parsing in bash scripts. Do not use sed, awk, or grep for YAML.
  Example: `yq -r '.tasks."0001".depends_on[]' deps-tracker.yaml`
```

**Good Example (Minimal)**

```markdown
AUTO [2026-02-10][task-0090]:
  Context: Patterns were being discovered but had no standard format for documentation
  Rule: Use AUTO [YYYY-MM-DD][task-XXX]: format for grep-friendly pattern discovery
```

**Poor Example (Missing Required Fields)**

```markdown
AUTO: Always use yq for YAML
# Missing: date, task ID, context
```

### Creation Checklist

Before adding an auto-rule, verify:

- [ ] Pattern observed at least twice
- [ ] Clear, actionable rule can be written
- [ ] No existing rule contradicts this one
- [ ] Not more than 1 auto-rule from this task already exists
- [ ] Format includes all required components

## Creation Criteria

### When to Create

Create a new RULES.md when ANY of these thresholds are met:

| Threshold | Description | Example |
|----------|-------------|---------|
| 2+ Unique Patterns | Directory has patterns not in parent | Backend uses different error handling |
| 3+ Parent Overrides | Consistent need to override parent | "Use tabs" contradicts parent "Use 2 spaces" |
| 10+ Files | Significant file count | Large feature module |
| 3+ Cross-Task Occurrences | Same pattern across tasks | All UI tasks need accessibility pattern |

### Decision Tree

```
Working in subdirectory?
├─ Yes → See unique patterns emerging?
│       ├─ Yes → Meets threshold (2+ patterns OR 3+ overrides)?
│       │       ├─ Yes → Create RULES.md
│       │       └─ No → Add to existing or parent RULES.md
│       └─ No → Use parent RULES.md
└─ No → Use root RULES.md
```

### Granularity Guidance

- **Don't** create RULES.md for every subdirectory
- **Do** create at module/package boundaries
- **Consider** IGNORE_PARENT_RULES for truly isolated codebases

### Examples

**Create RULES.md - Different Tech Stack**

```
/project/
├── RULES.md              # JavaScript conventions
└── backend/
    └── RULES.md          # Python conventions
```

**Create RULES.md - Significant File Count**

```
/project/
├── RULES.md
└── components/           # 15+ React components
    └── RULES.md          # Component patterns
```

**Create RULES.md - Consistent Overrides**

```
/project/
├── RULES.md              # Says "Use 2 spaces"
└── legacy-code/          # Uses tabs
    └── RULES.md          # Says "Use tabs"
```

**Don't Create - Minimal Deviation**

```
/project/
├── RULES.md              # Has "Use camelCase"
└── utils/
    └── helper.js         # One file snake_case - not enough
```

**Don't Create - Single Pattern**

```
/project/
├── RULES.md
└── docs/                 # Only markdown files
    └── README.md         # No RULES.md needed
```

## Workflow Diagram

### Complete RULES.md Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PROJECT START                                │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  Agent Starts Task Execution                        │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Lookup Phase                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ find_rules_files.sh                                          │  │
│  │                                                               │  │
│  │  Starting from working directory                            │  │
│  │       │                                                      │  │
│  │       ▼                                                      │  │
│  │  ┌─────────────────────┐                                    │  │
│  │  │ Check for RULES.md  │◄── Iterates toward root           │  │
│  │  └──────────┬──────────┘                                    │  │
│  │             │                                                 │  │
│  │             ▼                                                 │  │
│  │  ┌─────────────────────────────────────────────┐             │  │
│  │  │ IGNORE_PARENT_RULES found?                  │             │  │
│  │  │   OR .ralph/.git found?                     │             │  │
│  │  │   OR filesystem root?                        │             │  │
│  │  └───────────────┬─────────────────────────────┘             │  │
│  │                  │ No                                         │  │
│  │                  ▼                                            │  │
│  │          [Continue to parent]                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Application Phase                                 │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ apply-rules.sh                                                │  │
│  │                                                               │  │
│  │  Files collected: /proj/RULES.md /proj/src/RULES.md        │  │
│  │                                                               │  │
│  │  Process from ROOT to WORKING DIRECTORY:                     │  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────┐                │  │
│  │  │ Extract sections from each RULES.md    │                │  │
│  │  │   - Code Patterns                       │                │  │
│  │  │   - Common Pitfalls                     │                │  │
│  │  │   - Standard Approaches                 │                │  │
│  │  └────────────────────┬────────────────────┘                │  │
│  │                       │                                       │  │
│  │                       ▼                                       │  │
│  │  ┌─────────────────────────────────────────┐                │  │
│  │  │ Merge with DEEPEST RULE PRECEDENCE      │                │  │
│  │  │ (later files override earlier)         │                │  │
│  │  └────────────────────┬────────────────────┘                │  │
│  │                       │                                       │  │
│  │                       ▼                                       │  │
│  │  ┌─────────────────────────────────────────┐                │  │
│  │  │ Output merged rules for agent use       │                │  │
│  │  └─────────────────────────────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Task Execution                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Agent follows merged rules while working                     │  │
│  │                                                               │  │
│  │  Patterns Observed                                           │  │
│  │       │                                                      │  │
│  │       ▼                                                      │  │
│  │  ┌────────────────────────┐                                   │  │
│  │  │ First occurrence?     │                                   │  │
│  │  └───────────┬──────────┘                                   │  │
│  │              │                                                │  │
│  │      Yes     │     No                                         │  │
│  │              │     │                                          │  │
│  │              ▼     ▼                                          │  │
│  │  ┌──────────────┐  ┌────────────────────────────────────┐   │  │
│  │  │Document in   │  │ Apply Auto-Discovery Criteria     │   │  │
│  │  │activity.md   │  └──────────────┬─────────────────────┘   │  │
│  │  └──────────────┘                 │                           │  │
│  │                                   │                           │  │
│  │                          ┌────────▼─────────┐                │  │
│  │                          │Meets all criteria?│                │  │
│  │                          └────────┬─────────┘                │  │
│  │                                   │                           │  │
│  │                          Yes      │     No                    │  │
│  │                          │        │                          │  │
│  │                          ▼        │                          │  │
│  │                  ┌───────────────┐ │                          │  │
│  │                  │Create AUTO    │ │                          │  │
│  │                  │rule in local  │ │                          │  │
│  │                  │RULES.md       │ │                          │  │
│  │                  └───────────────┘ │                          │  │
│  │                                   │                           │  │
│  └───────────────────────────────────┴───────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         TASK COMPLETE                                │
│  Rules discovered during this task are now documented              │
└─────────────────────────────────────────────────────────────────────┘
```

### CLI Usage Diagram

```bash
# Find all RULES.md files from current directory to root
$ ./bin/find-rules-files.sh
/project/RULES.md /project/src/RULES.md /project/src/components/RULES.md

# Apply rules (merge and display)
$ ./bin/apply-rules.sh "/project/RULES.md /project/src/RULES.md /project/src/components/RULES.md"
Loading rules from: /project/RULES.md
Loading rules from: /project/src/RULES.md
Loading rules from: /project/src/components/RULES.md

CODE_PATTERNS:
(merged patterns from all files)

COMMON_PITFALLS:
(merged pitfalls from all files)

STANDARD_APPROACHES:
(merged approaches from all files)
```

## Examples

### Example 1: Simple Project Structure

```
/myproject/
├── RULES.md
├── src/
│   ├── main.js
│   └── utils.js
└── tests/
    └── main.test.js
```

**Root RULES.md** (`/myproject/RULES.md`):
```markdown
# Project Rules

## Code Patterns
- Use ES6+ syntax
- Use const/let, never var

## Standard Approaches
- Use Jest for testing
```

**Effective Rules in /myproject/src/utils.js**:
- Use ES6+ syntax
- Use const/let, never var
- Use Jest for testing

### Example 2: Multi-Stack Project

```
/myproject/
├── RULES.md              # JavaScript conventions
├── frontend/
│   ├── RULES.md          # React-specific rules
│   └── src/
│       └── components/
└── backend/
    └── RULES.md          # Python-specific rules
```

**Frontend RULES.md** has `IGNORE_PARENT_RULES`:
```markdown
IGNORE_PARENT_RULES

## Code Patterns
- Use React hooks
- Use functional components with arrow functions
```

**Effective Rules in /myproject/frontend/src/components/**:
- Use React hooks
- Use functional components with arrow functions

**Effective Rules in /myproject/backend/**:
- (Python rules from backend/RULES.md, NOT JavaScript from root)

### Example 3: Auto-Discovery

During task execution, agent YAML notices parsing errors:

1. **First occurrence** (task-0087): Document in activity.md
2. **Second occurrence** (task-0087): Apply auto-discovery criteria
3. **Result**: Add to `/myproject/RULES.md`:

```markdown
## Auto-Discovered Patterns

AUTO [2026-02-04][task-0087]:
  Context: Multiple tasks required YAML parsing, each initially used different tools
  Rule: Always use `yq` for YAML parsing in bash scripts. Do not use sed, awk, or grep for YAML.
  Example: `yq -r '.tasks."0001".depends_on[]' deps-tracker.yaml`
```

## Best Practices

### For New Projects

1. **Create root RULES.md early** - Establish conventions from the start
2. **Keep it minimal** - Add rules as patterns emerge, not preemptively
3. **Document rationale** - Explain why, not just what
4. **Use examples** - Show, don't just tell

### For Established Projects

1. **Audit existing rules** - Review and clean up periodically
2. **Consolidate duplicates** - Merge similar rules, remove conflicts
3. **Archive stale rules** - Remove rules that no longer apply

### For AI Agents

1. **Check rules at task start** - Run find_rules_files before implementing
2. **Apply merged rules** - Use apply-rules.sh to get combined guidance
3. **Document discoveries** - Note patterns in activity.md
4. **Propose improvements** - Suggest parent changes when appropriate

### General Guidelines

| Practice | Recommendation |
|----------|----------------|
| Rule specificity | More specific > More general |
| Examples | Always include when possible |
| Naming | Use descriptive, searchable names |
| Formatting | Keep grep-friendly structure |
| Updates | Review and update regularly |

## Troubleshooting

### Problem: Rules Not Being Found

**Symptoms**: Rules seem to be ignored

**Diagnosis**:
```bash
# Check if RULES.md exists
ls -la RULES.md

# Check find output
./bin/find-rules-files.sh
```

**Solutions**:
- Verify RULES.md file exists in expected location
- Check file is named exactly "RULES.md" (case-sensitive)
- Ensure file has read permissions

### Problem: Wrong Rules Applied

**Symptoms**: Unexpected rules from wrong directory

**Diagnosis**:
```bash
# Trace rule lookup
./bin/find-rules-files.sh /full/path/to/working/dir

# Check for unexpected parent rules
grep -r "IGNORE_PARENT_RULES" /path/to/parent/RULES.md
```

**Solutions**:
- Add `IGNORE_PARENT_RULES` to your directory's RULES.md
- Check for accidental parent rules in unexpected locations
- Verify merge precedence (deeper rules win)

### Problem: Duplicate/Conflicting Rules

**Symptoms**: Same rule appears multiple times with different values

**Diagnosis**:
```bash
# Find all RULES.md in path
./bin/find-rules-files.sh

# Check for conflicts
grep "Code Patterns" -A 5 /path/*/RULES.md
```

**Solutions**:
- Remove duplicate rules from child RULES.md
- Ensure deeper rules intentionally override parent
- Document override rationale in comments

### Problem: Auto-Rule Not Found

**Symptoms**: New auto-rule not being discovered

**Diagnosis**:
```bash
# Check format is correct
grep "AUTO \[" /path/to/RULES.md
```

**Solutions**:
- Verify format: `AUTO [YYYY-MM-DD][task-XXXX]:`
- Ensure date is ISO format (YYYY-MM-DD)
- Include task-ID in brackets: [task-XXXX]
- Check no extra characters before AUTO

### Problem: Rules File Not Found at Root

**Symptoms**: Lookup stops before reaching expected root

**Diagnosis**:
```bash
# Check for stop condition
ls -la .ralph  # Ralph directory?
ls -la .git    # Git directory?
```

**Solutions**:
- Project boundary (.ralph or .git) stops lookup
- Place RULES.md inside the boundary directory
- Use RULES.md in .ralph for project-specific rules

### Problem: Merge Not Working

**Symptoms**: Only one RULES.md's rules appear

**Diagnosis**:
```bash
# Manual merge test
./bin/apply-rules.sh "$(./bin/find-rules-files.sh)"
```

**Solutions**:
- Ensure multiple files in input to apply-rules.sh
- Check merge functions in apply-rules.sh
- Verify section headers match exactly ("Code Patterns", etc.)

### Problem: Permission Denied

**Symptoms**: Cannot read RULES.md files

**Diagnosis**:
```bash
ls -la /path/to/RULES.md
```

**Solutions**:
- Check file permissions (chmod +r)
- Verify ownership
- Check parent directory permissions

### Debugging Checklist

When rules aren't working as expected:

1. [ ] Verify RULES.md file exists: `ls RULES.md`
2. [ ] Check find output: `./bin/find-rules-files.sh`
3. [ ] Verify merge input: `apply-rules.sh "$(find_rules_files)"`
4. [ ] Check for IGNORE_PARENT_RULES: `grep IGNORE_PARENT_RULES RULES.md`
5. [ ] Verify stop condition: `ls -la .ralph .git`
6. [ ] Test with verbose output: Add debug echo to scripts

### Getting Help

For persistent issues:

1. Review this documentation thoroughly
2. Examine working RULES.md examples in the project
3. Review activity.md for similar past issues

## Related Files

- `/proj/jeeves/bin/find-rules-files.sh` - Rule file discovery
- `/proj/jeeves/bin/apply-rules.sh` - Rule application and merging
- `/proj/jeeves/Ralph/templates/RULES.md.template` - Template for new files
