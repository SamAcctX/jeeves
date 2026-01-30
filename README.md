# Jeeves - Containerized AI Development Environment

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-purple.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-AGPLv3-green.svg)](https://github.com/SamAcctX/jeeves/blob/main/LICENSE)

> A sophisticated Docker-based development environment that containerizes OpenCode and Claude Code with pre-configured MCP servers and AI agents

## ✨ Key Features

- 🐳 **Containerized Environment** - Consistent, portable development setup with Ubuntu base
- 🤖 **Dual AI Platforms** - OpenCode and Claude Code with unified configuration
- 🛠️ **Pre-configured MCP Servers** - Sequential Thinking, Fetch, SearxNG, Playwright
- 🎯 **Specialized AI Agents** - PRD Creator and Deepest-Thinking research agent
- 🌐 **Web UI Access** - Browser-based development at http://localhost:3333
- ⚡ **Cross-platform Support** - Windows, Linux, and macOS with proper file permissions

## 🚀 Quick Start

### Prerequisites
- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **PowerShell 7.0+** for Windows, or **PowerShell Core** for cross-platform support
- **Git** for cloning repository
- **Sufficient disk space**: ~5GB recommended for container image

### Installation
```bash
# 1. Clone the repository
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves

# 2. Build the Docker image
./jeeves.ps1 build

# 3. Start the container
./jeeves.ps1 start

# 4. Access your development environment
# Web UI: http://localhost:3333
# Terminal: ./jeeves.ps1 shell
```

### Verification
```bash
# Check container status
./jeeves.ps1 status

# Access the terminal for verification
./jeeves.ps1 shell

# Inside the container, verify installations
opencode --version
claude --version
```

## 📖 What is Jeeves?

Jeeves is a comprehensive development environment that combines the power of AI coding assistants with specialized tools and agents. It provides:

- **Unified AI Experience**: Seamlessly switch between OpenCode and Claude Code
- **Enhanced Capabilities**: MCP servers provide web search, browser automation, and structured reasoning
- **Specialized Agents**: AI assistants for product requirements and deep research
- **Production-Ready Setup**: Optimized configurations for serious development work

### Why Use Jeeves?

- 🔄 **Consistency**: Same environment across all machines
- 🚀 **Productivity**: Pre-configured tools and agents ready to use
- 🔒 **Privacy**: Local container with optional cloud AI services
- 🎯 **Focus**: Spend time coding, not configuring

## 🏗️ Architecture Overview

```mermaid
graph LR
    A[🐳 Container] --> B[🤖 AI Platforms]
    A --> C[🔌 MCP Servers]
    A --> D[👤 User Access]
    A --> E[🎯 AI Agents]
    
    B --> B1[OpenCode]
    B --> B2[Claude Code]
    
    E --> E1[📋 PRD Creator]
    E --> E2[🔬 Deepest Thinking]
    
    C --> C1[🧠 Sequential Thinking]
    C --> C2[🌐 Fetch]
    C --> C3[🔍 SearxNG]
    C --> C4[🎭 Playwright]
    
    D --> D1[🌐 Web UI:3333]
    D --> D2[💻 CLI/TUI]
    D --> D3[🖥️ Shell]
```

## 🎯 Features Deep Dive

### AI Agents

#### PRD Creator
Helps beginner developers create comprehensive Product Requirements Documents through structured questioning and technology recommendations.

**Usage:**
```bash
# Inside the container
@prd-creator
```

#### Deepest-Thinking
Conducts exhaustive research investigations using systematic methodology and academic-style reporting.

**Usage:**
```bash
# Inside the container
@deepest-thinking
```

### MCP Servers

#### Sequential Thinking
Structured analysis and reasoning tool for complex problem-solving.

#### Fetch Server
Web content retrieval and processing with automatic markdown conversion.

#### SearxNG
Privacy-focused web search capabilities with customizable search engines.

#### Playwright
Browser automation and web interaction for testing and scraping.

### Development Environment

- **Container Features**: Ubuntu base with modern Python/Node.js toolchain
- **OpenCode Integration**: CLI, TUI, and Web UI interfaces
- **Claude Code Support**: Dual platform capabilities with shared configuration
- **File Management**: Volume mounts for workspace and configuration persistence

## 📋 Usage Guide

### PowerShell Management Script

The `jeeves.ps1` script provides comprehensive container management:

| Command | Alias | Description | Example |
|---------|-------|-------------|---------|
| `build` | `b` | Build Docker image | `./jeeves.ps1 build --no-cache --desktop` |
| `start` | `up` | Launch container | `./jeeves.ps1 start --clean` |
| `stop` | `down` | Stop container | `./jeeves.ps1 stop --remove` |
| `restart` | - | Restart container | `./jeeves.ps1 restart` |
| `shell` | `attach`, `sh` | Terminal access | `./jeeves.ps1 shell` |
| `logs` | - | View logs | `./jeeves.ps1 logs` |
| `status` | `st`, `ps` | Check status | `./jeeves.ps1 status` |
| `clean` | - | Cleanup | `./jeeves.ps1 clean` |

#### Interactive Mode
```powershell
# Run without arguments for interactive menu
./jeeves.ps1
```

#### Platform Requirements
- **Windows**: PowerShell 7.0+ (pre-installed on Windows 10+)
- **Linux/macOS**: Install PowerShell Core:
  ```bash
  # Ubuntu/Debian
  sudo apt-get update && sudo apt-get install -y powershell
  
  # macOS
  brew install powershell
  ```

### Development Workflows

#### Web UI Workflow
1. Start container: `./jeeves.ps1 start`
2. Open browser: http://localhost:3333
3. Use browser-based development environment
4. Leverage AI assistance directly in browser
5. Switch between AI agents as needed

#### Terminal Workflow
1. Get shell access: `./jeeves.ps1 shell`
2. Work in `/proj` directory (mounted workspace)
3. Use OpenCode CLI/TUI commands
4. Access tmux sessions for persistent work
5. Utilize pre-installed development tools

#### Agent-Assisted Development
1. **PRD Creation**: Use `@prd-creator` for project planning
2. **Research Tasks**: Use `@deepest-thinking` for comprehensive investigation
3. **Code Development**: Leverage OpenCode/Claude Code AI
4. **Tool Integration**: Use MCP servers for enhanced functionality

## ⚙️ Configuration & Customization

### Docker Configuration

#### Custom Dockerfile
Modify `Dockerfile.jeeves` to add custom tools or dependencies:

```dockerfile
# Add your custom tools
RUN apt-get update && apt-get install -y \
    your-tool \
    && rm -rf /var/lib/apt/lists/*
```

#### Environment Variables
Key environment variables in docker-compose:

```yaml
environment:
  - PLAYWRIGHT_MCP_HEADLESS=1
  - PLAYWRIGHT_MCP_BROWSER=chromium
  - PLAYWRIGHT_MCP_NO_SANDBOX=1
  - PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=1
  - OPENCODE_ENABLE_EXA=false
  - SEARXNG_URL=${SEARXNG_URL:-}
```

### Agent Configuration

#### Installing Custom Agents
```bash
# Inside the container
install-agents.sh --global
```

#### Agent Templates
Create custom agents in `.opencode/agents/` or `.claude/agents/`:

```yaml
---
description: "Your custom agent"
mode: subagent
temperature: 0.7
permission:
  write: ask      # ask | allow | deny
  bash: ask       # ask | allow | deny
  webfetch: allow # ask | allow | deny
tools: [read, write, grep, glob, bash, webfetch, question]
---
```

### MCP Server Configuration

#### Adding New MCP Servers
```bash
# Inside the container
install-mcp-servers.sh --global --dry-run
```

#### Manual Configuration
Edit `opencode.json` (OpenCode) or `.claude.json` (Claude Code):

```json
{
  "mcp": {
    "servers": {
      "sequentialthinking": {
        "type": "local",
        "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"]
      }
    }
  }
}
```

## 🔧 Advanced Topics

### Development & Debugging

#### Building from Source
```bash
# Rebuild with no cache
./jeeves.ps1 clean
./jeeves.ps1 build --no-cache

# Build with desktop applications
./jeeves.ps1 build --desktop
```

#### Performance Optimization
- **Docker Memory**: Allocate 4GB+ in Docker Desktop settings
- **Storage**: Use SSD for better I/O performance
- **CPU**: Allocate 2+ cores for compilation tasks

#### Security Considerations
- Container runs as non-root user
- File permissions properly mapped via UID/GID
- Network isolation via Docker bridge
- No sensitive data in container image

### Integration & Automation

#### CI/CD Integration
```bash
# Example GitHub Actions workflow
- name: Test with Jeeves
  run: |
    ./jeeves.ps1 start
    docker exec jeeves bash -c "opencode run 'run tests'"
    ./jeeves.ps1 stop
```

#### Scripting Examples
```powershell
# Automated development workflow
./jeeves.ps1 start
docker exec jeeves bash -c "cd /proj && npm install && npm test"
./jeeves.ps1 stop
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](https://github.com/SamAcctX/jeeves/blob/main/CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
# Clone repository
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves

# Create development branch
git checkout -b feature/your-feature-name

# Make changes and test
./jeeves.ps1 build --no-cache
./jeeves.ps1 start

# Submit pull request
git add .
git commit -m "Add your feature"
git push origin feature/your-feature-name
```

## 📚 Reference Documentation

- [Command Reference](docs/commands.md)
- [Configuration Reference](docs/configuration.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🆘 Community & Support

- **Issues**: [GitHub Issues](https://github.com/SamAcctX/jeeves/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SamAcctX/jeeves/discussions)
- **Documentation**: [Full Docs](https://github.com/SamAcctX/jeeves/tree/main/docs)

## 📄 License & Legal

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](https://github.com/SamAcctX/jeeves/blob/main/LICENSE) file for details.

### Third-Party Licenses
- **OpenCode**: MIT License
- **Claude Code**: Commercial License (Terms of Service)
- **MCP Servers**: Various Open Source Licenses

---

**Built with ❤️ by the Jeeves team**

*Get productive instantly with AI-powered development in a container*