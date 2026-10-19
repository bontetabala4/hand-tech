import random
from dataclasses import dataclass

import httpx
from fastapi import HTTPException

from app.config import settings

MVP_SIGNS = ["BONJOUR", "MERCI", "OUI", "NON", "AIDE"]


@dataclass
class AIResult:
    sign: str | None
    confidence: float
    hand_detected: bool
    mocked: bool


async def predict(image: bytes, content_type: str) -> AIResult:
    """Appelle le service IA, ou renvoie une prédiction simulée si AI_MOCK=true."""
    if settings.ai_mock:
        return AIResult(
            sign=random.choice(MVP_SIGNS),
            confidence=round(random.uniform(0.7, 0.99), 2),
            hand_detected=True,
            mocked=True,
        )
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{settings.ai_service_url}/predict",
                files={"file": ("frame", image, content_type)},
            )
    except httpx.HTTPError as exc:
        raise HTTPException(503, "Service de reconnaissance indisponible") from exc
    if resp.status_code == 503:
        raise HTTPException(503, "Le modèle de reconnaissance n'est pas encore disponible")
    if resp.status_code != 200:
        raise HTTPException(502, "Réponse invalide du service de reconnaissance")
    data = resp.json()
    return AIResult(
        sign=data.get("sign"),
        confidence=float(data.get("confidence", 0.0)),
        hand_detected=bool(data.get("hand_detected", False)),
        mocked=False,
    )


async def check_ai_health() -> bool:
    """Return True only when the real AI service reports healthy."""
    if settings.ai_mock:
        return True
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            response = await client.get(f"{settings.ai_service_url}/health")
            return response.status_code == 200
    except httpx.HTTPError:
        return False
