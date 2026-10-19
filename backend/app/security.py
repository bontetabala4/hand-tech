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
