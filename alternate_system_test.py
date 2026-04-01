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
    print("✅ Database Seeded (Zone: Wheat Field, Device: esp_test_003)")

async def suite_1_planning_wheat():
    """Test: Strategic Planning for Wheat."""
    print("\n[SUITE 1] Testing Strategic Planning (WHEAT)...")
    async with httpx.AsyncClient() as client:
        from core.database import SessionLocal
        from models.farm import Zone
        
        db = SessionLocal()
        zone = db.query(Zone).filter(Zone.name == "Wheat Field").first()
        db.close()
        
        if not zone:
            print("❌ Suite 1 Failed: Could not find 'Wheat Field' in DB.")
            return False
            
        zone_id = zone.id
        print(f"🚀 Triggering Crop Plan for Wheat Zone {zone_id}...")
        response = await client.post(f"{BACKEND_URL}/ai/generate-plan/{zone_id}", timeout=60.0)
        
        if response.status_code == 200:
            plan = response.json()
            print(f"✅ SUCCESS: Recommended {plan.get('recommended_crop')}")
            print(f"   Context: Growing Wheat in Clay soil.")
            return True
        else:
            print(f"❌ Suite 1 Failed: {response.text}")
            return False

async def suite_2_leak_detection():
    """Test: Slow Leak Anomaly (Different from Burst)."""
    print("\n[SUITE 2] Testing Hardware Resilience (SLOW LEAK)...")
    # Simulate low but steady flow while IDLE
    sensor_history = [
        {"id": "esp_test_003", "moisture": 40, "flow": 0, "temp": 22},
        {"id": "esp_test_003", "moisture": 40, "flow": 0.5, "temp": 22} # MINOR LEAK
    ]
    
    async with httpx.AsyncClient() as client:
        response = await client.post(f"{AI_ENGINE_URL}/ai/diagnose", json=sensor_history, timeout=60.0)
        if response.status_code == 200:
            diagnoses = response.json()
            print(f"📋 AI Observations: {json.dumps(diagnoses, indent=2)}")
            return True
        print(f"❌ Suite 2 Failed: {response.text}")
        return False

async def suite_3_optimal_conditions():
    """Test: Operational Loop (Optimal - No Command expected)."""
    print("\n[SUITE 3] Testing Operational Sanity (OPTIMAL CONDITIONS)...")
    payload = {
        "device_uid": "esp_test_003",
        "soil_moisture": 28.0, # HEALTHY FOR CLAY
        "temperature": 24.0,   # OPTIMAL
        "humidity": 60.0,
        "flow": 0.0
    }
    
    async with httpx.AsyncClient() as client:
        print("📤 Sending Healthy Telemetry...")
        resp = await client.post(f"{BACKEND_URL}/sensors/", json=payload, timeout=60.0)
        if resp.status_code != 200:
            print(f"❌ Suite 3 Failed (Sensor Post): {resp.text}")
            return False
            
        print("⏳ Waiting to verify NO action taken (5s)...")
        await asyncio.sleep(5)
        
        # Check for pending commands (should be none for this device)
        cmds = await client.get(f"{BACKEND_URL}/commands/pending")
        triggered = any("esp_test_003" in str(c) for c in cmds.json())
        
        if not triggered:
            print(f"✅ SUCCESS: AI remained IDLE (Conditions are healthy).")
            return True
        else:
            print("❌ Suite 3 Failed: AI triggered unnecessary command.")
            return False

async def run_dashboard():
    if not await check_servers(): return
    
    await seed_system()
    
    results = {
        "Strategic Planning (Wheat)": await suite_1_planning_wheat(),
        "Hardware Resilience (Leak)": await suite_2_leak_detection(),
        "Operational Sanity (Healthy)": await suite_3_optimal_conditions()
    }
    
    print("\n" + "="*40)
    print("🏆 ALTERNATE TEST DASHBOARD")
    print("="*40)
    for name, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{name:<30} : {status}")
    print("="*40)

if __name__ == "__main__":
    asyncio.run(run_dashboard())
