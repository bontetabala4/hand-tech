from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_create_prediction_returns_mocked_result():
    response = client.post(
        "/api/v1/predictions",
        json={"image_base64": "ZmFrZV9pbWFnZQ==", "session_id": "test-session"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "sign" in data
    assert 0.0 <= data["confidence"] <= 1.0
    assert data["mocked"] is True
