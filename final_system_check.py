import asyncio
import os
import sys
import json
from datetime import datetime
from dotenv import load_dotenv

# Load env
# Load env from root
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

# 1. Setup Python Path
PROJECT_ROOT = os.getcwd()
sys.path.insert(0, PROJECT_ROOT)

# Import our Specialist Models from centralized application location
from application.ai.specialists.crop_plan_model import CropPlanModel
from application.ai.specialists.stage_awareness_model import StageAwarenessModel
from application.ai.models.anomaly_model import AnomalyModel
from application.ai.models.prediction_model import PredictionModel

async def test_strategic_planning():
    print("\n[PILLAR 1] Strategic Planning (Web Discovery + Guide RAG)...")
    planner = CropPlanModel()
    profile = {
        "zone_id": "test-zone-001",
        "soil": "Red Soil",
        "location": "Bengaluru",
        "current_crop": "Tomato"
    }
    print(f"   Searching for profitable crops in {profile['location']}...")
    plan = await planner.generate_optimized_plan(profile)
    
    if plan and "recommended_crop" in plan:
        print(f"   ✅ SUCCESS: Recommended {plan['recommended_crop']}")
        print(f"   RAG Integrity: {len(str(plan))} bytes of scientific data retrieved.")
        return True
    return False

async def test_hardware_resilience():
    print("\n[PILLAR 2] Hardware Resilience (Anomaly Diagnosis)...")
    model = AnomalyModel()
    
    # Simulate: High Flow with No Moisture Change (System IDLE)
    sensor_history = [
        {"id": "device_1", "moisture": 50, "flow": 0, "temp": 25},
        {"id": "device_1", "moisture": 50, "flow": 12.5, "temp": 25}
    ]
    
    print("   Analyzing suspicious telemetry (Flow: 12.5L/min)...")
    anomalies = await model.detect_anomalies(sensor_history, "IDLE")
    
    if anomalies and any("PIPE_BURST" in str(a) for a in anomalies):
        print(f"   ✅ SUCCESS: Correctly diagnosed 'PIPE_BURST'.")
        print(f"   AI Reason: {anomalies[0].get('ai_diagnosis', 'N/A')[:100]}...")
        return True
    return False

async def test_biological_decision():
    print("\n[PILLAR 3] Biological Decision (Stage + Prediction Loop)...")
    stager = StageAwarenessModel()
    predictor = PredictionModel(crop_type="Tomato")
    
    crop = "Tomato"
    day = 45 # Flowering/Fruiting Stage
    
    # 1. Stage Extraction
    print(f"   Resolving {crop} Protocol for Day {day} (Zaid Season)...")
    stage_report = stager.get_stage_context(crop, day, "Zaid")
    
    # 2. Prediction Calculation
    weather = {"temp": 42.0, "rain_mm": 0.0, "condition": "Hot"}
    history = [{"id": "d1", "moisture": 18.5}] # High Stress
    
    print("   Calculating FAO-56 Irrigation Need (Temp: 42°C)...")
    prediction = await predictor.predict_tomorrow_irrigation(history, weather, stage_report)
    
    if prediction and prediction.get("predicted_irrigation_need", 0) > 0:
        print(f"   ✅ SUCCESS: Irrigation required ({prediction['predicted_irrigation_need']}mm)")
        print(f"   Model Outcome: {prediction.get('ai_reasoning', 'N/A')[:80]}...")
        return True
    return False

async def run_verification():
    print("\n" + "="*50)
    print("🌍 AGRI-EXPERT INTELLIGENCE SUITE: SYSTEM CHECK")
    print("="*50)
    
    results = {
        "Strategic Planning (RAG)": await test_strategic_planning(),
        "Hardware Resilience (AI)": await test_hardware_resilience(),
        "Biological Decision (Loop)": await test_biological_decision()
    }
    
    print("\n" + "="*40)
    print("🏆 FINAL SYSTEM STATUS Dashboard")
    print("="*40)
    for name, success in results.items():
        status = "PASSED" if success else "FAILED"
        print(f"{name:<30} : {status}")
    print("="*40)

if __name__ == "__main__":
    asyncio.run(run_verification())
