# Model Mapping Guide

Ralph uses `agents.yaml` to configure which LLM models are used for each agent type. This guide explains how to optimize your model mappings for performance, cost, and capability.

**Key Concept:** Different tasks benefit from different model strengths. Ralph lets you map specific models to specific agent types.

## agents.yaml Structure

### File Location

- **Project-specific:** `.ralph/config/agents.yaml`
- **Template:** `jeeves/Ralph/templates/config/agents.yaml.template`

### Full Schema

```yaml
agents:
  <agent_type>:
    description: "Human-readable description of agent's purpose"
    preferred:
      opencode: <model_name>
      claude: <model_name>
    fallback:
      opencode: <model_name>
      claude: <model_name>
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `agents` | Yes | Root object containing all agent definitions |
| `<agent_type>` | Yes | One of: manager, architect, developer, tester, ui-designer, researcher, writer, decomposer |
| `description` | Yes | Human-readable description of agent's role |
| `preferred` | Yes | Models to use by default for each tool |
| `fallback` | No | Models to use if preferred model is unavailable or "inherit" |
| `opencode` | Yes* | Model name for OpenCode tool (*required if using opencode, use "inherit" to use default) |
| `claude` | Yes* | Model name for Claude tool (*required if using claude) |

### Special Values

**"inherit" Value:** Use `"inherit"` for OpenCode models to use Ralph's default model selection. This is the recommended approach for OpenCode as it allows Ralph to select the most appropriate available model.

## Tool-Specific Configuration

### OpenCode Models

```yaml
agents:
  developer:
    preferred:
      opencode: inherit
    fallback:
      opencode: inherit
```

**Supported Model Format:**
- Use `"inherit"` to use Ralph's default model selection
- Model identifiers are supported when explicitly specified
- Examples: `gpt-5.2`, `grok-4.1`, `gemini-3.0-flash`

### Claude Models

```yaml
agents:
  developer:
    preferred:
      claude: claude-sonnet-4.5
    fallback:
      claude: claude-haiku-4.5
```

**Supported Model Format:**
- Use Claude model identifiers
- Examples: `claude-opus-4.5`, `claude-sonnet-4.5`, `claude-haiku-4.5`

### Using Both Tools

```yaml
agents:
  developer:
    description: "Code implementation"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-haiku-4.5
```

## Model Selection at Runtime

### How It Works

1. User specifies tool: `--tool opencode` or `--tool claude`, or sets `RALPH_TOOL` environment variable
2. Ralph reads `agents.yaml`
3. For each agent invocation:
   - Look up agent type in yaml
   - Get preferred model for selected tool
   - If preferred is "inherit" or unavailable, use fallback model
   - Use that model for the agent

### Tool Selection Precedence

```bash
# Option 1: CLI flag (highest priority)
ralph-loop.sh --tool claude

# Option 2: Environment variable
export RALPH_TOOL=claude
ralph-loop.sh

