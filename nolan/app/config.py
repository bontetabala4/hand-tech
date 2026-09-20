from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Vebron 8 Engine"
    model_path: Path = Path("models/model.pt")
    videomae_model_path: Path = Path("models/videomae")
    labels_path: Path = Path("configs/labels.json")
    confidence_threshold: float = 0.50
    max_video_bytes: int = 50 * 1024 * 1024
    max_video_seconds: float = 10.0

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
