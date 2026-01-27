# Playwright MCP Integration Plan

## Project Overview & Current Analysis

Your jeeves project is a sophisticated AI development environment with:
- **Containerized AI workspace** with OpenCode and Claude Code
- **Automated MCP management** via `install-mcp-servers.sh`
- **Browserless service** already configured (`ghcr.io/browserless/chrome:latest`)
- **Pre-built AI agents** for PRD creation and deep thinking
- **Multi-platform support** with proper volume mappings

## Integration Strategy

### Phase 1: Core Infrastructure Updates

#### 1.1 Update MCP Installation Script
**File**: `jeeves/bin/install-mcp-servers.sh`

**Additions needed**:
```bash
# Add to MCP_SERVERS array
["playwright"]="@playwright/mcp@latest"

# Add to MCP_ENV_VARS array
["playwright"]="PLAYWRIGHT_MCP_CDP_ENDPOINT"

# Environment variable handling
PLAYWRIGHT_MCP_CDP_ENDPOINT=""
```

**Configuration logic**:
- Auto-detect browserless URL from environment
- Fallback to `http://browserless:3000` for container environment
- Support external browserless URLs for development

#### 1.2 Docker Configuration Updates

**File**: `Dockerfile.jeeves`

**Required additions**:
```dockerfile
# Add to runtime stage dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ... existing deps ...
    # Playwright browser dependencies
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libasound2

# Install Playwright browser (for fallback/local testing)
RUN npx playwright install chromium
RUN npx playwright install-deps chromium
```

**Environment variables in docker-compose.yml**:
```yaml
services:
  jeeves:
    environment:
      - BROWSERLESS_URL=http://browserless:3000
      - PLAYWRIGHT_MCP_CDP_ENDPOINT=ws://browserless:3000/devtools/browser
      - PLAYWRIGHT_MCP_HEADLESS=true
      - PLAYWRIGHT_MCP_BROWSER=chromium
      - PLAYWRIGHT_MCP_NO_SANDBOX=true
      - PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS=true
```

### Phase 2: Configuration Templates

#### 2.1 OpenCode Configuration
**Target**: `opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest"],
      "environment": {
        "PLAYWRIGHT_MCP_CDP_ENDPOINT": "ws://browserless:3000/devtools/browser",
        "PLAYWRIGHT_MCP_HEADLESS": "true",
        "PLAYWRIGHT_MCP_BROWSER": "chromium",
        "PLAYWRIGHT_MCP_NO_SANDBOX": "true",
        "PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS": "true"
      },
      "enabled": true
    }
  }
}
```

#### 2.2 Claude Code Configuration
**Target**: `.mcp.json`

```json
{
  "mcpServers": {
    "playwright": {
      "command": ["npx", "-y", "@playwright/mcp@latest"],
      "env": {
        "PLAYWRIGHT_MCP_CDP_ENDPOINT": "ws://browserless:3000/devtools/browser",
        "PLAYWRIGHT_MCP_HEADLESS": "true",
        "PLAYWRIGHT_MCP_BROWSER": "chromium",
        "PLAYWRIGHT_MCP_NO_SANDBOX": "true",
        "PLAYWRIGHT_MCP_ALLOW_UNRESTRICTED_FILE_ACCESS": "true"
      }
    }
  }
}
```

### Phase 3: Enhanced Capabilities & Agent Integration

#### 3.1 New Tools Available
After integration, agents will have access to:
- **Web Navigation**: `browser_navigate`, `browser_navigate_back`
- **Page Interaction**: `browser_click`, `browser_type`, `browser_fill_form`
- **Content Analysis**: `browser_snapshot`, `browser_take_screenshot`
- **Network Analysis**: `browser_network_requests`, `browser_console_messages`
- **Advanced Features**: `browser_drag`, `browser_select_option`, `browser_evaluate`

#### 3.2 Agent Enhancement Opportunities

**PRD Creator Enhancements** (Future Roadmap):
```markdown
## Suggested PRD Creator Enhancements

### Web Research Capabilities
- **Competitor Analysis**: Navigate to competitor websites and capture features
- **Market Research**: Auto-scrape industry reports and documentation
- **Technology Validation**: Verify technology stack choices on live sites
- **User Experience Review**: Capture screenshots of similar products

### Template Additions
- **Web App PRD Template**: Include sections for browser compatibility, responsive design
- **E-commerce PRD Template**: Payment gateway testing, checkout flow validation
- **SaaS PRD Template**: Multi-tenant architecture validation, user journey mapping
```

