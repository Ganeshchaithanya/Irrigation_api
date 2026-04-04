from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class NotificationResponse(BaseModel):
    id: UUID4
    user_id: Optional[UUID4] = None
    zone_id: Optional[UUID4] = None
    type: str
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
