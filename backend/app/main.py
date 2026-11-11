"""Point d'entrée de l'API Hand Tech."""

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.api.v1 import auth, translate, translations
from app.core.config import settings

logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description=(
        "API backend de Hand Tech. "
        "La reconnaissance de la langue des signes n'est pas encore intégrée."
    ),
)

if settings.cors_allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_allowed_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization"],
    )


@app.exception_handler(SQLAlchemyError)
async def database_error_handler(
    request: Request, exc: SQLAlchemyError
) -> JSONResponse:
    """Renvoie une erreur générique sans exposer les détails de la base."""
    logger.exception("Erreur pendant une opération sur la base de données.")
    return JSONResponse(
        status_code=503,
        content={
            "detail": "Le service de données est temporairement indisponible."
        },
    )


app.include_router(auth.router)
app.include_router(translations.router)
app.include_router(translate.router)


@app.get("/health", tags=["monitoring"])
async def health_check() -> dict:
    """Vérification simple de disponibilité du service."""
    return {"status": "ok", "environment": settings.environment}
