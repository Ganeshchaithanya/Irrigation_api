import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from core.database import Base

class ValveCommand(Base):
    __tablename__ = "valve_commands"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    command = Column(String(20))         # ON / OFF
    status = Column(String(20), default="PENDING")  # PENDING / SENT / EXECUTED
    duration_minutes = Column(Float, nullable=True)
    issuer = Column(String(30), default="MANUAL")   # MANUAL / AI_ENGINE
    
    created_at = Column(DateTime, default=func.now())