**Deepest-Thinking Enhancements** (Future Roadmap):
```markdown
## Suggested Deepest-Thinking Enhancements

### Live Investigation
- **Current Event Analysis**: Navigate to news sources for real-time information
- **Documentation Research**: Access latest API docs and technical specifications
- **Evidence Gathering**: Capture live web page states as evidence
- **Technical Validation**: Test code examples and implementations from documentation

### Analysis Templates
- **Web Application Analysis**: Performance, accessibility, SEO evaluation
- **Competitive Analysis**: Feature comparison matrix from live sites
- **Technical Due Diligence**: Technology stack verification and assessment
```

### Phase 4: Security & Best Practices

#### 4.1 Security Considerations
```markdown
## Security Implementation Plan

### Access Control
- **File Access**: Restrict to `/proj` and `/tmp` directories only
- **Network Restrictions**: Use browserless service as single gateway
- **Origin Filtering**: Optional domain allowlist/blocklist support

### Environment Variable Configuration
```bash
# For future domain restrictions
PLAYWRIGHT_MCP_ALLOWED_ORIGINS="https://example.com,https://api.example.com"
PLAYWRIGHT_MCP_BLOCKED_ORIGINS="https://malicious-site.com"
```

#### 4.2 Monitoring & Debugging
```bash
# Enable console logging for debugging
PLAYWRIGHT_MCP_CONSOLE_LEVEL="debug"

# Save traces for complex workflows
PLAYWRIGHT_MCP_SAVE_TRACE="true"

# Save session state for debugging
PLAYWRIGHT_MCP_SAVE_SESSION="true"
```

### Phase 5: Testing & Validation Plan

#### 5.1 Integration Tests
```bash
# Test basic browser automation
npx @playwright/mcp@latest --cdp-endpoint=ws://browserless:3000/devtools/browser

# Test navigation to common sites
# Test form interaction
# Test screenshot capture
# Test file upload/download
```

#### 5.2 Docker Compose Testing
```bash
# Test service connectivity
docker-compose up -d
docker exec jeeves curl -f http://browserless:3000/docs

# Test MCP server installation
docker exec jeeves /usr/local/bin/install-mcp-servers.sh --dry-run

# Test browser automation workflow
docker exec -it jeeves bash -c 'npx @playwright/mcp@latest --help'
```

## Implementation Checklist

### Immediate Implementation Steps
- [ ] Update `install-mcp-servers.sh` with Playwright MCP configuration
- [ ] Add browser environment variables to docker-compose.yml
- [ ] Update Dockerfile.jeeves with Playwright dependencies
- [ ] Test CDP connection to browserless service
- [ ] Validate MCP server installation and configuration

### Future Enhancement Steps
- [ ] Create web automation templates for PRD Creator
- [ ] Create investigation templates for Deepest-Thinking agent
- [ ] Implement security filtering capabilities
- [ ] Add monitoring and debugging tools
- [ ] Create example workflows and documentation

## Benefits Summary

**Immediate Benefits**:
- Web page automation and testing capabilities
- Integration with existing browserless infrastructure
- Consistent with current MCP management approach
- Minimal additional resource overhead

**Future Benefits**:
- Enhanced agent capabilities with web access
- Competitive analysis and market research automation
- Technical validation and documentation research
- Comprehensive web application testing

**Architecture Alignment**:
- Leverages existing browserless service
- Maintains container security boundaries
- Follows established configuration patterns
- Scalable for multiple concurrent sessions

## Comparison with Puppeteer

| Feature | Playwright | Puppeteer |
|---------|------------|-----------|
| Browser Support | Chrome, Firefox, Safari | Chrome/Chromium |
| API Design | Modern, promise-based | Established, stable |
| Documentation | Comprehensive | Mature |
| Community | Growing rapidly | Large, established |
| MCP Support | Official Microsoft | Community-driven |
| Cross-Browser | Native support | Limited (Chrome focus) |

This plan provides a solid foundation for web automation capabilities while maintaining professional standards and architectural consistency of your jeeves project.