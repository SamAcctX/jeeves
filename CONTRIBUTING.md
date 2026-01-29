# Contributing to Jeeves

Thank you for your interest in contributing to Jeeves! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **PowerShell 7.0+** for Windows, or **PowerShell Core** for cross-platform support
- **Git** for version control
- **Basic knowledge** of containerization and AI development tools

### Platform-Specific Setup

#### Windows
1. **Install Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop)
2. **PowerShell is pre-installed** on Windows 10+
3. **Git for Windows**: [git-scm.com](https://git-scm.com/download/win)

#### macOS
1. **Install Docker Desktop** for Mac from [docker.com](https://www.docker.com/products/docker-desktop)
2. **Install PowerShell Core**:
   ```bash
   brew install powershell
   ```
3. **Git for macOS**: [git-scm.com](https://git-scm.com/download/mac)

#### Linux (Ubuntu/Debian)
1. **Install Docker Engine**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose
   sudo usermod -aG docker $USER
   ```
2. **Install PowerShell Core**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install -y powershell
   
   # CentOS/RHEL/Fedora
   sudo yum install -y powershell
   sudo dnf install -y powershell
   ```
3. **Git for Linux**: 
   ```bash
   sudo apt-get install -y git
   ```

### Development Setup

1. **Fork and Clone**
```bash
git clone https://github.com/SamAcctX/jeeves.git
cd jeeves
```

2. **Create Development Branch**
```bash
git checkout -b feature/your-feature-name
```

3. **Set Up Development Environment**
```bash
# Build the development image
./jeeves.ps1 build --no-cache

# Start the container for development
./jeeves.ps1 start

# Access the container for testing
./jeeves.ps1 shell
```

4. **Verify Your Setup**
```bash
# Inside the container, verify tools work
opencode --version
claude --version
@prd-creator --help
@deepest-thinking --help
```

## 📋 Contribution Types

We welcome the following types of contributions:

### 🐛 Bug Reports
- Use the [GitHub Issues](https://github.com/SamAcctX/jeeves/issues) page
- Provide detailed reproduction steps
- Include environment information:
  - Operating system and version
  - Docker version
  - PowerShell version
  - Container status (running/stopped)
- Add relevant logs and screenshots
- Use the "Bug Report" issue template

### ✨ Feature Requests
- Open an issue with "Feature Request" label
- Describe the use case and problem you're solving
- Suggest potential implementation approaches
- Consider impact on existing functionality

### 📝 Documentation
- Improve README.md and other documentation files
- Fix typos and grammatical errors
- Add examples and tutorials
- Update outdated information
- Improve clarity and flow

### 🔧 Code Contributions
- Bug fixes and performance improvements
- New features and capabilities
- Refactoring and code cleanup
- Test coverage improvements
- Cross-platform compatibility fixes

### 🎨 Agents and MCP Servers
- New AI agents for specific use cases
- Additional MCP server integrations
- Agent template improvements
- Server configuration enhancements

## 🛠️ Development Workflow

### 1. Planning
- Check existing [Issues](https://github.com/SamAcctX/jeeves/issues) and [Discussions](https://github.com/SamAcctX/jeeves/discussions)
- Create an issue for discussion if needed
- Plan implementation approach
- Consider backward compatibility

### 2. Implementation
- Follow existing code style and patterns
- Add appropriate tests for new functionality
- Update documentation for new features
- Consider cross-platform compatibility

### 3. Testing
```bash
# Test your changes thoroughly
./jeeves.ps1 build --no-cache
./jeeves.ps1 start

# Test inside the container
./jeeves.ps1 shell -c "
# Test your changes here
opencode --agent your-new-agent
claude --help
./install-mcp-servers.sh --dry-run
./install-agents.sh --global
"

# Test different platforms if possible
```

### 4. Submission
1. **Commit your changes**:
```bash
git add .
git commit -m "feat: add your feature description"
```

2. **Push to your fork**:
```bash
git push origin feature/your-feature-name
```

3. **Create Pull Request**:
   - Use a descriptive title
   - Fill out the PR template completely
   - Link to relevant issues
   - Request review from maintainers

## 📝 Code Style Guidelines

### PowerShell Scripts
- **Use PowerShell 7.0+ syntax**
- Follow Microsoft PowerShell naming conventions (PascalCase for functions)
- Use cmdlet-style verb-noun naming
- Include comment-based help for functions
- Add proper error handling with try/catch
- Use Write-Output/Write-Error/Write-Warning for output

#### Example Function Style:
```powershell
function Get-JeevesStatus {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName = "jeeves"
    )
    
    try {
        $status = docker ps --filter "name=$ContainerName" --format "table {{.Names}}\t{{.Status}}"
        Write-Output $status
    }
    catch {
        Write-Error "Failed to get container status: $($_.Exception.Message)"
        exit 1
    }
}
```

### Docker Configuration
- **Use multi-stage builds** for efficiency
- **Specify base image tags** (don't use `latest`)
- **Document customizations** with comments
- **Minimize layer count** where possible

#### Example Dockerfile Style:
```dockerfile
# Stage 1: Base system
FROM ubuntu:22.04 AS base
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Runtime
FROM base AS runtime
COPY --from=base /usr/local/bin/opencode /usr/local/bin/opencode
CMD ["/bin/bash"]
```

### Shell Scripts
- **Use POSIX shell syntax** for compatibility
- **Include proper shebangs**: `#!/bin/bash`
- **Use `set -e`** for error handling
- **Quote variables properly**: `"$VAR"` not `$VAR`
- **Add usage information and help text**
- **Make scripts executable**: `chmod +x`

#### Example Script Style:
```bash
#!/bin/bash
# Jeeves Agent Installation Script
# Usage: ./install-agents.sh [OPTIONS]

set -e

show_help() {
    echo "Jeeves Agent Installation Script"
    echo "Usage: $0 [--global]"
    echo "  --global    Install globally"
}

# Main script logic here
```

### Agent Templates
- **Use YAML frontmatter** with required fields
- **Provide clear descriptions** of agent capabilities
- **Set appropriate tool permissions** (ask, allow, deny)
- **Include usage examples** in documentation
- **Test with both OpenCode and Claude Code**

## 🧪 Testing Guidelines

### Manual Testing Checklist
- [ ] Container builds successfully without errors
- [ ] Container starts and stops cleanly
- [ ] OpenCode CLI/TUI/Web UI work
- [ ] Claude Code integration works
- [ ] MCP servers install and function
- [ ] AI agents install and operate
- [ ] File permissions work correctly on host
- [ ] Cross-platform compatibility verified

### Automated Testing
```bash
# Run basic functionality tests
./jeeves.ps1 shell -c "
opencode --version
claude --version
cd /usr/local/bin && ./install-mcp-servers.sh --dry-run
./install-agents.sh --global
"

# Test agent functionality
./jeeves.ps1 shell -c "
@prd-creator --help
@deepest-thinking --help
"
```

### Cross-Platform Testing
- **Windows**: Test on Windows 10/11 with PowerShell 5.1/7.x
- **macOS**: Test on Intel and Apple Silicon Macs
- **Linux**: Test on Ubuntu 20.04/22.04 and Debian derivatives

## 🔄 Pull Request Process

### Before Submitting
1. **Test thoroughly** - Ensure your changes work as expected
2. **Update documentation** - Document new features and changes
3. **Check for existing issues** - Avoid duplicate work
4. **Keep changes focused** - One feature or fix per PR if possible

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Manual testing completed
- [ ] Cross-platform tested
- [ ] Automated tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

### Review Process
1. **Automated checks** - CI/CD pipeline validation
2. **Peer review** - At least one maintainer review required
3. **Testing validation** - Manual verification of changes
4. **Approval** - Maintainer approval required for merge

## 🏗️ Project Structure

```
jeeves/
├── README.md                    # Main documentation
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # AGPLv3 license
├── jeeves.ps1                   # Main management script
├── Dockerfile.jeeves            # Container build file
├── .gitignore                   # Git ignore rules
├── .tmp/                        # Generated configs (git ignored)
├── jeeves/                      # Package directory
│   ├── bin/                     # Installation scripts
│   │   ├── install-mcp-servers.sh
│   │   └── install-agents.sh
│   ├── PRD/                     # PRD Creator agent
│   │   ├── README-PRD.md
│   │   ├── prd-creator-prompt.md
│   │   ├── prd-creator-opencode-template.md
│   │   └── prd-creator-claude-template.md
│   └── Deepest-Thinking/        # Research agent
│       ├── README-Deepest-Thinking.md
│       ├── deepest-thinking-prompt.md
│       ├── deepest-thinking-opencode-template.md
│       └── deepest-thinking-claude-template.md
└── docs/                        # Reference documentation
    ├── commands.md
    ├── configuration.md
    └── troubleshooting.md
```

## 🎯 Areas for Contribution

### High Priority
- Bug fixes and stability improvements
- Documentation enhancements
- Test coverage improvements
- Cross-platform compatibility fixes

### Medium Priority
- New AI agent development
- Additional MCP server integrations
- Performance optimizations
- User experience improvements

### Low Priority
- New feature development
- Experimental integrations
- Advanced customization options

## 🤝 Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Avoid personal attacks or criticism

### Communication
- Use GitHub Issues for bug reports and questions
- Use GitHub Discussions for general conversation
- Be patient with response times
- Provide clear, actionable feedback

### Recognition
- Contributors are recognized in releases
- Significant contributions may be highlighted
- Community members are valued and appreciated

## 📚 Resources

### Development Tools
- [Docker Documentation](https://docs.docker.com/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [OpenCode Documentation](https://opencode.ai/docs/)
- [Claude Code Documentation](https://docs.claude.com/)

### MCP Resources
- [MCP Specification](https://modelcontextprotocol.io/)
- [Awesome MCP Servers](https://github.com/wong2/awesome-mcp-servers)
- [MCP Server Development Guide](https://docs.anthropic.com/claude/docs/mcp)

### AI Agent Development
- [OpenCode Agent Documentation](https://opencode.ai/docs/agents/)
- [Agent Best Practices](https://opencode.ai/docs/agent-best-practices/)
- [Agent Template Reference](https://opencode.ai/docs/agent-templates/)

## 🆘 Getting Help

### Troubleshooting
- Check the [troubleshooting guide](https://github.com/SamAcctX/jeeves/blob/main/docs/troubleshooting.md)
- Search existing [Issues](https://github.com/SamAcctX/jeeves/issues)
- Check container logs: `./jeeves.ps1 logs`

### Questions
- Open a [GitHub Discussion](https://github.com/SamAcctX/jeeves/discussions/new)
- Check documentation before asking questions
- Provide context and error messages when seeking help

### Reporting Issues
- Use the issue template found in `.github/ISSUE_TEMPLATE/` directory
- Include system information and reproduction steps
- Provide logs and screenshots when applicable

---

Thank you for contributing to Jeeves! Your contributions help make AI-powered development more accessible and productive for everyone.