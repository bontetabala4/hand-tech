"""Route de prédiction Hand Tech.

Aucune prédiction n'est produite tant qu'un véritable service IA
n'est pas disponible. Le contrat de requête existant est conservé.
"""

from fastapi import APIRouter, HTTPException, status

from app.models.prediction import PredictionRequest, PredictionResponse

router = APIRouter(prefix="/api/v1", tags=["predictions"])


@router.post(
    "/predictions",
    response_model=PredictionResponse,
    responses={
        503: {
            "description": "Service de reconnaissance IA indisponible."
        }
    },
)
async def create_prediction(payload: PredictionRequest) -> PredictionResponse:
    """Refuse explicitement la prédiction si le service IA n'est pas intégré."""
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail=(
            "Le service de reconnaissance IA n'est pas encore disponible. "
            "Aucune prédiction n'a été effectuée."
        ),
    )
