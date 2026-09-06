"""
Route POST /api/v1/predictions.

Étape MVP (Semaine 1) : réponse mockée pour permettre au Dev Mobile
d'intégrer l'appel API sans attendre le modèle IA (voir cahier des
charges, section 9 : "réponses mockées avant disponibilité du modèle IA").

TODO(Dev IA): remplacer l'appel mocké par un appel réel au service IA
via app/services/ai_client.py une fois le PoC MediaPipe/modèle prêt.
"""

import random

from fastapi import APIRouter

from app.models.prediction import PredictionRequest, PredictionResponse

router = APIRouter(prefix="/api/v1", tags=["predictions"])

# Liste temporaire de signes MVP — à remplacer par la liste validée (ticket EK-012)
_SIGNES_MVP_TEMPORAIRES = ["BONJOUR", "MERCI", "OUI", "NON", "AIDE"]


@router.post("/predictions", response_model=PredictionResponse)
async def create_prediction(payload: PredictionRequest) -> PredictionResponse:
    """
    Reçoit une image et retourne une prédiction.

    Implémentation actuelle : mockée (aucun modèle IA appelé).
    """
    return PredictionResponse(
        sign=random.choice(_SIGNES_MVP_TEMPORAIRES),
        confidence=round(random.uniform(0.75, 0.99), 2),
        mocked=True,
    )
