# Feature Request: Auto-populate Agent Sync with Current OpenCode Free Models

## Type
Enhancement / Feature Request

## Problem/Use Case

Currently, users must manually discover and configure which OpenCode Zen models are available for free. OpenCode offers several free models (e.g., `big-pickle`, `minimax-m2.5-free`, `gpt-5-nano`) that rotate or change over time, but there's no automated way to:

1. Discover which models are currently free on OpenCode Zen
2. Populate `agents.yaml` with these free models as defaults for agent configurations
3. Keep the free model list up-to-date as OpenCode changes their offerings

### Current Behavior
- Users must manually check https://opencode.ai/zen/v1/models to see available models
- Users must manually edit `agents.yaml` to configure free models
- No integration between OpenCode's model API and Jeeves agent configuration

### Desired Behavior
- A command or script that fetches current free models from OpenCode
- Automatic population of `agents.yaml` with free models as the `opencode:` preference
- Clear indication of which models are free vs. paid
- Optional: periodic update checks or manual refresh command

## Proposed Solution

Add a new capability to the agent sync system (either extend [`sync-agents.sh`](jeeves/bin/sync-agents.sh) or create a new helper script) that:

1. **Fetches current models** from OpenCode's API endpoint: `https://opencode.ai/zen/v1/models`
2. **Filters for free models** based on pricing data (input/output price = 0 or marked as free)
3. **Intelligently maps** free models to agent types based on capability:
   - Complex agents (architect, decomposer): Best available free model
   - Standard agents (developer, tester, writer): Capable free models
   - Light agents (researcher, ui-designer): Efficient free models
4. **Updates `agents.yaml`** with the free models as `opencode:` preferences

### Implementation Options

#### Option A: Extend `sync-agents.sh` with `--fetch-free-models` flag

Add a new flag that fetches and populates free models before syncing:

```bash
sync-agents --fetch-free-models  # Fetches free models and updates agents.yaml
sync-agents                      # Uses existing agents.yaml (current behavior)
```

**Pros:**
- Single script for all agent sync operations
- Familiar interface

**Cons:**
- Adds complexity to existing script
- Requires internet connectivity check

#### Option B: New `fetch-opencode-models.sh` script

Create a standalone script that generates/updates `agents.yaml` with free models:

```bash
fetch-opencode-models --free --output .ralph/config/agents.yaml
sync-agents  # Then sync as normal
```

**Pros:**
- Separation of concerns
- Can be used independently
- Easier to test and maintain

**Cons:**
- Another script to learn

#### Option C: Integration with `install-agents.sh`

During agent installation, offer to auto-configure free models:

```bash
install-agents --with-free-models
```

**Pros:**
- One-time setup during installation
- Seamless onboarding experience

**Cons:**
- Less flexible for updates
- Tied to installation flow

## Recommended Approach: Option B (New Script)

Create a new `fetch-opencode-models.sh` script that:

1. Queries `https://opencode.ai/zen/v1/models`
2. Parses JSON response (using `jq`)
3. Filters models where `pricing.input == 0 && pricing.output == 0`
4. Maps models to agent capabilities based on context window and features
5. Generates or updates `agents.yaml` with free models

### Model Mapping Strategy

| Agent Type | Priority Criteria | Example Free Model |
|------------|------------------|-------------------|
| `manager`, `decomposer` | Largest context, reasoning capable | `big-pickle` |
| `architect`, `decomposer-architect` | Large context, coding capable | `big-pickle` |
| `developer`, `tester` | Coding optimized, good context | `gpt-5-nano` |
| `writer`, `researcher` | Good context, text generation | `minimax-m2.5-free` |
| `ui-designer` | Multimodal if available | `minimax-m2.5-free` |

### File Changes Required

**New Files:**
- `jeeves/bin/fetch-opencode-models.sh` - Main script to fetch and populate models

**Files to Reference (not modify in this issue):**
- [`jeeves/bin/sync-agents.sh`](jeeves/bin/sync-agents.sh) - Existing sync functionality
- [`jeeves/Ralph/templates/config/agents.yaml.template`](jeeves/Ralph/templates/config/agents.yaml.template) - Template structure

### Script Requirements

