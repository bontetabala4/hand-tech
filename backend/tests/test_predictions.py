from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_prediction_returns_503_when_ai_service_is_unavailable():
    response = client.post(
        "/api/v1/predictions",
        json={
            "image_base64": "ZmFrZV9pbWFnZQ==",
            "session_id": "test-session",
        },
    )

    assert response.status_code == 503
    assert response.json()["detail"] == (
        "Le service de reconnaissance IA n'est pas encore disponible. "
        "Aucune prédiction n'a été effectuée."
    )
    assert "sign" not in response.json()
    assert "confidence" not in response.json()


def test_prediction_rejects_invalid_request():
    response = client.post(
        "/api/v1/predictions",
        json={"session_id": "test-session"},
    )

    assert response.status_code == 422


def test_prediction_openapi_documents_503_not_200():
    operation = app.openapi()["paths"]["/api/v1/predictions"]["post"]
    responses = operation["responses"]

    assert "503" in responses
    assert "422" in responses
    assert "200" not in responses
