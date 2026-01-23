# Jeeves Toolkit

A collection of development tools and utilities integrated into the Jeeves Docker environment. This toolkit enhances your development workflow with AI-assisted productivity tools.

---

## What's Included

### 📋 PRD Creator

A comprehensive Product Requirements Document (PRD) creation tool that helps you plan and document software projects using AI coding assistants like opencode or Claude.

**Quick Start:**
```bash
prd-creator init
prd-creator install
```

**Documentation:** See [README.md](./README.md) for complete usage instructions, MCP configuration, and best practices.

**Features:**
- Guided conversational PRD creation
- Educational approach for beginners
- Developer-optimized output with acceptance criteria
- Optional MCP server integration for enhanced research
- Compatible with both opencode and Claude

---

## Getting Started

### First Time Setup

No setup required! The toolkit is pre-installed in your Jeeves container.

To verify installation:
```bash
which prd-creator
prd-creator help
```

### Tool Management

The `prd-creator-uninstall` script is included for complete lifecycle management.

```bash
# Remove global agent
prd-creator-uninstall global

# Remove project agent  
prd-creator-uninstall project

# Remove both agents
prd-creator-uninstall all

# Uninstall options
--force    # Skip confirmation prompts
--dry-run   # Show what would be removed without actually removing
```

### Adding More Tools

To add new tools to the Jeeves toolkit:

1. **Create scripts** in `/workspace/jeeves/`
2. **Update Dockerfile** to copy files to `/usr/local/bin/` and `/opt/jeeves/`
3. **Follow patterns** - Use proper shebangs, error handling, and documentation

**Example Structure:**
```
jeeves/
├── my-tool.sh          # Executable script
├── my-tool.md           # Reference/documentation
└── Dockerfile.jeeves       # Build configuration (existing)
```

**Adding Scripts:**
1. Create `my-tool.sh` with proper structure and error handling
2. Add to Dockerfile: `COPY jeeves/my-tool.sh /usr/local/bin/my-tool`
3. Copy documentation: `COPY jeeves/my-tool.md /opt/jeeves/`

---

## Tool Location Reference

- **Executable scripts:** `/usr/local/bin/` (in PATH)
- **Reference files:** `/opt/jeeves/`
- **Source files:** `/workspace/jeeves/` (for Docker COPY)

---

## Support

For issues or questions about the PRD Creator, refer to the [detailed README](./README.md).

---

*Jeeves Toolkit - Enhanced development environment for AI-assisted coding*
