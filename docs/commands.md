# Command Reference

This document provides a comprehensive reference for all Jeeves and Ralph commands and their options.

## Jeeves PowerShell Management Script (`jeeves.ps1`)

The main script for managing the Jeeves Docker container and development environment.

### Core Commands

#### `build`
Build Docker image with optional customizations.

```powershell
./jeeves.ps1 build [--no-cache] [--desktop] [--install-claude-code]
```

**Options:**
- `--no-cache`: Build without using cache layers
- `--desktop`: Include desktop application builds
- `--install-claude-code`: Install Claude Code in the container

**Examples:**
```powershell
# Standard build
./jeeves.ps1 build

# Clean build without cache
./jeeves.ps1 build --no-cache

# Build with desktop applications
./jeeves.ps1 build --desktop

# Build with Claude Code
./jeeves.ps1 build --install-claude-code
```

#### `start`
Launch the Jeeves container with volume mounting and networking.

```powershell
./jeeves.ps1 start [--clean] [--dind]
```

**Options:**
- `--clean`: Rebuild image before starting
- `--dind`: Enable Docker-in-Docker (DinD) support

**Examples:**
```powershell
# Start container
./jeeves.ps1 start

# Rebuild and start
./jeeves.ps1 start --clean

# Start with Docker-in-Docker support
./jeeves.ps1 start --dind
```

#### `stop`
Stop the running Jeeves container.

```powershell
./jeeves.ps1 stop [--remove] [--force]
```

**Options:**
- `--remove`: Remove container after stopping
- `--force`: Force stop using SIGKILL instead of graceful SIGTERM

**Examples:**
```powershell
# Stop container
./jeeves.ps1 stop

# Stop and remove
./jeeves.ps1 stop --remove

# Force stop
./jeeves.ps1 stop --force
```

#### `restart`
Restart the Jeeves container.

```powershell
./jeeves.ps1 restart [--no-cache] [--desktop] [--install-claude-code] [--dind]
```

**Options:**
- `--no-cache`: Build without using cache layers (when rebuilding)
- `--desktop`: Include desktop application builds (when rebuilding)
- `--install-claude-code`: Install Claude Code in the container (when rebuilding)
- `--dind`: Enable Docker-in-Docker (DinD) support

#### `shell`
Get interactive bash access to the container.

```powershell
./jeeves.ps1 shell [--new]
```

**Options:**
- `--new`: Stop and remove existing container before entering

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

#### `rm`
Remove the Jeeves container (stops if running).

```powershell
./jeeves.ps1 rm
```

### Interactive Mode

Running the script without arguments displays an interactive menu:

```powershell
./jeeves.ps1
```

## Ralph Loop Commands

### `ralph-init.sh`
Initialize Ralph project scaffolding.

```bash
ralph-init.sh [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help message
- `--force`, `-f`: Skip overwrite prompts
- `--rules`: Force RULES.md creation

**Examples:**
```bash
# Interactive setup
ralph-init.sh

# Force overwrite existing files
ralph-init.sh --force

# Force RULES.md creation
ralph-init.sh --rules
```

**What it does:**
- Validates required tools (yq, jq, git)
- Creates Ralph directory structure
- Copies configuration templates
- Sets up agent and skill directories
- Configures git integration
- Runs installation scripts

### `ralph-loop.sh`
Main loop orchestration script for autonomous task execution.

```bash
ralph-loop.sh [OPTIONS]
```

**Options:**
- `-t, --tool {opencode|claude}`: Select AI tool (default: opencode)
- `-m, --max-iterations N`: Maximum iterations (default: 100, 0=unlimited)
- `-s, --skip-sync`: Skip pre-loop agent synchronization
- `-n, --no-delay`: Disable backoff delays
- `-d, --dry-run`: Print commands without executing
- `-v, --verbose`: Enable JSON format output in OpenCode
- `-h, --help`: Show this help message

**Examples:**
```bash
# Default execution with OpenCode
ralph-loop.sh

# Use Claude Code instead of OpenCode
ralph-loop.sh --tool claude

# Limit to 50 iterations
ralph-loop.sh --max-iterations 50

# Skip agent synchronization
ralph-loop.sh --skip-sync

# Disable backoff delays
ralph-loop.sh --no-delay

