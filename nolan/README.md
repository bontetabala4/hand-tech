# LSF Sign Recognition Engine

MVP for isolated French Sign Language (LSF) sign recognition.

The first version accepts a video containing one sign, extracts hand and pose landmarks with MediaPipe, and returns a predicted gloss with a confidence score. It does not yet translate continuous LSF into natural French.

## Quick start

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
pytest
```

The API can be started with:

```powershell
uvicorn app.main:app --reload
```

Then open `http://127.0.0.1:8000/docs`.

## Current status

The repository contains the production shape of the MVP, but no trained model or licensed LSF dataset is included. Before inference can return predictions:

1. Obtain an LSF dataset with a licence compatible with the company use case.
2. Put isolated videos under `data/raw/<LABEL>/`.
3. Extract landmarks with `python scripts/extract_landmarks.py`.
4. Train a checkpoint with `python scripts/train.py`.
5. Set `MODEL_PATH` to the generated checkpoint.

## Dataset split

Splits must be made by signer, never randomly by video. A signer must not appear in both training and test sets, otherwise the evaluation can be misleading.

## API

`POST /v1/recognize` accepts a video file and returns:

```json
{
  "model_version": "untrained",
  "glosses": [
    {
      "label": "BONJOUR",
      "confidence": 0.92,
      "start": 0.0,
      "end": 1.2
    }
  ]
}
```

`GET /health` reports whether the service is ready and whether a checkpoint is loaded.

## Project layout

- `app/preprocessing.py`: video decoding and MediaPipe landmark extraction.
- `app/model.py`: PyTorch temporal classifier and checkpoint loading.
- `app/engine.py`: recognition orchestration.
- `app/main.py`: FastAPI application.
- `scripts/`: dataset preparation and training entry points.
- `tests/`: focused unit tests that do not require a camera or dataset.
