from sqlalchemy import Column, Integer, String, Enum, TIMESTAMP, text
from sqlalchemy.sql import func
from app.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    status = Column(Enum('active', 'blocked'), default='active')
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), 
                       onupdate=func.current_timestamp())

class UserSecret(Base):
    __tablename__ = "user_secrets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    email_provider = Column(Enum('gmail', 'outlook', 'custom'), nullable=False)
    encrypted_app_password = Column(String(500), nullable=False)
    iv = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), 
                       onupdate=func.current_timestamp())

class EmailLog(Base):
    __tablename__ = "email_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    recipients = Column(String(2000), nullable=False)
    subject = Column(String(500))
    status = Column(Enum('success', 'partial', 'failed'), nullable=False)
    message_id = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())