# Dry run mode
ralph-loop.sh --dry-run
```

**Environment Variables:**
- `RALPH_TOOL`: Default tool selection
- `RALPH_MAX_ITERATIONS`: Maximum loop iterations
- `RALPH_BACKOFF_BASE`: Backoff base delay (default: 2)
- `RALPH_BACKOFF_MAX`: Backoff max delay (default: 60)
- `RALPH_MANAGER_MODEL`: Override Manager model

**Logging:**
A log file with timestamps is automatically created at:
`.ralph/logs/ralph-loop-YYYYMMDD-HHMMSS.log`

### `sync-agents.sh`
Synchronize agent model configurations from agents.yaml to agent files.

```bash
sync-agents.sh [OPTIONS]
```

**Options:**
- `--help`, `-h`: Show help message
- `--tool TOOL`, `-t`: Specify tool (opencode|claude)
- `--config FILE`, `-c`: Custom agents.yaml path
- `--show`, `-s`: Show parsed agents (don't sync)
- `--dry-run`, `-d`: Show what would be updated

**Examples:**
```bash
# Sync agents for default tool (OpenCode)
sync-agents.sh

# Sync agents for Claude Code
sync-agents.sh --tool claude

# Show what would be updated (dry run)
sync-agents.sh --dry-run

# Show parsed agents without syncing
sync-agents.sh --show
```

## Container Installation Scripts

### MCP Server Installation (`install-mcp-servers.sh`)

```bash
# Install all MCP servers in project scope
./install-mcp-servers.sh

# Install all MCP servers globally
./install-mcp-servers.sh --global

# Install with dry run (preview)
./install-mcp-servers.sh --global --dry-run
```

**Supported Servers:**
- `sequentialthinking`: Structured analysis and reasoning
- `fetch`: Web content retrieval
- `searxng`: Privacy-focused search
- `playwright`: Browser automation

### Agent Installation (`install-agents.sh`)

```bash
# Install all agents (PRD Creator and Deepest-Thinking) in project scope
install-agents.sh

# Install all agents globally
install-agents.sh --global

# Install only Deepest-Thinking agent
install-agents.sh --deepest

# Show usage information
install-agents.sh --help
```

**Available Agents:**
- `prd-creator`: Product Requirements Document creator
- `deepest-thinking`: Research and investigation agent

### Skill Dependency Installation (`install-skill-deps.sh`)

Installs dependencies for Ralph skills.

```bash
./install-skill-deps.sh
```

## OpenCode Commands

### CLI Usage

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

### Agent Management

```bash
# List available agents
opencode agent list

# Use specific agent
@prd-creator
@deepest-thinking
@manager
```

### Session Management

```bash
# Continue last session
opencode --continue

# Start specific session
opencode --session session-id-here

# List sessions
opencode session list
```

### TUI Commands

```bash
# Navigate in TUI
? - Show help
q - Quit
/ - Search
: - Command mode
```

## Claude Code Commands

### Basic Usage

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

### Project Management

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

## Docker Commands

### Manual Container Management

```bash
# Build image manually
docker build -f Dockerfile.jeeves -t jeeves:latest

# Run container manually
docker run -it --name jeeves \
  -p 3333:3333 \
  -v $(pwd):/proj \
  -v ~/.config/opencode:/home/jeeves/.config/opencode \
  -v ~/.claude:/home/jeeves/.claude \
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

networks:
  jeeves-network:
    driver: bridge
```

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
export UID=$(id -u)
export GID=$(id -g)
```

### OpenCode Environment

```bash
# Configuration directory
export OPENCODE_CONFIG_DIR=/home/jeeves/.config/opencode

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
| 0 | Success | Operation completed successfully |
| 1 | Error | Operation failed - check error message for details |

**Note:** The script currently uses simplified exit codes (0 for success, 1 for any error). Check the error message output for specific failure details.

## Help and Support

For additional help:
- Check the [troubleshooting guide](troubleshooting.md)
- Open an issue on [GitHub Issues](https://github.com/SamAcctX/jeeves/issues)
- Review the [main documentation](README.md)

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
| Initialize Ralph project | `ralph-init.sh` |
| Start Ralph Loop | `ralph-loop.sh` |
| Sync agents | `sync-agents.sh` |
