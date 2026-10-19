from uuid import UUID

from pydantic import BaseModel, Field


class PredictionInput(BaseModel):
    session_id: UUID
    frames: list[str] = Field(default_factory=list)
    model_version: str = "production"

class PredictionResult(BaseModel):
    sign: str | None
    text: str | None
    confidence: float = Field(ge=0, le=1)
    model_name: str
    model_version: str
    processing_time_ms: int

class PredictionResponse(BaseModel):
    prediction: PredictionResult
