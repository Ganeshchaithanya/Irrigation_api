from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.models.farm import Zone, Acre, Farm
from application.schemas.ai import PredictionResponse, CropPlanResponse, AiValidationLogResponse, PredictionCreate, CropPlanCreate
from application.services import ai_service
from application.services.decision_service import DecisionService
from application.ai.specialists.crop_plan_model import CropPlanModel
from pydantic import UUID4
from typing import List

router = APIRouter()
planner = CropPlanModel()
decision_engine = DecisionService()

@router.get("/predictions/{zone_id}", response_model=List[PredictionResponse])
def get_predictions(zone_id: UUID4, limit: int = 5, db: Session = Depends(get_db)):
    return ai_service.get_latest_predictions(db, zone_id=zone_id, limit=limit)

@router.get("/crop-plan/{zone_id}", response_model=CropPlanResponse)
def get_crop_plan(zone_id: UUID4, db: Session = Depends(get_db)):
    return ai_service.get_active_crop_plan(db, zone_id=zone_id)

@router.get("/validation-logs/{zone_id}", response_model=List[AiValidationLogResponse])
def get_validation_logs(zone_id: UUID4, limit: int = 10, db: Session = Depends(get_db)):
    return ai_service.get_ai_validation_logs(db, zone_id=zone_id, limit=limit)

@router.post("/predictions")
def push_prediction(data: PredictionCreate, db: Session = Depends(get_db)):
    # 1. Save prediction trace to DB
    record = ai_service.create_prediction(db, data)
    
    # 2. Evaluate hardware decision based on predicted need
    decision = decision_engine.evaluate_prediction(data.predicted_irrigation_need, str(data.zone_id))
    
    # Note: Backend would typically dispatch MQTT/IoT message here.
    
    # 3. Return the exact decision to the AI Engine so `ValidationModel` can audit it
    return {
        "status": "success",
        "prediction_id": record.id,
        "hardware_decision": decision
    }

@router.post("/generate-plan/{zone_id}", response_model=CropPlanResponse)
async def generate_plan(zone_id: UUID4, db: Session = Depends(get_db)):
    """
    RAG + Reasoning Pipeline:
    1. DEEP FETCH: Joint query to build Farm Profile.
    2. REASONING: Combine Web Research + ChromaDB Memory + Agronomist Prompt.
    3. STORAGE: Save the generated JSON plan to PostgreSQL.
    """
    # 1. Gather Rich Profile
    record = db.query(Zone, Farm.location, User.preferred_language)\
        .join(Acre, Zone.acre_id == Acre.id)\
        .join(Farm, Acre.farm_id == Farm.id)\
        .join(User, Farm.user_id == User.id)\
        .filter(Zone.id == zone_id).first()
    
    if not record:
        raise HTTPException(status_code=404, detail="Zone data not found")
        
    zone, location, lang = record
    
    profile = {
        "zone_id": str(zone_id),
        "soil": zone.soil_type or "Red Soil",
        "location": location or "Unknown Region",
        "current_crop": zone.crop_type or "None",
        "language": lang or "en"
    }
    
    # 2. Reasoning Layer (RAG-Enabled)
    plan_data = await planner.generate_optimized_plan(profile)
    
    if "error" in plan_data:
        raise HTTPException(status_code=500, detail=f"LLM Reasoning failed: {plan_data['error']}")
    
    # 3. Persistence
    plan_create = CropPlanCreate(zone_id=zone_id, **plan_data)
    return ai_service.create_crop_plan(db, plan_create)
