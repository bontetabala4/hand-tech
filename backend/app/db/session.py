"""Création du moteur et des sessions SQLAlchemy."""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


def get_db() -> Generator[Session, None, None]:
    """Fournit une session DB et nettoie toute transaction interrompue."""
    db = SessionLocal()
    try:
        yield db
    except Exception:
        # Évite de laisser une transaction en échec dans la session.
        db.rollback()
        raise
    finally:
        db.close()
