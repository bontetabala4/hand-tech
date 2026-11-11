"""Modèles SQLAlchemy enregistrés pour les migrations."""

from app.models.translation_history import TranslationHistory
from app.models.user import User

__all__ = ["User", "TranslationHistory"]
