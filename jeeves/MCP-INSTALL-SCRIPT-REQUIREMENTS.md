# MCP Installation Script Requirements

## Overview
Create a BASH script to pre-install and configure MCP (Model Context Protocol) servers for both OpenCode and Claude Code. The script supports both project-local and user/global scope installations.

## Configuration Files

### OpenCode

#### Global Scope
- **Path**: `~/.config/opencode/opencode.json`
- **Structure**: 
  ```json
  {
    "$schema": "https://opencode.ai/config.json",
    "mcp": {
      "server-name": {
        "type": "local",
        "command": ["npx", "-y", "package-name"],
        "environment": {
          "ENV_VAR": "value"
        }
      }
    }
  }
  ```

#### Project Scope
- **Path**: `./opencode.json` (in current directory)
- **Structure**: Same as global scope (including `$schema` field)

### Claude Code

#### Global Scope
- **Path**: `~/.claude.json`
- **Structure**:
  ```json
  {
    "mcpServers": {
      "server-name": {
        "command": ["npx", "-y", "package-name"],
        "args": ["optional", "args"],
        "env": {
          "ENV_VAR": "value"
        }
      }
    }
  }
  ```

#### Project Scope
- **Path**: `./.mcp.json` (in current directory)
- **Structure**: Same as global scope (no top-level fields)

## MCP Servers to Install

1. **sequentialthinking**
   - OpenCode: `@modelcontextprotocol/server-sequential-thinking`
   - Claude Code: `@modelcontextprotocol/server-sequential-thinking`

2. **fetch**
   - OpenCode: `python -m mcp_server_fetch`
   - Claude Code: `python -m mcp_server_fetch`

3. **searxng**
   - Prompt user for SEARXNG_URL
   - OpenCode: `mcp-searxng` with user-provided `SEARXNG_URL`
   - Claude Code: `mcp-searxng` with user-provided `SEARXNG_URL`

## Script Behavior Requirements

### 1. Scope Selection
- **Default**: Project-local scope (install in current directory)
- **Flag**: `--global` to install in user/global scope
- **Behavior**: 
  - Project scope: Use `./opencode.json` (OpenCode) and `./.mcp.json` (Claude Code)
  - Global scope: Use `~/.config/opencode/opencode.json` (OpenCode) and `~/.claude.json` (Claude Code)

### 2. File Handling
- **OpenCode**: 
  - Check if config file exists
  - If exists: merge MCP configurations, avoid duplicates
  - If not exists: create fresh config file with MCP section

- **Claude Code**:
  - Check if config file exists
  - If exists: merge `mcpServers` configurations, avoid duplicates
  - If not exists: create fresh config file with `mcpServers` section

### 3. Merging Logic
- **For OpenCode**: Merge into `mcp` object, check for existing server names
- **For Claude Code**: Merge into `mcpServers` object, check for existing server names
- **Preserve**: All other config sections (providers, settings, etc.)
- **Avoid**: Duplicate MCP entries with same server names

### 4. Backup Functionality
- Before modifying existing config files, create a backup:
  - Project scope: `./opencode.json.backup` or `./.mcp.json.backup`
  - Global scope: `~/.config/opencode/opencode.json.backup` or `~/.claude.json.backup`
- Backup timestamp included in filename

### 5. Dry-Run/Preview Mode
- Flag: `--dry-run` to preview changes without modifying files
- Output: Show what would be added/modified without writing to files
- Useful for testing and verification

### 6. JSON Validation
- Ensure all JSON files remain valid after modifications
- Use `jq` for JSON parsing and manipulation (if available)
- Fallback to `python -m json.tool` if `jq` not available

### 7. Error Handling
- Check if required tools are installed (Node.js, Python, npx)
- Handle permission errors when writing config files
- Provide clear error messages for each failure scenario
- Log successful installations

### 8. Idempotency
- Script should be safe to run multiple times
- No changes if MCPs are already configured
- No destructive operations

### 9. Output
- Display progress messages for each MCP being installed
- Show success/failure for each configuration file
- Provide summary at the end
- In dry-run mode, show preview of changes

## Script Features

### Required Features
- **Scope Selection**: Default to project scope, with `--global` flag for user scope
- **Backup**: Create timestamped backups before modifying existing configs
- **Dry-Run**: Preview mode with `--dry-run` flag
- **Merging**: Smart merging of MCP configurations without duplicates
- **JSON Validation**: Ensure valid JSON after modifications
- **Error Handling**: Clear error messages and dependency checks
- **Idempotency**: Safe to run multiple times

### Optional Features (to be determined)
- Custom MCP server list (command-line arguments)
- Logging to file
- Verification of MCP server functionality after installation
- Interactive mode for searxng URL input

## Dependencies
- `jq` (preferred for JSON manipulation)
- `python` (for JSON validation and fallback)
- `npx` (for Node.js package execution)
- `node` (for running MCP servers)

## Example Usage

### Project-local scope (default)
```bash
./install-mcp-servers.sh
```

### Global scope
```bash
./install-mcp-servers.sh --global
```

### Dry-run mode
```bash
./install-mcp-servers.sh --dry-run
```

### Global scope with dry-run
```bash
./install-mcp-servers.sh --global --dry-run
```

## Testing Requirements
- Test with existing config files (verify merging works)
- Test with non-existent config files (verify creation works)
- Test with duplicate MCP entries (verify no duplicates added)
- Test with invalid JSON (verify error handling)
- Test on clean system (verify all MCPs installed correctly)
- Test project scope installation (default behavior)
- Test global scope installation with `--global` flag
- Test dry-run mode (preview without modifications)
- Test backup functionality (verify backups created)
- Test idempotency (run multiple times, verify no changes)
- Test searxng URL prompt (interactive input)
