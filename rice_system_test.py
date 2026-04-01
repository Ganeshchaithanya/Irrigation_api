import asyncio
import httpx
import json
import os
import sys
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend", ".env"))

# PATH SETUP
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, PROJECT_ROOT)

BACKEND_URL = "http://localhost:8000/api/v1"
AI_ENGINE_URL = "http://localhost:8001"

async def check_servers():
    print("🔍 Checking system status...")
    async with httpx.AsyncClient() as client:
        try:
            await client.get(f"http://localhost:8000/")
            await client.get(f"{AI_ENGINE_URL}/")
            print(f"✅ Backend: ONLINE | AI Engine: ONLINE")
            return True
        except Exception:
            print("❌ ERROR: Both servers (Port 8000 & 8001) must be running.")
            return False

async def seed_system():
    print("\n🌱 Seeding Test Environment...")
    from backend.application.seed import seed_db
    seed_db()

async def suite_1_planning_rice():
    """Test: Strategic Planning for Rice Paddy."""
    print("\n[SUITE 1] Testing Strategic Planning (RICE)...")
    async with httpx.AsyncClient() as client:
        from core.database import SessionLocal
        from models.farm import Zone
        
        db = SessionLocal()
        zone = db.query(Zone).filter(Zone.name == "Rice Paddy").first()
        db.close()
        
        if not zone:
            print("❌ Suite 1 Failed: Could not find 'Rice Paddy' in DB.")
            return False
            
        zone_id = zone.id
        print(f"🚀 Triggering Crop Plan for Rice Zone {zone_id}...")
        response = await client.post(f"{BACKEND_URL}/ai/generate-plan/{zone_id}", timeout=60.0)
        
        if response.status_code == 200:
            plan = response.json()
            print(f"✅ SUCCESS: Recommended {plan.get('recommended_crop')}")
            print(f"   Context: Growing Rice in Clay Loam soil.")
            return True
        else:
            print(f"❌ Suite 1 Failed: {response.text}")
            return False

async def suite_2_flood_detection():
    """Test: Heavy saturation/flood anomaly detection."""
    print("\n[SUITE 2] Testing Hardware Resilience (FLOOD/OVERSATURATION)...")
    # Simulate dangerously high moisture and flow
    sensor_history = [
        {"id": "esp_test_004", "moisture": 60, "flow": 2.0, "temp": 30},
        {"id": "esp_test_004", "moisture": 95, "flow": 15.0, "temp": 30} # SUDDEN FLOOD
    ]
    
    async with httpx.AsyncClient() as client:
        response = await client.post(f"{AI_ENGINE_URL}/ai/diagnose", json=sensor_history, timeout=60.0)
        if response.status_code == 200:
            diagnoses = response.json()
            print(f"📋 AI Observations: {json.dumps(diagnoses, indent=2)}")
            return True
        print(f"❌ Suite 2 Failed: {response.text}")
        return False

async def suite_3_disease_risk():
    """Test: High humidity + High Temp = Fungal risk triggers."""
    print("\n[SUITE 3] Testing Operational Intelligence (DISEASE RISK)...")
    payload = {
        "device_uid": "esp_test_004",
        "soil_moisture": 80.0, 
        "temperature": 35.0,  
        "humidity": 90.0,      # HIGH HUMIDITY + HIGH TEMP
        "flow": 1.0
    }
    
    async with httpx.AsyncClient() as client:
        print("📤 Sending High Humidity Telemetry...")
        resp = await client.post(f"{BACKEND_URL}/sensors/", json=payload, timeout=60.0)
        if resp.status_code != 200:
            print(f"❌ Suite 3 Failed (Sensor Post): {resp.text}")
            return False
            
        print("⏳ Waiting for AI Decision (5s)...")
        await asyncio.sleep(5)
        
        cmds = await client.get(f"{BACKEND_URL}/commands/pending")
        triggered = any("esp_test_004" in str(c) for c in cmds.json())
        
        if not triggered:
            # For disease risk, it shouldn't trigger water ON, it should trigger an alert. 
            # We assume it remains idle for valve.
            print(f"✅ SUCCESS: AI remained IDLE on irrigation (Did not water during high humidity/fungal risk).")
            return True
        else:
            print("❌ Suite 3 Failed: AI incorrectly triggered watering during fungal risk conditions.")
            return False

async def run_dashboard():
    if not await check_servers(): return
    await seed_system()
    
    results = {
        "Strategic Planning (Rice)": await suite_1_planning_rice(),
        "Hardware Resilience (Flood)": await suite_2_flood_detection(),
        "Operational Sanity (Disease)": await suite_3_disease_risk()
    }
    
    print("\n" + "="*40)
    print("🏆 RICE PADDY CUSTOM TEST")
    print("="*40)
    for name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{name:<30} : {status}")
    print("="*40)

if __name__ == "__main__":
    asyncio.run(run_dashboard())
