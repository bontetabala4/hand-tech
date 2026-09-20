import tempfile
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile

from app.config import get_settings
from app.engine import RecognitionEngine
from app.schemas import HealthResponse, RecognitionResponse

settings = get_settings()
app = FastAPI(title=settings.app_name, version="0.1.0")

try:
    engine = RecognitionEngine(settings)
except RuntimeError:
    engine = None


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", model_loaded=engine is not None and engine.is_ready)


@app.post("/v1/recognize", response_model=RecognitionResponse)
async def recognize(file: UploadFile = File(...)) -> RecognitionResponse:
    if engine is None or not engine.is_ready:
        raise HTTPException(status_code=503, detail="No trained model is configured")
    payload = await file.read()
    if len(payload) > settings.max_video_bytes:
        raise HTTPException(status_code=413, detail="Video exceeds the maximum allowed size")
    suffix = Path(file.filename or "sequence.webm").suffix or ".webm"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=True) as temporary_file:
        temporary_file.write(payload)
        temporary_file.flush()
        try:
            return engine.recognize(temporary_file.name)
        except ValueError as error:
            raise HTTPException(status_code=422, detail=str(error)) from error
        except RuntimeError as error:
            raise HTTPException(status_code=422, detail=str(error)) from error