# Option 3: Default (lowest priority)
ralph-loop.sh  # Uses opencode by default
```

## Model Recommendations by Agent Type

### Manager Agent

**Purpose:** Task orchestration, state management, handoffs

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-opus-4.5 | claude-sonnet-4.5 | Best for coordination |

**Why:** Management requires broad reasoning and ability to coordinate multiple agents.

### Architect Agent

**Purpose:** System design, API design, database schema

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-opus-4.5 | claude-sonnet-4.5 | Best for design |

**Why:** Architecture requires strong reasoning and ability to consider trade-offs.

### Developer Agent

**Purpose:** Code implementation, debugging

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-sonnet-4.5 | claude-haiku-4.5 | Good balance |

**Why:** Coding tasks need models proficient in multiple languages and patterns.

### UI-Designer Agent

**Purpose:** UI/UX design, frontend implementation

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-opus-4.5 | claude-sonnet-4.5 | Attention to detail |

**Why:** UI work requires understanding visual design principles and user experience.

### Tester Agent

**Purpose:** Test cases, edge case detection

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-sonnet-4.5 | claude-haiku-4.5 | Detail-oriented |

**Why:** Testing requires identifying edge cases and being thorough.

### Researcher Agent

**Purpose:** Investigation, documentation review, analysis

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-opus-4.5 | claude-sonnet-4.5 | Analysis depth |

**Why:** Research requires broad knowledge and analytical capabilities.

### Writer Agent

**Purpose:** Documentation, content creation

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-sonnet-4.5 | claude-haiku-4.5 | Good prose |

**Why:** Writing tasks benefit from clear, concise output.

### Decomposer Agent

**Purpose:** Task decomposition, coordination

**Recommended Models:**
| Tool | Preferred | Fallback | Reason |
|------|-----------|----------|--------|
| opencode | inherit | inherit | Uses Ralph default |
| claude | claude-opus-4.5 | claude-sonnet-4.5 | Organization |

**Why:** Decomposition requires understanding complex requirements and breaking them down logically.

## Complete Example Configuration

```yaml
agents:
  manager:
    description: "Ralph Loop Manager - orchestrates task execution, manages state, handles handoffs"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  architect:
    description: "System design and architecture tasks"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  developer:
    description: "Code implementation and debugging"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-haiku-4.5

  ui-designer:
    description: "UI/UX design and implementation"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  tester:
    description: "Testing and quality assurance"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-haiku-4.5

  researcher:
    description: "Research, analysis, and documentation"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5

  writer:
    description: "Documentation and content creation"
    preferred:
      opencode: inherit
      claude: claude-sonnet-4.5
    fallback:
      opencode: inherit
      claude: claude-haiku-4.5

  decomposer:
    description: "Task decomposition, TODO management, agent coordination"
    preferred:
      opencode: inherit
      claude: claude-opus-4.5
    fallback:
      opencode: inherit
      claude: claude-sonnet-4.5
```

## Performance vs Cost Trade-offs

### Model Tiers

**Tier 1 - Best Performance (Higher Cost)**
- claude: claude-opus-4.5

**Tier 2 - Good Balance**
- claude: claude-sonnet-4.5

**Tier 3 - Cost-Effective**
- claude: claude-haiku-4.5

### Optimization Strategies

**Strategy 1: Critical Tasks Get Best Models**

```yaml
# Use best model for architecture (critical decisions)
architect:
  preferred:
    claude: claude-opus-4.5  # Best reasoning

# Use cheaper model for writing (less critical)
writer:
  preferred:
    claude: claude-haiku-4.5  # Cheaper, sufficient
```

**Strategy 2: Fallback to Cheaper Models**

```yaml
developer:
  preferred:
    claude: claude-sonnet-4.5
  fallback:
    claude: claude-haiku-4.5  # Cheaper fallback
```

**Strategy 3: Tool-Specific Optimization**

```yaml
# Use Claude's best for complex tasks
architect:
  preferred:
    claude: claude-opus-4.5
```

## Syncing Agent Configuration

### When to Sync

- After modifying agents.yaml
- After adding new agent types
- When switching tools
- After updating model names

### Running sync-agents

```bash
# Sync all agents (for OpenCode by default)
sync-agents

# Sync for specific tool
sync-agents --tool claude

# Dry run (preview changes)
sync-agents --dry-run

# Show parsed agents without syncing
sync-agents --show

# Use custom config path
sync-agents --config /path/to/agents.yaml
```

### Environment Variables

```bash
# Set tool via environment variable
RALPH_TOOL=claude sync-agents

# Custom agents.yaml path
AGENTS_YAML=/path/to/agents.yaml sync-agents
```

### What sync-agents Does

1. Validates agents.yaml exists and has valid YAML syntax
2. Extracts all agent types from the `agents` key in agents.yaml
3. Searches for agent definition files in these paths (in priority order):
   - `.ralph/agents/`
   - `.opencode/agents/`
   - `.claude/agents/`
   - `~/.config/opencode/agents/`
   - `~/.claude/agents/`
4. For each agent file found:
   - Reads current frontmatter
   - Gets model from `preferred.<tool>` in agents.yaml
   - If preferred is empty/null, falls back to `fallback.<tool>`
   - Updates the `model:` field in frontmatter
5. Preserves all other content in the agent file

### Example Sync Output

```
[INFO] Using tool: opencode
[SUCCESS] agents.yaml validated
[INFO] Loaded 8 agent type(s) from agents.yaml
[INFO] Agent file search paths:
  .ralph/agents - not found
  .opencode/agents - found (8 files)
  .claude/agents - not found
  /home/user/.config/opencode/agents - not found
  /home/user/.claude/agents - not found
