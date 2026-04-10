from sqlalchemy import (
    Column, Integer, BigInteger, Boolean, Float, String,
    DateTime, ForeignKey, Index, CheckConstraint, JSON
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from application.core.database import Base


class ZoneData(Base):
    __tablename__ = "zone_data"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # VARCHAR(50) — no FK, loose coupling matches hardware string identifiers
    zone_id = Column(String(50), nullable=False)

    temperature = Column(Float)
    humidity = Column(Float)

    timestamp = Column(DateTime, nullable=False, default=func.now())

    __table_args__ = (
        Index("idx_zone_zone", "zone_id"),
    )


class NodeData(Base):
    __tablename__ = "node_data"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # References devices.device_uid (the ESP string e.g. "esp_test_002"), not the UUID PK
    device_id = Column(String(50), ForeignKey("devices.device_uid"), nullable=False)
    zone_id = Column(String(50), nullable=False)   # VARCHAR — no FK, matches SQL schema

    soil_moisture = Column(Float)

    battery_percentage = Column(Float)
    solar_voltage = Column(Float)
    solar_efficiency = Column(Float)

    # Hardware feedback fields
    valve_status = Column(Boolean, nullable=False, default=False)       # actual valve state reported by device
    commanded_state = Column(Boolean, nullable=False, default=False)    # last command sent to device

    timestamp = Column(DateTime, nullable=False, default=func.now())

    __table_args__ = (
        Index("idx_node_device", "device_id"),
        Index("idx_node_zone", "zone_id"),
        CheckConstraint("soil_moisture BETWEEN 0 AND 100", name="soil_range"),
        CheckConstraint("battery_percentage BETWEEN 0 AND 100", name="battery_range"),
    )


class MasterData(Base):
    __tablename__ = "master_data"

    id = Column(Integer, primary_key=True, autoincrement=True)

    flow_rate = Column(Float)
    water_consumed = Column(Float)
    is_raining = Column(Boolean, default=False)

    battery_percentage = Column(Float)
    solar_voltage = Column(Float)
    solar_efficiency = Column(Float)
    
    valve_status = Column(Boolean, nullable=False, default=False) # Consolidated pump/valve status for the Master

    timestamp = Column(DateTime, nullable=False, default=func.now())


class SensorDataRaw(Base):
    """Raw log of every incoming payload — useful for debugging and replay."""
    __tablename__ = "sensor_data_raw"

    id = Column(Integer, primary_key=True, autoincrement=True)
    device_id = Column(String(50))
    type = Column(String(20))       # "NODE", "MASTER", etc.
    payload = Column(JSONB)
    timestamp = Column(DateTime, nullable=False, default=func.now())
