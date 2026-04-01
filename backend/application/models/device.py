import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base

class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_uid = Column(String, unique=True, nullable=False, index=True)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    position_label = Column(String(10)) # START, MIDDLE, END
    
    battery_level = Column(Float)
    solar_intensity = Column(Float)
    
    last_seen = Column(DateTime)
    status = Column(String(20), default="ACTIVE")
    
    zone = relationship("Zone", back_populates="devices")
    sensor_data = relationship("SensorData", back_populates="device", cascade="all, delete-orphan")
    
    created_at = Column(DateTime, default=func.now())

    __table_args__ = (
        UniqueConstraint('zone_id', 'position_label', name='_zone_position_uc'),
    )
