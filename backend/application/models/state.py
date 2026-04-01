from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from core.database import Base

class ZoneState(Base):
    __tablename__ = "zone_state"

    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"), primary_key=True)
    
    state = Column(String(20)) # IDLE / IRRIGATING / COOLDOWN / ERROR / SOAKING
    last_irrigation_time = Column(DateTime)
    cycle_start_time = Column(DateTime) # Tracks when the current cycle & soak loop began
    
    current_moisture = Column(Float)
    expected_moisture = Column(Float)
    
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
