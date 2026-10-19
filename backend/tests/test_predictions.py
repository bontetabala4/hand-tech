from tests.conftest import IMG


def test_analyze_without_save_does_not_touch_history(client, auth):
    r = client.post("/api/v1/predictions", files=IMG, headers=auth)
    assert r.status_code == 200
    body = r.json()
    assert body["sign"] in {"BONJOUR", "MERCI", "OUI", "NON", "AIDE"}
    assert body["saved"] is False
    assert client.get("/api/v1/predictions", headers=auth).json()["total"] == 0


def test_analyze_with_save_and_delete(client, auth):
    r = client.post("/api/v1/predictions?save=true", files=IMG, headers=auth)
    assert r.status_code == 200 and r.json()["saved"] is True
    hist = client.get("/api/v1/predictions", headers=auth).json()
    assert hist["total"] == 1
    pid = hist["items"][0]["id"]
    assert client.delete(f"/api/v1/predictions/{pid}", headers=auth).status_code == 204
    assert client.get("/api/v1/predictions", headers=auth).json()["total"] == 0


def test_rejects_bad_media_type(client, auth):
    r = client.post(
        "/api/v1/predictions",
        files={"file": ("x.txt", b"hello", "text/plain")},
        headers=auth,
    )
    assert r.status_code == 415


def test_free_quota_then_premium_unlocks(client, auth):
    for _ in range(3):
        assert client.post("/api/v1/predictions", files=IMG, headers=auth).status_code == 200
    blocked = client.post("/api/v1/predictions", files=IMG, headers=auth)
    assert blocked.status_code == 429
    assert blocked.json()["detail"]["code"] == "quota_exceeded"

    sub = client.post("/api/v1/subscriptions/dev/activate", headers=auth)
    assert sub.status_code == 200 and sub.json()["plan"] == "premium"
    assert client.post("/api/v1/predictions", files=IMG, headers=auth).status_code == 200


def test_free_history_is_capped_premium_is_not(client, auth):
    for _ in range(4):
        client.post("/api/v1/predictions?save=true", files=IMG, headers=auth)
    # le plan gratuit du test autorise 3 analyses/jour : la 4e n'est pas enregistrée
    free = client.get("/api/v1/predictions", headers=auth).json()
    assert free["total"] == 2 and len(free["items"]) == 2 and free["limited"] is True
    client.post("/api/v1/subscriptions/dev/activate", headers=auth)
    full = client.get("/api/v1/predictions", headers=auth).json()
    assert full["total"] == 3 and full["limited"] is False
