"""Point d'entrée de l'API Hand Tech."""

from fastapi import FastAPI

from app.api.v1 import auth, predictions
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="API backend du projet Hand Tech — reconnaissance de la langue des signes.",
)

app.include_router(predictions.router)
app.include_router(auth.router)


@app.get("/health", tags=["monitoring"])
async def health_check() -> dict:
    """Vérification simple de disponibilité du service."""
    return {"status": "ok", "environment": settings.environment}
