from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.schemas.irrigation import IrrigationLogCreate, IrrigationLogResponse
from application.services import irrigation_service
from pydantic import UUID4
from typing import List

router = APIRouter()

@router.post("/", response_model=IrrigationLogResponse)
def log_irrigation_event(data: IrrigationLogCreate, db: Session = Depends(get_db)):
    """Manually log a completed irrigation event."""
    return irrigation_service.log_irrigation(db, data)

@router.post("/start/{zone_id}", response_model=IrrigationLogResponse)
def start_irrigation(zone_id: UUID4, db: Session = Depends(get_db)):
    """Manually start an irrigation session for a zone."""
    return irrigation_service.start_irrigation_session(db, zone_id, trigger_type="MANUAL")

@router.post("/stop/{zone_id}", response_model=IrrigationLogResponse)
async def stop_irrigation(zone_id: UUID4, average_flow: float = 0.0, db: Session = Depends(get_db)):
    """Stop the active irrigation session for a zone."""
    return await irrigation_service.stop_irrigation_session(db, zone_id, average_flow=average_flow)

@router.get("/history/{zone_id}", response_model=List[IrrigationLogResponse])
def get_irrigation_history(zone_id: UUID4, limit: int = 30, db: Session = Depends(get_db)):
    """Get all past irrigation sessions for a zone."""
    return irrigation_service.get_irrigation_history(db, zone_id=zone_id, limit=limit)
