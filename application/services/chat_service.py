from sqlalchemy.orm import Session
from application.models.chat import ChatLog, MessageTemplate
from application.models.sensor import NodeData, ZoneData
from application.models.ai import AiValidationLog, Prediction, CropPlan
from application.models.notification import Notification
from application.models.device import Device
from application.models.farm import Farm, Acre, Zone
from pydantic import UUID4
from application.schemas.chat import ChatLogCreate

def log_chat_interaction(db: Session, data: ChatLogCreate):
    db_chat = ChatLog(**data.model_dump())
    db.add(db_chat)
    db.commit()
    db.refresh(db_chat)
    return db_chat

def get_chat_history(db: Session, user_id: UUID4, limit: int = 20):
    return db.query(ChatLog).filter(ChatLog.user_id == user_id).order_by(ChatLog.created_at.desc()).limit(limit).all()

def get_message_template(db: Session, code: str):
    return db.query(MessageTemplate).filter(MessageTemplate.code == code).first()

def get_all_templates(db: Session):
    return db.query(MessageTemplate).all()

def update_user_language(db: Session, user_id: UUID4, language: str):
    """
    Active UI Setting Change:
    Updates the user's preferred language in the database.
    """
    from models.user import User
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.preferred_language = language
        db.commit()
    return user

def _sanitize_reasoning(reasoning: str) -> str:
    """
    Security Layer:
    Strips raw Chain-of-Thought or debug internal logic from AI logs.
    """
    if not reasoning: return "Operating within normal parameters."
    import re
    sentences = re.split(r'(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)\s', reasoning)
    return " ".join(sentences[:2])

def get_farmer_context(db: Session, user_id: UUID4):
    """
    Context-Aware Prioritization Layer:
    Aggregates farm state into three tiers of relevance.
    """
    context = {
        "critical": [],      # Tier 1: Alerts
        "essential": [],     # Tier 2: Latest Sensors
        "supplemental": [],  # Tier 3: AI Decision History
        "is_priority": False
    }
    
    # 1. Resolve User → Farm → Acres → Zones
    zones = (
        db.query(Zone)
        .join(Acre).join(Farm)
        .filter(Farm.user_id == user_id)
        .all()
    )
    zone_ids = [z.id for z in zones]
    
    # 2. Populate CRITICAL context (Active Alerts)
    alerts = (
        db.query(Notification)
        .filter(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc())
        .limit(3)
        .all()
    )
    context["critical"] = [
        {"title": n.title, "message": n.message, "severity": n.notif_type}
        for n in alerts
    ]
    context["is_priority"] = len(context["critical"]) > 0

    # 3. Populate ESSENTIAL context (Latest Sensors)
    devices = db.query(Device).filter(Device.zone_id.in_(zone_ids)).all()
    device_ids = [d.id for d in devices]
    
    if device_ids:
        latest_readings = (
            db.query(NodeData)
            .filter(NodeData.device_id.in_(device_ids))
            .order_by(NodeData.timestamp.desc())
            .limit(3)
            .all()
        )
        for r in latest_readings:
            # Join with latest zone environment for the context
            z_env = db.query(ZoneData).filter(ZoneData.zone_id == r.zone_id).order_by(ZoneData.timestamp.desc()).first()
            context["essential"].append({
                "moisture": r.soil_moisture, 
                "temp": z_env.temperature if z_env else 25.0, 
                "time": r.timestamp.isoformat()
            })

    # 4. Populate SUPPLEMENTAL context (Sanitized AI History)
    validations = (
        db.query(AiValidationLog)
        .filter(AiValidationLog.zone_id.in_(zone_ids))
        .order_by(AiValidationLog.created_at.desc())
        .limit(3)
        .all()
    )
    for v in validations:
        summary = _sanitize_reasoning(v.reasoning)
        context["supplemental"].append({
            "decision": v.decision, 
            "summary": summary, 
            "time": v.created_at.isoformat()
        })
        
        # v3 Conflict Guard: Elevate any safety halts to Critical context
        if "CONFLICT_SHIELD" in (v.reasoning or ""):
            context["critical"].append({
                "title": "SAFETY CONFLICT DETECTED",
                "message": "Model vs. Sensor disagreement (Safety Halt).",
                "severity": "CRITICAL"
            })
            context["is_priority"] = True

    # 5. Populate Crop Plan and Predictions (for full architecture connection)
    if zone_ids:
        # Get active crop plan
        plan = db.query(CropPlan).filter(CropPlan.zone_id.in_(zone_ids)).order_by(CropPlan.created_at.desc()).first()
        if plan:
            context["essential"].append({
                "type": "CROP_PLAN",
                "recommended_crop": plan.recommended_crop,
                "expected_yield": plan.expected_yield,
                "risk_score": plan.risk_score,
                "created_at": plan.created_at.isoformat()
            })
            
        # Get latest prediction
        prediction = db.query(Prediction).filter(Prediction.zone_id.in_(zone_ids)).order_by(Prediction.prediction_time.desc()).first()
        if prediction:
            context["essential"].append({
                "type": "AI_PREDICTION",
                "predicted_moisture": prediction.predicted_moisture,
                "predicted_irrigation_need_mm": prediction.predicted_irrigation_need,
                "hours_until_needed": prediction.hours_until_needed,
                "recommendation": prediction.recommendation_text,
                "time": prediction.prediction_time.isoformat() if prediction.prediction_time else ""
            })

    return context
