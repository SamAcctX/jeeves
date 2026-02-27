# Configuration Reference

This document provides detailed information about configuring Jeeves and the Ralph Loop, including Docker, agents, MCP servers, and development environment settings.

## Ralph Loop Configuration

### Ralph Directory Structure

The Ralph Loop creates and uses a `.ralph/` directory structure in your project root:

```
.ralph/
├── config/
│   ├── agents.yaml          # Agent model mappings
│   └── deps-tracker.yaml    # Task dependencies
├── prompts/
│   └── ralph-prompt.md      # Ralph Loop prompt
├── specs/
│   └── PRD-*.md             # Product Requirements Documents
├── tasks/
│   ├── TODO.md              # Task checklist
│   ├── done/                # Completed tasks (preserved)
│   └── XXXX/                # Individual task folders
└── logs/
    └── ralph-loop-YYYYMMDD-HHMMSS.log  # Loop execution logs
```

### agents.yaml Configuration

Defines model mappings for each agent type:

```yaml
# .ralph/config/agents.yaml

# Default model for all agents
default:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Manager agent - orchestrates task execution
manager:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Architect agent - system design and architecture planning
architect:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Developer agent - code implementation and debugging
developer:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Tester agent - QA, test creation, and validation
tester:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# UI Designer agent - interface design and responsive layout
ui-designer:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Researcher agent - investigation and documentation
researcher:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Writer agent - content creation and editing
writer:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Decomposer agent - task breakdown and TODO management
decomposer:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# PRD Creator agent - Product Requirements Document creation
prd-creator:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1

# Deepest-Thinking agent - comprehensive research and investigation
deepest-thinking:
  model: "anthropic/claude-3-5-sonnet"
  temperature: 0.1
```

### deps-tracker.yaml Configuration

Tracks task dependencies:

```yaml
# .ralph/config/deps-tracker.yaml

dependencies:
  "0001": []
  "0002": ["0001"]
  "0003": ["0001"]
  "0004": ["0002", "0003"]

metadata:
  generated: "2024-01-01T00:00:00Z"
  version: 1
```

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
    image: jeeves:latest
    runtime: nvidia
    shm_size: "2gb"
    gpus: all
    environment:
      - NVIDIA_DRIVER_CAPABILITIES=all
      - CUDA_VISIBLE_DEVICES=all
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
    # Docker-in-Docker support (only added when --dind flag is used)
    # privileged: true
    # environment:
    #   - ENABLE_DIND=true

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
| `ENABLE_DIND` | `false` | Enable Docker-in-Docker support |

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
    },
    "fetch": {
      "type": "local",
      "command": ["python", "-m", "mcp_server_fetch"]
    },
    "searxng": {
      "type": "local",
      "command": ["npx", "-y", "mcp-searxng"],
      "environment": {
        "SEARXNG_URL": "https://searxng.example.com"
      }
    },
        "playwright": {
          "type": "local",
          "command": ["npx", "-y", "@playwright/mcp@latest", "--isolated", "--no-sandbox"],
          "environment": {
            "PLAYWRIGHT_MCP_HEADLESS": "true",
            "PLAYWRIGHT_MCP_BROWSER": "chromium"
          }
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
    },
    "searxng": {
      "command": ["npx", "-y", "mcp-searxng"],
      "env": {
        "SEARXNG_URL": "https://searxng.example.com"
      }
    },
    "playwright": {
      "command": ["npx", "-y", "@playwright/mcp@latest", "--isolated", "--no-sandbox"],
      "env": {
        "PLAYWRIGHT_MCP_HEADLESS": "true",
        "PLAYWRIGHT_MCP_BROWSER": "chromium",
        "PLAYWRIGHT_MCP_NO_SANDBOX": "true",
        "PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS": "true"
      }
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

For additional configuration examples, see the [troubleshooting guide](troubleshooting.md).
