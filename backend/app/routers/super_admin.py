import time
import uuid
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select, text
from sqlalchemy.orm import Session

from app.database import engine, get_db
from app.deps import require_super_admin
from app.legacy_models import Prediction, Subscription, User
from app.legacy_schemas import (
    AuditLogOut,
    GlobalConfigOut,
    GlobalConfigUpdateIn,
    SuperAdminRoleUpdateIn,
    SystemHealthOut,
)
from app.services.ai_client import check_ai_health

router = APIRouter(prefix="/super-admin", tags=["super-admin"])

# In-memory mock configuration & audit log store
_GLOBAL_CONFIG = {
    "maintenance_mode": False,
    "min_confidence_threshold": 0.60,
    "max_free_daily_analyses": 5,
    "tts_enabled": True,
    "ai_fallback_enabled": True,
}

_AUDIT_LOGS = [
    {
        "id": "log-001",
        "timestamp": datetime.now(UTC),
        "actor": "super_admin@handtech.ai",
        "action": "SYSTEM_BOOT",
        "target": "Infrastructure",
        "details": "Démarrage des conteneurs Backend & Service IA",
        "severity": "info",
    },
    {
        "id": "log-002",
        "timestamp": datetime.now(UTC),
        "actor": "system",
        "action": "DB_MIGRATION",
        "target": "PostgreSQL 16",
        "details": "Schéma appliqué avec succès via Alembic",
        "severity": "info",
    },
]


@router.get("/system-health", response_model=SystemHealthOut)
async def get_system_health(
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
) -> SystemHealthOut:
    t0 = time.perf_counter()
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        db_status = "healthy"
        db_latency_ms = round((time.perf_counter() - t0) * 1000, 2)
    except Exception:
        db_status = "unreachable"
        db_latency_ms = 999.0

    ai_healthy = await check_ai_health()
    today_start = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    today_predictions = db.scalar(
        select(func.count(Prediction.id)).where(Prediction.created_at >= today_start)
    ) or 0

    return SystemHealthOut(
        backend_status="healthy",
        db_status=db_status,
        ai_service_status="healthy" if ai_healthy else "degraded",
        db_latency_ms=db_latency_ms,
        active_connections=engine.pool.checkedin() + engine.pool.checkedout() if hasattr(engine, "pool") else 4,
        total_predictions_today=today_predictions,
        memory_usage_mb=128.4,
    )


@router.get("/revenue")
def get_revenue_stats(
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
) -> dict:
    total_revenue = db.scalar(
        select(func.sum(Subscription.amount_usd)).where(Subscription.status == "active")
    ) or 0.0

    recent_transactions = db.scalars(
        select(Subscription)
        .order_by(Subscription.created_at.desc())
        .limit(10)
    ).all()

    return {
        "mrr_usd": round(float(total_revenue), 2),
        "arr_projected_usd": round(float(total_revenue) * 12, 2),
        "active_subscriptions": len(recent_transactions),
        "recent_transactions": [
            {
                "id": str(s.id),
                "user_id": str(s.user_id),
                "plan": s.plan,
                "amount": s.amount_usd,
                "provider": s.provider,
                "status": s.status,
                "date": s.created_at.isoformat() if s.created_at else None,
            }
            for s in recent_transactions
        ],
    }


@router.patch("/users/{user_id}/role")
def update_user_role(
    user_id: uuid.UUID,
    payload: SuperAdminRoleUpdateIn,
    db: Session = Depends(get_db),
    admin: User = Depends(require_super_admin),
) -> dict:
    target = db.get(User, user_id)
    if not target:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Utilisateur introuvable")
    
    if target.id == admin.id and payload.role != "super_admin":
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Impossible de rétrograder votre propre compte Super Admin")

    old_role = target.role
    target.role = payload.role
    db.commit()

    _AUDIT_LOGS.insert(
        0,
        {
            "id": f"log-{uuid.uuid4().hex[:6]}",
            "timestamp": datetime.now(UTC),
            "actor": admin.email,
            "action": "ROLE_CHANGE",
            "target": target.email,
            "details": f"Changement de rôle : {old_role} -> {payload.role}",
            "severity": "warning",
        },
    )
    return {"message": f"Rôle de {target.email} mis à jour : {payload.role}"}


@router.get("/audit-logs", response_model=list[AuditLogOut])
def get_audit_logs(_: User = Depends(require_super_admin)) -> list[AuditLogOut]:
    return [
        AuditLogOut(
            id=log["id"],
            timestamp=log["timestamp"],
            actor=log["actor"],
            action=log["action"],
            target=log["target"],
            details=log["details"],
            severity=log["severity"],
        )
        for log in _AUDIT_LOGS[:50]
    ]


@router.get("/config", response_model=GlobalConfigOut)
def get_global_config(_: User = Depends(require_super_admin)) -> GlobalConfigOut:
    return GlobalConfigOut(**_GLOBAL_CONFIG)


@router.patch("/config", response_model=GlobalConfigOut)
def update_global_config(
    payload: GlobalConfigUpdateIn,
    admin: User = Depends(require_super_admin),
) -> GlobalConfigOut:
    updates = payload.model_dump(exclude_unset=True)
    _GLOBAL_CONFIG.update(updates)

    _AUDIT_LOGS.insert(
        0,
        {
            "id": f"log-{uuid.uuid4().hex[:6]}",
            "timestamp": datetime.now(UTC),
            "actor": admin.email,
            "action": "CONFIG_UPDATE",
            "target": "GlobalSystemConfig",
            "details": f"Paramètres modifiés : {updates}",
            "severity": "info",
        },
    )
    return GlobalConfigOut(**_GLOBAL_CONFIG)
