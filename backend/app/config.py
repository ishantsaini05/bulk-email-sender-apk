from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database - Railway से automatically मिलेगा
    DATABASE_URL: str
    
    # JWT
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # App
    APP_NAME: str = "Premium Email App"
    DEBUG: bool = False
    
    # AES Encryption
    AES_SECRET_KEY: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
