import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from application.core.database import Base

class Farm(Base):
    __tablename__ = "farms"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    name = Column(String)
    location = Column(String)
    created_at = Column(DateTime, default=func.now())

    owner = relationship("User", back_populates="farms")
    acres = relationship("Acre", back_populates="farm")
    diary_logs = relationship("DiaryLog", back_populates="farm")

class DiaryLog(Base):
    __tablename__ = "diary_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id"))
    title = Column(String)
    description = Column(String)
    event_type = Column(String) 
    icon_name = Column(String) 
    color_hex = Column(String, default="#10b981")
    created_at = Column(DateTime, default=func.now())

    farm = relationship("Farm", back_populates="diary_logs")

class Acre(Base):
    __tablename__ = "acres"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id"))
    name = Column(String)
    size = Column(Float)
    created_at = Column(DateTime, default=func.now())

    farm = relationship("Farm", back_populates="acres")
    zones = relationship("Zone", back_populates="acre")

class Zone(Base):
    __tablename__ = "zones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    acre_id = Column(UUID(as_uuid=True), ForeignKey("acres.id"))
    name = Column(String)
    crop_type = Column(String)
    soil_type = Column(String)
    mode = Column(String(10), default="AUTO") # AUTO / MANUAL
    
    start_node = Column(String, default="Unknown", nullable=True)
    mid_node = Column(String, default="Unknown", nullable=True)
    end_node = Column(String, default="Unknown", nullable=True)

    # ── Phase 4: Hardware Node Positions ─────────
    devices = relationship("Device", back_populates="zone", cascade="all, delete-orphan")
    
    # ── Phase 5: Seasonal Strategy ───────
    sowing_date = Column(DateTime, default=func.now())
    harvest_date = Column(DateTime, nullable=True)
    seasonal_water_budget_mm = Column(Float, default=1200.0) 
    
    created_at = Column(DateTime, default=func.now())

    acre = relationship("Acre", back_populates="zones")
    et_history = relationship("ETData", back_populates="zone")
