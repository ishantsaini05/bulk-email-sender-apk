"""
EmailLog Model - Store email sending history (UPDATED)
"""
from sqlalchemy import Column, Integer, String, Text, TIMESTAMP
from sqlalchemy.sql import func
from app.database import Base

class EmailLog(Base):
    __tablename__ = "email_logs"
    __table_args__ = {"extend_existing": True}
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False)
    
    # Recipients (stored as JSON string)
    recipients = Column(String(2000), nullable=False)  # Changed from Text to String(2000)
    
    # Email details
    subject = Column(String(500))
    body_preview = Column(String(500), nullable=True)  # Make nullable
    
    # Status tracking
    status = Column(
        String(50),
        default='pending',
        nullable=False
    )
    
    # Email server message ID
    message_id = Column(String(500), nullable=True)
    
    # Error message if failed
    error_message = Column(Text, nullable=True)
    
    # Attachment count
    attachments_count = Column(Integer, default=0)
    
    # Timestamps
    created_at = Column(TIMESTAMP, server_default=func.now())
    sent_at = Column(TIMESTAMP, nullable=True)
    
    # NEW columns that exist in database (add these)
    sender_email = Column(String(255), nullable=True)
    body = Column(Text, nullable=True)
    cc_recipients = Column(Text, nullable=True)
    bcc_recipients = Column(Text, nullable=True)
    
    def __repr__(self):
        return f"<EmailLog(id={self.id}, user_id={self.user_id}, status={self.status})>"