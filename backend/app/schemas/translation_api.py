"""Contrat HTTP de traduction attendu par le client Flutter."""

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


SUPPORTED_LANGUAGES = {"de", "en", "es", "fr", "it", "pt"}


class TextTranslationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    q: str = Field(min_length=1, max_length=5000)
    source: str = Field(min_length=2, max_length=5)
    target: str = Field(min_length=2, max_length=5)
    format: Literal["text"] = "text"

    @field_validator("q")
    @classmethod
    def validate_text(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Le texte à traduire ne peut pas être vide.")
        return value

    @field_validator("source", "target")
    @classmethod
    def validate_language(cls, value: str) -> str:
        normalized = value.lower()
        if normalized not in SUPPORTED_LANGUAGES:
            raise ValueError("Langue non prise en charge.")
        return normalized


class TextTranslationResponse(BaseModel):
    translatedText: str = Field(min_length=1)
