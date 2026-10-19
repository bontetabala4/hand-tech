import re
import uuid
from datetime import datetime
from typing import Annotated

from pydantic import AfterValidator, BaseModel, Field

try:
    from email_validator import EmailNotValidError, validate_email
    _HAS_EMAIL_VALIDATOR = True
except ImportError:
    _HAS_EMAIL_VALIDATOR = False

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")


def _check_email(value: str) -> str:
    clean = value.strip().lower()
    if _HAS_EMAIL_VALIDATOR:
        try:
            return validate_email(clean, check_deliverability=False).normalized.lower()
        except EmailNotValidError as exc:
            raise ValueError(f"Adresse e-mail invalide : {exc}") from exc
    if not EMAIL_REGEX.match(clean):
        raise ValueError("Adresse e-mail invalide")
    return clean


Email = Annotated[str, AfterValidator(_check_email)]


class RegisterIn(BaseModel):
    email: Email
    full_name: str = Field(min_length=2, max_length=120)
    password: str = Field(min_length=8, max_length=128)


class LoginIn(BaseModel):
    email: Email
    password: str = Field(min_length=1, max_length=128)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    role: str = "user"
    plan: str
    is_active: bool = True
    created_at: datetime


class AdminStatsOut(BaseModel):
    total_users: int
    premium_users: int
    total_predictions: int
    avg_confidence: float
    active_signs_count: int
    ai_status: str


class AdminUserUpdateIn(BaseModel):
    is_active: bool | None = None
    plan: str | None = None


class SuperAdminRoleUpdateIn(BaseModel):
    role: str = Field(pattern="^(user|admin|super_admin)$")


class SystemHealthOut(BaseModel):
    backend_status: str
    db_status: str
    ai_service_status: str
    db_latency_ms: float
    active_connections: int
    total_predictions_today: int
    memory_usage_mb: float


class AuditLogOut(BaseModel):
    id: str
    timestamp: datetime
    actor: str
    action: str
    target: str
    details: str
    severity: str  # info | warning | critical


class GlobalConfigOut(BaseModel):
    maintenance_mode: bool
    min_confidence_threshold: float
    max_free_daily_analyses: int
    tts_enabled: bool
    ai_fallback_enabled: bool


class GlobalConfigUpdateIn(BaseModel):
    maintenance_mode: bool | None = None
    min_confidence_threshold: float | None = None
    max_free_daily_analyses: int | None = None
    tts_enabled: bool | None = None
    ai_fallback_enabled: bool | None = None


class PredictionOut(BaseModel):
    sign: str | None
    confidence: float
    hand_detected: bool
    mocked: bool
    saved: bool
    id: uuid.UUID | None = None
    created_at: datetime | None = None


class HistoryItemOut(BaseModel):
    id: uuid.UUID
    sign: str
    confidence: float
    mocked: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class HistoryOut(BaseModel):
    items: list[HistoryItemOut]
    total: int
    limited: bool


class PlanOut(BaseModel):
    code: str
    name: str
    price_usd: float
    period_days: int | None
    features: list[str]


class SubscriptionStatusOut(BaseModel):
    plan: str
    expires_at: datetime | None
    daily_limit: int | None
    used_today: int
    remaining: int | None
    history_limit: int | None


class CheckoutIn(BaseModel):
    provider: str = Field(default="mobile_money", pattern="^(mobile_money|card|manual)$")


class CheckoutOut(BaseModel):
    reference: str
    amount_usd: float
    status: str
    instructions: str


class WebhookIn(BaseModel):
    reference: str
    status: str = Field(pattern="^(paid|failed)$")
