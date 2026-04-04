from sqlalchemy.orm import Session
from application.models.command import ValveCommand
from application.schemas.command import CommandCreate

def create_command(db: Session, data: CommandCreate):
    # Deduplicate pending commands targeting the same zone with the exact same intent
    existing = db.query(ValveCommand).filter(
        ValveCommand.zone_id == data.zone_id, 
        ValveCommand.status == "PENDING", 
        ValveCommand.command == data.command
    ).first()
    
    if existing:
        return existing
        
    db_command = ValveCommand(**data.model_dump(), status="PENDING")
    db.add(db_command)
    db.commit()
    db.refresh(db_command)
    return db_command

def get_pending_commands(db: Session, zone_id):
    return db.query(ValveCommand).filter(ValveCommand.zone_id == zone_id, ValveCommand.status == "PENDING").all()
