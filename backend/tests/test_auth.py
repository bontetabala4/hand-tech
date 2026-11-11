"""Tests du flux d'authentification Google."""

from fastapi.testclient import TestClient

from app.api.v1 import auth
from app.main import app

client = TestClient(app)


def test_auth_me_requires_bearer_token():
    response = client.get("/api/v1/auth/me")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_auth_me_returns_only_verified_google_identity(monkeypatch):
    monkeypatch.setattr(auth.settings, "google_client_id", "web-client-id")
    monkeypatch.setattr(
        auth,
        "verify_google_id_token",
        lambda token, client_id: {
            "sub": "google-subject-123",
            "email": "user@example.com",
            "email_verified": True,
            "aud": client_id,
        },
    )

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer valid-test-token"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "authenticated": True,
        "user": {
            "sub": "google-subject-123",
            "email": "user@example.com",
            "email_verified": True,
        },
    }


def test_auth_me_rejects_invalid_or_wrong_audience_token(monkeypatch):
    monkeypatch.setattr(auth.settings, "google_client_id", "expected-client-id")

    def reject_token(token: str, client_id: str):
        raise ValueError("Invalid token or audience")

    monkeypatch.setattr(auth, "verify_google_id_token", reject_token)

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid-test-token"},
    )

    assert response.status_code == 401


def test_auth_me_fails_closed_when_google_client_id_is_missing(monkeypatch):
    monkeypatch.setattr(auth.settings, "google_client_id", None)

    response = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer any-token"},
    )

    assert response.status_code == 503
