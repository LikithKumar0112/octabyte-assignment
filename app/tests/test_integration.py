import pytest
from fastapi.testclient import TestClient

from src.main import app, init_db

pytestmark = pytest.mark.integration

init_db()
client = TestClient(app)


def test_create_then_list_item_round_trip():
    resp = client.post("/api/items", json={"name": "integration-test-item"})
    assert resp.status_code == 201

    resp = client.get("/api/items")
    assert resp.status_code == 200
    names = [item["name"] for item in resp.json()]
    assert "integration-test-item" in names


def test_ready_reports_db_connectivity():
    resp = client.get("/ready")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ready"}
