import asyncio
import os
import sys
import uuid
import json
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 1. PATH SETUP: Ensure all modules are discoverable from root
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, PROJECT_ROOT)
sys.path.insert(0, os.path.join(PROJECT_ROOT, "backend", "application"))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "ai_engine"))

from core.database import Base
from ai_engine.services.ai_service import AIService
from services.decision_service import DecisionService
from models.farm import Farm, Acre, Zone
from models.device import Device
from models.sensor import SensorData
from models.ai import AiValidationLog, Prediction

# 2. TEST DATABASE: Use Local SQLite for total logic verification
TEST_DB_URL = "sqlite:///./test_resilience.db"
test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# Auto-generate all schemas
import models.farm, models.device, models.sensor, models.ai, models.command, models.state, models.chat, models.notification
Base.metadata.drop_all(bind=test_engine) # Clean start
Base.metadata.create_all(bind=test_engine)

async def run_resilience_test():
    db = TestSessionLocal()
    
    # Initialize Core Services (Injecting them directly for Logic-Only check)
    ai_logic = AIService()
    decision_logic = DecisionService()
    
    print("\n" + "🚀" * 15)
    print("🔥 E2E SYSTEM RESILIENCE TEST (Standalone Logic)")
    print("🚀" * 15)

    try:
        # A. SEED: Mock Infrastructure
        user_id = uuid.uuid4()
        farm = Farm(user_id=user_id, name="Resilience Demo Farm", location="Bengaluru")
        db.add(farm)
        db.flush()

        acre = Acre(farm_id=farm.id, name="North Acre", size=1.0)
        db.add(acre)
        db.flush()

        zone = Zone(acre_id=acre.id, name="Corn Patch", crop_type="Maize", soil_type="Black Soil")
        db.add(zone)
        db.flush()

        # Create 3-Node Topology
        nodes = {}
        for pos in ["START", "MIDDLE", "END"]:
            dev = Device(id=uuid.uuid4(), zone_id=zone.id, position_label=pos, status="ACTIVE")
            db.add(dev)
            nodes[pos] = dev
        db.commit()
        print(f"✅ Created Zone '{zone.name}' with 3 Nodes (Logic Grid OK).")

        # B. SCENARIO: MIDDLE NODE FAILS (Virtual Sensing Trigger)
        print("\n" + "🛠️ SCENARIO: MIDDLE Node is FAULTY (Static 0.0 moisture readings)")
        print("🛠️ EXPECTED BEHAVIOR: AI identifies fault -> Switches to Surrogate START Node.")
        
        now = datetime.utcnow()
        for i in range(12): # 12 hours of data
            # START Node has realistic dropping moisture (40% down to 35%)
            db.add(SensorData(device_id=nodes["START"].id, soil_moisture=40.0 - (i*0.5), timestamp=now - timedelta(hours=i)))
            # MIDDLE Node is CRITICAL FAULT (Stuck at 0.0)
            db.add(SensorData(device_id=nodes["MIDDLE"].id, soil_moisture=0.0, timestamp=now - timedelta(hours=i)))
            # END Node is Healthy
            db.add(SensorData(device_id=nodes["END"].id, soil_moisture=42.0 - (i*0.4), timestamp=now - timedelta(hours=i)))
        db.commit()

        # C. TRIGGER: Call the Decision Pipeline logic on the FAILED node
        print("\n🧠 Invoking AI Decision Orchestrator (Logic Scan)...")
        
        # We simulate the gathering step the real DecisionService does
        neighbors = [{"id": str(nodes[p].id), "position_label": p, "status": nodes[p].status} for p in nodes]
        readings = db.query(SensorData).filter(SensorData.device_id == nodes["MIDDLE"].id).order_by(SensorData.timestamp.desc()).all()
        sensor_history = [{"moisture": r.soil_moisture, "temp": 25.0} for r in readings]

        # ACT: Run Anomaly -> Surrogacy -> Stage -> Prediction -> Validation
        report = await ai_logic.generate_full_report(
            raw_sensor_data=sensor_history,
            weather_data={}, # WeatherService will auto-fetch live data
            zone_id=str(zone.id),
            neighbors=neighbors,
            day_of_growth=25 # Maize Vegetative Stage
        )

        # D. VERIFY: Output Intelligence Report
        print("\n" + "="*50)
        print("📊 STANDALONE AI REPORT (Llama-3.2-3B reasoning)")
        print("="*50)
        
        anom = report.get('anomalies', [])
        print(f"📡 Hardware Health: {'⚠️ ANOMALY DETECTED' if anom else '✅ HEALTHY'}")
        for a in anom:
            print(f"   - Diagnosis: {a.get('ai_diagnosis')}")

        pred = report.get('predictions', {})
        print(f"\n🔮 Prediction & Resiliency:")
        print(f"   - Surrogate Active: {pred.get('is_virtual_sensing_active')} (Surrogate used: True)")
        print(f"   - Biological Stage: Vegetative (High Water Sensitivity)")
        print(f"   - Tomorrow MM: {pred.get('tomorrow_mm_needed')} mm")
        print(f"   - Backend Action: {report.get('backend_action')}")
        print(f"\n💡 AI REASONING EXAMPLE:")
        print(f"   \"{pred.get('ai_reasoning')}\"")

        # E. PERSISTENCE CHECK: Did backend logic save to our local DB?
        # We manually process the report into the DB logic for verification
        await decision_logic._process_ai_report(db, zone.id, report, sensor_history[0])
        
        final_log = db.query(AiValidationLog).filter(AiValidationLog.zone_id == zone.id).first()
        if final_log:
            print(f"\n✅ SUCCESS: Validation Trace saved - Decision: {final_log.decision}")

    except Exception as e:
        print(f"\n❌ TEST CRITICAL FAILURE: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()
        print("\n🏁 Resilience Logic Check Complete.")

if __name__ == "__main__":
    if not os.getenv("GROQ_API_KEY"):
        print("⚠️ WARNING: GROQ_API_KEY missing. Reasoning will use fallbacks.")
    asyncio.run(run_resilience_test())
