"""API privée de l'historique des traductions textuelles."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_google_user
from app.db.session import get_db
from app.models.translation_history import TranslationHistory
from app.models.user import User
from app.schemas.translation import TranslationHistoryCreate, TranslationHistoryRead

router = APIRouter(prefix="/api/v1/translations", tags=["translation history"])


def _get_or_create_user(db: Session, claims: dict) -> User:
    """Associe le compte local au subject Google déjà vérifié par la dépendance."""
    user = db.scalar(select(User).where(User.google_sub == claims["sub"]))
    if user is None:
        user = User(
            google_sub=claims["sub"],
            email=claims.get("email"),
            email_verified=claims.get("email_verified") is True,
        )
        db.add(user)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            user = db.scalar(select(User).where(User.google_sub == claims["sub"]))
            if user is None:
                raise
        else:
            db.refresh(user)
    else:
        user.email = claims.get("email")
        user.email_verified = claims.get("email_verified") is True
        db.commit()
        db.refresh(user)
    return user


@router.post(
    "",
    response_model=TranslationHistoryRead,
    status_code=status.HTTP_201_CREATED,
)
def create_translation_history(
    payload: TranslationHistoryCreate,
    claims: dict = Depends(get_current_google_user),
    db: Session = Depends(get_db),
) -> TranslationHistory:
    user = _get_or_create_user(db, claims)
    entry = TranslationHistory(user_id=user.id, **payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("", response_model=list[TranslationHistoryRead])
def list_translation_history(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    claims: dict = Depends(get_current_google_user),
    db: Session = Depends(get_db),
) -> list[TranslationHistory]:
    user = _get_or_create_user(db, claims)
    statement = (
        select(TranslationHistory)
        .where(TranslationHistory.user_id == user.id)
        .order_by(TranslationHistory.created_at.desc(), TranslationHistory.id.desc())
        .offset(offset)
        .limit(limit)
    )
    return list(db.scalars(statement).all())


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_translation_history_entry(
    entry_id: uuid.UUID,
    claims: dict = Depends(get_current_google_user),
    db: Session = Depends(get_db),
) -> Response:
    user = _get_or_create_user(db, claims)
    entry = db.scalar(
        select(TranslationHistory).where(
            TranslationHistory.id == entry_id,
            TranslationHistory.user_id == user.id,
        )
    )
    if entry is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Traduction introuvable.")
    db.delete(entry)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def delete_all_translation_history(
    claims: dict = Depends(get_current_google_user),
    db: Session = Depends(get_db),
) -> Response:
    user = _get_or_create_user(db, claims)
    entries = db.scalars(
        select(TranslationHistory).where(TranslationHistory.user_id == user.id)
    ).all()
    for entry in entries:
        db.delete(entry)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
