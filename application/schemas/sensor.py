from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional

class SensorDataCreate(BaseModel):
    device_id: str  # The ESP32 sends a string 'esp_test_002' which aligns with device_uid
    timestamp: datetime
    
    # Soil Data
    soil_moisture: float
    
    # Environment Data
    temperature: float
    humidity: float
    
    # System Data
    flow: float
    water_consumed: float = 0.0
    is_raining: bool = False
    
    # Telemetry
    solar_voltage: float = 0.0
    battery_percentage: float = 100.0
    solar_efficiency: float = 0.0

class ZoneDataResponse(BaseModel):
    id: int
    zone_id: str
    temperature: float
    humidity: float
    timestamp: datetime
    class Config: from_attributes = True

class NodeDataResponse(BaseModel):
    id: int
    device_id: str
    zone_id: str
    soil_moisture: float
    battery_percentage: float
    solar_voltage: float
    solar_efficiency: float
    timestamp: datetime
    class Config: from_attributes = True

class MasterDataResponse(BaseModel):
    id: int
    flow_rate: float
    water_consumed: float
    is_raining: bool
    battery_percentage: float
    solar_voltage: float
    solar_efficiency: float
    timestamp: datetime
    class Config: from_attributes = True

# For backwards compatibility or unified responses
class SensorDataResponse(BaseModel):
    id: int
    device_id: UUID4
    timestamp: datetime
    soil_moisture: Optional[float] = None
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    class Config: from_attributes = True
