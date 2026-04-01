from sqlalchemy import Column, BigInteger, Boolean, Float, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base

class SensorData(Base):
    __tablename__ = "sensor_data"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"))
    
    device = relationship("Device", back_populates="sensor_data")

    timestamp = Column(DateTime, nullable=False, index=True)
    
    soil_moisture = Column(Float)
    temperature = Column(Float)
    humidity = Column(Float)
    flow = Column(Float)
    water_consumed = Column(Float)
    is_raining = Column(Boolean, default=False)
    
    solar_voltage = Column(Float, nullable=True)
    battery_percentage = Column(Float, nullable=True)
    
    created_at = Column(DateTime, default=func.now())

    __table_args__ = (
        Index('idx_sensor_device_time', 'device_id', 'timestamp'),
    )
