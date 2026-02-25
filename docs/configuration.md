# Configuration Reference

This document provides detailed information about configuring Jeeves, including Docker, agents, MCP servers, and development environment settings.

## Docker Configuration

### Dockerfile.jeeves

The main Docker build file defines the Jeeves container environment.

#### Build Stages

```dockerfile
# Stage 1: Base system
FROM ubuntu:latest AS base
# System packages and Python/Node.js setup

# Stage 2: Builder
FROM base AS opencode-builder
# Builds OpenCode from source with optional desktop binaries

# Stage 3: Runtime
FROM base AS runtime
# Final container setup with user and tools
```

#### Customization Options

**Adding System Packages:**
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        your-custom-package \
        && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

**Setting Environment Variables:**
```dockerfile
ENV YOUR_CUSTOM_VAR="default_value"
ENV PATH="/usr/local/bin:${PATH}"
```

### Docker Compose Configuration

Generated dynamically in `.tmp/docker-compose.yml`:

```yaml
services:
  jeeves:
    build:
      context: ..
      dockerfile: Dockerfile.jeeves
    environment:
      - PLAYWRIGHT_MCP_HEADLESS=1
      - PLAYWRIGHT_MCP_BROWSER=chromium
      - PLAYWRIGHT_MCP_NO_SANDBOX=1
      - PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1
      - OPENCODE_ENABLE_EXA=false
    volumes:
      - $(pwd):/proj:rw
      - ~/.claude:/home/jeeves/.claude:rw
      - ~/.config/opencode:/home/jeeves/.config/opencode:rw
      - ~/.opencode:/home/jeeves/.opencode:rw
    ports:
      - "3333:3333"
    networks:
      - jeeves-network

networks:
  jeeves-network:
    driver: bridge
```

#### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `$(pwd)` | `/proj` | Project workspace |
| `~/.claude` | `/home/jeeves/.claude` | Claude Code configuration |
| `~/.config/opencode` | `/home/jeeves/.config/opencode` | OpenCode configuration |
| `~/.opencode` | `/home/jeeves/.opencode` | OpenCode agent directory |

#### Environment Variables

| Variable | Default | Description |
|----------|---------|---------|
| `PLAYWRIGHT_MCP_HEADLESS` | `1` | Playwright headless mode |
| `PLAYWRIGHT_MCP_BROWSER` | `chromium` | Default Playwright browser |
| `PLAYWRIGHT_MCP_NO_SANDBOX` | `1` | Disable browser sandbox |
| `PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS` | `1` | Allow file access |
| `OPENCODE_ENABLE_EXA` | `false` | Disable Exa web search |
| `SEARXNG_URL` | (empty) | SearxNG search service URL |

## OpenCode Configuration

### Configuration File Location

- **File**: `~/.config/opencode/opencode.json`
- **Container Path**: `/home/jeeves/.config/opencode/opencode.json`

### Basic Configuration Structure

```json
{
  "version": "1.0",
  "model": "anthropic/claude-3-5-sonnet",
  "providers": {
    "anthropic": {
      "api_key": "your-api-key-here"
    }
  },
  "mcp": {
    "sequentialthinking": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

## Claude Code Configuration

### Configuration File Location

- **Global**: `~/.claude.json`
- **Project**: `.mcp.json`
- **Container Path**: `/home/jeeves/.claude/.claude.json`

### Basic Configuration Structure

```json
{
  "api_key": "sk-ant-api-key-here",
  "model": "claude-3-5-sonnet",
  "mcpServers": {
    "sequentialthinking": {
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "fetch": {
      "command": ["python", "-m", "mcp_server_fetch"]
    }
  }
}
```

## Agent Configuration

### Agent Template Structure

```yaml
---
description: "Brief description of agent capabilities"
mode: subagent

permission:
  write: ask
  bash: ask
  webfetch: allow
  edit: deny
tools:
  read: true
  write: true
  grep: true
  glob: true
  bash: true
  webfetch: true
  question: true
  sequentialthinking: true
---
```

### Permission Levels

- **ask**: Prompt user for approval before executing
- **allow**: Automatically allow without confirmation
- **deny**: Never allow to tool/operation

### Available Tools

| Tool | Description | Permission Recommendation |
|------|-------------|----------------------|
| `read` | Read files from filesystem | allow (safe) |
| `write` | Write files to filesystem | ask (data loss risk) |
| `grep` | Search file contents | allow (safe) |
| `glob` | Find files by pattern | allow (safe) |
| `bash` | Execute shell commands | ask (security risk) |
| `webfetch` | Retrieve web content | allow (external data) |
| `websearch` | Search the web | ask (rate limits) |
| `codesearch` | Search code repositories | allow (computation) |
| `question` | Ask user questions | allow (interactive) |
| `edit` | Edit file contents | ask (destructive) |
| `sequentialthinking` | Structured analysis | allow (computation) |

## Performance Configuration

### Docker Resource Limits

```yaml
# docker-compose.yml
services:
  jeeves:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
```

### OpenCode Performance

```json
{
  "performance": {
    "max_concurrent_requests": 10,
    "request_timeout": 30000,
    "cache_size": 1000,
    "enable_caching": true
  }
}
```

## Security Configuration

### Docker Security

```yaml
# docker-compose.yml
services:
  jeeves:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    user: "1000:1000"
```

## Troubleshooting Configuration

### Common Issues

#### API Key Problems
```bash
# Test API key
curl -X POST https://api.anthropic.com/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: your-key-here" \
  -d '{"model": "claude-3-haiku", "max_tokens": 10, "messages": [{"role": "user", "content": "Hi"}]}'

# Check configuration
opencode config show
claude config show
```

## Advanced Configuration

### Custom MCP Servers

#### Creating Custom Server
```json
{
  "mcp": {
    "servers": {
      "your-custom-server": {
        "type": "local",
        "command": "your-server-command",
        "args": ["--arg1", "--arg2"],
        "environment": {
          "CUSTOM_VAR": "value",
          "PATH": "/custom/path:$PATH"
        }
      }
    }
  }
}
```

## Development Environment Configuration

### Shell Environment

#### Bash Configuration (.bashrc)

```bash
# Custom aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Environment variables
export EDITOR=vim
export BROWSER=/usr/bin/w3m

# Docker detection
if [ -f /.dockerenv ]; then
    echo "🐳 Running in Docker container"
fi
```

#### Git Configuration

```bash
# Identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Performance
git config --global core.preloadindex true
git config --global core.fscache true

# Merge strategy
git config --global merge.ff only
```

For additional configuration examples, see the [troubleshooting guide](https://github.com/SamAcctX/jeeves/blob/main/docs/troubleshooting.md).