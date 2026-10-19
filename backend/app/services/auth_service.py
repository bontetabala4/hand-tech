"""Logique métier liée aux comptes utilisateurs et à l'authentification."""

from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.models.db_models import User


def get_user_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()


def create_user(
    db: Session, email: str, password: str, display_name: str | None = None
) -> User:
    """
    Crée un utilisateur avec un mot de passe haché.

    Lève sqlalchemy.exc.IntegrityError si l'email existe déjà (contrainte
    unique en base) — c'est à l'appelant (la route) de la traduire en
    réponse HTTP 409 lisible plutôt que de laisser fuiter une erreur SQL.
    """
    user = User(
        email=email, hashed_password=hash_password(password), display_name=display_name
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    """Renvoie l'utilisateur si email + mot de passe correspondent, sinon None."""
    user = get_user_by_email(db, email)
    if user is None or not verify_password(password, user.hashed_password):
        return None
    return user
