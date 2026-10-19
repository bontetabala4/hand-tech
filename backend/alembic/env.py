from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool

from alembic import context
admin@DESKTOP-4C0DAR0 MINGW64 ~/Desktop/bonte/hand-tech/backend (feature/automatic-sign-language-routing)
$
echo "===== MODELES HISTORIQUES ====="
cat app/legacy_models.py
cat app/legacy_schemas.py

echo "===== NOUVEAUX MODELES ====="
cat app/models/user.py
cat app/models/translation.py
cat app/models/organization.py
cat app/models/device.py
cat app/models/__init__.py

echo "===== SECURITE ====="
cat app/security.py
cat app/core/security.py

echo "===== ROUTES ACTIVES ====="
cat app/routers/auth.py
cat app/routers/subscriptions.py

echo "===== CONFIGURATION ALEMBIC ====="
cat alembic.ini

echo "===== DEPENDANCES ET CONFIGURATION DU PROJET ====="
cat pyproject.toml
cat ../.env.example
===== MODELES HISTORIQUES =====
import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.timeutils import utcnow


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(120))
    password_hash: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    role: Mapped[str] = mapped_column(String(20), default="user")  # user | admin | super_admin
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Subscription(Base):
    __tablename__ = "subscriptions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    plan: Mapped[str] = mapped_column(String(20), default="premium")
    # pending | active | failed
    status: Mapped[str] = mapped_column(String(20), default="pending")
    provider: Mapped[str] = mapped_column(String(30), default="manual")
    provider_ref: Mapped[str | None] = mapped_column(String(120), unique=True, nullable=True)
    amount_usd: Mapped[float] = mapped_column(Float)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Prediction(Base):
    __tablename__ = "predictions"

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    sign: Mapped[str] = mapped_column(String(50))
    confidence: Mapped[float] = mapped_column(Float)
    mocked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )


class UsageDaily(Base):
    __tablename__ = "usage_daily"
    __table_args__ = (UniqueConstraint("user_id", "day", name="uq_usage_user_day"),)

    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    day: Mapped[date] = mapped_column(Date)
    analyses: Mapped[int] = mapped_column(Integer, default=0)
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
===== NOUVEAUX MODELES =====
import uuid
from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("organizations.id"))
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(30), default="USER", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    organization = relationship("Organization", back_populates="users")
import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class TranslationSession(Base):
    __tablename__ = "translation_sessions"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    organization_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("organizations.id"))
    device_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("devices.id"))
    status: Mapped[str] = mapped_column(String(30), default="CREATED", nullable=False)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    translation_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    average_confidence: Mapped[float | None] = mapped_column(Float)
    predictions = relationship("Prediction", back_populates="session")

class Prediction(Base):
    __tablename__ = "predictions"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("translation_sessions.id"), nullable=False)
    model_name: Mapped[str] = mapped_column(String(120), nullable=False)
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    sign: Mapped[str | None] = mapped_column(String(120))
    text: Mapped[str | None] = mapped_column(String(500))
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    processing_time_ms: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    session = relationship("TranslationSession", back_populates="predictions")
import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Organization(Base):
    __tablename__ = "organizations"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    sector: Mapped[str | None] = mapped_column(String(100))
    status: Mapped[str] = mapped_column(String(30), default="ACTIVE", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    users = relationship("User", back_populates="organization")
    devices = relationship("Device", back_populates="organization")
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Device(Base):
    __tablename__ = "devices"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    serial_number: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    type: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="OFFLINE", nullable=False)
    battery_level: Mapped[int | None] = mapped_column(Integer)
    firmware_version: Mapped[str | None] = mapped_column(String(50))
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    organization = relationship("Organization", back_populates="devices")
from app.models.device import Device
from app.models.organization import Organization
from app.models.translation import Prediction, TranslationSession
from app.models.user import User

__all__ = ["Organization", "User", "Device", "TranslationSession", "Prediction"]
===== SECURITE =====
import base64
import hashlib
import hmac
import json
import secrets
import time
import uuid
from datetime import timedelta

try:
    import bcrypt
    _HAS_BCRYPT = True
except ImportError:
    _HAS_BCRYPT = False

