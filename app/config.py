"""Configuration settings for the embeddings service."""

from pydantic import ConfigDict
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Authentication
    auth_token: str

    # Model configuration
    model_name: str = "ViT-B-32"
    pretrained: str = "laion2b_s34b_b79k"

    # Server configuration
    workers: int = 4

    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=False,
    )


settings = Settings()
