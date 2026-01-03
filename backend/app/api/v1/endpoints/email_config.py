"""
Email Configuration API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.core.dependencies import get_current_user
from app.schemas.email_config import (
    EmailConfigCreate, EmailConfigResponse, 
    EmailConfigUpdate, EmailTestRequest, EmailTestResponse
)
from app.crud.email_crud import EmailConfigCRUD
from app.core.smtp_client import SMTPClient
from app.models.user import User

router = APIRouter()

@router.post("/setup", response_model=EmailConfigResponse)
def setup_email_config(
    config: EmailConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Setup email configuration (Gmail/Outlook)
    """
    # Validate provider-specific settings
    if config.email_provider.value == "gmail":
        if not config.smtp_host:
            config.smtp_host = "smtp.gmail.com"
        if not config.smtp_port:
            config.smtp_port = 587
    
    elif config.email_provider.value == "outlook":
        if not config.smtp_host:
            config.smtp_host = "smtp.office365.com"
        if not config.smtp_port:
            config.smtp_port = 587
    
    elif config.email_provider.value == "custom":
        if not config.smtp_host or not config.smtp_port:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="SMTP host and port required for custom provider"
            )
    
    # Save configuration
    db_config = EmailConfigCRUD.create_config(db, current_user.id, config)
    
    return db_config

@router.get("/", response_model=EmailConfigResponse)
def get_email_config(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get user's email configuration
    """
    config = EmailConfigCRUD.get_config(db, current_user.id)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email configuration not found"
        )
    
    return config

@router.post("/test", response_model=EmailTestResponse)
def test_email_config(
    test_request: EmailTestRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Test email configuration by sending a test email
    """
    # Get user's email config
    config = EmailConfigCRUD.get_config(db, current_user.id)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email configuration not found. Please setup first."
        )
    
    try:
        # Get decrypted password
        from app.crud.email_crud import EmailConfigCRUD
        password = EmailConfigCRUD.get_decrypted_password(db, current_user.id, config.email_provider)
        
        if not password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not decrypt password"
            )
        
        # Send test email
        smtp_client = SMTPClient(
            smtp_host=config.smtp_host or "smtp.gmail.com",
            smtp_port=config.smtp_port or 587,
            username=config.email_address,
            password=password,
            use_tls=config.use_tls if hasattr(config, 'use_tls') else True
        )
        
        message_id = smtp_client.send_email(
            to_email=test_request.test_recipient,
            subject="Test Email from Premium Email App",
            body="This is a test email to verify your email configuration is working correctly.",
            is_html=False
        )
        
        return EmailTestResponse(
            success=True,
            message="Test email sent successfully",
            test_email_id=message_id
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to send test email: {str(e)}"
        )

@router.delete("/")
def delete_email_config(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete user's email configuration
    """
    deleted = EmailConfigCRUD.delete_config(db, current_user.id)
    
    if deleted == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No email configuration found"
        )
    
    return {"message": "Email configuration deleted successfully"}