try:
    import jwt
    _HAS_PYJWT = True
except ImportError:
    _HAS_PYJWT = False

from app.config import settings
from app.timeutils import utcnow

ALGORITHM = "HS256"


# ---------------------------------------------------------------------------
# Password Hashing & Verification
# ---------------------------------------------------------------------------

def _prepare(password: str) -> bytes:
    """Pré-hash SHA-256 : normalisation et contournement de la limite de 72 octets."""
    return base64.b64encode(hashlib.sha256(password.encode("utf-8")).digest())


def hash_password(password: str) -> str:
    if _HAS_BCRYPT:
        return bcrypt.hashpw(_prepare(password), bcrypt.gensalt()).decode("utf-8")

    # Fallback robuste PBKDF2-HMAC-SHA256 (Standard Library)
    salt = secrets.token_hex(16)
    kdf = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
    return f"pbkdf2_sha256${salt}${base64.b64encode(kdf).decode('utf-8')}"


def verify_password(password: str, password_hash: str) -> bool:
    if password_hash.startswith("pbkdf2_sha256$"):
        parts = password_hash.split("$")
        if len(parts) != 3:
            return False
        salt, expected_b64 = parts[1], parts[2]
        kdf = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 100_000)
        return hmac.compare_digest(base64.b64encode(kdf).decode("utf-8"), expected_b64)

    if _HAS_BCRYPT:
        try:
            return bcrypt.checkpw(_prepare(password), password_hash.encode("utf-8"))
        except ValueError:
            return False
    return False


# ---------------------------------------------------------------------------
# JWT Token Generation & Verification
# ---------------------------------------------------------------------------

def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")


def _b64url_decode(s: str) -> bytes:
    padding = "=" * ((4 - len(s) % 4) % 4)
    return base64.urlsafe_b64decode((s + padding).encode("utf-8"))


def create_access_token(user_id: uuid.UUID) -> tuple[str, int]:
    expires = timedelta(minutes=settings.access_token_expire_minutes)
    exp_timestamp = int((utcnow() + expires).timestamp())
    now_timestamp = int(utcnow().timestamp())

    if _HAS_PYJWT:
        payload = {"sub": str(user_id), "iat": now_timestamp, "exp": exp_timestamp}
        token = jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)
        return token, int(expires.total_seconds())

    # Fallback JWT HMAC-SHA256 standard
    header_json = json.dumps({"alg": "HS256", "typ": "JWT"}).encode("utf-8")
    payload_json = json.dumps({"sub": str(user_id), "iat": now_timestamp, "exp": exp_timestamp}).encode("utf-8")

    header_b64 = _b64url_encode(header_json)
    payload_b64 = _b64url_encode(payload_json)

    msg = f"{header_b64}.{payload_b64}".encode()
    sig = hmac.new(settings.secret_key.encode("utf-8"), msg, hashlib.sha256).digest()
    sig_b64 = _b64url_encode(sig)

    return f"{header_b64}.{payload_b64}.{sig_b64}", int(expires.total_seconds())


def decode_token(token: str) -> uuid.UUID | None:
    if _HAS_PYJWT:
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
            return uuid.UUID(payload["sub"])
        except Exception:
            pass

    # Fallback standard JWT verification
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        header_b64, payload_b64, sig_b64 = parts
        msg = f"{header_b64}.{payload_b64}".encode()
        expected_sig = hmac.new(settings.secret_key.encode("utf-8"), msg, hashlib.sha256).digest()

        if not hmac.compare_digest(_b64url_decode(sig_b64), expected_sig):
            return None

        payload = json.loads(_b64url_decode(payload_b64).decode("utf-8"))
        if payload.get("exp", 0) < int(time.time()):
            return None  # Token expired

        return uuid.UUID(payload["sub"])
    except Exception:
        return None
from datetime import UTC, datetime, timedelta

from jose import jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return pwd_context.verify(password, password_hash)


