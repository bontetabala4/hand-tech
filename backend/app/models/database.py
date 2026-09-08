"""
Configuration de la connexion à la base de données PostgreSQL via SQLAlchemy.

Ce fichier définit :
- le moteur de connexion (engine)
- la fabrique de sessions (SessionLocal)
- la classe de base pour tous les modèles ORM (Base)
- une dépendance FastAPI (get_db) pour injecter une session dans les routes
- un type GUID indépendant du moteur, pour que les tests puissent tourner
  sur SQLite (rapide, en mémoire) sans dépendre d'un vrai PostgreSQL
"""

import uuid
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.types import CHAR, TypeDecorator

from app.core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    """Classe de base dont héritent tous les modèles ORM (tables SQL)."""

    pass


class GUID(TypeDecorator):
    """
    Type UUID portable : utilise le type natif PostgreSQL en production,
    et une simple colonne texte (CHAR(36)) sur les moteurs qui ne le
    supportent pas nativement (ex: SQLite, utilisé pour les tests).

    Sans ce type, nos modèles seraient couplés à PostgreSQL et impossibles
    à tester rapidement sans lancer un vrai conteneur de base de données.
    """

    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_UUID(as_uuid=True))
        return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == "postgresql":
            return str(value)
        return str(value if isinstance(value, uuid.UUID) else uuid.UUID(str(value)))

    def process_result_value(self, value, dialect):
        if value is None or isinstance(value, uuid.UUID):
            return value
        return uuid.UUID(str(value))


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