[INFO] Found 8 agent file(s) total
[SUCCESS] Updated .opencode/agents/manager.md with model: inherit
[SUCCESS] Updated .opencode/agents/architect.md with model: inherit
[SUCCESS] Updated .opencode/agents/developer.md with model: inherit
[SUCCESS] Sync complete: 8 updated, 0 failed
[SUCCESS] Agent synchronization complete for tool: opencode
```

### Idempotency

The sync-agents script is idempotent. Running it multiple times with the same configuration will not make unnecessary changes. It checks if the model value already matches before updating.

## Updating Model Names

### Why Models Change

- Providers release new versions
- Model names updated (e.g., gpt-4 → gpt-5)
- Old models deprecated
- New capabilities available

### Update Process

1. Check current model availability
2. Update agents.yaml with new model names
3. Run sync-agents to propagate changes
4. Test with new models

### Example Update

**Before:**
```yaml
developer:
  preferred:
    claude: claude-sonnet-4.0
```

**After:**
```yaml
developer:
  preferred:
    claude: claude-sonnet-4.5
```

```bash
# Sync changes
sync-agents --tool claude
```

## Validation and Troubleshooting

### Validating Configuration

```bash
# Check YAML syntax
yq eval '.' .ralph/config/agents.yaml

# Validate structure
yq eval '.agents | keys' .ralph/config/agents.yaml

# Check specific agent
yq eval '.agents.developer.preferred.claude' .ralph/config/agents.yaml
```

### Common Issues

**Issue 1: Model not found**
```
Error: Model 'claude-sonnet-4.5' not available
```
**Solution:**
- Check model name spelling
- Verify model is supported by tool
- Update to available model name
- Or configure fallback

**Issue 2: Invalid YAML**
```
Error: YAML parsing failed
```
**Solution:**
- Check indentation (use spaces, not tabs)
- Verify colons are followed by spaces
- Validate with: `yq eval '.' agents.yaml`

**Issue 3: sync-agents not updating**
```
[WARNING] No agent files found to synchronize
```
**Solution:**
- Check agent.md files exist in search paths
- Verify agents.yaml has correct agent names
- Check file permissions

**Issue 4: Wrong model being used**
```
[EXPECTED] claude-sonnet-4.5
[ACTUAL] claude-haiku-4.5
```
**Solution:**
- Check RALPH_TOOL environment variable
- Verify --tool flag value
- Confirm agents.yaml has correct mapping
- Run sync-agents
- Check agent.md frontmatter

### Debugging with --show

Use the `--show` flag to see how agents.yaml is being parsed without making changes:

```bash
sync-agents --show
```

Output:
```
[INFO] Parsed agents from .ralph/config/agents.yaml:
[INFO]
[INFO] Agent: manager
[INFO]   Description: Ralph Loop Manager - orchestrates task execution...
[INFO]   Model (opencode): inherit
[INFO]
[INFO] Agent: architect
[INFO]   Description: System design and architecture tasks
[INFO]   Model (opencode): inherit
```

## Best Practices

### DO:
- Use `"inherit"` for OpenCode to leverage Ralph's default model selection
- Configure fallback models for reliability
- Keep agents.yaml in version control
- Run sync-agents after changes
- Update model names when providers change
- Choose models appropriate for task type

### DON'T:
- Use model names without verifying availability
- Skip fallback configuration
- Mix different model naming conventions
- Forget to sync after editing agents.yaml
- Use most expensive model for all tasks

## Summary

Model mapping is key to optimizing Ralph's performance and cost:
- Match model strengths to task types
- Use preferred/fallback for reliability
- Use "inherit" for OpenCode to leverage Ralph defaults
- Sync configuration after changes
- Update model names as needed
- Balance performance vs cost

**Remember:** You're responsible for keeping model names current as providers update their offerings. Use `sync-agents --show` to verify your configuration is correct.
