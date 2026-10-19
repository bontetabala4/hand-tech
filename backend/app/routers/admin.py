import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import require_admin
from app.legacy_models import Prediction, Subscription, User
from app.legacy_schemas import AdminStatsOut, AdminUserUpdateIn, HistoryItemOut, UserOut
from app.services.ai_client import check_ai_health
from app.services.premium import quota_status

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats", response_model=AdminStatsOut)
async def get_admin_stats(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> AdminStatsOut:
    total_users = db.scalar(select(func.count(User.id))) or 0
    now = datetime.now(UTC)
    premium_users = (
        db.scalar(
            select(func.count(func.distinct(Subscription.user_id))).where(
                Subscription.status == "active",
                Subscription.expires_at > now,
            )
        )
        or 0
    )
    total_predictions = db.scalar(select(func.count(Prediction.id))) or 0
    avg_conf = db.scalar(select(func.avg(Prediction.confidence))) or 0.88
    ai_healthy = await check_ai_health()

    return AdminStatsOut(
        total_users=total_users,
        premium_users=premium_users,
        total_predictions=total_predictions,
        avg_confidence=round(float(avg_conf), 4),
        active_signs_count=5,  # BONJOUR, MERCI, OUI, NON, AIDE
        ai_status="online" if ai_healthy else "mock_fallback",
    )


@router.get("/users")
def list_users(
    search: str | None = None,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> dict:
    query = select(User)
    if search:
        pattern = f"%{search.strip().lower()}%"
        query = query.where(
            (func.lower(User.email).like(pattern)) | (func.lower(User.full_name).like(pattern))
        )
    total = db.scalar(select(func.count()).select_from(query.subquery())) or 0
    users = db.scalars(query.order_by(User.created_at.desc()).offset(offset).limit(limit)).all()

    items = [
        UserOut(
            id=u.id,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            plan=quota_status(db, u.id).plan,
            is_active=u.is_active,
            created_at=u.created_at,
        )
        for u in users
    ]
    return {"total": total, "items": items}


@router.patch("/users/{user_id}/status")
def update_user_status(
    user_id: uuid.UUID,
    payload: AdminUserUpdateIn,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
) -> dict:
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Utilisateur introuvable")
    
    # Prevent disabling oneself
    if payload.is_active is not None:
        if target.id == admin.id and not payload.is_active:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Impossible de désactiver son propre compte")
        target.is_active = payload.is_active

    if payload.plan:
        from datetime import timedelta

        from app.legacy_models import Subscription
        if payload.plan == "premium":
            now = datetime.now(UTC)
            sub = Subscription(
                user_id=target.id,
                plan="premium",
                status="active",
                provider="admin_grant",
                provider_ref=f"grant_{uuid.uuid4().hex[:8]}",
                amount_usd=0.0,
                started_at=now,
                expires_at=now + timedelta(days=365),
            )
            db.add(sub)
        elif payload.plan == "free":
            # Expire active subscriptions
            active_subs = db.scalars(
                select(Subscription).where(
                    Subscription.user_id == target.id,
                    Subscription.status == "active",
                )
            ).all()
            for s in active_subs:
                s.status = "canceled"
                s.expires_at = datetime.now(UTC)

    db.commit()
    return {"message": "Utilisateur mis à jour avec succès"}


@router.get("/dataset")
def get_dataset_info(_: User = Depends(require_admin)) -> dict:
    return {
        "model_version": "v1.2.0-mediapipe-mlp",
        "input_features": 63,  # 21 3D hand landmarks
        "classes": [
            {"id": "BONJOUR", "label": "Bonjour / Salutations", "samples": 420, "accuracy": 0.96},
            {"id": "MERCI", "label": "Merci / Gratitude", "samples": 380, "accuracy": 0.94},
            {"id": "OUI", "label": "Oui / Accord", "samples": 410, "accuracy": 0.95},
            {"id": "NON", "label": "Non / Désaccord", "samples": 395, "accuracy": 0.93},
            {"id": "AIDE", "label": "Aide / Urgence", "samples": 450, "accuracy": 0.97},
        ],
        "last_trained_at": "2026-09-15T14:30:00Z",
    }


@router.get("/flagged", response_model=list[HistoryItemOut])
def get_flagged_predictions(
    limit: int = 20,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> list[HistoryItemOut]:
    # Return predictions with confidence < 0.70 for quality review
    items = db.scalars(
        select(Prediction)
        .where(Prediction.confidence < 0.70)
        .order_by(Prediction.created_at.desc())
        .limit(limit)
    ).all()
    return [
        HistoryItemOut(
            id=p.id,
            sign=p.sign,
            confidence=p.confidence,
            mocked=p.mocked,
            created_at=p.created_at,
        )
        for p in items
    ]
