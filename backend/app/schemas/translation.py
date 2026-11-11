"""Schémas de validation pour l'historique des traductions."""

from datetime import datetime
import uuid

from pydantic import BaseModel, ConfigDict, Field


class TranslationHistoryCreate(BaseModel):
    source_text: str = Field(min_length=1, max_length=5000)
    translated_text: str = Field(min_length=1, max_length=5000)
    source_language: str = Field(min_length=2, max_length=16)
    target_language: str = Field(min_length=2, max_length=16)


class TranslationHistoryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    source_text: str
    translated_text: str
    source_language: str
    target_language: str
    created_at: datetime
