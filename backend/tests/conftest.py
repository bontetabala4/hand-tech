import os

os.environ["DATABASE_URL"] = "sqlite://"
os.environ["AI_MOCK"] = "true"
os.environ["ENVIRONMENT"] = "test"
os.environ["FREE_DAILY_ANALYSES"] = "3"
os.environ["FREE_HISTORY_LIMIT"] = "2"
os.environ["SECRET_KEY"] = "test-secret-key-0123456789-0123456789"
os.environ["PAYMENT_WEBHOOK_SECRET"] = "test-webhook-secret-0123456789"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    def override():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture()
def auth(client):
    r = client.post(
        "/api/v1/auth/register",
        json={"email": "bonte@example.com", "full_name": "Bonté T", "password": "motdepasse123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


IMG = {"file": ("frame.jpg", b"\xff\xd8\xff\xe0fakejpeg", "image/jpeg")}
