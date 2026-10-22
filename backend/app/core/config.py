"""Configuration de l'application, chargée depuis les variables d'environnement."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )

    app_name: str = "Hand Tech API"
    environment: str = "development"

    database_url: str = "postgresql://handtech:handtech@db:5432/handtech"
    ai_service_url: str = "http://ai-service:8001"


settings = Settings()
