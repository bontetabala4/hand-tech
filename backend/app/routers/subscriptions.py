import hmac
import uuid
from datetime import timedelta

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.deps import get_current_user
from app.legacy_models import Subscription, User
from app.legacy_schemas import (
    CheckoutIn,
    CheckoutOut,
    PlanOut,
    SubscriptionStatusOut,
    WebhookIn,
)
from app.services.premium import active_subscription, quota_status
from app.timeutils import as_utc, utcnow

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


@router.get("/plans", response_model=list[PlanOut])
def plans() -> list[PlanOut]:
    return [
        PlanOut(
            code="free",
            name="Gratuit",
            price_usd=0.0,
            period_days=None,
            features=[
                f"{settings.free_daily_analyses} analyses par jour",
                f"Historique limité aux {settings.free_history_limit} derniers résultats",
            ],
        ),
        PlanOut(
            code="premium",
            name="Premium",
            price_usd=settings.premium_price_usd,
            period_days=settings.premium_period_days,
            features=[
                "Analyses illimitées",
                "Historique complet",
                "Accès prioritaire aux nouveautés",
            ],
        ),
    ]


@router.get("/me", response_model=SubscriptionStatusOut)
def my_subscription(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> SubscriptionStatusOut:
    q = quota_status(db, user.id)
    return SubscriptionStatusOut(
        plan=q.plan,
        expires_at=q.expires_at,
        daily_limit=q.daily_limit,
        used_today=q.used_today,
        remaining=q.remaining,
        history_limit=q.history_limit,
    )


@router.post("/checkout", response_model=CheckoutOut, status_code=status.HTTP_201_CREATED)
def checkout(
    payload: CheckoutIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckoutOut:
    """Crée une demande d'abonnement en attente de paiement.
    Le paiement réel (Mobile Money / carte) est confirmé via le webhook du prestataire."""
    reference = f"HT-{uuid.uuid4().hex[:12].upper()}"
    sub = Subscription(
        user_id=user.id,
        plan="premium",
        status="pending",
        provider=payload.provider,
        provider_ref=reference,
        amount_usd=settings.premium_price_usd,
    )
    db.add(sub)
    db.commit()
    return CheckoutOut(
        reference=reference,
        amount_usd=sub.amount_usd,
        status=sub.status,
        instructions=(
            f"Effectuez le paiement de {sub.amount_usd:.2f} USD en indiquant la référence "
            f"{reference}. Votre abonnement sera activé dès confirmation du paiement."
        ),
    )


def _activate(db: Session, sub: Subscription) -> None:
    now = utcnow()
    current = active_subscription(db, sub.user_id)
    start = as_utc(current.expires_at) if current and current.expires_at else now
    sub.status = "active"
    sub.started_at = now
    sub.expires_at = start + timedelta(days=settings.premium_period_days)
    db.commit()


@router.post("/webhook", status_code=status.HTTP_200_OK)
def payment_webhook(
    payload: WebhookIn,
    x_webhook_secret: str = Header(default=""),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    """Appelé par le prestataire de paiement (à brancher : Flutterwave, CinetPay, Stripe…)."""
    if not hmac.compare_digest(x_webhook_secret, settings.payment_webhook_secret):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Signature invalide")
    sub = db.scalar(select(Subscription).where(Subscription.provider_ref == payload.reference))
    if sub is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Référence inconnue")
    if sub.status == "pending":  # idempotent : un webhook rejoué n'a aucun effet
        if payload.status == "paid":
            _activate(db, sub)
        else:
            sub.status = "failed"
            db.commit()
    return {"status": sub.status}


@router.post("/dev/activate", response_model=SubscriptionStatusOut)
def dev_activate(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> SubscriptionStatusOut:
    """Active Premium sans paiement. Désactivé en production."""
    if settings.environment == "production":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    sub = Subscription(
        user_id=user.id,
        plan="premium",
        status="pending",
        provider="dev",
        provider_ref=f"DEV-{uuid.uuid4().hex[:12].upper()}",
        amount_usd=0.0,
    )
    db.add(sub)
    db.commit()
    _activate(db, sub)
    return my_subscription(user, db)
