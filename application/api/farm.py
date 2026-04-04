from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from application.core.database import get_db
from pydantic import UUID4
from typing import List
from application.models.farm import Farm, Acre, Zone, DiaryLog
from application.models.device import Device
from application.schemas.farm import FarmCreate, FarmResponse, AcreCreate, AcreResponse, ZoneCreate, ZoneResponse, DiaryLogCreate, DiaryLogResponse

router = APIRouter()

@router.post("/farm", response_model=FarmResponse)
def create_farm(data: FarmCreate, user_id: UUID4, db: Session = Depends(get_db)):
    db_farm = Farm(**data.model_dump(), user_id=user_id)
    db.add(db_farm)
    db.commit()
    db.refresh(db_farm)
    return db_farm

@router.get("/my-farms", response_model=List[FarmResponse])
def get_my_farms(user_id: UUID4, db: Session = Depends(get_db)):
    """List all farms owned by a user."""
    return db.query(Farm).filter(Farm.user_id == user_id).all()

@router.post("/acre", response_model=AcreResponse)
def create_acre(data: AcreCreate, db: Session = Depends(get_db)):
    db_acre = Acre(**data.model_dump())
    db.add(db_acre)
    db.commit()
    db.refresh(db_acre)
    return db_acre

@router.get("/acres/{farm_id}", response_model=List[AcreResponse])
def get_acres(farm_id: UUID4, db: Session = Depends(get_db)):
    """List all acres in a farm."""
    return db.query(Acre).filter(Acre.farm_id == farm_id).all()

@router.post("/zone", response_model=ZoneResponse)
def create_zone(data: ZoneCreate, db: Session = Depends(get_db)):
    db_zone = Zone(
        acre_id=data.acre_id, 
        name=data.name, 
        crop_type=data.crop_type, 
        soil_type=data.soil_type, 
        mode=data.mode
    )
    db.add(db_zone)
    db.flush() # Secure the ID before iterating devices

    for idx, node_uid in enumerate(data.nodes):
        label = f"N-{idx+1}"
        db_dev = Device(device_uid=node_uid, zone_id=db_zone.id, position_label=label)
        db.add(db_dev)

    db.commit()
    db.refresh(db_zone)
    
    # Pack for response model schema (which expects nodes: List[str])
    db_zone.nodes = data.nodes
    return db_zone

@router.get("/zones/{acre_id}", response_model=List[ZoneResponse])
def get_zones(acre_id: UUID4, db: Session = Depends(get_db)):
    """List all zones in an acre."""
    return db.query(Zone).filter(Zone.acre_id == acre_id).all()

@router.delete("/zone/{zone_id}")
def delete_zone(zone_id: UUID4, db: Session = Depends(get_db)):
    """Soft delete — removes zone from DB. IoT commands for this zone will fail gracefully."""
    zone = db.query(Zone).filter(Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    db.delete(zone)
    db.commit()
    return {"status": "deleted", "zone_id": str(zone_id)}

@router.post("/diary/{farm_id}", response_model=DiaryLogResponse)
def create_diary_log(farm_id: UUID4, data: DiaryLogCreate, db: Session = Depends(get_db)):
    db_log = DiaryLog(**data.model_dump(), farm_id=farm_id)
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

@router.get("/diary/{farm_id}", response_model=List[DiaryLogResponse])
def get_diary_logs(farm_id: UUID4, db: Session = Depends(get_db)):
    """List all diary logs for a farm in descending chronological order."""
    return db.query(DiaryLog).filter(DiaryLog.farm_id == farm_id).order_by(DiaryLog.created_at.desc()).all()
