import asyncio
import os
import sys
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend", ".env"))

# 1. PATH SETUP
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, PROJECT_ROOT)

from llm.crop_plan_model import CropPlanModel

async def test_full_funnel():
    print("\n" + "🌱" * 15)
    print("🚀 DISCOVERY-TO-GUIDE FUNNEL TEST")
    print("🌱" * 15)

    planner = CropPlanModel()
    
    # Simulate a farmer's profile
    profile = {
        "soil": "Black Soil",
        "location": "Maharashtra",
        "lat": 19.0760,
        "lon": 72.8777
    }

    print(f"\n🔍 STEP 1 & 2: DISCOVERING GOLD CROPS (Weather + Soil: {profile['soil']})...")
    try:
        # This will trigger the web search discovery and the RAG lookup
        plan = await planner.generate_optimized_plan(profile)
        
        print("\n🏆 DISCOVERY RESULT:")
        print(f"   - Recommended Crop: {plan.get('recommended_crop')}")
        print(f"   - Market Outlook: {plan.get('market_outlook')}")
        print(f"   - Reasoning: {plan.get('reasoning')[:150]}...")

        print("\n📜 STEP 3: SCIENTIFIC GUIDE INITIATED (Expert RAG):")
        steps = plan.get('scientific_steps', {})
        print(f"   - Soil Prep: {steps.get('soil_preparation', 'No data')[:100]}...")
        print(f"   - Irrigation: {steps.get('irrigation_strategy', 'No data')[:100]}...")
        print(f"   - Fertilizer: {plan.get('fertilizer_plan', 'No data')[:100]}...")

        print("\n✅ TEST SUCCESS: Discovery linked to Scientific Guide.")
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")

if __name__ == "__main__":
    if not os.getenv("GROQ_API_KEY"):
        print("❌ ERROR: GROQ_API_KEY missing.")
    else:
        asyncio.run(test_full_funnel())
