import asyncio
import sys
import os

# Add project root to path so we can run directly
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application.ai.specialists.crop_plan_model import CropPlanModel
from application.ai.specialists.stage_awareness_model import StageAwarenessModel

async def test_planning_specialist():
    print("--- [TEST] Agri-Expert Strategist ---")
    planner = CropPlanModel()
    profile = {
        "soil": "Red Soil",
        "location": "Bengaluru",
        "zone_id": "Z-1"
    }
    
    print(f"Requesting a Crop Plan for {profile['soil']} in {profile['location']}...")
    plan = await planner.generate_optimized_plan(profile)
    print("Optimization Plan Received:")
    print(plan)
    print("----------------------------------------\n")

async def test_stage_awareness_specialist():
    print("--- [TEST] Agri-Expert Stage Analyst ---")
    specialist = StageAwarenessModel()
    
    # We test on actual data from our dataset
    crop = "Tomato"
    day = 45
    season = "Zaid"
    
    print(f"Requesting Stage Info: {crop} at Day {day} ({season})")
    
    stage_info = await specialist.get_stage_context(crop, day, season)
    print("Specialist Answer:")
    print(stage_info)
    print("----------------------------------------\n")

async def main():
    print("Starting Multi-Model Integration Test...\n")
    
    try:
        await test_planning_specialist()
    except Exception as e:
        print(f"Planning test failed: {e}")
        
    try:
        await test_stage_awareness_specialist()
    except Exception as e:
        print(f"Stage Analyst test failed: {e}")
    
    print("Integration Test Complete.")

if __name__ == "__main__":
    asyncio.run(main())
