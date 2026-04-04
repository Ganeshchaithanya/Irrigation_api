from datetime import datetime
from fastapi import HTTPException
from sqlalchemy.orm import Session
from application.models.farm import Zone
from application.models.irrigation import IrrigationLog
from sqlalchemy import func

class SafetyEngine:
    COOLDOWN_SECONDS = 3600  # 1 hour minimum gap

    @staticmethod
    def validate_action(db: Session, zone_id: str, action: str, duration: int):
        # 1. Zone Validation
        zone = db.query(Zone).filter(Zone.id == zone_id).first()
        if not zone:
            raise HTTPException(status_code=404, detail="Zone not found")

        # 2. Command bounds
        if action.lower() != "irrigate":
            raise HTTPException(status_code=400, detail=f"Unsupported AI action: {action}")
            
        if duration <= 0 or duration > 120:
            raise HTTPException(status_code=400, detail=f"Security Lock: Duration {duration} mins out of bounds (1-120)")

        # 3. Cooldown Guard
        last_log = db.query(IrrigationLog)\
            .filter(IrrigationLog.zone_id == zone_id)\
            .order_by(IrrigationLog.created_at.desc()).first()
            
        if last_log and last_log.created_at:
            diff = (datetime.utcnow() - last_log.created_at).total_seconds()
            if diff < SafetyEngine.COOLDOWN_SECONDS:
                remaining_mins = int((SafetyEngine.COOLDOWN_SECONDS - diff) / 60)
                raise HTTPException(status_code=403, detail=f"Cooldown Guard Active: Please wait {remaining_mins} more minutes before irrigating this zone again.")
        
        # 4. Success Pipeline
        return True
