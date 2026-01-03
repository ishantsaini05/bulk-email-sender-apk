"""
Email Sending API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import json

from app.database import get_db
from app.core.dependencies import get_current_user
from app.schemas.email import (
    EmailSendRequest, EmailSendResponse, 
    EmailLogResponse, EmailRecipient, EmailAttachment
)
from app.crud.email_crud import EmailConfigCRUD, EmailLogCRUD
from app.core.smtp_client import SMTPClient
from app.models.user import User

router = APIRouter()

def send_email_background(
    db: Session,
    user_id: int,
    email_request: EmailSendRequest,
    email_log_id: int
):
    try:
        config = EmailConfigCRUD.get_config(db, user_id)
        
        if not config:
            EmailLogCRUD.update_log_status(db, email_log_id, "failed")
            return
        
        password = EmailConfigCRUD.get_decrypted_password(db, user_id, config.email_provider)
        
        if not password:
            EmailLogCRUD.update_log_status(db, email_log_id, "failed")
            return
        
        smtp_client = SMTPClient(
            smtp_host=config.smtp_host or "smtp.gmail.com",
            smtp_port=config.smtp_port or 587,
            username=config.email_address,
            password=password,
            use_tls=getattr(config, 'use_tls', True)
        )
        
        attachments_list = []
        if email_request.attachments and len(email_request.attachments) > 0:
            print(f"Converting {len(email_request.attachments)} attachments to dict format...")
            for idx, att in enumerate(email_request.attachments):
                size = getattr(att, 'size_in_bytes', None) or getattr(att, 'size', 0)
                attachments_list.append({
                    'filename': att.filename,
                    'content_type': att.content_type,
                    'base64_content': att.base64_content,
                    'size_in_bytes': size,
                })
                print(f"   {idx+1}. {att.filename} ({att.content_type}, {size} bytes)")
        else:
            print(f"   No attachments to send")
        
        all_recipients = email_request.recipients.to.copy()
        failed_recipients = []
        successful_recipients = []
        
        for recipient in email_request.recipients.to:
            try:
                print(f"Sending to: {recipient}")
                print(f"   Subject: {email_request.subject}")
                print(f"   Body: {email_request.body[:50]}...")
                print(f"   Attachments: {len(attachments_list)}")
                
                message_id = smtp_client.send_email(
                    to_email=[recipient],
                    cc_email=[],
                    bcc_email=[],
                    subject=email_request.subject,
                    body=email_request.body,
                    is_html=email_request.is_html,
                    attachments=attachments_list
                )
                
                successful_recipients.append(recipient)
                print(f"Email sent successfully to: {recipient}")
                
            except Exception as e:
                failed_recipients.append(recipient)
                print(f"Failed to send to {recipient}: {str(e)}")
                import traceback
                traceback.print_exc()
        
        if successful_recipients:
            if failed_recipients:
                EmailLogCRUD.update_log_status(db, email_log_id, "partial", f"Sent to {len(successful_recipients)} recipients")
                print(f"Partial success: {len(successful_recipients)}/{len(all_recipients)} sent")
            else:
                EmailLogCRUD.update_log_status(db, email_log_id, "success", f"Sent to {len(successful_recipients)} recipients")
                print(f"All emails sent successfully!")
        else:
            EmailLogCRUD.update_log_status(db, email_log_id, "failed", "Failed to send to all recipients")
            print(f"All emails failed")
        
    except Exception as e:
        EmailLogCRUD.update_log_status(db, email_log_id, "failed", str(e))
        print(f"Error in send_email_background: {str(e)}")
        import traceback
        traceback.print_exc()

@router.post("/send", response_model=EmailSendResponse)
def send_email(
    email_request: EmailSendRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    config = EmailConfigCRUD.get_config(db, current_user.id)
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email configuration not found. Please setup first."
        )
    
    if not email_request.recipients.to:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one 'to' recipient is required"
        )
    
    print(f"Email request from user {current_user.id} ({config.email_address})")
    print(f"   To recipients: {email_request.recipients.to}")
    print(f"   Subject: {email_request.subject}")
    print(f"   Body length: {len(email_request.body)} chars")
    print(f"   Attachments: {len(email_request.attachments) if email_request.attachments else 0}")
    
    if email_request.attachments:
        total_size = 0
        for idx, att in enumerate(email_request.attachments):
            size = getattr(att, 'size_in_bytes', None) or getattr(att, 'size', 0)
            print(f"   {idx+1}. {att.filename} - {att.content_type} - {size} bytes")
            total_size += size
        
        print(f"   Total attachment size: {total_size/1024:.1f} KB")
        
        if total_size > 25 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Total attachment size {total_size/1024/1024:.1f}MB exceeds 25MB limit"
            )
    
    email_log = EmailLogCRUD.create_log(
        db=db,
        user_id=current_user.id,
        recipients=json.dumps({
            'to': email_request.recipients.to,
            'cc': email_request.recipients.cc,
            'bcc': email_request.recipients.bcc,
            'total': len(email_request.recipients.to) + 
                    len(email_request.recipients.cc) + 
                    len(email_request.recipients.bcc)
        }),
        subject=email_request.subject,
        status="pending"
    )
    
    background_tasks.add_task(
        send_email_background,
        db, current_user.id, email_request, email_log.id
    )
    
    return EmailSendResponse(
        success=True,
        message=f"Email is being sent individually to {len(email_request.recipients.to)} recipient(s)",
        email_log_id=email_log.id
    )

@router.get("/history", response_model=List[EmailLogResponse])
def get_email_history(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    logs = EmailLogCRUD.get_user_logs(db, current_user.id, skip, limit)
    return logs