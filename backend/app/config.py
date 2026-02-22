import os

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "GAT Mentor API"
    DEBUG: bool = False
    DATABASE_URL: str = "sqlite:///./gat_mentor.db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    API_V1_PREFIX: str = "/api/v1"
    ALLOWED_ORIGINS: str = "*"
    PORT: int = 8000

    class Config:
        env_file = ".env" if os.path.exists(".env") else None


settings = Settings()
