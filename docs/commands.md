# Command Reference

This document provides a comprehensive reference for all Jeeves commands and their options.

## PowerShell Management Script (`jeeves.ps1`)

The main script for managing the Jeeves Docker container and development environment.

### Core Commands

#### `build`
Build Docker image with optional customizations.

```powershell
./jeeves.ps1 build [--no-cache] [--desktop]
```

**Options:**
- `--no-cache`: Build without using cache layers
- `--desktop`: Include desktop application builds

**Examples:**
```powershell
# Standard build
./jeeves.ps1 build

# Clean build without cache
./jeeves.ps1 build --no-cache

# Build with desktop applications
./jeeves.ps1 build --desktop
```

#### `start`
Launch the Jeeves container with volume mounting and networking.

```powershell
./jeeves.ps1 start [--clean]
```

**Options:**
- `--clean`: Rebuild image before starting

**Examples:**
```powershell
# Start container
./jeeves.ps1 start

# Rebuild and start
./jeeves.ps1 start --clean
```

#### `stop`
Stop the running Jeeves container.

```powershell
./jeeves.ps1 stop [--remove]
```

**Options:**
- `--remove`: Remove container after stopping

**Examples:**
```powershell
# Stop container
./jeeves.ps1 stop

# Stop and remove
./jeeves.ps1 stop --remove
```

#### `restart`
Restart the Jeeves container.

```powershell
./jeeves.ps1 restart
```

#### `shell`
Get interactive bash access to the container.

```powershell
./jeeves.ps1 shell
```

#### `logs`
View real-time container logs.

```powershell
./jeeves.ps1 logs
```

#### `status`
Display container and image status information.

```powershell
./jeeves.ps1 status
```

#### `clean`
Remove all Jeeves containers and images.

```powershell
./jeeves.ps1 clean
```

### Interactive Mode

Running the script without arguments displays an interactive menu:

```powershell
./jeeves.ps1
```

## Container Commands

### OpenCode Commands

#### CLI Usage
```bash
# Start TUI (default)
opencode

# Run single command
opencode run "explain how closures work in JavaScript"

# Use specific model
opencode --model anthropic/claude-3-5-sonnet

# Start web server
opencode web --port 3333 --hostname 0.0.0.0
```

#### Agent Management
```bash
# List available agents
opencode agent list

# Use specific agent
@prd-creator
@deepest-thinking
```

#### Session Management
```bash
# Continue last session
opencode --continue

# Start specific session
opencode --session session-id-here

# List sessions
opencode session list
```

#### TUI Commands
```bash
# Navigate in TUI
? - Show help
q - Quit
/ - Search
: - Command mode
```

### Claude Code Commands

#### Basic Usage
```bash
# Start interactive session
claude

# Ask question
claude "how do I implement authentication?"

# Edit file
claude --edit filename.js

# Show context
claude show-context
```

#### Project Management
```bash
# Initialize project
claude init

# Add files to context
claude add-context README.md src/

# Remove from context
claude remove-context README.md

# Show context
claude show-context
```

## Installation Scripts

### MCP Server Installation (`install-mcp-servers.sh`)

```bash
# Install all MCP servers globally
./install-mcp-servers.sh --global

# Install with dry run (preview)
./install-mcp-servers.sh --global --dry-run
```

**Supported Servers:**
- `sequential-thinking`: Structured analysis and reasoning
- `fetch`: Web content retrieval
- `searxng`: Privacy-focused search
- `playwright`: Browser automation

### Agent Installation (`install-agents.sh`)

```bash
# Install all agents globally
./install-agents.sh --global
```

**Available Agents:**
- `prd-creator`: Product Requirements Document creator
- `deepest-thinking`: Research and investigation agent

## Docker Commands

### Manual Container Management

```bash
# Build image manually
docker build -f Dockerfile.jeeves -t jeeves:latest

# Run container manually
docker run -it --name jeeves \
  -p 3333:3333 \
  -v $(pwd):/proj \
  -v /home/jeeves/.opencode:/root/.opencode \
  -v /home/jeeves/.claude:/root/.claude \
  jeeves:latest

# View logs
docker logs -f jeeves

# Execute command in container
docker exec -it jeeves bash -c "your command here"

# Stop container
docker stop jeeves

# Remove container
docker rm jeeves

# Remove image
docker rmi jeeves:latest
```

### Docker Compose

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild and start
docker compose up -d --build
```

## Configuration Commands

### OpenCode Configuration

```bash
# View configuration
opencode config show

# Set configuration value
opencode config set key value

# Edit configuration
opencode config edit
```

### Claude Code Configuration

```bash
# View configuration
claude config show

# Set API key
claude config set anthropic.api_key your-key-here
```

## Environment Variables

### Docker Environment

```bash
# Set user ID for file permissions
export PUID=$(id -u)
export PGID=$(id -g)
```

### OpenCode Environment

```bash
# Configuration directory
export OPENCODE_CONFIG_DIR=/root/.opencode

# Web UI port
export OPENCODE_WEB_PORT=3333
```

### Claude Code Environment

```bash
# API key
export ANTHROPIC_API_KEY=your-key-here
```

## Troubleshooting Commands

### Container Issues

```bash
# Check if Docker is running
docker --version
docker info

# Check container status
docker ps -a | grep jeeves

# Check resource usage
docker stats jeeves

# Check disk space
df -h

# Clean Docker system
docker system prune -f
```

### Network Issues

```bash
# Test DNS resolution
docker exec jeeves nslookup google.com

# Check network connectivity
docker exec jeeves ping -c 3 8.8.8.8

# Check firewall (Linux)
sudo ufw status
```

### Permission Issues

```bash
# Check file permissions
ls -la /proj

# Fix ownership (Linux)
sudo chown -R $USER:$USER /proj
```

## Exit Codes

| Code | Meaning | Action |
|-------|---------|--------|
| 0 | Success | Operation completed |
| 1 | General Error | Check error message |
| 2 | Invalid Arguments | Check command syntax |
| 3 | Docker Not Available | Install/start Docker |
| 4 | Container Not Found | Build/start container |
| 5 | Permission Denied | Check Docker permissions |

## Help and Support

For additional help:
- Check the [troubleshooting guide](https://github.com/SamAcctX/jeeves/blob/main/docs/troubleshooting.md)
- Open an issue on [GitHub Issues](https://github.com/SamAcctX/jeeves/issues)
- Review the [main documentation](../README.md)

### Quick Reference

| Need to... | Use this command |
|-------------|------------------|
| Start development | `./jeeves.ps1 start` |
| Access terminal | `./jeeves.ps1 shell` |
| Check status | `./jeeves.ps1 status` |
| View logs | `./jeeves.ps1 logs` |
| Stop container | `./jeeves.ps1 stop` |
| Rebuild image | `./jeeves.ps1 build --no-cache` |
| Clean up | `./jeeves.ps1 clean` |