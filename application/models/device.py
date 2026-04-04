import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from application.core.database import Base

class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_uid = Column(String, unique=True, nullable=False, index=True)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    position_label = Column(String(10)) # START, MIDDLE, END
    role = Column(String(20), default="WORKER") # LEADER, WORKER, MASTER
    
    battery_level = Column(Float)
    solar_intensity = Column(Float)
    
    last_seen = Column(DateTime)
    status = Column(String(20), default="ACTIVE")
    
    zone = relationship("Zone", back_populates="devices")
    # Note: NodeData relationship removed — NodeData.device_id now references
    # devices.device_uid (VARCHAR) rather than the UUID PK. Use manual queries.
    
    created_at = Column(DateTime, default=func.now())

    __table_args__ = (
        UniqueConstraint('zone_id', 'position_label', name='_zone_position_uc'),
    )
