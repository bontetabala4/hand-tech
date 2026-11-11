"""Authentification Google ID Token pour les routes protégées."""

from typing import Any

import requests
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.exceptions import GoogleAuthError, TransportError
from google.auth.transport.requests import Request
from google.oauth2 import id_token

from app.core.config import settings

router = APIRouter(prefix="/api/v1/auth", tags=["authentication"])
bearer_scheme = HTTPBearer(auto_error=False)


def verify_google_id_token(token: str, client_id: str) -> dict[str, Any]:
    """Vérifie signature, issuer, expiration et audience auprès de Google."""
    return id_token.verify_oauth2_token(
        token,
        Request(),
        audience=client_id,
    )


async def get_current_google_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict[str, Any]:
    """Retourne uniquement les informations issues d'un ID Token vérifié."""
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentification Bearer requise.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="L'authentification Google n'est pas encore configurée.",
        )

    try:
        claims = verify_google_id_token(
            credentials.credentials,
            settings.google_client_id,
        )
    except TransportError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Le service de vérification Google est temporairement inaccessible.",
        ) from None
    except (ValueError, GoogleAuthError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google ID Token invalide ou expiré.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None

    subject = claims.get("sub")
    if not isinstance(subject, str) or not subject:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Le jeton Google ne contient pas d'identifiant utilisateur valide.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    email = claims.get("email")
    return {
        "sub": subject,
        "email": email if isinstance(email, str) else None,
        "email_verified": claims.get("email_verified") is True,
    }


@router.get("/me")
async def read_current_user(
    current_user: dict[str, Any] = Depends(get_current_google_user),
) -> dict[str, Any]:
    """Expose l'identité Google vérifiée, sans créer de compte en base."""
    return {"authenticated": True, "user": current_user}
