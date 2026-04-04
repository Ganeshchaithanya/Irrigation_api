import uuid
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from application.core.database import Base

class AiValidationLog(Base):
    __tablename__ = "ai_validation_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    decision = Column(String)
    reasoning = Column(String)
    confidence = Column(Float)
    risk_level = Column(String(10))
    anomaly_detected = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=func.now())

class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    type = Column(String(30))
    predicted_moisture = Column(Float)
    predicted_irrigation_need = Column(Float)
    hours_until_needed = Column(Float)
    tomorrow_mm_needed = Column(Float)
    is_virtual_sensing_active = Column(Boolean, default=False)
    
    stage_context = Column(String)
    recommendation_text = Column(String)
    
    prediction_time = Column(DateTime)
    created_at = Column(DateTime, default=func.now())

class CropPlan(Base):
    __tablename__ = "crop_plans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    recommended_crop = Column(String)
    
    irrigation_strategy = Column(JSONB)
    fertilizer_plan = Column(JSONB)
    pesticide_plan = Column(JSONB)
    
    expected_yield = Column(Float)
    risk_score = Column(Float)
    
    created_at = Column(DateTime, default=func.now())
