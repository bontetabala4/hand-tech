"""Tests d'intégration de l'historique avec une base SQLite isolée."""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.v1 import auth, translations
from sqlalchemy.exc import OperationalError
from app.db.base import Base
from app.db.session import get_db
from app.main import app


@pytest.fixture
def api_client(monkeypatch):
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    test_session = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = test_session()
        try:
            yield db
        finally:
            db.close()

    monkeypatch.setattr(auth.settings, "google_client_id", "test-client-id")
    monkeypatch.setattr(
        auth,
        "verify_google_id_token",
        lambda token, client_id: {
            "sub": token,
            "email": f"{token}@example.test",
            "email_verified": True,
            "aud": client_id,
        },
    )
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def auth_headers(user_token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {user_token}"}


def create_entry(client: TestClient, user: str, phrase: str):
    return client.post(
        "/api/v1/translations",
        headers=auth_headers(user),
        json={
            "source_text": phrase,
            "translated_text": phrase,
            "source_language": "fr",
            "target_language": "fr",
        },
    )


def test_database_errors_return_safe_service_unavailable_response(api_client, monkeypatch):
    def fail_commit(db):
        raise OperationalError("INSERT", {}, Exception("sensitive database detail"))

    monkeypatch.setattr(translations, "_commit", fail_commit)

    response = create_entry(api_client, "google-user-a", "Bonjour")

    assert response.status_code == 503
    assert response.json() == {
        "detail": "Le service de données est temporairement indisponible."
    }
    assert "sensitive database detail" not in response.text


def test_user_can_create_list_and_delete_own_history(api_client):
    created = create_entry(api_client, "google-user-a", "Bonjour")
    assert created.status_code == 201
    entry_id = created.json()["id"]

    listed = api_client.get(
        "/api/v1/translations", headers=auth_headers("google-user-a")
    )
    assert listed.status_code == 200
    assert len(listed.json()) == 1
    assert listed.json()[0]["source_text"] == "Bonjour"

    deleted = api_client.delete(
        f"/api/v1/translations/{entry_id}",
        headers=auth_headers("google-user-a"),
    )
    assert deleted.status_code == 204

    empty = api_client.get(
        "/api/v1/translations", headers=auth_headers("google-user-a")
    )
    assert empty.status_code == 200
    assert empty.json() == []


def test_users_cannot_read_or_delete_another_users_history(api_client):
    created = create_entry(api_client, "google-user-a", "Bonjour")
    entry_id = created.json()["id"]

    other_user_history = api_client.get(
        "/api/v1/translations", headers=auth_headers("google-user-b")
    )
    assert other_user_history.status_code == 200
    assert other_user_history.json() == []

    forbidden_delete = api_client.delete(
        f"/api/v1/translations/{entry_id}",
        headers=auth_headers("google-user-b"),
    )
    assert forbidden_delete.status_code == 404


def test_user_can_delete_all_own_history_without_affecting_others(api_client):
    assert create_entry(api_client, "google-user-a", "Bonjour").status_code == 201
    assert create_entry(api_client, "google-user-a", "Merci").status_code == 201
    assert create_entry(api_client, "google-user-b", "Hello").status_code == 201

    deleted = api_client.delete(
        "/api/v1/translations", headers=auth_headers("google-user-a")
    )
    assert deleted.status_code == 204

    user_a_history = api_client.get(
        "/api/v1/translations", headers=auth_headers("google-user-a")
    )
    user_b_history = api_client.get(
        "/api/v1/translations", headers=auth_headers("google-user-b")
    )
    assert user_a_history.json() == []
    assert len(user_b_history.json()) == 1
    assert user_b_history.json()[0]["source_text"] == "Hello"
