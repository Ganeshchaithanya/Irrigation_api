import subprocess
import os
import sys
import time
import httpx
import json
import asyncio
from typing import Optional
from dotenv import load_dotenv

# Global Path Setup
PROJECT_ROOT = os.getcwd()
BACKEND_APP_PATH = os.path.join(PROJECT_ROOT, "backend", "application")
AI_ENGINE_PATH = os.path.join(PROJECT_ROOT, "ai_engine")

# Ensure sub-processes and the main script can import correctly
current_pythonpath = os.getenv("PYTHONPATH", "")
os.environ["PYTHONPATH"] = f"{PROJECT_ROOT};{BACKEND_APP_PATH};{AI_ENGINE_PATH};{current_pythonpath}"

if BACKEND_APP_PATH not in sys.path:
    sys.path.append(BACKEND_APP_PATH)
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Load common environment from backend for all processes
load_dotenv(os.path.join(PROJECT_ROOT, "backend", ".env"))


def start_server(name: str, port: int, cwd: str, extra_path: str):
    print(f"🚀 Starting {name} on port {port}...")
    # The process will inherit the global os.environ which already has the fixed PYTHONPATH
    
    # We use a shell-free popen to avoid terminal overhead in this automated test
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "main:app", "--host", "127.0.0.1", "--port", str(port)],
        cwd=os.path.join(PROJECT_ROOT, cwd),
        env=os.environ,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    return proc

async def wait_for_server(port: int, name: str, proc: subprocess.Popen, timeout: int = 60):
    url = f"http://127.0.0.1:{port}/"
    print(f"⌛ Waiting for {name} to be ready (timeout {timeout}s)...")
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
            
            # Check if process died
            if proc.poll() is not None:
                stdout, stderr = proc.communicate()
                print(f"❌ {name} process died unexpectedly.")
                print(f"STDOUT: {stdout}")
                print(f"STDERR: {stderr}")
                return False
                
            await asyncio.sleep(1)
    
    print(f"❌ {name} failed to start on port {port} within {timeout}s.")
    # Try to capture output from the zombie process
    try:
        stdout, stderr = proc.communicate(timeout=2)
        print(f"STDOUT: {stdout}")
        print(f"STDERR: {stderr}")
    except Exception:
        print("Could not capture process output.")
    return False

async def run_tests():
    print("\n" + "="*50)
    print("🌟 THE ULTIMATE AGRI-EXPERT SYSTEM TEST")
    print("="*50)
    
    # Paths are already setup globally
    
    backend = start_server("Backend", 8000, "backend/application", "backend/application")
    ai_engine = start_server("AI Engine", 8001, "ai_engine", "ai_engine")
    
    try:
        if not await wait_for_server(8000, "Backend", backend): return
        if not await wait_for_server(8001, "AI Engine", ai_engine): return
        
        # 1. Seed DB
        print("\n🌱 Seeding database...")
        from backend.application.seed import seed_db
        seed_db()
        
        # 2. Run Suites
        print("\n🏃 Executing Test Suite 3: CUSTOM (Rice Paddy)...")
        test_proc_3 = subprocess.run([sys.executable, "rice_system_test.py"])
        
        if test_proc_3.returncode == 0:
            print("\n✅ INTEGRATION TEST COMPLETE: ALL SYSTEMS PASSED.")
        else:
            print("\n❌ INTEGRATION TEST FAILED: One or more suites failed.")
            
    finally:
        print("\n🛑 Shutting down servers...")
        backend.terminate()
        ai_engine.terminate()

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(run_tests())
