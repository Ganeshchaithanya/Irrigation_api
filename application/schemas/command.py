from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class CommandCreate(BaseModel):
    zone_id: UUID4
    command: str
    duration_minutes: Optional[int] = None
    issuer: Optional[str] = "MANUAL"

class AICommandExecuteRequest(BaseModel):
    zone_id: UUID4
    action: str
    duration: int

class CommandResponse(BaseModel):
    id: UUID4
    zone_id: UUID4
    command: str
    status: str
    duration_minutes: Optional[int] = None
    issuer: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
