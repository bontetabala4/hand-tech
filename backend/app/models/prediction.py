"""
Schémas Pydantic du contrat /api/v1/predictions.

Ce contrat est la frontière stable entre le mobile, le backend et le
service IA. Toute modification doit être versionnée (voir docs/architecture.md).
"""

import uuid
from datetime import datetime, timezone

from pydantic import BaseModel, Field


class PredictionRequest(BaseModel):
    """Requête envoyée par l'application mobile."""

    image_base64: str = Field(
        ...,
        description="Frame image encodée en base64 (JPEG/PNG).",
    )
    session_id: str | None = Field(
        default=None,
        description="Identifiant de session côté mobile, pour l'historique.",
    )


class PredictionResponse(BaseModel):
    """Réponse renvoyée au mobile."""

    sign: str = Field(..., description="Signe reconnu, ex: 'BONJOUR'.")
    confidence: float = Field(
        ..., ge=0.0, le=1.0, description="Score de confiance du modèle."
    )
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    mocked: bool = Field(
        default=False,
        description="True tant que le service IA n'est pas branché (MVP).",
    )


class PredictionHistoryItem(BaseModel):
    """Une prédiction telle qu'enregistrée en base, pour l'écran Historique (section 9)."""

    id: uuid.UUID
    sign: str
    confidence: float
    mocked: bool
    created_at: datetime

    class Config:
        from_attributes = True  # permet de construire directement depuis un objet ORM
