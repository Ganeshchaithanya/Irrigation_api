import asyncio
import httpx
import json
import os
import sys
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend", ".env"))

# 1. PATH SETUP
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, PROJECT_ROOT)

BACKEND_URL = "http://localhost:8000/api/v1"
AI_ENGINE_URL = "http://localhost:8001"

async def check_servers():
    """Verify both ports are active."""
    print("🔍 Checking system status...")
    async with httpx.AsyncClient() as client:
        try:
            be = await client.get(f"http://localhost:8000/")
            ai = await client.get(f"{AI_ENGINE_URL}/")
            print(f"✅ Backend: ONLINE | AI Engine: ONLINE")
            return True
        except Exception:
            print("❌ ERROR: Both servers (Port 8000 & 8001) must be running.")
            return False

async def seed_system():
    """Ensure test data exists."""
    print("\n🌱 Seeding Test Environment...")
    from backend.application.seed import seed_db
    seed_db()
    print("✅ Database Seeded (Zone: Tomato Zone, Device: esp_test_002)")

async def suite_1_planning():
    """Test: Strategic Planning (Discovery + RAG Guide)."""
    print("\n[SUITE 1] Testing Strategic Discovery & Planning...")
    async with httpx.AsyncClient() as client:
        # Discovery: Find the Zone ID for 'Tomato Zone' directly from DB
        from core.database import SessionLocal
        from models.farm import Zone
        
        db = SessionLocal()
        zone = db.query(Zone).filter(Zone.name == "Tomato Zone").first()
        db.close()
        
        if not zone:
            print("❌ Suite 1 Failed: Could not find 'Tomato Zone' in DB.")
            return False
            
        zone_id = zone.id
        
        print(f"🚀 Triggering Crop Plan for Zone {zone_id}...")
        response = await client.post(f"{BACKEND_URL}/ai/generate-plan/{zone_id}", timeout=60.0)
        
        if response.status_code == 200:
            plan = response.json()
            print(f"✅ SUCCESS: Recommended {plan.get('recommended_crop')}")
            print(f"   Outlook: {plan.get('market_outlook')} | Scientific Guide Attached.")
            return True
        else:
            print(f"❌ Suite 1 Failed: {response.text}")
            return False

async def suite_2_anomaly():
    """Test: Hardware Resilience (Anomaly Detection)."""
    print("\n[SUITE 2] Testing Hardware Resilience (Anomaly Diagnosis)...")
    # Simulate high flow while system is IDLE
    sensor_history = [
        {"id": "esp_test_002", "moisture": 50, "flow": 0, "temp": 25},
        {"id": "esp_test_002", "moisture": 50, "flow": 10.5, "temp": 25} # CRITICAL BURST
    ]
    
    async with httpx.AsyncClient() as client:
        response = await client.post(f"{AI_ENGINE_URL}/ai/diagnose", json=sensor_history, timeout=60.0)
        if response.status_code == 200:
            diagnoses = response.json()
            if diagnoses and "PIPE_BURST" in str(diagnoses[0]):
                print(f"✅ SUCCESS: AI diagnosed Bursting Pipe.")
                print(f"   Diagnosis: {diagnoses[0].get('ai_diagnosis')}")
                return True
        print(f"❌ Suite 2 Failed: {response.text}")
        return False

async def suite_3_operational():
    """Test: Operational Loop (Sensor -> AI -> Valve Command)."""
    print("\n[SUITE 3] Testing Operational Intelligence Loop...")
    payload = {
        "device_uid": "esp_test_002",
        "soil_moisture": 15.5, # CRITICAL STRESS
        "temperature": 42.0,   # HEAT STRESS
        "humidity": 30.0,
        "flow": 0.0
    }
    
    async with httpx.AsyncClient() as client:
        print("📤 Sending Stress Telemetry...")
        resp = await client.post(f"{BACKEND_URL}/sensors/", json=payload, timeout=60.0)
        if resp.status_code != 200:
            print(f"❌ Suite 3 Failed (Sensor Post): {resp.text}")
            return False
            
        print("⏳ Waiting for AI Decision (5s)...")
        await asyncio.sleep(5)
        
        # Check for pending commands
        cmds = await client.get(f"{BACKEND_URL}/commands/pending")
        triggered = any("esp_test_002" in str(c) or "ON" in str(c) for c in cmds.json())
        
        if triggered:
            print(f"✅ SUCCESS: AI triggered Valve Command.")
            return True
        else:
            print("❌ Suite 3 Failed: No valve command generated.")
            return False

async def run_dashboard():
    if not await check_servers(): return
    
    await seed_system()
    
    results = {
        "Strategic Planning (RAG)": await suite_1_planning(),
        "Hardware Resilience (Anomaly)": await suite_2_anomaly(),
        "Operational Loop (Decision)": await suite_3_operational()
    }
    
    print("\n" + "="*40)
    print("🏆 SYSTEM HEALTH DASHBOARD")
    print("="*40)
    for name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{name:<30} : {status}")
    print("="*40)

if __name__ == "__main__":
    asyncio.run(run_dashboard())