def create_access_token(subject: str) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": subject,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.jwt_access_minutes),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=ALGORITHM)
===== ROUTES ACTIVES =====
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.legacy_models import User
from app.legacy_schemas import LoginIn, RegisterIn, TokenOut, UserOut
from app.security import create_access_token, hash_password, verify_password
from app.services.premium import quota_status

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterIn, db: Session = Depends(get_db)) -> TokenOut:
    if db.scalar(select(User).where(User.email == payload.email)):
        raise HTTPException(status.HTTP_409_CONFLICT, "Cette adresse e-mail est déjà utilisée")
    user = User(
        email=payload.email,
        full_name=payload.full_name.strip(),
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    token, expires_in = create_access_token(user.id)
    return TokenOut(access_token=token, expires_in=expires_in)


@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn, db: Session = Depends(get_db)) -> TokenOut:
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not user.is_active or not verify_password(
        payload.password, user.password_hash
    ):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "E-mail ou mot de passe incorrect")
    token, expires_in = create_access_token(user.id)
    return TokenOut(access_token=token, expires_in=expires_in)


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> UserOut:
    return UserOut(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        plan=quota_status(db, user.id).plan,
        is_active=user.is_active,
        created_at=user.created_at,
    )
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
===== CONFIGURATION ALEMBIC =====
[alembic]
script_location = alembic
prepend_sys_path = .

[loggers]
keys = root,sqlalchemy,alembic
[handlers]
keys = console
[formatters]
keys = generic
[logger_root]
level = WARN
handlers = console
qualname =
[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine
[logger_alembic]
level = INFO
handlers =
qualname = alembic
[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic
[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
===== DEPENDANCES ET CONFIGURATION DU PROJET =====
[build-system]
requires = ["setuptools>=68.0"]
build-backend = "setuptools.build_meta"

[project]
name = "fastapi-backend"
version = "0.1.0"
description = "Spécification et socle technique de l'API FastAPI"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115.0,<1.0.0",
    "uvicorn[standard]>=0.30.0,<1.0.0",
    "pydantic>=2.8.0,<3.0.0",
    "pydantic-settings>=2.4.0,<3.0.0",
    "sqlalchemy>=2.0.30,<3.0.0",
    "asyncpg>=0.29.0,<1.0.0",
    "alembic>=1.13.0,<2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.2.0,<9.0.0",
    "pytest-asyncio>=0.23.0,<1.0.0",
    "httpx>=0.27.0,<1.0.0",
    "ruff>=0.5.0,<1.0.0",
    "mypy>=1.10.0,<2.0.0",
]

[tool.setuptools.packages.find]
where = ["."]

[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # Pyflakes
    "I",   # isort (import sorting)
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
]
ignore = []

[tool.mypy]
python_version = "3.12"
strict = true
ignore_missing_imports = true
explicit_package_bases = true

[tool.pytest.ini_options]
minversion = "8.0"
addopts = "-ra -q"
testpaths = ["tests"]
asyncio_mode = "auto"PROJECT_NAME="Hand Tech API"
ENVIRONMENT="development"
DEBUG=True
API_V1_STR="/api/v1"

# Sécurité (Clé dev placeholder 32+ octets)
JWT_SECRET_KEY="DEV_ONLY_UNSECURE_SECRET_KEY_CHANGE_THIS_IN_PRODUCTION_32BYTES_MIN"
ACCESS_TOKEN_EXPIRE_MINUTES=60

# Configuration CORS (Format JSON strict compatible avec Pydantic Settings)
CORS_ORIGINS=["http://localhost:3000","http://127.0.0.1:3000"]

# PostgreSQL - Configuration du conteneur DB
POSTGRES_SERVER="db"
POSTGRES_PORT=5432
POSTGRES_USER="postgres_dev"
POSTGRES_PASSWORD="postgres_dev_password"
POSTGRES_DB="app_dev_db"

# URL de connexion SQLAlchemy Async (Communication inter-conteneurs Docker)
DATABASE_URL="postgresql+asyncpg://postgres_dev:postgres_dev_password@db:5432/app_dev_db"
admin@DESKTOP-4C0DAR0 MINGW64 ~/Desktop/bonte/hand-tech/backend (feature/automatic-sign-language-routing)
$

config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)
config.set_main_option("sqlalchemy.url", settings.database_url.replace("%", "%%"))
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=settings.database_url, target_metadata=target_metadata, literal_binds=True
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
