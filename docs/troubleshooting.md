# Troubleshooting Guide

This document provides solutions to common issues and problems when using Jeeves.

## Container Issues

### Container Won't Start

#### Problem
```bash
./jeeves.ps1 start
# Error: container creation failed
```

#### Solutions

**1. Check Docker Status**
```bash
# Verify Docker is running
docker --version
docker info

# Check if Docker daemon is active
sudo systemctl status docker
```

**2. Check for Port Conflicts**
```bash
# Check if port 3333 is already in use
netstat -tlnp | grep 3333
# or
lsof -i :3333
```

**3. Free Up Port**
```bash
# Find and kill process using port
sudo fuser -k 3333/tcp
# or
sudo lsof -ti:3333 | xargs kill -9
```

**4. Rebuild Container**
```bash
# Clean rebuild
./jeeves.ps1 clean
./jeeves.ps1 build --no-cache
./jeeves.ps1 start
```

### Container Stops Immediately

#### Problem
Container starts but exits immediately without staying running.

#### Solutions

**1. Check Container Logs**
```bash
./jeeves.ps1 logs --tail 50
```

**2. Inspect Container**
```bash
docker inspect jeeves
```

**3. Run Interactively for Debugging**
```bash
docker run -it --rm jeeves:latest /bin/bash
```

**4. Check Entry Point**
```bash
# Verify entry script exists
docker run -it --entrypoint /bin/bash jeeves:latest ls -la /
```

### Permission Issues

#### File Permission Denied
```bash
# Error: permission denied when accessing files
```

#### Solutions

**1. Check User ID Mapping**
```bash
# Host user ID
id -u
id -g

# Container user ID  
docker exec jeeves id

# Fix mapping
export PUID=$(id -u)
export PGID=$(id -g)
./jeeves.ps1 stop
./jeeves.ps1 start
```

**2. Fix Volume Permissions**
```bash
# Check current permissions
ls -la ~/.opencode ~/.claude

# Fix ownership (Linux)
sudo chown -R $USER:$USER ~/.opencode ~/.claude

# Fix permissions
chmod 755 ~/.opencode ~/.claude
chmod 600 ~/.opencode/opencode.json ~/.claude/.claude.json
```

**3. Windows-Specific Issues**
```powershell
# Check file permissions on Windows
icacls ~/.opencode

# Fix Docker Desktop shared drives permissions
# In Docker Desktop settings, ensure file sharing is enabled
```

## OpenCode Issues

### OpenCode Not Found

#### Problem
```bash
opencode --version
# Error: command not found
```

#### Solutions

**1. Verify Installation**
```bash
# Check if OpenCode is installed
docker exec jeeves which opencode

# Check installation directory
docker exec jeeves ls -la /usr/local/bin/ | grep opencode

# Reinstall OpenCode
docker exec jeeves npm install -g @opencode-ai/opencode
```

**2. Check PATH**
```bash
# Verify OpenCode is in PATH
docker exec jeeves echo $PATH

# Update PATH temporarily
export PATH="/usr/local/bin:$PATH"
opencode --version
```

### API Connection Issues

#### Problem
```bash
opencode run "test message"
# Error: API connection failed, authentication error
```

#### Solutions

**1. Check API Key**
```bash
# Verify API key is set
opencode config show

# Set API key
opencode config set anthropic.api_key your-api-key-here

# Set via environment
export ANTHROPIC_API_KEY=your-api-key-here
```

**2. Test Network Connectivity**
```bash
# Test from container
docker exec jeeves curl -I https://api.anthropic.com

# Test DNS resolution
docker exec jeeves nslookup api.anthropic.com

# Check firewall
docker exec jeeves ping -c 3 api.anthropic.com
```

**3. Check API Status**
```bash
# Check Anthropic status page
curl -s https://status.anthropic.com

# Check rate limits
# Review API dashboard for usage
```

### Web UI Not Accessible

#### Problem
Cannot access http://localhost:3333

#### Solutions

**1. Check Container Status**
```bash
./jeeves.ps1 status
docker ps | grep jeeves
```

**2. Verify Port Binding**
```bash
docker port jeeves
# Should show: 3333/tcp -> 0.0.0.0:3333
```

