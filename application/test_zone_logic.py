import sys
import os
from datetime import datetime
from sqlalchemy.orm import Session

# Add the project root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application.core.database import SessionLocal, Base, engine
from application.models.user import User
from application.models.farm import Farm, Acre, Zone
from application.models.device import Device
from application.models.sensor import NodeData, ZoneData, MasterData
from application.schemas.sensor import SensorDataCreate
from application.services import sensor_service

def setup_test_data(db: Session):
    # 1. Create User/Farm/Acre/Zone
    user = db.query(User).first()
    if not user:
        user = User(name="Test User", phone="+1999999999", is_phone_verified=True)
        db.add(user)
        db.commit()
        db.refresh(user)
    
    farm = db.query(Farm).first()
    if not farm:
        farm = Farm(user_id=user.id, name="Test Farm", location="Test Location")
        db.add(farm)
        db.commit()
        db.refresh(farm)
        
    acre = db.query(Acre).first()
    if not acre:
        acre = Acre(farm_id=farm.id, name="Test Acre", size=1.0)
        db.add(acre)
        db.commit()
        db.refresh(acre)
        
    zone = db.query(Zone).first()
    if not zone:
        zone = Zone(acre_id=acre.id, name="Test Zone", crop_type="Test Crop", soil_type="Test Soil")
        db.add(zone)
        db.commit()
        db.refresh(zone)

    # 2. Register Devices with Roles
    # Leader
    leader = db.query(Device).filter(Device.device_uid == "esp_leader").first()
    if not leader:
        leader = Device(device_uid="esp_leader", zone_id=zone.id, role="LEADER", position_label="START")
        db.add(leader)
    
    # Worker
    worker = db.query(Device).filter(Device.device_uid == "esp_worker").first()
    if not worker:
        worker = Device(device_uid="esp_worker", zone_id=zone.id, role="WORKER", position_label="MIDDLE")
        db.add(worker)
        
    # Master
    master = db.query(Device).filter(Device.device_uid == "esp_master").first()
    if not master:
        master = Device(device_uid="esp_master", role="MASTER") # Master doesn't need to be in a zone
        db.add(master)
        
    db.commit()
    return zone.id

def test_sensor_routing():
    db = SessionLocal()
    try:
        zone_id = setup_test_data(db)
        
        # --- TEST 1: LEADER POST ---
        print("\n[TEST 1] Posting from LEADER (esp_leader)...")
        leader_payload = SensorDataCreate(
            device_id="esp_leader",
            timestamp=datetime.now(),
            soil_moisture=35.5,
            temperature=28.4,
            humidity=55.2,
            flow=0.0
        )
        res1 = sensor_service.create_sensor_data(db, leader_payload)
        
        # Verify NodeData (Soil)
        node_rec = db.query(NodeData).filter(NodeData.device_id == res1.device_id).order_by(NodeData.timestamp.desc()).first()
        print(f"✅ NodeData created: Moisture={node_rec.soil_moisture}")
        
        # Verify ZoneData (Environment)
        zone_rec = db.query(ZoneData).filter(ZoneData.zone_id == zone_id).order_by(ZoneData.timestamp.desc()).first()
        print(f"✅ ZoneData created: Temp={zone_rec.temperature}, Humidity={zone_rec.humidity}")

        # --- TEST 2: WORKER POST ---
        print("\n[TEST 2] Posting from WORKER (esp_worker)...")
        worker_payload = SensorDataCreate(
            device_id="esp_worker",
            timestamp=datetime.now(),
            soil_moisture=42.1,
            temperature=99.9, # Should be ignored for worker
            humidity=99.9,    # Should be ignored for worker
            flow=0.0
        )
        res2 = sensor_service.create_sensor_data(db, worker_payload)
        
        # Verify NodeData
        node_rec_worker = db.query(NodeData).filter(NodeData.device_id == res2.device_id).order_by(NodeData.timestamp.desc()).first()
        print(f"✅ NodeData created for worker: Moisture={node_rec_worker.soil_moisture}")
        
        # Verify ZoneData was NOT updated with worker's junk temp
        latest_zone = db.query(ZoneData).filter(ZoneData.zone_id == zone_id).order_by(ZoneData.timestamp.desc()).first()
        if latest_zone.temperature == 99.9:
            print("❌ FAILED: Worker accidentally updated ZoneData environment!")
        else:
            print(f"✅ ZoneData remains correct (Temp={latest_zone.temperature})")

        # --- TEST 3: MASTER POST ---
        print("\n[TEST 3] Posting from MASTER (esp_master)...")
        master_payload = SensorDataCreate(
            device_id="esp_master",
            timestamp=datetime.now(),
            soil_moisture=0.0,
            temperature=0.0,
            humidity=0.0,
            flow=12.5,
            water_consumed=150.0,
            is_raining=True
        )
        res3 = sensor_service.create_sensor_data(db, master_payload)
        
        # Verify MasterData
        master_rec = db.query(MasterData).order_by(MasterData.timestamp.desc()).first()
        print(f"✅ MasterData created: Flow={master_rec.flow_rate}, Raining={master_rec.is_raining}")

    finally:
        db.close()

if __name__ == "__main__":
    test_sensor_routing()
