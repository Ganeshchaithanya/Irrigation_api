from sqlalchemy.orm import Session
from application.models.state import ZoneState
from datetime import datetime

def get_zone_state(db: Session, zone_id):
    state = db.query(ZoneState).filter(ZoneState.zone_id == zone_id).first()
    if not state:
        # Default fallback creation for brand new zones
        state = ZoneState(zone_id=zone_id, state="IDLE", current_moisture=0.0)
        db.add(state)
        db.commit()
        db.refresh(state)
    return state

def update_zone_state(db: Session, zone_id, state: str, moisture: float = None, log_irrigation_time: bool = False):
    db_state = get_zone_state(db, zone_id)
    db_state.state = state
    
    if moisture is not None:
        db_state.current_moisture = moisture
        
    if log_irrigation_time:
        db_state.last_irrigation_time = datetime.utcnow()
        
    db.commit()
    return db_state
