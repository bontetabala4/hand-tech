import httpx
from fastapi import APIRouter, HTTPException

from app.core.config import settings
from app.schemas.translation import PredictionInput, PredictionResponse

router = APIRouter()

@router.post("/predict", response_model=PredictionResponse)
async def predict(payload: PredictionInput):
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{settings.ai_service_url}/api/v1/inference/predict",
                json=payload.model_dump(mode="json"),
            )
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=503, detail=f"AI service unavailable: {exc}") from exc
