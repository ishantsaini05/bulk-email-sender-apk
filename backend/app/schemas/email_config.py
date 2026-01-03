"""
Email Configuration Schemas
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class EmailProvider(str, Enum):
    GMAIL = "gmail"
    OUTLOOK = "outlook"
    CUSTOM = "custom"

class EmailConfigBase(BaseModel):
    email_provider: EmailProvider
    email_address: EmailStr
    app_password: str = Field(..., min_length=8, description="App-specific password")
    smtp_host: Optional[str] = None
    smtp_port: Optional[int] = None
    use_tls: bool = True

class EmailConfigCreate(EmailConfigBase):
    pass

class EmailConfigUpdate(BaseModel):
    app_password: Optional[str] = Field(None, min_length=8)
    smtp_host: Optional[str] = None
    smtp_port: Optional[int] = None
    use_tls: Optional[bool] = None

class EmailConfigResponse(BaseModel):
    id: int
    user_id: int
    email_provider: EmailProvider
    email_address: EmailStr
    smtp_host: Optional[str]
    smtp_port: Optional[int]
    use_tls: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class EmailTestRequest(BaseModel):
    test_recipient: EmailStr = Field(..., description="Email to send test to")

class EmailTestResponse(BaseModel):
    success: bool
    message: str
    test_email_id: Optional[str] = None