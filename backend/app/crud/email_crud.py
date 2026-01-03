"""
CRUD operations for Email
"""
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import Optional, List
from app.models.user_secret import UserSecret
from app.models.email_log import EmailLog
from app.schemas.email_config import EmailConfigCreate, EmailConfigUpdate
from app.core.encryption import encrypt_password, decrypt_password
import json

class EmailConfigCRUD:
    
    @staticmethod
    def create_config(db: Session, user_id: int, config: EmailConfigCreate):
        """Create or update email configuration"""
        # Encrypt the app password
        encrypted_password, iv = encrypt_password(config.app_password)
        
        # Check if config already exists
        existing = db.query(UserSecret).filter(
            UserSecret.user_id == user_id,
            UserSecret.email_provider == config.email_provider.value
        ).first()
        
        if existing:
            # Update existing
            existing.encrypted_app_password = encrypted_password
            existing.iv = iv
            existing.email_address = config.email_address
            existing.smtp_host = config.smtp_host
            existing.smtp_port = config.smtp_port
            existing.use_tls = str(config.use_tls).lower()
            db.commit()
            db.refresh(existing)
            return existing
        
        # Create new
        db_config = UserSecret(
            user_id=user_id,
            email_provider=config.email_provider.value,
            email_address=config.email_address,
            encrypted_app_password=encrypted_password,
            iv=iv,
            smtp_host=config.smtp_host,
            smtp_port=config.smtp_port,
            use_tls=str(config.use_tls).lower()
        )
        db.add(db_config)
        db.commit()
        db.refresh(db_config)
        return db_config
    
    @staticmethod
    def get_config(db: Session, user_id: int, provider: str = None):
        """Get email configuration for user"""
        query = db.query(UserSecret).filter(UserSecret.user_id == user_id)
        if provider:
            query = query.filter(UserSecret.email_provider == provider)
        return query.first()
    
    @staticmethod
    def delete_config(db: Session, user_id: int, provider: str = None):
        """Delete email configuration"""
        query = db.query(UserSecret).filter(UserSecret.user_id == user_id)
        if provider:
            query = query.filter(UserSecret.email_provider == provider)
        deleted_count = query.delete()
        db.commit()
        return deleted_count
    
    @staticmethod
    def get_decrypted_password(db: Session, user_id: int, provider: str):
        """Get decrypted app password"""
        config = db.query(UserSecret).filter(
            UserSecret.user_id == user_id,
            UserSecret.email_provider == provider
        ).first()
        if not config:
            return None
        return decrypt_password(config.encrypted_app_password, config.iv)

class EmailLogCRUD:
    
    @staticmethod
    def create_log(db: Session, user_id: int, recipients: List[str], 
                   subject: str, status: str, message_id: Optional[str] = None):
        """Create email log entry"""
        recipients_str = json.dumps(recipients) if isinstance(recipients, list) else recipients
        log = EmailLog(
            user_id=user_id,
            recipients=recipients_str,
            subject=subject,
            status=status,
            message_id=message_id
        )
        db.add(log)
        db.commit()
        db.refresh(log)
        return log
    
    @staticmethod
    def get_user_logs(db: Session, user_id: int, skip: int = 0, limit: int = 50):
        """Get email logs for user"""
        return db.query(EmailLog)\
            .filter(EmailLog.user_id == user_id)\
            .order_by(desc(EmailLog.created_at))\
            .offset(skip)\
            .limit(limit)\
            .all()
    
    @staticmethod
    def update_log_status(db: Session, log_id: int, status: str, message_id: str = None):
        """Update email log status"""
        log = db.query(EmailLog).filter(EmailLog.id == log_id).first()
        if log:
            log.status = status
            if message_id:
                log.message_id = message_id
            db.commit()
            db.refresh(log)
        return log
