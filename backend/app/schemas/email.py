"""
Email Sending Schemas
"""
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime

class EmailRecipient(BaseModel):
    to: List[EmailStr] = Field(..., description="Primary recipients")
    cc: Optional[List[EmailStr]] = None
    bcc: Optional[List[EmailStr]] = None

class EmailAttachment(BaseModel):
    filename: str
    content_type: str
    base64_content: str = Field(..., description="Base64 encoded file content")

class EmailSendRequest(BaseModel):
    recipients: EmailRecipient
    subject: str = Field(..., min_length=1, max_length=500)
    body: str = Field(..., description="Email body (HTML supported)")
    is_html: bool = False
    attachments: Optional[List[EmailAttachment]] = None

class EmailLogResponse(BaseModel):
    id: int
    user_id: int
    recipients: str
    subject: str
    status: str
    message_id: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class EmailSendResponse(BaseModel):
    success: bool
    message: str
    message_id: Optional[str] = None
    email_log_id: Optional[int] = None