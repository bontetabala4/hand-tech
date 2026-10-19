import uuid
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.config import settings
from app.legacy_models import Prediction, Subscription, UsageDaily
from app.timeutils import as_utc, utcnow


@dataclass
class Quota:
    plan: str
    expires_at: datetime | None
    daily_limit: int | None
    used_today: int
    remaining: int | None
    history_limit: int | None


def active_subscription(db: Session, user_id: uuid.UUID) -> Subscription | None:
    now = utcnow()
    subs = db.scalars(
        select(Subscription).where(
            Subscription.user_id == user_id, Subscription.status == "active"
        )
    ).all()
    valid = [s for s in subs if s.expires_at and as_utc(s.expires_at) > now]
    return max(valid, key=lambda s: as_utc(s.expires_at)) if valid else None


def is_premium(db: Session, user_id: uuid.UUID) -> bool:
    return active_subscription(db, user_id) is not None


def used_today(db: Session, user_id: uuid.UUID) -> int:
    value = db.scalar(
        select(UsageDaily.analyses).where(
            UsageDaily.user_id == user_id, UsageDaily.day == utcnow().date()
        )
    )
    return value or 0


def quota_status(db: Session, user_id: uuid.UUID) -> Quota:
    sub = active_subscription(db, user_id)
    used = used_today(db, user_id)
    if sub:
        return Quota("premium", sub.expires_at, None, used, None, None)
    limit = settings.free_daily_analyses
    return Quota("free", None, limit, used, max(0, limit - used), settings.free_history_limit)


def increment_usage(db: Session, user_id: uuid.UUID) -> None:
    today = utcnow().date()
    row = db.scalar(
        select(UsageDaily).where(UsageDaily.user_id == user_id, UsageDaily.day == today)
    )
    if row is None:
        db.add(UsageDaily(user_id=user_id, day=today, analyses=1))
    else:
        row.analyses += 1
    db.commit()


def count_predictions(db: Session, user_id: uuid.UUID) -> int:
    return db.scalar(select(func.count()).select_from(Prediction).where(Prediction.user_id == user_id)) or 0
