from sqlalchemy.orm import Session
from typing import Optional

from app.core.security import get_password_hash, verify_password
from app.models.user import User
from app.schemas.user import UserCreate
from app.utils.password import validate_password_strength

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()

def create_user(db: Session, user: UserCreate) -> User:
    # Validate password strength
    is_valid, message = validate_password_strength(user.password)
    if not is_valid:
        raise ValueError(message)

    # Check if user already exists
    if get_user_by_email(db, email=user.email):
        raise ValueError("User with this email already exists")

    hashed_password = get_password_hash(user.password)

    db_user = User(
        name=user.name,
        email=user.email,
        hashed_password=hashed_password
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email=email)

    if not user or user.status != "active":
        return None

    if not verify_password(password, user.hashed_password):
        return None

    return user
