import subprocess
import sys
import os
import time

def start_service(name, command, cwd):
    print(f"Starting {name}...")
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.abspath(".")
    process = subprocess.Popen(
        command,
        cwd=cwd,
        env=env,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    return process

if __name__ == "__main__":
    root = os.path.abspath(".")
    
    # 1. Start Backend (Port 8000)
    # We need to include both the root (for llm) and the application folder (for routes/core)
    env = os.environ.copy()
    abs_root = os.path.abspath(".")
    abs_backend = os.path.join(abs_root, "backend", "application")
    env["PYTHONPATH"] = f"{abs_root};{abs_backend}"
    
    backend_cmd = [sys.executable, "-m", "uvicorn", "backend.application.main:app", "--port", "8000"]
    backend_proc = subprocess.Popen(
        backend_cmd,
        cwd=abs_root,
        env=env,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    
    # 2. Start AI Engine (Port 8001)
    ai_cmd = [sys.executable, "-m", "uvicorn", "ai_engine.main:app", "--port", "8001"]
    ai_proc = subprocess.Popen(
        ai_cmd,
        cwd=abs_root,
        env=env,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    
    print("\nServices are launching. Waiting 5s for stability...")
    time.sleep(5)
    
    # Check if they are still running
    if backend_proc.poll() is None:
        print("Backend is running.")
    else:
        print("Backend failed to start.")
        print(backend_proc.stdout.read())
        
    if ai_proc.poll() is None:
        print("AI Engine is running.")
    else:
        print("AI Engine failed to start.")
        print(ai_proc.stdout.read())
        
    print("\nStarting Flutter App...")
    flutter_cmd = ["flutter", "run", "-d", "chrome"]
    subprocess.run(flutter_cmd, cwd=os.path.join(root, "aquasol_app"), shell=True)
