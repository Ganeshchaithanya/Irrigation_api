from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from core.database import get_db
from schemas.sensor import SensorDataCreate, SensorDataResponse
from services import sensor_service
from services.decision_service import DecisionService
from pydantic import UUID4
from typing import List

router = APIRouter()
_decision = DecisionService()

@router.post("/", response_model=SensorDataResponse)
def submit_sensor_data(data: SensorDataCreate, db: Session = Depends(get_db)):
    """IoT device posts sensor telemetry. Triggers AI decision pipeline."""
    db_data = sensor_service.create_sensor_data(db, data)
    _decision.evaluate_device_trigger(db, device_id=db_data.device_id)
    return db_data

@router.get("/history/{device_id}", response_model=List[SensorDataResponse])
def get_sensor_history(device_id: UUID4, limit: int = 48, db: Session = Depends(get_db)):
    """Return last N readings for a device (for chart display)."""
    return sensor_service.get_sensor_history(db, device_id=device_id, limit=limit)

@router.get("/latest/zone/{zone_id}", response_model=List[SensorDataResponse])
def get_latest_for_zone(zone_id: UUID4, db: Session = Depends(get_db)):
    """Return the latest sensor reading from every device in a zone."""
    return sensor_service.get_latest_by_zone(db, zone_id=zone_id)
