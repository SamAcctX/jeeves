"""
HTTP/SSE transport wrapper for the Crawl4AI MCP server.

This module imports the existing `server` instance from crawler_agent.mcp_server
and serves it over HTTP using the MCP SDK's built-in SSE transport, making it
accessible as a network service rather than requiring stdio subprocess spawning.

Usage:
    python -m crawler_agent.mcp_server_http

Environment variables:
    MCP_HTTP_HOST: Bind address (default: 0.0.0.0)
    MCP_HTTP_PORT: Listen port (default: 8080)
    CRAWL4AI_MCP_LOG: Log level (default: INFO)
"""
from __future__ import annotations

import os
import sys
import logging

import uvicorn
from starlette.applications import Starlette
from starlette.routing import Route, Mount
from starlette.responses import JSONResponse

from mcp.server.sse import SseServerTransport

from .mcp_server import server

_LOG_LEVEL = os.getenv("CRAWL4AI_MCP_LOG", "INFO").upper()
logger = logging.getLogger("crawl4ai_mcp_http")
if not logger.handlers:
    _h = logging.StreamHandler(sys.stderr)
    _h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s [%(name)s] %(message)s"))
    logger.addHandler(_h)
logger.setLevel(_LOG_LEVEL)
logger.propagate = False

sse_transport = SseServerTransport("/messages/")


async def handle_sse(request):
    async with sse_transport.connect_sse(
        request.scope, request.receive, request._send
    ) as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options(),
        )


async def handle_messages(request):
    await sse_transport.handle_post_message(
        request.scope, request.receive, request._send
    )


async def health(request):
    return JSONResponse({"status": "ok", "server": "crawl4ai-mcp"})


app = Starlette(
    routes=[
        Route("/health", health, methods=["GET"]),
        Route("/sse", handle_sse),
        Mount("/messages/", app=sse_transport.handle_post_message),
    ],
)


def main() -> None:
    host = os.getenv("MCP_HTTP_HOST", "0.0.0.0")
    port = int(os.getenv("MCP_HTTP_PORT", "8080"))
    logger.info("Starting crawl4ai-mcp HTTP/SSE server on %s:%d", host, port)
    uvicorn.run(app, host=host, port=port, log_level=_LOG_LEVEL.lower())


if __name__ == "__main__":
    main()
