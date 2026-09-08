"""
Tests de l'endpoint de prédiction.

Astuce importante : on ne teste PAS contre le vrai PostgreSQL de
développement. On substitue la dépendance get_db par une base SQLite
en mémoire, créée à chaque exécution des tests. Cela rend les tests
rapides, reproductibles, et indépendants de Docker/PostgreSQL — ils
passeront aussi bien en local que dans la CI GitHub Actions.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app.main import app
from app.models.database import Base, get_db
from app.models import db_models  # noqa: F401  (enregistre les modèles sur Base)

# StaticPool est indispensable ici : par défaut, SQLAlchemy ouvrirait une
# nouvelle connexion SQLite à chaque requête, et "sqlite:///:memory:" crée
# une base DIFFÉRENTE et vide à chaque nouvelle connexion. StaticPool force
# la réutilisation d'une seule connexion, donc d'une seule base en mémoire,
# partagée entre la création des tables et les requêtes des tests.
engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base.metadata.create_all(bind=engine)


def _override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = _override_get_db

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


def test_prediction_is_persisted_in_database():
    """Vérifie que la prédiction est bien enregistrée, pas seulement renvoyée."""
    response = client.post(
        "/api/v1/predictions",
        json={"image_base64": "ZmFrZQ=="},
    )
    assert response.status_code == 200

    db = TestingSessionLocal()
    try:
        count = db.query(db_models.Prediction).count()
        assert count >= 1
    finally:
        db.close()


def test_list_predictions_returns_history():
    """Vérifie que GET /api/v1/predictions renvoie bien l'historique créé."""
    client.post("/api/v1/predictions", json={"image_base64": "ZmFrZQ=="})
    client.post("/api/v1/predictions", json={"image_base64": "ZmFrZQ=="})

    response = client.get("/api/v1/predictions")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2
    assert "sign" in data[0]
    assert "created_at" in data[0]
