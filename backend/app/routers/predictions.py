import uuid

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.deps import get_current_user
from app.legacy_models import Prediction, User
from app.legacy_schemas import HistoryOut, PredictionOut
from app.services import ai_client
from app.services.premium import count_predictions, increment_usage, quota_status

router = APIRouter(prefix="/predictions", tags=["predictions"])

ALLOWED_TYPES = {"image/jpeg", "image/png"}


@router.post("", response_model=PredictionOut)
async def analyze(
    file: UploadFile = File(...),
    save: bool = Query(False, description="Enregistrer le résultat dans l'historique"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PredictionOut:
    """Analyse une image. Utilisé en continu par le mode temps réel (save=false)
    et pour enregistrer un résultat précis dans l'historique (save=true)."""
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, "Image JPEG ou PNG requise")
    data = await file.read(settings.max_image_bytes + 1)
    if not data:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Image vide")
    if len(data) > settings.max_image_bytes:
        raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Image trop volumineuse")

    quota = quota_status(db, user.id)
    if quota.remaining is not None and quota.remaining <= 0:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "quota_exceeded",
                "message": "Limite quotidienne atteinte. Passez à Premium pour un usage illimité.",
            },
        )

    result = await ai_client.predict(data, file.content_type or "image/jpeg")
    increment_usage(db, user.id)

    record: Prediction | None = None
    if save and result.sign is not None:
        record = Prediction(
            user_id=user.id,
            sign=result.sign,
            confidence=result.confidence,
            mocked=result.mocked,
        )
        db.add(record)
        db.commit()

    return PredictionOut(
        sign=result.sign,
        confidence=result.confidence,
        hand_detected=result.hand_detected,
        mocked=result.mocked,
        saved=record is not None,
        id=record.id if record else None,
        created_at=record.created_at if record else None,
    )


@router.get("", response_model=HistoryOut)
def history(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> HistoryOut:
    quota = quota_status(db, user.id)
    total = count_predictions(db, user.id)
    cap = quota.history_limit  # None pour Premium
    visible_total = min(total, cap) if cap is not None else total
    if cap is not None:
        limit = max(0, min(limit, cap - offset))
    stmt = (
        select(Prediction)
        .where(Prediction.user_id == user.id)
        .order_by(Prediction.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    items = db.scalars(stmt).all() if limit > 0 else []
    return HistoryOut(
        items=items,  # type: ignore[arg-type]
        total=visible_total,
        limited=cap is not None and total > cap,
    )


@router.delete("/{prediction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_prediction(
    prediction_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    record = db.get(Prediction, prediction_id)
    if record is None or record.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Résultat introuvable")
    db.delete(record)
    db.commit()
