"""
Streamable HTTP transport wrapper for the Crawl4AI MCP server.

This module imports the existing `server` instance from crawler_agent.mcp_server
and serves it over Streamable HTTP using the MCP SDK's StreamableHTTPSessionManager,
making it accessible as a network service at POST/GET /mcp.

This is the newer MCP transport (2025-03-26 spec) that supersedes SSE.
Clients configure it with: {"type": "streamable-http", "url": "http://host:8080/mcp"}

Usage:
    python -m crawler_agent.mcp_server_streamable_http

Environment variables:
    MCP_HTTP_HOST: Bind address (default: 0.0.0.0)
    MCP_HTTP_PORT: Listen port (default: 8080)
    CRAWL4AI_MCP_LOG: Log level (default: INFO)
"""
from __future__ import annotations

import contextlib
import os
import sys
import logging
from collections.abc import AsyncIterator

import uvicorn
from starlette.applications import Starlette
from starlette.middleware.cors import CORSMiddleware
from starlette.routing import Mount, Route
from starlette.responses import JSONResponse
from starlette.types import Receive, Scope, Send

from mcp.server.streamable_http_manager import StreamableHTTPSessionManager

from .mcp_server import server

_LOG_LEVEL = os.getenv("CRAWL4AI_MCP_LOG", "INFO").upper()
logger = logging.getLogger("crawl4ai_mcp_streamable_http")
if not logger.handlers:
    _h = logging.StreamHandler(sys.stderr)
    _h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
    logger.addHandler(_h)
logger.setLevel(_LOG_LEVEL)
logger.propagate = False


session_manager = StreamableHTTPSessionManager(
    app=server,
    json_response=False,
)


async def handle_mcp(scope: Scope, receive: Receive, send: Send) -> None:
    await session_manager.handle_request(scope, receive, send)


async def health(request):
    return JSONResponse({"status": "ok", "server": "crawl4ai-mcp", "transport": "streamable-http"})


@contextlib.asynccontextmanager
async def lifespan(app: Starlette) -> AsyncIterator[None]:
    async with session_manager.run():
        logger.info("crawl4ai-mcp streamable-http server started")
        try:
            yield
        finally:
            logger.info("crawl4ai-mcp streamable-http server shutting down")


starlette_app = Starlette(
    routes=[
        Route("/health", health, methods=["GET"]),
        Mount("/mcp", app=handle_mcp),
    ],
    lifespan=lifespan,
)

app = CORSMiddleware(
    starlette_app,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "DELETE"],
    expose_headers=["Mcp-Session-Id"],
)


def main() -> None:
    host = os.getenv("MCP_HTTP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_HTTP_PORT", "8080"))
    logger.info("Starting crawl4ai-mcp streamable-http server on %s:%d", host, port)
    uvicorn.run(app, host=host, port=port, log_level=_LOG_LEVEL.lower())


if __name__ == "__main__":
    main()
