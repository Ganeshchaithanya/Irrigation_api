from sqlalchemy.orm import Session
from application.core.database import SessionLocal
from application.models.user import User
from application.models.farm import Farm, Acre, Zone
from application.models.device import Device

def seed_db():
    db: Session = SessionLocal()
    
    # 1. Device 1: Tomatoes
    device1 = db.query(Device).filter(Device.device_uid == "esp_test_002").first()
    if not device1:
        print("Seeding Tomato Zone...")
        user = db.query(User).filter(User.phone == "+1234567890").first()
        if not user:
            user = User(name="Test User", phone="+1234567890", is_phone_verified=True)
            db.add(user)
            db.commit()
            db.refresh(user)
        
        farm = db.query(Farm).filter(Farm.user_id == user.id, Farm.name == "Demo Farm").first()
        if not farm:
            farm = Farm(user_id=user.id, name="Demo Farm", location="Test Location")
            db.add(farm)
            db.commit()
            db.refresh(farm)
            
        acre = db.query(Acre).filter(Acre.farm_id == farm.id, Acre.name == "North Acre").first()
        if not acre:
            acre = Acre(farm_id=farm.id, name="North Acre", size=1.5)
            db.add(acre)
            db.commit()
            db.refresh(acre)
            
        zone = Zone(acre_id=acre.id, name="Tomato Zone", crop_type="Tomatoes", soil_type="Loam", mode="AUTO")
        db.add(zone)
        db.commit()
        db.refresh(zone)
        
        device1 = Device(device_uid="esp_test_002", zone_id=zone.id, position_label="START", status="ACTIVE")
        db.add(device1)
        db.commit()
        print(f"Created Tomato Zone & esp_test_002")

    # 2. Device 2: Wheat (NEW TEST CASE)
    device2 = db.query(Device).filter(Device.device_uid == "esp_test_003").first()
    if not device2:
        print("Seeding Wheat Field...")
        user = db.query(User).filter(User.phone == "+1234567890").first()
        farm = db.query(Farm).filter(Farm.user_id == user.id, Farm.name == "Demo Farm").first()
        
        acre2 = db.query(Acre).filter(Acre.farm_id == farm.id, Acre.name == "South Acre").first()
        if not acre2:
            acre2 = Acre(farm_id=farm.id, name="South Acre", size=2.0)
            db.add(acre2)
            db.commit()
            db.refresh(acre2)
            
        zone2 = Zone(acre_id=acre2.id, name="Wheat Field", crop_type="Wheat", soil_type="Clay", mode="AUTO")
        db.add(zone2)
        db.commit()
        db.refresh(zone2)
        
        device2 = Device(device_uid="esp_test_003", zone_id=zone2.id, position_label="END", status="ACTIVE")
        db.add(device2)
        db.commit()
        print(f"Created Wheat Field & esp_test_003")

    # 3. Device 3: Rice (NEW CUSTOM TEST CASE)
    device3 = db.query(Device).filter(Device.device_uid == "esp_test_004").first()
    if not device3:
        print("Seeding Rice Paddy...")
        user = db.query(User).filter(User.phone == "+1234567890").first()
        farm = db.query(Farm).filter(Farm.user_id == user.id, Farm.name == "Demo Farm").first()
        
        acre3 = db.query(Acre).filter(Acre.farm_id == farm.id, Acre.name == "East Acre").first()
        if not acre3:
            acre3 = Acre(farm_id=farm.id, name="East Acre", size=3.0)
            db.add(acre3)
            db.commit()
            db.refresh(acre3)
            
        zone3 = Zone(acre_id=acre3.id, name="Rice Paddy", crop_type="Rice", soil_type="Clay Loam", mode="AUTO")
        db.add(zone3)
        db.commit()
        db.refresh(zone3)
        
        device3 = Device(device_uid="esp_test_004", zone_id=zone3.id, position_label="MIDDLE", status="ACTIVE")
        db.add(device3)
        db.commit()
        print(f"Created Rice Paddy & esp_test_004")

    print("\nSeed configuration complete! Multiple test cases available.")
    db.close()

if __name__ == "__main__":
    seed_db()
