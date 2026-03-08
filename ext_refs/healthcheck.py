"""Simple healthcheck script for the crawl4ai-mcp HTTP server."""
import sys
import urllib.request

try:
    req = urllib.request.Request("http://localhost:8080/health")
    with urllib.request.urlopen(req, timeout=5) as resp:
        if resp.status == 200:
            sys.exit(0)
        sys.exit(1)
except Exception:
    sys.exit(1)
