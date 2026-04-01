from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import sys
import os

# Allow importing from the current directory, project root, and backend
ROOT_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKEND_PATH = os.path.join(ROOT_PATH, "backend", "application")

for path in [ROOT_PATH, BACKEND_PATH, os.path.dirname(os.path.abspath(__file__))]:
    if path not in sys.path:
        sys.path.append(path)

from ai_services.ai_service import AIService
from ai_services.validation_service import ValidationService
from ai_services.anomaly_service import AnomalyService

app = FastAPI(title="Irrigation AI Engine", version="2.0.0")
ai_orchestrator = AIService()
validator = ValidationService()
diagnostician = AnomalyService()

class AIRunRequest(BaseModel):
    sensor_data: List[dict]
    zone_id: str
    current_state: str = "IDLE"
    crop_season: str = "Kharif"
    day_of_growth: int = 45
    neighbors: List[dict] = [] # List of {id, position_label}

class ValidationRequest(BaseModel):
    decision: str
    latest_sensor: dict
    weather_data: dict

@app.get("/")
def read_root():
    return {"status": "ONLINE", "engine": "Irrigation_AI_v2"}

@app.post("/ai/run")
async def run_ai_pipeline(req: AIRunRequest):
    """
    Main Orchestration Endpoint:
    Runs the full Stage -> Prediction -> Anomaly -> Validation pipeline.
    Includes Node Surrogacy (START/MIDDLE/END) logic.
    """
    try:
        report = await ai_orchestrator.generate_full_report(
            raw_sensor_data=req.sensor_data,
            weather_data={}, # Weather is fetched internally by AIService
            zone_id=req.zone_id,
            current_state=req.current_state,
            crop_season=req.crop_season,
            day_of_growth=req.day_of_growth,
            neighbors=req.neighbors
        )
        return report
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ai/validate")
async def validate_only(req: ValidationRequest):
    """Chatbot Utility: Audits a specific decision without running the whole pipeline."""
    return await validator.get_second_opinion(req.decision, req.latest_sensor, req.weather_data)

@app.post("/ai/diagnose")
async def diagnose_only(sensor_history: List[dict], current_state: str = "IDLE"):
    """Chatbot Utility: Diagnoses sensor anomalies on-demand."""
    return await diagnostician.check_sensor_health(sensor_history, current_state)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
