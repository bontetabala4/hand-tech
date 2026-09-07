"""
Point d'entrée d'Alembic. Modifié pour :
1. Lire l'URL de la base depuis app.core.config (au lieu de alembic.ini en dur),
   pour ne pas dupliquer la configuration ni exposer de secret dans un fichier versionné.
2. Pointer vers nos modèles (app.models.db_models) pour la détection automatique
   des changements de schéma (--autogenerate).
"""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.core.config import settings
from app.models.database import Base
from app.models import db_models  # noqa: F401  (nécessaire pour enregistrer les modèles)

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Génère le SQL sans se connecter réellement à la base (mode 'offline')."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Applique les migrations en se connectant réellement à la base."""
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
