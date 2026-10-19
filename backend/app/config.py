from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Hand Tech API"
    environment: str = "development"
    database_url: str = "sqlite:///./handtech.db"
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 1440
    cors_origins: str = "*"

    ai_service_url: str = "http://ai-service:8001"
    ai_mock: bool = True
    max_image_bytes: int = 5_000_000

    free_daily_analyses: int = 300
    free_history_limit: int = 20
    premium_price_usd: float = 9.99
    premium_period_days: int = 30
    payment_webhook_secret: str = "change-me-webhook"

    @model_validator(mode="after")
    def _check_production_secrets(self) -> "Settings":
        if self.environment == "production":
            weak = {"change-me", "change-me-webhook"}
            if self.secret_key in weak or self.payment_webhook_secret in weak:
                raise ValueError("SECRET_KEY et PAYMENT_WEBHOOK_SECRET doivent être définis en production")
            if self.secret_key.startswith("CHANGE_ME") or len(self.secret_key) < 32:
                raise ValueError("SECRET_KEY trop faible pour la production")
        return self


settings = Settings()
