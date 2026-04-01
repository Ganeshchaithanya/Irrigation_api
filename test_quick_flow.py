import subprocess
import os
import sys
import time
import httpx
import asyncio
from datetime import datetime
from dotenv import load_dotenv

# Global Path Setup
PROJECT_ROOT = os.getcwd()
BACKEND_APP_PATH = os.path.join(PROJECT_ROOT, "backend", "application")
AI_ENGINE_PATH = os.path.join(PROJECT_ROOT, "ai_engine")

current_pythonpath = os.getenv("PYTHONPATH", "")
os.environ["PYTHONPATH"] = f"{PROJECT_ROOT};{BACKEND_APP_PATH};{AI_ENGINE_PATH};{current_pythonpath}"

load_dotenv(os.path.join(PROJECT_ROOT, "backend", ".env"))

def start_server(name: str, port: int, cwd: str):
    print(f"🚀 Starting {name} on port {port}...")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", str(port)],
        cwd=os.path.join(PROJECT_ROOT, cwd),
        env=os.environ,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return proc

async def wait_for_server(port: int, name: str, timeout: int = 15):
    url = f"http://127.0.0.1:{port}/"
    start_time = time.time()
    async with httpx.AsyncClient() as client:
        while time.time() - start_time < timeout:
            try:
                resp = await client.get(url)
                if resp.status_code == 200:
                    print(f"✅ {name} is ONLINE.")
                    return True
            except Exception:
                pass
            await asyncio.sleep(1)
    return False

async def run_flow_test():
    print("="*50)
    print("🌟 TESTING E2E IRRIGATION FLOW (SENSOR -> AI -> VALVE)")
    print("="*50)
    
    backend = start_server("Backend", 8000, "backend/application")
    ai_engine = start_server("AI Engine", 8001, "ai_engine")
    
    try:
        if not await wait_for_server(8000, "Backend"): return
        if not await wait_for_server(8001, "AI Engine"): return
        
        # 1. Seed DB
        print("\n🌱 Seeding database with our mock setup...")
        from backend.application.test_all_db_models import test_all_models
        test_all_models()
        
        # 2. Test Sensor Data Flow
        async with httpx.AsyncClient() as client:
            print("\n📡 Sending Low Moisture Telemetry...")
            payload = {
                "device_id": "DEV_001",
                "timestamp": datetime.utcnow().isoformat(),
                "soil_moisture": 15.0,  # CRITICAL LOW (forces watering)
                "temperature": 32.0,  
                "humidity": 40.0,
                "flow": 0.0,
                "is_raining": False
            }
            
            resp = await client.post("http://127.0.0.1:8000/api/v1/sensors/", json=payload, timeout=20.0)
            if resp.status_code == 200:
                print(f"✅ Telemetry Accepted. Response: {resp.json()}")
            else:
                print(f"❌ Telemetry Rejected: {resp.text}")
                return
                
            print("⏳ Waiting for AI Decision Processing (5s)...")
            await asyncio.sleep(5)
            
            # 3. Verify Valve Commands
            print("\n🔄 Fetching Pending Valve Commands...")
            cmds = await client.get("http://127.0.0.1:8000/api/v1/commands/pending")
            
            if cmds.status_code == 200:
                commands = cmds.json()
                print(f"📋 Commands Found: {len(commands)}")
                for c in commands:
                    print(f"   ⚙️ Command: {c['command']} for Zone {c['zone_id']} | Status: {c['status']}")
                
                if any("OPEN" in str(c) for c in commands):
                    print("\n🎉 SUCCESS: The AI correctly identified low moisture and triggered an OPEN valve command!")
                else:
                    print("\n⚠️ WARNING: The AI did not issue an OPEN command. Either threshold wasn't hit or there's an issue.")
            else:
                print(f"❌ Failed to fetch commands: {cmds.text}")
            
    finally:
        print("\n🛑 Shutting down servers...")
        backend.terminate()
        ai_engine.terminate()

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(run_flow_test())