**3. Check from Inside Container**
```bash
./jeeves.ps1 shell
netstat -tlnp | grep 3333
curl -I http://localhost:3333
```

**4. Check Firewall**
```bash
# Linux
sudo ufw status
sudo iptables -L

# Windows
# Check Windows Defender Firewall
# Check corporate firewall
```

## Claude Code Issues

### Claude Code Not Found

#### Problem
```bash
claude --version
# Error: command not found
```

#### Solutions

**1. Verify Installation**
```bash
# Check Claude installation
docker exec jeeves which claude

# Reinstall Claude Code
docker exec jeeves curl -fsSL https://claude.ai/install.sh | bash
```

**2. Alternative Installation Methods**
```bash
# Using npm
docker exec jeeves npm install -g @anthropic-ai/claude-code

# Using pip
docker exec jeeves pip install claude-code
```

### Authentication Issues

#### Problem
```bash
claude
# Error: authentication failed, invalid API key
```

#### Solutions

**1. Set API Key**
```bash
claude config set anthropic.api_key your-api-key-here
```

**2. Check Configuration**
```bash
claude config show
cat ~/.claude/.claude.json
```

## MCP Server Issues

### MCP Servers Not Working

#### Problem
```bash
opencode agent list
# No MCP servers shown
```

#### Solutions

**1. Check Installation**
```bash
# Test manual server installation
docker exec jeeves npx -y @modelcontextprotocol/server-sequential-thinking --help

# Check installation script
cd /usr/local/bin
./install-mcp-servers.sh --dry-run
./install-mcp-servers.sh --global
```

**2. Verify Configuration**
```bash
# OpenCode configuration
cat ~/.opencode/opencode.json | jq .mcp

# Claude configuration
cat ~/.claude/.claude.json | jq .mcpServers
```

**3. Test Individual Servers**
```bash
# Test sequential thinking
npx -y @modelcontextprotocol/server-sequential-thinking

# Test fetch server
mcp-server-fetch --help
```

### SearxNG Connection Issues

#### Problem
SearxNG MCP server cannot connect to search service.

#### Solutions

**1. Set SearxNG URL**
```bash
# Set environment variable
export SEARXNG_URL=https://search.example.com

# Set in configuration
opencode config set mcp.servers.searxng.environment.SEARXNG_URL https://search.example.com
```

**2. Use Public Instance**
```bash
# Set to public SearxNG instance
export SEARXNG_URL=https://search.brave.com
```

**3. Test Connection**
```bash
# Test SearxNG service
curl -I $SEARXNG_URL
```

### Playwright Issues

#### Problem
Playwright MCP server fails to start or browser automation doesn't work.

#### Solutions

**1. Install Browsers**
```bash
# Install Playwright browsers
docker exec jeeves npx playwright install

# With environment variables
PLAYWRIGHT_MCP_HEADLESS=1 npx playwright install
```

**2. Check Browser Path**
```bash
# Verify browser installation
docker exec jeeves ls -la $PLAYWRIGHT_MCP_HEADLESS

# Test manually
docker exec jeeves $PLAYWRIGHT_MCP_HEADLESS/ms-playwright --version
```

**3. Display Issues**
```bash
# If running in headless environment
export DISPLAY=:99
```

## Performance Issues

### Container is Slow

#### Problem
Container operations are sluggish, responses are delayed.

#### Solutions

**1. Check Resource Usage**
```bash
# Monitor container resources
docker stats jeeves

# Check system resources
htop
free -h
df -h
```

**2. Optimize Docker**
```bash
# Increase memory allocation
# In Docker Desktop settings: 4GB+ RAM

# Use SSD storage
# Ensure Docker uses SSD for better I/O

# Optimize Docker daemon
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "max-concurrent-downloads": 10
}
```

**3. Clean Up Docker**
```bash
# Remove unused images
docker image prune -f

# Clean up volumes
docker volume prune -f

# System cleanup
docker system prune -f
```

### High Memory Usage

#### Problem
Container consumes excessive memory.

#### Solutions

**1. Monitor Memory**
```bash
# Real-time monitoring
docker stats --format "table {{.Container}}\t{{.MemUsage}}"

# Check container limits
docker inspect jeeves | jq .HostConfig.Memory
```

