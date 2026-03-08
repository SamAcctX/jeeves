# Crawl4AI HTTP-Streamable MCP Server: Sidecar Container Plan

## Goal

Build a self-contained Docker image that wraps the [crawl4ai-mcp-server](https://github.com/sadiuysal/crawl4ai-mcp-server) project with HTTP-Streamable MCP transport, enabling it to run as a sidecar container reachable over the network rather than requiring stdio subprocess spawning.

This replaces Firecrawl MCP with a self-hosted, free alternative offering equivalent tools: `scrape`, `crawl`, `crawl_site`, `crawl_sitemap`.

## Architecture

```
┌────────────────────┐     HTTP/SSE      ┌──────────────────────────┐
│  MCP Client        │ ───────────────►  │  crawl4ai-mcp-http       │
│  (Claude/OpenCode) │  POST /mcp        │  (sidecar container)     │
│                    │  GET  /sse        │                          │
│                    │ ◄───────────────  │  FastAPI + MCP SDK       │
│                    │   SSE stream      │  + Crawl4AI + Playwright │
└────────────────────┘                   └──────────────────────────┘
```

## Transport Options

The MCP Python SDK (`mcp` package) supports three transports:

1. **stdio** (current) -- subprocess-only, no network
2. **SSE** (Server-Sent Events) -- HTTP POST for requests, SSE stream for responses. Supported by most MCP clients.
3. **Streamable HTTP** (2025 spec) -- Single HTTP endpoint, bidirectional. Newer, not all clients support it yet.

**Recommendation**: Use **SSE transport** for broadest client compatibility. The MCP Python SDK has built-in support via `mcp.server.sse`.

## Implementation Plan

### 1. Fork/Clone the Upstream Repo

```bash
git clone https://github.com/sadiuysal/crawl4ai-mcp-server.git
cd crawl4ai-mcp-server
```

### 2. Add HTTP Transport Entrypoint

Create `crawler_agent/mcp_server_http.py` alongside the existing `mcp_server.py`. This file imports the existing `server` instance and runs it with SSE transport instead of stdio.

See reference implementation: `ext_refs/mcp_server_http.py`

### 3. Update requirements.txt

Add the SSE transport dependencies:

```
mcp>=1.1.0,<2.0.0
crawl4ai>=0.7.0,<0.8.0
pydantic>=2.7,<3.0
playwright>=1.44,<2.0
httpx>=0.27,<1.0
starlette>=0.27
uvicorn>=0.29
anyio>=4.0
sse-starlette>=1.6
```

Note: `openai-agents` is NOT needed for the MCP server itself (only for their example agent script).

### 4. Create Dockerfile

See reference implementation: `ext_refs/Dockerfile.crawl4ai-mcp`

Key design decisions:
- Base on `python:3.11-slim` (no CUDA needed for web scraping)
- Install Playwright chromium only (not firefox/webkit)
- Run as non-root user
- Expose port 8080 for HTTP transport
- Healthcheck via `/health` endpoint

### 5. Docker Compose Integration

Add to your project's `docker-compose.yml`:

```yaml
services:
  crawl4ai-mcp:
    build:
      context: ./crawl4ai-mcp-server
      dockerfile: Dockerfile
    image: crawl4ai-mcp:latest
    ports:
      - "8080:8080"
    volumes:
      - ./crawls:/app/crawls
    environment:
      - CRAWL4AI_MCP_LOG=INFO
      - MCP_HTTP_PORT=8080
    healthcheck:
      test: ["CMD", "python", "-c", "import httpx; httpx.get('http://localhost:8080/health').raise_for_status()"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '2.0'
    networks:
      - app-network
```

### 6. MCP Client Configuration

For clients that support SSE transport (Claude Code, OpenCode, etc.):

```json
{
  "mcpServers": {
    "crawl4ai": {
      "type": "sse",
      "url": "http://crawl4ai-mcp:8080/sse"
    }
  }
}
```

For OpenCode format:

```json
{
  "mcp": {
    "crawl4ai": {
      "type": "sse",
      "url": "http://crawl4ai-mcp:8080/sse"
    }
  }
}
```

## File Manifest

Reference files provided in this directory:

| File | Purpose |
|------|---------|
| `mcp_server_http.py` | SSE transport wrapper (broad client compatibility) |
| `mcp_server_streamable_http.py` | Streamable HTTP transport wrapper (newer spec, recommended) |
| `Dockerfile.crawl4ai-mcp` | Production Dockerfile for the sidecar |
| `docker-compose.crawl4ai.yml` | Standalone compose file for testing |
| `healthcheck.py` | Simple healthcheck script |

## Transport Variants

### SSE (`mcp_server_http.py`)
- Endpoint: `GET /sse` (event stream), `POST /messages/` (client messages)
- Client config: `{"type": "sse", "url": "http://host:8080/sse"}`
- Broadest client support (all current MCP clients)
- Long-lived SSE connection

### Streamable HTTP (`mcp_server_streamable_http.py`)
- Endpoint: `POST /mcp` (requests), `GET /mcp` (optional server-initiated stream)
- Client config: `{"type": "streamable-http", "url": "http://host:8080/mcp"}`
- 2025-03-26 MCP spec, supersedes SSE
- Cleaner connection model (no long-lived stream required)
- Session management via `Mcp-Session-Id` header
- CORS headers included for browser-based clients

### Switching Between Them

Change the Dockerfile CMD:

```dockerfile
# SSE (fallback)
CMD ["python", "-m", "crawler_agent.mcp_server_http"]

# Streamable HTTP (recommended)
CMD ["python", "-m", "crawler_agent.mcp_server_streamable_http"]
```

Or use an environment variable with an entrypoint script to select at runtime.

## Migration from Firecrawl

The crawl4ai tools map to Firecrawl equivalents:

| Firecrawl | Crawl4AI | Notes |
|-----------|----------|-------|
| `scrape_url` | `scrape` | Nearly identical -- URL in, markdown out |
| `crawl_url` | `crawl` | BFS crawl with depth/page limits |
| `map_url` | `crawl_sitemap` | Sitemap-based discovery |
| (none) | `crawl_site` | Persistent site crawl -- bonus feature |

## Testing

```bash
docker compose -f docker-compose.crawl4ai.yml up --build -d
curl http://localhost:8080/health
python -c "
import httpx, json
resp = httpx.post('http://localhost:8080/mcp', json={
    'jsonrpc': '2.0', 'id': 1, 'method': 'initialize',
    'params': {'protocolVersion': '2024-11-05', 'capabilities': {},
               'clientInfo': {'name': 'test', 'version': '1.0'}}
})
print(json.dumps(resp.json(), indent=2))
"
```

## Build Complexity

- Estimated image size: ~800MB (Playwright + Chromium dominate)
- Build time: ~3-5 minutes
- No CUDA/GPU needed
- Single Python runtime, no Node.js required
