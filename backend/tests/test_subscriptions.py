import os


def test_plans_listed(client):
    plans = client.get("/api/v1/subscriptions/plans").json()
    assert [p["code"] for p in plans] == ["free", "premium"]


def test_checkout_and_webhook_flow(client, auth):
    co = client.post("/api/v1/subscriptions/checkout", json={"provider": "mobile_money"}, headers=auth)
    assert co.status_code == 201
    ref = co.json()["reference"]
    assert client.get("/api/v1/subscriptions/me", headers=auth).json()["plan"] == "free"

    bad = client.post(
        "/api/v1/subscriptions/webhook",
        json={"reference": ref, "status": "paid"},
        headers={"X-Webhook-Secret": "wrong"},
    )
    assert bad.status_code == 401

    ok = client.post(
        "/api/v1/subscriptions/webhook",
        json={"reference": ref, "status": "paid"},
        headers={"X-Webhook-Secret": os.environ["PAYMENT_WEBHOOK_SECRET"]},
    )
    assert ok.status_code == 200 and ok.json()["status"] == "active"
    me = client.get("/api/v1/subscriptions/me", headers=auth).json()
    assert me["plan"] == "premium" and me["daily_limit"] is None

    # webhook rejoué : aucun effet, pas de double prolongation
    before = me["expires_at"]
    client.post(
        "/api/v1/subscriptions/webhook",
        json={"reference": ref, "status": "paid"},
        headers={"X-Webhook-Secret": os.environ["PAYMENT_WEBHOOK_SECRET"]},
    )
    assert client.get("/api/v1/subscriptions/me", headers=auth).json()["expires_at"] == before


def test_failed_payment_keeps_free(client, auth):
    ref = client.post("/api/v1/subscriptions/checkout", json={}, headers=auth).json()["reference"]
    client.post(
        "/api/v1/subscriptions/webhook",
        json={"reference": ref, "status": "failed"},
        headers={"X-Webhook-Secret": os.environ["PAYMENT_WEBHOOK_SECRET"]},
    )
    assert client.get("/api/v1/subscriptions/me", headers=auth).json()["plan"] == "free"


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}
