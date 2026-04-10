from pydantic import BaseModel, UUID4, field_validator
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
    
    # Hardware Status
    valve_status: Optional[bool] = False
    commanded_state: Optional[bool] = False
    rssi: Optional[int] = None

    @field_validator('valve_status', 'commanded_state', mode='before')
    @classmethod
    def validate_bool_or_none(cls, v):
        if v is None:
            return False
        return v

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
    valve_status: bool
    rssi: Optional[int] = None
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
    valve_status: bool
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