The new script should:
- [ ] Accept `--free` flag to filter only free models
- [ ] Accept `--output` flag to specify output file (default: `.ralph/config/agents.yaml`)
- [ ] Accept `--dry-run` flag to preview changes without writing
- [ ] Validate OpenCode API response
- [ ] Handle network errors gracefully
- [ ] Preserve existing `claude:` configurations
- [ ] Only update `opencode:` model preferences
- [ ] Provide informative output about which models were selected

### Example Usage

```bash
# Fetch free models and update agents.yaml
fetch-opencode-models --free

# Preview what would be updated
fetch-opencode-models --free --dry-run

# Output to different file
fetch-opencode-models --free --output ./my-agents.yaml

# Then sync agents as usual
sync-agents
```

### Expected Output Format

When run successfully, the script should output:

```
[INFO] Fetching models from OpenCode Zen API...
[INFO] Found 3 free models: big-pickle, gpt-5-nano, minimax-m2.5-free
[INFO] Mapping models to agent types...
[INFO]   manager -> big-pickle
[INFO]   architect -> big-pickle
[INFO]   developer -> gpt-5-nano
[INFO]   tester -> gpt-5-nano
[INFO]   ...
[INFO] Writing configuration to .ralph/config/agents.yaml
[SUCCESS] Updated 11 agent configurations with free models
```

## API Reference

**Endpoint:** `GET https://opencode.ai/zen/v1/models`

**Response Format (expected):**
```json
{
  "data": [
    {
      "id": "big-pickle",
      "name": "Big Pickle",
      "pricing": {
        "input": 0,
        "output": 0,
        "cached_read": 0
      },
      "context_window": 128000,
      "capabilities": ["coding", "reasoning"]
    },
    {
      "id": "kimi-k2.5",
      "name": "Kimi K2.5",
      "pricing": {
        "input": 0.6,
        "output": 3.0,
        "cached_read": 0.08
      },
      "context_window": 262144
    }
  ]
}
```

**Free Model Identification:**
- Models where `pricing.input == 0` AND `pricing.output == 0`

## Dependencies

- `curl` or `wget` for HTTP requests
- `jq` for JSON parsing (preferred over `yq` for JSON)
- `yq` for YAML manipulation (already required by `sync-agents.sh`)

## Documentation Updates

Files that should reference this new capability:
- `docs/configuration.md` - Add section on auto-configuring free models
- `jeeves/bin/README.md` - Document the new script
- `README.md` - Mention in quick start/setup section

## Testing Checklist

- [ ] Script fetches models successfully from OpenCode API
- [ ] Free models are correctly identified (input/output = 0)
- [ ] Generated agents.yaml is valid YAML
- [ ] Existing Claude configurations are preserved
- [ ] Dry-run mode shows changes without writing
- [ ] Network errors are handled gracefully
- [ ] Script works on Linux, macOS, and WSL

## Alternatives Considered

### Alternative 1: Static List of Free Models
Maintain a hardcoded list of known free models in the repository.

- **Pros:** Simple, no network calls
- **Cons:** Quickly outdated, requires frequent updates

### Alternative 2: Document Manual Process
Just document how to manually find and configure free models.

- **Pros:** No code to maintain
- **Cons:** Poor user experience, barrier to entry

### Alternative 3: Integration with `opencode` CLI
Use the `opencode` CLI's `/models` command if available.

- **Pros:** Uses official tooling
- **Cons:** Requires `opencode` to be installed and configured first, may not expose free/paid distinction programmatically

**Selected:** Option B (New Script) - Best balance of automation and flexibility

## Additional Context

### OpenCode Zen Free Models (Subject to Change)

Current free models offered by OpenCode Zen (verify at https://opencode.ai/zen):
- `big-pickle` - Free (stealth model)
- `minimax-m2.5-free` - Free (limited time)
- `gpt-5-nano` - Free

These models are provided "as-is" during their free period and may change.

### Related Issues

- This would complement the existing [`sync-agents.sh`](jeeves/bin/sync-agents.sh) workflow
- May relate to container initialization in [`ralph-init.sh`](jeeves/bin/ralph-init.sh)

## Effort Estimate

- **Scope:** 1 new shell script (~150-200 lines) + documentation
- **Estimated Time:** 3-4 hours
- **Risk:** Low (adds new functionality, doesn't modify existing critical paths)

## Checklist

- [x] I've searched for similar feature requests
- [x] This feature improves the onboarding experience
- [x] This feature reduces manual configuration burden
- [x] This feature aligns with OpenCode's free tier offering
