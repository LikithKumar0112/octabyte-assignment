import json
import logging
import os
import sys
import time
from contextlib import asynccontextmanager
from typing import Optional

import psycopg
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# Structured (JSON) logging to stdout -> picked up by the ECS awslogs driver
# ---------------------------------------------------------------------------
logger = logging.getLogger("app")
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter("%(message)s"))
logger.addHandler(handler)
logger.setLevel(logging.INFO)


def log_event(**fields):
    logger.info(json.dumps(fields, default=str))


# ---------------------------------------------------------------------------
# Config — read only from environment variables, never hard-coded
# ---------------------------------------------------------------------------
PORT = int(os.getenv("PORT", "8000"))
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "apppassword")


def db_conninfo() -> str:
    return (
        f"host={DB_HOST} port={DB_PORT} dbname={DB_NAME} "
        f"user={DB_USER} password={DB_PASSWORD}"
    )


def get_connection():
    return psycopg.connect(db_conninfo(), connect_timeout=5)


def init_db():
    """Create the table on startup (happy path). A real project would use
    Alembic migrations or a one-off ECS migration task instead."""
    with get_connection() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS items (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )
        conn.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Don't crash the process if the DB isn't reachable at boot — /health
    # must stay green so the ALB doesn't kill the task; /ready reflects DB state.
    try:
        init_db()
    except Exception as exc:  # noqa: BLE001
        log_event(event="startup_db_init_failed", error=str(exc))
    yield


app = FastAPI(title="8byte DevOps Assignment App", lifespan=lifespan)


@app.middleware("http")
async def request_logger(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration_ms = round((time.time() - start) * 1000, 2)
    log_event(
        event="request",
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration_ms=duration_ms,
    )
    return response


class ItemIn(BaseModel):
    name: str


class Item(BaseModel):
    id: int
    name: str
    created_at: str


@app.get("/health")
def health():
    """Liveness probe used by the ALB target group. Never touches the DB —
    a slow/unavailable database must not take healthy tasks out of rotation."""
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Readiness probe: confirms DB connectivity. Used by the deploy
    pipeline's smoke test, not by the ALB health check."""
    try:
        with get_connection() as conn:
            conn.execute("SELECT 1")
        return {"status": "ready"}
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=503, detail=f"db not ready: {exc}")


@app.get("/api/items")
def list_items():
    with get_connection() as conn:
        rows = conn.execute(
            "SELECT id, name, created_at FROM items ORDER BY id DESC"
        ).fetchall()
    return [{"id": r[0], "name": r[1], "created_at": str(r[2])} for r in rows]


@app.post("/api/items", status_code=201)
def create_item(item: ItemIn):
    with get_connection() as conn:
        row = conn.execute(
            "INSERT INTO items (name) VALUES (%s) RETURNING id, name, created_at",
            (item.name,),
        ).fetchone()
        conn.commit()
    return {"id": row[0], "name": row[1], "created_at": str(row[2])}


@app.get("/", response_class=HTMLResponse)
def frontend():
    """A single static page is enough to satisfy 'load balancer for the
    frontend' — it calls the API below via fetch()."""
    return """
    <!doctype html><html><head><title>8byte Assignment</title></head>
    <body style="font-family:sans-serif;max-width:480px;margin:40px auto">
      <h2>8byte DevOps Assignment</h2>
      <p>Environment: <b id="env"></b></p>
      <form id="f"><input id="name" placeholder="item name" required/>
        <button>Add</button></form>
      <ul id="list"></ul>
      <script>
        document.getElementById('env').textContent = location.hostname;
        async function refresh() {
          const res = await fetch('/api/items');
          const items = await res.json();
          document.getElementById('list').innerHTML =
            items.map(i => `<li>${i.name} — ${i.created_at}</li>`).join('');
        }
        document.getElementById('f').addEventListener('submit', async (e) => {
          e.preventDefault();
          const name = document.getElementById('name').value;
          await fetch('/api/items', {method: 'POST', headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({name})});
          document.getElementById('name').value = '';
          refresh();
        });
        refresh();
      </script>
    </body></html>
    """