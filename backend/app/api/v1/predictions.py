"""
Route POST /api/v1/predictions.

Étape MVP (Semaine 1-2) : le signe reconnu est encore mocké (aucun modèle IA
appelé), mais chaque prédiction est désormais réellement enregistrée en base
de données (ticket EK-031), pour que l'historique (section 9, écran
"Historique") ait de vraies données à afficher dès maintenant.

TODO(Dev IA): remplacer le choix aléatoire par un appel réel au service IA
via app/services/ai_client.py une fois le PoC MediaPipe/modèle prêt.
"""

import random

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.models.database import get_db
from app.models.prediction import PredictionHistoryItem, PredictionRequest, PredictionResponse
from app.services.prediction_service import get_recent_predictions, record_prediction

router = APIRouter(prefix="/api/v1", tags=["predictions"])

# Liste temporaire de signes MVP — à remplacer par la liste validée (ticket EK-012)
_SIGNES_MVP_TEMPORAIRES = ["BONJOUR", "MERCI", "OUI", "NON", "AIDE"]


@router.post("/predictions", response_model=PredictionResponse)
async def create_prediction(
    payload: PredictionRequest, db: Session = Depends(get_db)
) -> PredictionResponse:
    """
    Reçoit une image et retourne une prédiction.

    Le signe est encore mocké, mais la prédiction est réellement persistée
    (table predictions, rattachée à une session et un utilisateur).
    """
    sign = random.choice(_SIGNES_MVP_TEMPORAIRES)
    confidence = round(random.uniform(0.75, 0.99), 2)

    record_prediction(db, sign=sign, confidence=confidence, mocked=True)

    return PredictionResponse(sign=sign, confidence=confidence, mocked=True)


@router.get("/predictions", response_model=list[PredictionHistoryItem])
async def list_predictions(
    limit: int = 50, db: Session = Depends(get_db)
) -> list[PredictionHistoryItem]:
    """
    Retourne l'historique des prédictions les plus récentes (écran
    "Historique", section 9 du cahier des charges).

    MVP mono-utilisateur anonyme : pas encore de filtrage par utilisateur
    connecté (voir TODO dans prediction_service.get_recent_predictions).
    """
    predictions = get_recent_predictions(db, limit=limit)
    return [PredictionHistoryItem.model_validate(p) for p in predictions]
