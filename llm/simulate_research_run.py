import asyncio
import json
import uuid
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from llm.research_agent import WebResearcher
from llm.agent import AgriExpertAgent

async def simulate_research_and_planning():
    """
    SIMULATION: The Autonomous Agri-Analyst
    1. Define User Profile (Soil: Black Soil, Location: Bidar)
    2. Web Researcher: Search for live trends.
    3. Ingestion: Save to Vector DB.
    4. AgriExpert: Generate the personalized Roadmap.
    """
    print("\n🕵️ STARTING AUTONOMOUS RESEARCH SIMULATION...\n")
    
    # 1. Profile Context
    profile = {
        "soil": "Black Soil",
        "location": "Bidar, Karnataka",
        "current_crop": "Ragi"
    }
    
    # 2. Initialize Agents
    researcher = WebResearcher()
    advisor = AgriExpertAgent()
    
    # 3. Step 1: Web Research
    print(f"🔎 STEP 1: Researching {profile['soil']} in {profile['location']}...")
    intelligence = await researcher.fetch_agronomic_intelligence(profile['soil'], profile['location'])
    
    for discovery in intelligence['discoveries']:
        print(f"  ↳ Found: {discovery}")
        
    # 4. Step 2: Extraction & Ingestion
    print("\n📥 STEP 2: Extracting Intelligence & Ingesting into Knowledge Base...")
    structured_data = await researcher.extract_structured_intelligence(intelligence['discoveries'])
    advisor.kb.add_crop_knowledge(structured_data)
    
    # 5. Step 3: Personalized Recommendation (RAG)
    print("\n🧠 STEP 3: Generating Success Roadmap (RAG-Powered)...")
    try:
        plan = await advisor.recommend_crop_plan(profile)
        
        print("\n" + "="*50)
        print("🌟 PERSONALIZED CROP ADVICE")
        print("="*50)
        print(f"RECOMMENDED CROP: {plan['recommended_crop']}")
        print(f"EXPECTED YIELD: {plan['expected_yield']} tons/ha")
        print(f"RISK SCORE: {plan['risk_score']*100}%")
        
        print("\n💡 EXPERT REASONING & ROADMAP:")
        print(f"\"{plan['market_reasoning']}\"")
        
    except Exception as e:
        print(f"❌ Error during advisory generation: {e}")

    print("\n✅ Simulation Complete. The Agent has learned from the web and updated its reasoning.")

if __name__ == "__main__":
    asyncio.run(simulate_research_and_planning())
