import uuid
from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base

class DailyAggregate(Base):
    __tablename__ = "daily_aggregates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    date = Column(Date, nullable=False)
    
    avg_moisture = Column(Float)
    avg_temperature = Column(Float)
    avg_humidity = Column(Float)
    
    total_irrigation_minutes = Column(Float)
    water_usage = Column(Float)
    created_at = Column(DateTime, default=func.now())

class MonthlyAggregate(Base):
    __tablename__ = "monthly_aggregates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    month = Column(Date, nullable=False)
    
    avg_moisture = Column(Float)
    total_irrigation_minutes = Column(Float)
    water_usage = Column(Float)
    created_at = Column(DateTime, default=func.now())

class YearlyAggregate(Base):
    __tablename__ = "yearly_aggregates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    year = Column(Integer, nullable=False)
    
    avg_moisture = Column(Float)
    total_irrigation_minutes = Column(Float)
    water_usage = Column(Float)
    created_at = Column(DateTime, default=func.now())

class PlantHealthScore(Base):
    __tablename__ = "plant_health_scores"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    
    score = Column(Integer)
    status = Column(String(20))
    reason = Column(String)
    
    date = Column(Date, nullable=False)
    created_at = Column(DateTime, default=func.now())

class ETData(Base):
    __tablename__ = "et_data"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"))
    timestamp = Column(DateTime, nullable=False, index=True)
    et_value = Column(Float)
    
    created_at = Column(DateTime, default=func.now())

    zone = relationship("Zone", back_populates="et_history")
