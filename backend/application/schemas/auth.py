from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    phone: str
    name: str

class UserResponse(UserCreate):
    id: UUID4
    email: Optional[str] = None
    preferred_language: str
    is_phone_verified: bool
    is_email_verified: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class OTPRequest(BaseModel):
    phone: str

class OTPVerify(BaseModel):
    phone: str
    otp_code: str

class SessionResponse(BaseModel):
    token: str
    user_id: UUID4
    expires_at: datetime

class UserPreferenceUpdate(BaseModel):
    preferred_language: str
