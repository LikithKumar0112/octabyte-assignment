import pytest
from fastapi.testclient import TestClient

from src.main import app

pytestmark = pytest.mark.unit

client = TestClient(app, raise_server_exceptions=False)


def test_health_returns_200_without_db():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_frontend_serves_html():
    resp = client.get("/")
    assert resp.status_code == 200
    assert "8byte" in resp.text


def test_create_item_rejects_missing_name():
    resp = client.post("/api/items", json={})
    assert resp.status_code == 422