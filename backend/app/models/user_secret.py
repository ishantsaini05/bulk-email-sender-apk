"""
UserSecret Model - Store encrypted email passwords
"""
from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, Enum
from sqlalchemy.sql import func
from app.database import Base

class UserSecret(Base):
    __tablename__ = "user_secrets"
    __table_args__ = {"extend_existing": True}
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)  # ForeignKey to users.id
    
    # Email provider type
    email_provider = Column(
        Enum('gmail', 'outlook', 'yahoo', 'custom', name='email_provider_enum'),
        nullable=False
    )
    
    # User's email address (for display purposes)
    email_address = Column(String(255), nullable=False)
    
    # Encrypted app-specific password
    encrypted_app_password = Column(String(500), nullable=False)
    
    # Initialization Vector for AES encryption
    iv = Column(String(255), nullable=False)
    
    # SMTP Configuration (nullable for default providers)
    smtp_host = Column(String(100), nullable=True)
    smtp_port = Column(Integer, nullable=True)
    use_tls = Column(String(10), default='true')  # 'true' or 'false'
    
    # Timestamps
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    def __repr__(self):
        return f"<UserSecret(id={self.id}, user_id={self.user_id}, provider={self.email_provider})>"