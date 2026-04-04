import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from application.core.database import Base

class IrrigationLog(Base):
    __tablename__ = "irrigation_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    
    duration_minutes = Column(Float)
    water_used = Column(Float)
    
    trigger_type = Column(String(20)) # AUTO / MANUAL
    reason_code = Column(String)
    
    moisture_before = Column(Float)
    moisture_after = Column(Float)
    et_context = Column(Float)
    
    created_at = Column(DateTime, default=func.now())
