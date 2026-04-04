from sqlalchemy.orm import Session
from application.models.irrigation import IrrigationLog
from datetime import datetime
from application.services.sensor_service import get_latest_by_zone
from application.services.ws_manager import ws_manager
import asyncio

def start_irrigation_session(db: Session, zone_id, trigger_type="AUTO", reason_code="", moisture_before=None, et_context=None):
    # First ensure we don't have hanging sessions
    existing = db.query(IrrigationLog).filter(IrrigationLog.zone_id == zone_id, IrrigationLog.end_time == None).first()
    if existing:
        return existing
        
    # Auto-capture current moisture if not provided
    if moisture_before is None:
        readings = get_latest_by_zone(db, zone_id)
        if readings:
            moisture_before = sum(r.soil_moisture for r in readings) / len(readings)

    db_log = IrrigationLog(
        zone_id=zone_id,
        start_time=datetime.utcnow(),
        trigger_type=trigger_type,
        reason_code=reason_code,
        moisture_before=moisture_before,
        et_context=et_context
    )
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

async def stop_irrigation_session(db: Session, zone_id, average_flow=0.0, moisture_after=None):
    db_log = db.query(IrrigationLog).filter(IrrigationLog.zone_id == zone_id, IrrigationLog.end_time == None).first()
    
    if db_log:
        db_log.end_time = datetime.utcnow()
        duration = (db_log.end_time - db_log.start_time).total_seconds() / 60.0 # minutes
        db_log.duration_minutes = duration
        
        # Simulated water calculation (Flow L/min * Duration) if flow is available
        db_log.water_used = duration * average_flow if average_flow else 0.0
        
        # Auto-capture new moisture if not provided
        if moisture_after is None:
            readings = get_latest_by_zone(db, zone_id)
            if readings:
                moisture_after = sum(r.soil_moisture for r in readings) / len(readings)

        if moisture_after is not None:
            db_log.moisture_after = moisture_after
            
        db.commit()
        db.refresh(db_log)

        # ── BROADCAST FEEDBACK (Continuous Learning Loop) ──
        if db_log.moisture_before is not None and db_log.moisture_after is not None:
            delta = db_log.moisture_after - db_log.moisture_before
            await ws_manager.broadcast("ai-decisions", {
                "event": "irrigation_feedback",
                "zone_id": str(zone_id),
                "delta": round(delta, 1),
                "duration": round(duration, 1),
                "message": f"Optimization Complete: +{round(delta, 1)}% moisture gain over {round(duration, 1)} mins."
            })
        
    return db_log

def log_irrigation(db: Session, data):
    db_log = IrrigationLog(**data.model_dump())
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def get_irrigation_history(db: Session, zone_id, limit: int = 30):
    """Return past irrigation sessions for a zone."""
    return (
        db.query(IrrigationLog)
        .filter(IrrigationLog.zone_id == zone_id)
        .order_by(IrrigationLog.start_time.desc())
        .limit(limit)
        .all()
    )
