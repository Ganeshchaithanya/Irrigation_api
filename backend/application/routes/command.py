from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from schemas.command import CommandCreate, CommandResponse, AICommandExecuteRequest
from services import command_service
from services.safety_engine import SafetyEngine
from services.ws_manager import ws_manager
from models.command import ValveCommand
from pydantic import UUID4
from typing import List

router = APIRouter()

@router.post("/", response_model=CommandResponse)
def issue_valve_command(data: CommandCreate, db: Session = Depends(get_db)):
    """Manually issue a valve command (ON/OFF) for a zone."""
    return command_service.create_command(db, data)

@router.post("/ai-execute", response_model=CommandResponse)
async def execute_ai_command(data: AICommandExecuteRequest, db: Session = Depends(get_db)):
    """AI engine issues a command, intercepted by the Safety Engine."""
    # 1. Pipeline Gate: Safety Validation
    SafetyEngine.validate_action(db, str(data.zone_id), data.action, data.duration)
    
    # 2. Safety Assured: Queue the valve command
    command_create = CommandCreate(
        zone_id=data.zone_id,
        command="ON",
        duration_minutes=data.duration,
        issuer="AI_ENGINE"
    )
    result = command_service.create_command(db, command_create)

    # 3. Broadcast to real-time ai-decisions channel
    await ws_manager.broadcast("ai-decisions", {
        "event": "ai_command_queued",
        "zone_id": str(data.zone_id),
        "action": data.action,
        "duration": data.duration,
        "command_id": str(result.id)
    })
    return result

@router.get("/pending/{zone_id}", response_model=List[CommandResponse])
def get_pending_commands(zone_id: UUID4, db: Session = Depends(get_db)):
    """IoT device polls this to fetch pending valve commands."""
    return command_service.get_pending_commands(db, zone_id)

@router.patch("/{command_id}/ack", response_model=CommandResponse)
def acknowledge_command(command_id: UUID4, db: Session = Depends(get_db)):
    """
    IoT device calls this after executing a command.
    Marks it as EXECUTED so it won't be re-sent.
    """
    cmd = db.query(ValveCommand).filter(ValveCommand.id == command_id).first()
    if not cmd:
        raise HTTPException(status_code=404, detail="Command not found")
    cmd.status = "EXECUTED"
    db.commit()
    db.refresh(cmd)
    return cmd
