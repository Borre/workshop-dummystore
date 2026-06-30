"""gateway-api — DummyStore API Gateway (port 9000).

Routes frontend requests to backend microservices:
  - catalog-api:8080 (products)
  - orders-api:8000  (orders)
"""

import logging
from contextlib import asynccontextmanager
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import JSONResponse
from pythonjsonlogger import jsonlogger

# ---------------------------------------------------------------------------
# Logging setup — structured JSON output
# ---------------------------------------------------------------------------

_log_handler = logging.StreamHandler()
_log_handler.setFormatter(
    jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )
)

_logger = logging.getLogger("gateway-api")
_logger.setLevel(logging.INFO)
_logger.addHandler(_log_handler)
_logger.propagate = False

# ---------------------------------------------------------------------------
# HTTP clients shared across requests
# ---------------------------------------------------------------------------

_client: httpx.AsyncClient | None = None

SERVICES = {
    "catalog": "http://catalog-api:8080",
    "orders": "http://orders-api:8000",
}


def _get_client() -> httpx.AsyncClient:
    assert _client is not None, "httpx client not initialised"
    return _client


# ---------------------------------------------------------------------------
# Lifespan — manage httpx client
# ---------------------------------------------------------------------------


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _client
    _client = httpx.AsyncClient(timeout=httpx.Timeout(10.0))
    _logger.info("gateway-api starting", extra={"port": 9000})
    yield
    await _client.aclose()
    _logger.info("gateway-api stopped")


# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------

app = FastAPI(
    title="DummyStore Gateway API",
    description="API Gateway for the DummyStore workshop application",
    version="0.1.0",
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _check_service(name: str, url: str) -> str:
    """Return ``"up"`` or ``"down"`` for a backend service."""
    try:
        resp = await _get_client().get(f"{url}/health", timeout=5.0)
        return "up" if resp.status_code < 500 else "down"
    except httpx.HTTPError:
        return "down"


async def _proxy(path: str, method: str, base_url: str, request: Request) -> Response:
    """Forward a request to the target service and return its response."""
    client = _get_client()
    target_url = f"{base_url}{path}"

    body = await request.body()
    headers = _clean_headers(request)
    params = dict(request.query_params)

    try:
        resp = await client.request(
            method=method,
            url=target_url,
            content=body,
            headers=headers,
            params=params,
        )
    except httpx.HTTPError as exc:
        _logger.error("proxy error", extra={"target": target_url, "error": str(exc)})
        raise HTTPException(status_code=502, detail=f"Bad gateway: {exc}") from exc

    return Response(
        content=resp.content,
        status_code=resp.status_code,
        headers=dict(resp.headers),
    )


def _clean_headers(request: Request) -> dict[str, str]:
    """Return forwarded headers, dropping hop-by-hop and host headers."""
    skip = {
        "host",
        "connection",
        "transfer-encoding",
        "keep-alive",
        "proxy-authorization",
        "proxy-authenticate",
        "te",
        "trailer",
        "upgrade",
    }
    return {
        k: v
        for k, v in request.headers.items()
        if k.lower() not in skip
    }


async def _service_status() -> dict[str, str]:
    """Probe all backends and return their status."""
    status: dict[str, str] = {}
    for name, url in SERVICES.items():
        status[name] = await _check_service(name, url)
    return status


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.get("/")
async def root() -> dict[str, Any]:
    """Root endpoint — health summary with per-service status."""
    services = await _service_status()
    overall = "ok" if all(v == "up" for v in services.values()) else "degraded"
    _logger.info("health check", extra={"services": services, "overall": overall})
    return {"status": overall, "services": services}


@app.get("/health")
async def health() -> dict[str, Any]:
    """Health-check endpoint with per-service status."""
    services = await _service_status()
    overall = "ok" if all(v == "up" for v in services.values()) else "degraded"
    return {"status": overall, "services": services}


@app.get("/api/products")
async def list_products(request: Request) -> Response:
    """Proxy GET /api/products → catalog-api:8080/products"""
    _logger.info("proxy-catalog: list products")
    return await _proxy("/products", "GET", SERVICES["catalog"], request)


@app.get("/api/products/{product_id}")
async def get_product(product_id: int, request: Request) -> Response:
    """Proxy GET /api/products/{id} → catalog-api:8080/products/{id}"""
    _logger.info("proxy-catalog: get product", extra={"product_id": product_id})
    return await _proxy(f"/products/{product_id}", "GET", SERVICES["catalog"], request)


@app.post("/api/orders")
async def create_order(request: Request) -> Response:
    """Proxy POST /api/orders → orders-api:8000/orders"""
    _logger.info("proxy-orders: create order")
    return await _proxy("/orders", "POST", SERVICES["orders"], request)


@app.get("/api/orders")
async def list_orders(request: Request) -> Response:
    """Proxy GET /api/orders → orders-api:8000/orders"""
    _logger.info("proxy-orders: list orders")
    return await _proxy("/orders", "GET", SERVICES["orders"], request)
