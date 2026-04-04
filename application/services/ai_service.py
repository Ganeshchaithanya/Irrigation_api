from sqlalchemy.orm import Session
from application.models.ai import AiValidationLog, Prediction, CropPlan
from pydantic import UUID4

def get_latest_predictions(db: Session, zone_id: UUID4, limit: int = 5):
    return db.query(Prediction).filter(Prediction.zone_id == zone_id).order_by(Prediction.prediction_time.desc()).limit(limit).all()

def get_active_crop_plan(db: Session, zone_id: UUID4):
    return db.query(CropPlan).filter(CropPlan.zone_id == zone_id).order_by(CropPlan.created_at.desc()).first()

def get_ai_validation_logs(db: Session, zone_id: UUID4, limit: int = 10):
    return db.query(AiValidationLog).filter(AiValidationLog.zone_id == zone_id).order_by(AiValidationLog.created_at.desc()).limit(limit).all()

def create_prediction(db: Session, data):
    db_prediction = Prediction(**data.model_dump())
    db.add(db_prediction)
    db.commit()
    db.refresh(db_prediction)
    return db_prediction

def create_crop_plan(db: Session, data):
    db_plan = CropPlan(**data.model_dump())
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)
    return db_plan
