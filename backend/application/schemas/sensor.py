from pydantic import BaseModel, UUID4
from datetime import datetime

class SensorDataCreate(BaseModel):
    device_id: str  # The ESP32 sends a string 'esp_test_002' which aligns with device_uid
    timestamp: datetime
    soil_moisture: float
    temperature: float
    humidity: float
    flow: float
    water_consumed: float = 0.0
    is_raining: bool = False
    
    solar_voltage: float = 0.0
    battery_percentage: float = 100.0

class SensorDataResponse(SensorDataCreate):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True # pydantic v2 compatible
