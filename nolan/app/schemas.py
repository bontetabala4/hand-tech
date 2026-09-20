from pydantic import BaseModel, Field


class GlossPrediction(BaseModel):
    label: str
    confidence: float = Field(ge=0.0, le=1.0)
    start: float = Field(ge=0.0)
    end: float = Field(ge=0.0)


class RecognitionResponse(BaseModel):
    model_version: str
    glosses: list[GlossPrediction]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
