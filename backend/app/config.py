from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # App
    APP_NAME: str = "Premium Email App"
    DEBUG: bool = False
    
    # AES Encryption - ADD THIS
    AES_SECRET_KEY: Optional[str] = None
    
    class Config:
        env_file = ".env"

settings = Settings()