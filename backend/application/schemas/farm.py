from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class ZoneCreate(BaseModel):
    acre_id: UUID4
    name: str
    crop_type: str
    soil_type: str
    mode: str = "AUTO"
    start_node: str = "Unknown"
    mid_node: str = "Unknown"
    end_node: str = "Unknown"

class ZoneResponse(ZoneCreate):
    id: UUID4
    created_at: datetime
    
    class Config:
        from_attributes = True

class AcreCreate(BaseModel):
    farm_id: UUID4
    name: str
    size: float

class AcreResponse(AcreCreate):
    id: UUID4
    created_at: datetime
    
    class Config:
        from_attributes = True

class FarmCreate(BaseModel):
    name: str
    location: str

class FarmResponse(FarmCreate):
    id: UUID4
    user_id: UUID4
    created_at: datetime
    
    class Config:
        from_attributes = True

class DiaryLogCreate(BaseModel):
    title: str
    description: str
    event_type: str = "action"
    icon_name: str = "plus"
    color_hex: str = "#10b981"

class DiaryLogResponse(DiaryLogCreate):
    id: UUID4
    farm_id: UUID4
    created_at: datetime
    
    class Config:
        from_attributes = True
