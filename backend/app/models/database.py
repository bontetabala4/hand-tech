"""
Configuration de la connexion à la base de données PostgreSQL via SQLAlchemy.

Ce fichier définit :
- le moteur de connexion (engine)
- la fabrique de sessions (SessionLocal)
- la classe de base pour tous les modèles ORM (Base)
- une dépendance FastAPI (get_db) pour injecter une session dans les routes
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Classe de base dont héritent tous les modèles ORM (tables SQL)."""

    pass


def get_db() -> Generator[Session, None, None]:
    """
    Dépendance FastAPI : ouvre une session DB pour la durée d'une requête,
    puis la ferme automatiquement (même en cas d'erreur).

    Usage dans une route :
        def ma_route(db: Session = Depends(get_db)):
            ...
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
