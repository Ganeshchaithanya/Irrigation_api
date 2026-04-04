from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class ChatRequest(BaseModel):
    user_id: UUID4
    query: str
    language: str = "en"

class ChatLogCreate(BaseModel):
    user_id: UUID4
    query: str
    response: str
    language: str

class ChatLogResponse(ChatLogCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class MessageTemplateCreate(BaseModel):
    code: str
    en: str
    hi: str
    kn: str
    te: str

class MessageTemplateResponse(MessageTemplateCreate):
    class Config:
        from_attributes = True
