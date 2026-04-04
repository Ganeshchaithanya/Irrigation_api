from pydantic import BaseModel, UUID4
from datetime import datetime, date
from typing import Optional

class ETDataCreate(BaseModel):
    zone_id: UUID4
    timestamp: datetime
    et_value: float

class ETDataResponse(ETDataCreate):
    id: UUID4
    created_at: datetime
    
    class Config:
        from_attributes = True

class DailyAggregateCreate(BaseModel):
    zone_id: UUID4
    date: date
    avg_moisture: float
    avg_temperature: float
    avg_humidity: float
    total_irrigation_minutes: float
    water_usage: float

class DailyAggregateResponse(DailyAggregateCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class MonthlyAggregateCreate(BaseModel):
    zone_id: UUID4
    month: date
    avg_moisture: float
    total_irrigation_minutes: float
    water_usage: float

class MonthlyAggregateResponse(MonthlyAggregateCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class YearlyAggregateCreate(BaseModel):
    zone_id: UUID4
    year: int
    avg_moisture: float
    total_irrigation_minutes: float
    water_usage: float

class YearlyAggregateResponse(YearlyAggregateCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class PlantHealthScoreCreate(BaseModel):
    zone_id: UUID4
    score: int
    status: str
    reason: Optional[str] = None
    date: date

class PlantHealthScoreResponse(PlantHealthScoreCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True
