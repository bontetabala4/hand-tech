"""Tests de validation des données d'historique."""

import pytest
from pydantic import ValidationError

from app.schemas.translation import TranslationHistoryCreate


def test_translation_history_accepts_valid_payload():
    payload = TranslationHistoryCreate(
        source_text="Bonjour",
        translated_text="Hello",
        source_language="fr",
        target_language="en",
    )
    assert payload.source_text == "Bonjour"
    assert payload.target_language == "en"


def test_translation_history_rejects_empty_text():
    with pytest.raises(ValidationError):
        TranslationHistoryCreate(
            source_text="",
            translated_text="Hello",
            source_language="fr",
            target_language="en",
        )


def test_translation_history_rejects_text_over_5000_characters():
    with pytest.raises(ValidationError):
        TranslationHistoryCreate(
            source_text="x" * 5001,
            translated_text="Hello",
            source_language="fr",
            target_language="en",
        )
