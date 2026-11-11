"""API privée de l'historique des traductions textuelles."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_google_user
from app.db.session import get_db
from app.models.translation_history import TranslationHistory
from app.models.user import User
from app.schemas.translation import TranslationHistoryCreate, TranslationHistoryRead

router = APIRouter(prefix="/api/v1/translations", tags=["translation history"])


def _commit(db: Session) -> None:
    """Valide une transaction ou la remet proprement à zéro en cas d'échec."""
    try:
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise


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
            _commit(db)
        except IntegrityError:
            # Deux requêtes simultanées peuvent tenter de créer le même compte.
            user = db.scalar(select(User).where(User.google_sub == claims["sub"]))
            if user is None:
                raise
        else:
            db.refresh(user)
    else:
        # Une lecture ne doit pas provoquer une écriture si le profil n'a pas changé.
        token_email = claims.get("email")
        token_email_verified = claims.get("email_verified") is True
        changed = False

        if token_email is not None and user.email != token_email:
            user.email = token_email
            changed = True
        if user.email_verified != token_email_verified:
            user.email_verified = token_email_verified
            changed = True

        if changed:
            _commit(db)
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
    _commit(db)
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
    _commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def delete_all_translation_history(
    claims: dict = Depends(get_current_google_user),
    db: Session = Depends(get_db),
) -> Response:
    user = _get_or_create_user(db, claims)
    db.execute(
        delete(TranslationHistory).where(TranslationHistory.user_id == user.id)
    )
    _commit(db)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
