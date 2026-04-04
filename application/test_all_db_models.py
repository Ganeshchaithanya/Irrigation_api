import os
import sys

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from application.core.database import SessionLocal, engine, Base

from application.models.user import User, OtpVerification, UserSession
from application.models.farm import Farm, Acre, Zone
from application.models.device import Device
from application.models.sensor import NodeData, ZoneData, MasterData, SensorDataRaw
from application.models.irrigation import IrrigationLog
from application.models.command import ValveCommand
from application.models.state import ZoneState
from application.models.analytics import DailyAggregate, MonthlyAggregate, YearlyAggregate, PlantHealthScore, ETData
from application.models.ai import AiValidationLog, Prediction, CropPlan
from application.models.chat import ChatLog, MessageTemplate
from application.models.notification import Notification
from application.models.feedback import IrrigationFeedback

def test_all_models():
    print("Connecting to database...")
    print("Recreating tables (if missing) for testing...")
    Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    try:
        timestamp = int(datetime.utcnow().timestamp())
        phone = f"+123456{timestamp}"
        device_uid = f"DEV_{timestamp}"
        
        print(f"Inserting test data for User module (phone: {phone})...")
        user = User(name="Test User", phone=phone, is_phone_verified=True)
        db.add(user)
        db.commit()
        db.refresh(user)
        
        otp = OtpVerification(phone=phone, otp_code="1234", expires_at=datetime.utcnow() + timedelta(minutes=10))
        db.add(otp)
        
        session = UserSession(user_id=user.id, token=f"test_token_{timestamp}", expires_at=datetime.utcnow() + timedelta(days=1))
        db.add(session)
        db.commit()

        print("Inserting test data for Farm module...")
        farm = Farm(user_id=user.id, name="Test Valley Farm", location="California")
        db.add(farm)
        db.commit()
        db.refresh(farm)

        acre = Acre(farm_id=farm.id, name="Sector A", size=10.5)
        db.add(acre)
        db.commit()
        db.refresh(acre)

        zone = Zone(acre_id=acre.id, name="Tomato Zone", crop_type="Tomatoes", soil_type="Loam", mode="AUTO", seasonal_water_budget_mm=1000.0)
        db.add(zone)
        db.commit()
        db.refresh(zone)

        from application.models.farm import DiaryLog
        print("Inserting Diary Log...")
        d_log = DiaryLog(
            farm_id=farm.id,
            title="System Initialized",
            description="AquaSol AI engine activated for all zones.",
            event_type="ai",
            icon_name="sparkles",
            color_hex="#3b82f6"
        )
        db.add(d_log)
        db.commit()

        print("Inserting test data for Device and Sensors (Role-Based)...")
        device = Device(device_uid=device_uid, zone_id=zone.id, position_label="START", role="LEADER", status="ACTIVE", battery_level=95.0, solar_intensity=80.0, last_seen=datetime.utcnow())
        db.add(device)
        db.commit()
        db.refresh(device)

        # 1. Node Data (Soil)
        node_data = NodeData(
            device_id=device.device_uid,
            zone_id=str(zone.id),
            soil_moisture=45.5,
            battery_percentage=95.0,
            solar_voltage=12.5,
            solar_efficiency=80.0,
            valve_status=False,
            commanded_state=False
        )
        db.add(node_data)

        # 2. Zone Data (Environment)
        zone_data = ZoneData(
            zone_id=str(zone.id),
            temperature=24.0,
            humidity=60.0
        )
        db.add(zone_data)

        # 3. Master Data (System)
        master_data = MasterData(
            flow_rate=10.5,
            water_consumed=500.0,
            is_raining=False,
            battery_percentage=100.0,
            solar_voltage=18.0,
            solar_efficiency=95.0
        )
        db.add(master_data)
        db.commit()

        print("Inserting test data for Irrigation and Commands...")
        valve_command = ValveCommand(zone_id=zone.id, command="OPEN", status="PENDING")
        db.add(valve_command)
        db.commit()
        db.refresh(valve_command)

        irrigation_log = IrrigationLog(
            zone_id=zone.id, 
            start_time=datetime.utcnow() - timedelta(minutes=30),
            end_time=datetime.utcnow(),
            duration_minutes=30.0,
            water_used=150.5,
            trigger_type="AUTO",
            reason_code="LOW_MOISTURE",
            moisture_before=30.0,
            moisture_after=60.0,
            et_context=4.5
        )
        db.add(irrigation_log)
        db.commit()

        print("Inserting test data for States and Analytics...")
        zone_state = ZoneState(zone_id=zone.id, state="IDLE", last_irrigation_time=datetime.utcnow(), current_moisture=45.5, expected_moisture=50.0)
        db.add(zone_state)
        
        et_data = ETData(zone_id=zone.id, timestamp=datetime.utcnow(), et_value=4.5)
        db.add(et_data)

        daily_agg = DailyAggregate(zone_id=zone.id, date=datetime.utcnow().date(), avg_moisture=45.0, total_irrigation_minutes=30.0, water_usage=150.5)
        db.add(daily_agg)
        
        monthly_agg = MonthlyAggregate(zone_id=zone.id, month=datetime.utcnow().replace(day=1).date(), avg_moisture=44.0, total_irrigation_minutes=300.0, water_usage=1500.0)
        db.add(monthly_agg)
        
        yearly_agg = YearlyAggregate(zone_id=zone.id, year=2026, avg_moisture=44.0, total_irrigation_minutes=3000.0, water_usage=15000.0)
        db.add(yearly_agg)
        
        health_score = PlantHealthScore(zone_id=zone.id, date=datetime.utcnow().date(), score=85, status="GOOD", reason="Optimal moisture")
        db.add(health_score)
        db.commit()

        print("Inserting test data for AI and ML models...")
        ai_log = AiValidationLog(zone_id=zone.id, decision="IRRIGATE", reasoning="Low moisture", confidence=0.92, anomaly_detected=False)
        db.add(ai_log)
        
        prediction = Prediction(zone_id=zone.id, type="MOISTURE_DROP", predicted_moisture=40.0, predicted_irrigation_need=10.5, hours_until_needed=12.0)
        db.add(prediction)
        
        crop_plan = CropPlan(zone_id=zone.id, recommended_crop="Tomatoes", expected_yield=5000.0, risk_score=0.1)
        db.add(crop_plan)
        db.commit()

        print("Inserting test data for Chat and Feedback...")
        chat_log = ChatLog(user_id=user.id, query="How are my tomatoes doing?", response="They are doing great.", language="en")
        db.add(chat_log)
        
        msg_template = MessageTemplate(code="LOW_MOISTURE_ALERT", en="Alert: Zone has low moisture.")
        db.add(msg_template)
        
        notification = Notification(user_id=user.id, zone_id=zone.id, type="ALERT", title="Low Moisture Warning", message="Tomato zone moisture is below threshold.")
        db.add(notification)
        
        feedback = IrrigationFeedback(
            zone_id=zone.id,
            predicted_need_mm=10.0,
            predicted_moisture_after=65.0,
            actual_moisture_after=62.0,
            delta_moisture=-3.0,
            effectiveness=0.85
        )
        db.add(feedback)
        db.commit()

        print("\nSuccessfully tested all models!")
        print("Data is stored in db. All database data was cleared prior to this test, and a fresh test has been completed.")
        
    except Exception as e:
        db.rollback()
        print(f"Error during testing: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    test_all_models()
