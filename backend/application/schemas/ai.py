from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import Optional, Dict, Any

class AiValidationLogCreate(BaseModel):
    zone_id: UUID4
    decision: str
    reasoning: str
    confidence: float
    risk_level: str
    anomaly_detected: bool = False

class AiValidationLogResponse(AiValidationLogCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class PredictionCreate(BaseModel):
    zone_id: UUID4
    type: str # moisture_forecast, irrigation_demand, etc.
    predicted_moisture: float
    predicted_irrigation_need: float
    
    hours_until_needed: Optional[float] = None
    tomorrow_mm_needed: Optional[float] = None
    is_virtual_sensing_active: bool = False
    
    stage_context: Optional[str] = None
    recommendation_text: Optional[str] = None
    prediction_time: datetime

class PredictionResponse(PredictionCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True

class CropPlanCreate(BaseModel):
    zone_id: UUID4
    recommended_crop: str
    irrigation_strategy: Dict[str, Any]
    fertilizer_plan: Dict[str, Any]
    pesticide_plan: Dict[str, Any]
    expected_yield: float
    risk_score: float

class CropPlanResponse(CropPlanCreate):
    id: UUID4
    created_at: datetime

    class Config:
        from_attributes = True
