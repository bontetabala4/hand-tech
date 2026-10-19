def test_register_and_me(client, auth):
    r = client.get("/api/v1/auth/me", headers=auth)
    assert r.status_code == 200
    body = r.json()
    assert body["email"] == "bonte@example.com"
    assert body["plan"] == "free"


def test_duplicate_email(client, auth):
    r = client.post(
        "/api/v1/auth/register",
        json={"email": "BONTE@example.com", "full_name": "Autre", "password": "motdepasse123"},
    )
    assert r.status_code == 409


def test_login_ok_and_wrong_password(client, auth):
    ok = client.post(
        "/api/v1/auth/login", json={"email": "bonte@example.com", "password": "motdepasse123"}
    )
    assert ok.status_code == 200 and ok.json()["access_token"]
    bad = client.post(
        "/api/v1/auth/login", json={"email": "bonte@example.com", "password": "mauvais"}
    )
    assert bad.status_code == 401


def test_invalid_email_and_short_password(client):
    r = client.post(
        "/api/v1/auth/register",
        json={"email": "pas-un-email", "full_name": "Test", "password": "motdepasse123"},
    )
    assert r.status_code == 422
    r = client.post(
        "/api/v1/auth/register",
        json={"email": "a@example.com", "full_name": "Test", "password": "court"},
    )
    assert r.status_code == 422


def test_protected_routes_need_token(client):
    assert client.get("/api/v1/auth/me").status_code == 401
    assert client.get("/api/v1/predictions").status_code == 401
    assert client.get("/api/v1/auth/me", headers={"Authorization": "Bearer x"}).status_code == 401
