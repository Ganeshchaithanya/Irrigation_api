from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.services import sensor_service
from application.services.decision_service import DecisionService
from pydantic import UUID4
from typing import List, Union, Optional
from application.schemas.sensor import (
    SensorDataCreate,
    NodeDataResponse,
    ZoneDataResponse,
    MasterDataResponse,
)

router = APIRouter()
_decision = DecisionService()


@router.post("/", response_model=Union[NodeDataResponse, MasterDataResponse])
def submit_sensor_data(data: SensorDataCreate, db: Session = Depends(get_db)):
    """IoT device posts sensor telemetry. Triggers AI decision pipeline for nodes."""
    db_data = sensor_service.create_sensor_data(db, data)

    # Only trigger AI decision pipeline for NodeData (devices in a zone)
    if hasattr(db_data, "device_id"):
        _decision.evaluate_device_trigger(db, device_id=db_data.device_id)

    return db_data


# ── Node / Soil Data ────────────────────────────────────────────────────────

@router.get("/history/{device_id}", response_model=List[NodeDataResponse])
def get_sensor_history(device_id: UUID4, limit: int = 48, db: Session = Depends(get_db)):
    """Return last N soil/battery readings for a device (used for chart display)."""
    return sensor_service.get_sensor_history(db, device_id=device_id, limit=limit)


@router.get("/latest/device/{device_id}", response_model=Optional[NodeDataResponse])
def get_latest_for_device(device_id: UUID4, db: Session = Depends(get_db)):
    """Return the single most recent NodeData reading for a specific device."""
    return sensor_service.get_latest_sensor_data(db, device_id=device_id)


@router.get("/latest/zone/{zone_id}", response_model=List[NodeDataResponse])
def get_latest_for_zone(zone_id: UUID4, db: Session = Depends(get_db)):
    """Return the latest soil reading from every device (node) in a zone."""
    return sensor_service.get_latest_by_zone(db, zone_id=zone_id)


# ── Zone / Environmental Data ───────────────────────────────────────────────

@router.get("/zone/{zone_id}/environment", response_model=Optional[ZoneDataResponse])
def get_zone_environment(zone_id: UUID4, db: Session = Depends(get_db)):
    """Return the latest temperature & humidity snapshot for a zone (from its Leader node)."""
    return sensor_service.get_latest_zone_data(db, zone_id=zone_id)


# ── Master / System Data ────────────────────────────────────────────────────

@router.get("/master/latest", response_model=Optional[MasterDataResponse])
def get_master_data(db: Session = Depends(get_db)):
    """Return the latest system-level reading from the Master device (flow, rain, solar)."""
    return sensor_service.get_latest_master_data(db)

