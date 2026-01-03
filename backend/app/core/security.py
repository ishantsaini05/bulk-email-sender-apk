from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.config import settings
from app.schemas.user import TokenData

# 🔥 REPLACE BCRYPT WITH ARGON2 (NO 72-BYTE LIMIT!)
pwd_context = CryptContext(
    schemes=["argon2"],  # Argon2 has NO byte limit!
    deprecated="auto",
    
    # Optimized for development (fast but secure)
    argon2__time_cost=2,          # Number of iterations
    argon2__memory_cost=102400,   # Memory usage (100MB)
    argon2__parallelism=8,        # Parallel threads
    argon2__salt_len=16,          # Salt length
    argon2__hash_len=32,          # Hash length
)

def get_password_hash(password: str) -> str:
    """Hash a password using Argon2 - NO 72-BYTE LIMIT!"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against an Argon2 hash"""
    return pwd_context.verify(plain_password, hashed_password)

# JWT functions (unchanged)
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Optional[TokenData]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            return None
        return TokenData(user_id=int(user_id))
    except JWTError:
        return None