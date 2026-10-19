from typing import Annotated, Any

from pydantic import BeforeValidator, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


def parse_cors(v: Any) -> list[str] | str:
    if isinstance(v, str) and not v.startswith("["):
        return [i.strip() for i in v.split(",")]
    elif isinstance(v, (list, str)):
        return v
    raise ValueError(v)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",
    )

    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"
    CORS_ORIGINS: Annotated[list[str], BeforeValidator(parse_cors)] = []

    DATABASE_URL: str | None = None
    AI_SERVICE_URL: str = "http://ai-service:8001"
    AI_MOCK: bool = True

    # Database
    POSTGRES_SERVER: str = "db"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "handtech_user"
    POSTGRES_PASSWORD: str = "handtech_dev_password"
    POSTGRES_DB: str = "handtech_db"

    @computed_field  # type: ignore[prop-decorator]
    @property
    def ASYNC_DATABASE_URI(self) -> str:
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def database_url(self) -> str:
        return self.DATABASE_URL or self.ASYNC_DATABASE_URI

    @property
    def ai_service_url(self) -> str:
        return self.AI_SERVICE_URL

    @property
    def ai_mock(self) -> bool:
        return self.AI_MOCK

    # JWT Settings (Réservés pour l'étape ultérieure)
    JWT_SECRET_KEY: str = "change_this_to_a_secure_32_byte_secret_in_production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30


settings = Settings()