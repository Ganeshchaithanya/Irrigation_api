import asyncio
import sys
import os
import httpx
from sqlalchemy.orm import Session
from models.sensor import SensorData
from models.device import Device
from models.command import ValveCommand
from models.state import ZoneState
from services import irrigation_service, state_service

# Allow importing from the ai_engine directory
AI_ENGINE_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "ai_engine")
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)


class DecisionService:
    """
    The critical bridge between IoT sensor data and the AI Engine.
    
    Two responsibilities:
    1. evaluate_device_trigger() — called when a sensor POSTs data:
       - Gathers sensor history → calls AIService → creates ValveCommands + IrrigationLogs + Notifications.
    2. evaluate_prediction() — called by the AI route when a prediction is POSTed:
       - Maps mm of water needed → VALVE_ON duration minutes.
    """
    
    # mm of ETc → minutes of valve open time (1mm = 5 minutes, based on standard drip flow)
    MM_TO_MINUTES = 5
    MAX_IRRIGATION_MINUTES = 120  # Safety cap: never irrigate more than 2 hours at once

    def evaluate_prediction(self, predicted_need_mm: float, zone_id: str) -> dict:
        """Maps AI predicted irrigation need in mm to a hardware duration decision."""
        if predicted_need_mm <= 0:
            return {
                "action": "IDLE",
                "duration_minutes": 0,
                "reason": "AI Prediction indicates 0 irrigation requirement."
            }
        duration = min(int(predicted_need_mm * self.MM_TO_MINUTES), self.MAX_IRRIGATION_MINUTES)
        return {
            "action": "VALVE_ON",
            "duration_minutes": duration,
            "reason": f"AI Prediction: {predicted_need_mm:.2f}mm needed → {duration} mins at standard drip rate."
        }

    def evaluate_device_trigger(self, db: Session, device_id):
        """
        Called every time a sensor data packet arrives.
        Runs the full AI pipeline asynchronously (non-blocking via thread).
        """
        try:
            asyncio.create_task(self._run_ai_pipeline(db, device_id))
        except RuntimeError:
            # Fallback: if no event loop, run directly (e.g. in tests)
            loop = asyncio.new_event_loop()
            loop.run_until_complete(self._run_ai_pipeline(db, device_id))

    async def _run_ai_pipeline(self, db: Session, device_id):
        """
        Full AI pipeline:
        1. Load zone context (crop_type, soil, state).
        2. Load last 24 sensor readings as historical data.
        3. Call AIService with this data.
        4. Act on the AI report: create commands, logs, notifications.
        """
        try:
            # 1. Resolve device → zone
            device = db.query(Device).filter(Device.id == device_id).first()
            if not device or not device.zone_id:
                return
            zone_id = device.zone_id

            # 2. Load zone state and metadata
            zone_state = state_service.get_zone_state(db, zone_id)
            current_state = zone_state.state if zone_state else "IDLE"

            # 3. Collect last 24 sensor readings for this device
            readings = (
                db.query(SensorData)
                .filter(SensorData.device_id == device_id)
                .order_by(SensorData.timestamp.desc())
                .limit(24)
                .all()
            )
            if not readings:
                return

            # Format sensor data for AIService
            sensor_stream = []
            for i, r in enumerate(reversed(readings)):  # oldest first
                entry = {
                    "id": str(device_id),
                    "moisture": r.soil_moisture or 50.0,
                    "temp": r.temperature or 25.0,
                    "humidity": r.humidity or 60.0,
                    "flow": r.flow or 0.0,
                    "water_consumed": r.water_consumed or 0.0,
                }
                # Inject previous moisture for sudden-drop detection
                if i > 0:
                    entry["previous_moisture"] = sensor_stream[-1]["moisture"]
                sensor_stream.append(entry)

            # 4. Get Neighbors in the same Zone (for Virtual Sensing / Surrogacy)
            neighbors = []
            zone_devices = db.query(Device).filter(Device.zone_id == zone_id).all()
            for d in zone_devices:
                neighbors.append({
                    "id": str(d.id),
                    "position_label": d.position_label,
                    "status": d.status
                })

            # 5. Call AI Engine via HTTP (microservice pattern)
            payload = {
                "sensor_data": sensor_stream,
                "zone_id": str(zone_id),
                "current_state": current_state,
                "neighbors": neighbors
            }
            
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.post(
                        "http://localhost:8001/ai/run",
                        json=payload,
                        timeout=30.0
                    )
                    if response.status_code != 200:
                        print(f"[DECISION] AI Engine returned {response.status_code}")
                        return
                    report = response.json()
            except Exception as e:
                print(f"[DECISION] AI Engine unreachable: {e}")
                return

            # 5. Act on AI Report
            await self._process_ai_report(db, zone_id, report, sensor_stream[-1])

        except Exception as e:
            print(f"[DECISION] Pipeline error: {e}")

    async def _process_ai_report(self, db: Session, zone_id, report: dict, latest_reading: dict):
        """Creates DB entries based on the AI report."""
        from services.notification_service import NotificationService
        from models.farm import Zone
        
        # Get user_id for notifications via zone → acre → farm
        zone = db.query(Zone).filter(Zone.id == zone_id).join(Zone.acre).join(Zone.acre.property.mapper.class_.farm).first()
        user_id = None
        try:
            from models.farm import Acre, Farm
            acre = db.query(Acre).filter(Acre.id == zone.acre_id).first()
            farm = db.query(Farm).filter(Farm.id == acre.farm_id).first()
            user_id = farm.user_id
        except Exception:
            pass
        
        notif_svc = NotificationService(db)

        # Handle ANOMALIES
        anomalies = report.get("anomalies", [])
        for anomaly in anomalies:
            severity = anomaly.get("severity", "medium")
            alert_type = "CRITICAL" if severity == "critical" else "ALERT"
            notif_svc.create(
                user_id=user_id,
                zone_id=zone_id,
                notif_type=alert_type,
                title=f"⚠️ Hardware Fault: {anomaly.get('type', 'UNKNOWN')}",
                message=anomaly.get("ai_diagnosis", "Sensor anomaly detected. Please check the hardware.")
            )

        # Handle BACKEND ACTION (irrigation command)
        backend_action = report.get("backend_action", "IDLE")
        if backend_action != "IDLE" and "VALVE_ON" in backend_action:
            # Parse duration from action string e.g. "VALVE_ON for 15 mins"
            try:
                duration = int(backend_action.split("for")[1].split("min")[0].strip())
            except Exception:
                duration = 15  # Default fallback

            # Create valve command
            existing = db.query(ValveCommand).filter(
                ValveCommand.zone_id == zone_id,
                ValveCommand.status == "PENDING",
                ValveCommand.command == "ON"
            ).first()
            if not existing:
                cmd = ValveCommand(
                    zone_id=zone_id,
                    command="ON",
                    duration_minutes=duration,
                    trigger="AI_AUTO",
                    status="PENDING"
                )
                db.add(cmd)
                db.commit()

                # Start irrigation log
                irrigation_service.start_irrigation_session(
                    db, zone_id,
                    trigger_type="AI_AUTO",
                    reason_code=report.get("predictions", {}).get("ai_reasoning", ""),
                    moisture_before=latest_reading.get("moisture"),
                    et_context=report.get("predictions", {}).get("etc")
                )

                # Update prediction entry with new temporal fields
                from models.ai import Prediction
                pred_data = report.get("predictions", {})
                new_pred = Prediction(
                    zone_id=zone_id,
                    type="DAILY_INTELLIGENCE",
                    predicted_moisture=pred_data.get("predicted_moisture", 0.0),
                    predicted_irrigation_need=pred_data.get("predicted_irrigation_need", 0.0),
                    hours_until_needed=pred_data.get("hours_until_needed"),
                    tomorrow_mm_needed=pred_data.get("tomorrow_mm_needed"),
                    is_virtual_sensing_active=pred_data.get("is_virtual_sensing_active", False),
                    stage_context=pred_data.get("stage_context", ""),
                    recommendation_text=pred_data.get("ai_reasoning", ""),
                    prediction_time=datetime.utcnow()
                )
                db.add(new_pred)
                db.commit()

                # Update zone state
                state_service.update_zone_state(db, zone_id, "IRRIGATING", moisture=latest_reading.get("moisture"))

                notif_svc.create(
                    user_id=user_id,
                    zone_id=zone_id,
                    notif_type="INFO",
                    title="💧 Irrigation Started",
                    message=f"AI triggered irrigation for {duration} minutes based on ETc calculation."
                )
        
        # Handle VALIDATION log
        validation = report.get("validation", {})
        if validation:
            from models.ai import AiValidationLog
            log = AiValidationLog(
                zone_id=zone_id,
                decision=backend_action,
                reasoning=str(report.get("predictions", {}).get("ai_reasoning", validation.get("reasoning", ""))),
                confidence=float(validation.get("confidence", 0.9)),
                risk_level=str(validation.get("risk_level", "LOW")),
                anomaly_detected=len(anomalies) > 0
            )
            db.add(log)
            db.commit()
