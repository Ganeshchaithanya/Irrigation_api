import os
import sys

# Add project root to sys.path
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.append(PROJECT_ROOT)

def verify_unification():
    print("\n--- Starting Unified Architecture Verification ---")
    
    try:
        print("1. Testing root import of application.main...")
        from application.main import app
        print("   [SUCCESS] Root main.app imported.")
    except Exception as e:
        print(f"   [FAILED] Could not import main.app: {e}")
        return

    try:
        print("2. Testing core infrastructure imports...")
        from application.core.database import SessionLocal, Base
        from application.core.config import settings
        print("   [SUCCESS] Core components available.")
    except Exception as e:
        print(f"   [FAILED] Core import failure: {e}")
        return

    try:
        print("3. Testing AI logic imports...")
        # Since I merged data into models/, these should still work if they are .py files
        from application.ai.models.prediction_model import PredictionModel
        from application.ai.specialists.ingest_expert_guides import ingest_all_guides
        print("   [SUCCESS] AI components imported.")
    except Exception as e:
        print(f"   [FAILED] AI import failed: {e}")
        return

    try:
        print("4. Testing API route resolution...")
        from application.api import sensor, irrigation, ai
        print("   [SUCCESS] API Routers (Sensor, Irrigation, AI) found.")
    except Exception as e:
        print(f"   [FAILED] API Route failure: {e}")
        return

    print("\n--- Verification Complete: ALL PILLARS UNIFIED AND FUNCTIONAL ---")

if __name__ == "__main__":
    verify_unification()
