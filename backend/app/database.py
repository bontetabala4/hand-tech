
from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import settings


def _sync_database_url(url: str) -> str:
    """Convertit les URL PostgreSQL async en URL adaptées au moteur synchrone."""
    parsed_url = make_url(url)

    if parsed_url.drivername == "postgresql+asyncpg":
        parsed_url = parsed_url.set(drivername="postgresql+psycopg")
    elif parsed_url.drivername in {"postgres", "postgresql"}:
        parsed_url = parsed_url.set(drivername="postgresql+psycopg")

    return parsed_url.render_as_string(hide_password=False)


SYNC_DATABASE_URL = _sync_database_url(settings.database_url)

engine_kwargs = {"pool_pre_ping": True}
if SYNC_DATABASE_URL.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(SYNC_DATABASE_URL, **engine_kwargs)
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    pass


def get_db() -> Iterator[Session]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