**2. Reduce Memory Usage**
```bash
# Limit Node.js memory
export NODE_OPTIONS="--max-old-space-size=2048"

# Clean npm cache
docker exec jeeves npm cache clean --force

# Limit concurrent operations
opencode config set performance.max_concurrent_requests 5
```

## Network Issues

### Cannot Connect to Internet

#### Problem
Container cannot access external services.

#### Solutions

**1. Check DNS Configuration**
```bash
# Test DNS resolution
docker exec jeeves nslookup google.com

# Check resolv.conf
docker exec jeeves cat /etc/resolv.conf

# Set custom DNS
# docker-compose.yml
services:
  jeeves:
    dns:
      - 8.8.8.8
      - 1.1.1.1
```

**2. Check Network Connectivity**
```bash
# Test external connectivity
docker exec jeeves ping -c 3 8.8.8.8

# Check proxy settings
docker exec jeeves env | grep -i proxy
```

**3. Check Firewall**
```bash
# Check firewall status
sudo ufw status

# Check Docker network
docker network ls
docker network inspect jeeves_jeeves-network
```

### Port Forwarding Issues

#### Problem
Cannot access services from host machine.

#### Solutions

**1. Check Port Binding**
```bash
docker port jeeves
```

**2. Verify Network Access**
```bash
# Test from host
curl -I http://localhost:3333

# Test from other machines
curl -I http://your-host-ip:3333
```

## File System Issues

### Volume Mount Problems

#### Problem
Changes in container don't persist to host.

#### Solutions

**1. Check Volume Mounts**
```bash
docker inspect jeeves | jq .Mounts
```

**2. Verify Host Directory**
```bash
# Check if directory exists
ls -la /path/to/project

# Check permissions
ls -la /path/to/project
```

**3. Fix Permissions**
```bash
# Ensure ownership matches
sudo chown -R $USER:$USER /path/to/project

# Fix directory permissions
chmod 755 /path/to/project
```

### Disk Space Issues

#### Problem
Out of disk space preventing container operation.

#### Solutions

**1. Check Disk Usage**
```bash
df -h

# Check Docker space
docker system df
```

**2. Clean Up**
```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune -f

# Clean up build cache
docker builder prune -f
```

## Platform-Specific Issues

### Windows PowerShell Issues

#### Problem
```powershell
./jeeves.ps1
# Error: The term './jeeves.ps1' is not recognized as a cmdlet, function, operable program...
```

#### Solutions

**1. Use PowerShell Properly**
```powershell
# Use pwsh command if available
pwsh ./jeeves.ps1

# Or use full path
powershell -ExecutionPolicy Bypass -File ./jeeves.ps1
```

**2. Check Execution Policy**
```powershell
# Check current policy
Get-ExecutionPolicy

# Set for current session
Set-ExecutionPolicy -Scope Process -Bypass
```

### Linux/macOS Issues

#### Problem
PowerShell not available on Linux/macOS.

#### Solutions

**1. Install PowerShell Core**
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y powershell

# macOS
brew install powershell
```

**2. Use Alternative Shell**
```bash
# Convert to bash script
# Or use provided shell scripts directly
```

## Getting Help

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Enable debug logging
export DEBUG=1
export JEEVES_DEBUG=1

# Build with debug output
./jeeves.ps1 build --debug 2>&1 | tee build.log
```

### Log Collection

Collect diagnostic information:

```bash
# Container logs
./jeeves.ps1 logs > jeeves-debug.log 2>&1

# System information
docker info > docker-info.log
docker version > docker-version.log

# Configuration files
cat ~/.opencode/opencode.json > opencode-config.log
cat ~/.claude/.claude.json > claude-config.log
```

### Report Issues

When filing issues on [GitHub](https://github.com/SamAcctX/jeeves/issues), include:

- Operating system and version
- Docker version and configuration
- PowerShell version
- Complete error messages
- Steps to reproduce
- Expected vs actual behavior
- Diagnostic logs

### Community Support

- **GitHub Issues**: [Report bugs](https://github.com/SamAcctX/jeeves/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/SamAcctX/jeeves/discussions)
- **Documentation**: [Full docs](https://github.com/SamAcctX/jeeves/tree/main/docs)