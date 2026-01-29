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

# Stage 2: Runtime
FROM base AS runtime
# Final container setup with user and tools
```

#### Customization Options

**Adding System Packages:**
```dockerfile
RUN apt-get update && apt-get install -y \
    your-custom-package \
    && rm -rf /var/lib/apt/lists/*
```

**Setting Environment Variables:**
```dockerfile
ENV YOUR_CUSTOM_VAR="default_value"
ENV PATH="/usr/local/bin:${PATH}"
```

### Docker Compose Configuration

Generated dynamically in `.tmp/docker-compose.yml`:

```yaml
version: '3.8'

services:
  jeeves:
    build:
      context: .
      dockerfile: Dockerfile.jeeves
      target: runtime
    image: jeeves:latest
    container_name: jeeves
    ports:
      - "3333:3333"
    volumes:
      - ./:/proj
      - /home/jeeves/.opencode:/root/.opencode
      - /home/jeeves/.claude:/root/.claude
    environment:
      - PLAYWRIGHT_MCP_HEADLESS=1
      - SEARXNG_URL=${SEARXNG_URL:-}
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
    networks:
      - jeeves-network
    user: "${PUID}:${PGID}"
```

#### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./` | `/proj` | Project workspace |
| `/home/jeeves/.opencode` | `/root/.opencode` | OpenCode configuration |
| `/home/jeeves/.claude` | `/root/.claude` | Claude Code configuration |

#### Environment Variables

| Variable | Default | Description |
|----------|---------|---------|
| `PLAYWRIGHT_MCP_HEADLESS` | `1` | Playwright browser installation |
| `SEARXNG_URL` | (empty) | SearxNG search service URL |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |

## OpenCode Configuration

### Configuration File Location

- **File**: `~/.opencode/opencode.json`
- **Container Path**: `/root/.opencode/opencode.json`

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
    "servers": {
      "sequential-thinking": {
        "type": "local",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
        "environment": {}
      }
    }
  },
  "agents": {
    "directory": "/root/.opencode/agents"
  }
}
```

## Claude Code Configuration

### Configuration File Location

- **Primary**: `~/.claude/.claude.json`
- **Alternative**: `~/.claude/mcp.json`

### Basic Configuration Structure

```json
{
  "api_key": "sk-ant-api-key-here",
  "model": "claude-3-5-sonnet",
  "mcpServers": {
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
      "env": {}
    },
    "fetch": {
      "command": "mcp-server-fetch",
      "args": [],
      "env": {}
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
temperature: 0.7
permission:
  write: ask      # ask | allow | deny
  bash: ask       # ask | allow | deny
  webfetch: allow # ask | allow | deny
  edit: deny       # ask | allow | deny
tools: [read, write, grep, glob, bash, webfetch, question]
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