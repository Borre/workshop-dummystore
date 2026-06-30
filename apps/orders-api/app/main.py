import logging
from datetime import datetime, timezone

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from pythonjsonlogger import jsonlogger

# ---------------------------------------------------------------------------
# Logging – structured JSON
# ---------------------------------------------------------------------------
_handler = logging.StreamHandler()
_formatter = jsonlogger.JsonFormatter(
    fmt="%(asctime)s %(name)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
)
_handler.setFormatter(_formatter)
_log = logging.getLogger("orders-api")
_log.addHandler(_handler)
_log.setLevel(logging.INFO)

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(title="Orders API", version="1.0.0")

# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------
class Order(BaseModel):
    id: int = Field(default=0, ge=0)
    product_id: int
    quantity: int
    customer: str
    status: str
    total: float
    created_at: str = ""


class OrderCreate(BaseModel):
    product_id: int
    quantity: int
    customer: str
    total: float = 0.0


# ---------------------------------------------------------------------------
# In-memory storage
# ---------------------------------------------------------------------------
orders: list[Order] = []
next_id: int = 1

CATALOG_API_BASE = "http://catalog-api:8080"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
async def _validate_product(product_id: int) -> bool:
    """Return True if catalog-api reports the product exists."""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.get(
                f"{CATALOG_API_BASE}/api/products/{product_id}"
            )
            return resp.is_success
    except httpx.RequestError as exc:
        _log.warning("catalog-api unreachable for product %s: %s", product_id, exc)
        return False


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/orders")
async def list_orders():
    return orders


@app.get("/orders/{order_id}")
async def get_order(order_id: int):
    for o in orders:
        if o.id == order_id:
            return o
    raise HTTPException(status_code=404, detail="Order not found")


@app.post("/orders", status_code=201)
async def create_order(data: OrderCreate):
    global next_id

    if not await _validate_product(data.product_id):
        raise HTTPException(
            status_code=400,
            detail=f"Product with id {data.product_id} does not exist or catalog-api is unavailable",
        )

    order = Order(
        id=next_id,
        product_id=data.product_id,
        quantity=data.quantity,
        customer=data.customer,
        status="pending",
        total=data.total,
        created_at=datetime.now(timezone.utc).isoformat(),
    )
    orders.append(order)
    next_id += 1

    _log.info("Order created", extra={"order_id": order.id, "product_id": order.product_id})
    return order
