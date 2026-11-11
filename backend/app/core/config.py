"""Configuration de l'application, chargée depuis les variables d'environnement."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Hand Tech API"
    environment: str = "development"

    database_url: str = "postgresql://handtech:handtech@db:5432/handtech"
    ai_service_url: str = "http://ai-service:8001"
    google_client_id: str | None = None

    libretranslate_url: str | None = None
    libretranslate_api_key: str | None = None
    translation_timeout_seconds: float = Field(default=30.0, gt=0, le=120)
    cors_allowed_origins: list[str] = Field(default_factory=list)


settings = Settings()
