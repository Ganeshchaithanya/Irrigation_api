from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class IrrigationLogCreate(BaseModel):
    zone_id: UUID4
    start_time: datetime
    end_time: Optional[datetime] = None
    trigger_type: str
    reason_code: str
    moisture_before: Optional[float] = None
    moisture_after: Optional[float] = None
    et_context: Optional[float] = None

class IrrigationLogResponse(IrrigationLogCreate):
    id: UUID4
    duration_minutes: Optional[float] = None
    water_used: Optional[float] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
