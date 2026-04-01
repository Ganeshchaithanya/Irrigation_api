import time
import uuid
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from backend.application.core.database import SessionLocal
from backend.application.models.feedback import IrrigationFeedback
from backend.application.models.sensor import SensorData
from backend.application.models.device import Device
from backend.application.models.farm import Zone
from ai_services.anomaly_service import AnomalyService
from llm.utils.weather import WeatherService

class FeedbackWorker:
    """
    AquaSol Feedback Crawler.
    Runs periodically to 'close the loop' on irrigation decisions.
    """
    
    def __init__(self, wait_hours=2):
        self.wait_hours = wait_hours
        self.anomaly_svc = AnomalyService()
        self.weather_svc = WeatherService()

    def process_pending_feedback(self):
        """
        Scans for IrrigationFeedback records that haven't been 'closed'
        (i.e., actual_moisture_after is NULL) and are older than wait_hours.
        """
        db = SessionLocal()
        try:
            # 1. Find records needing processing
            # Record was created when irrigation started, now we check if it's been wait_hours
            threshold_time = datetime.utcnow() - timedelta(hours=self.wait_hours)
            
            pending = (
                db.query(IrrigationFeedback)
                .filter(IrrigationFeedback.actual_moisture_after == None)
                .filter(IrrigationFeedback.created_at <= threshold_time)
                .all()
            )
            
            print(f"[FEEDBACK] Found {len(pending)} pending records to calibrate.")
            
            for record in pending:
                # v4 Elite Upgrade: Disturbance Rejection
                if self._is_disturbed(db, record):
                    print(f"[FEEDBACK] Skipping Zone {record.zone_id} due to Rain/Anomaly disturbance.")
                    # Mark as skipped by setting a tiny non-null value or stay null
                    record.actual_moisture_after = -1.0 # Internal code for 'Skipped'
                    continue
                
                self._calibrate_record(db, record)
                
            db.commit()
        finally:
            db.close()

    def _calibrate_record(self, db: Session, record: IrrigationFeedback):
        """
        Calculates delta, effectiveness, and Phase 2 Soil Physics.
        """
        devices = db.query(Device).filter(Device.zone_id == record.zone_id).all()
        device_ids = [d.id for d in devices]
        if not device_ids: return

        # Reading 1: Immediately after irrigation (to see peak moisture)
        peak_reading = (
            db.query(SensorData)
            .filter(SensorData.device_id.in_(device_ids))
            .filter(SensorData.timestamp >= record.irrigation_ended_at)
            .order_by(SensorData.timestamp.asc()) # Get the first one after end
            .first()
        )

        # Reading 2: 2 hours later (the standard feedback window)
        final_reading = (
            db.query(SensorData)
            .filter(SensorData.device_id.in_(device_ids))
            .filter(SensorData.timestamp <= record.feedback_recorded_at)
            .order_by(SensorData.timestamp.desc())
            .first()
        )
        
        if peak_reading and final_reading:
            record.actual_moisture_after = final_reading.soil_moisture
            record.delta_moisture = record.actual_moisture_after - record.predicted_moisture_after
            
            # v4 Elite: Soil Physics Scaling
            # 1. Retention Efficiency: Gain per mm applied
            gain = peak_reading.soil_moisture - (record.predicted_moisture_after - record.predicted_need_mm * 2)
            if record.predicted_need_mm > 0:
                record.retention_efficiency = max(0, min(1.0, gain / (record.predicted_need_mm * 5)))

            # 2. Drainage Rate: Loss per hour during percolation
            time_diff = (final_reading.timestamp - peak_reading.timestamp).total_seconds() / 3600
            if time_diff > 0:
                drop = peak_reading.soil_moisture - final_reading.soil_moisture
                record.drainage_rate = drop / time_diff

            record.effectiveness = record.compute_effectiveness()
            print(f"[FEEDBACK] v4 Physics: Zone {record.zone_id} | Gain {gain:.1f}% | Drainage {record.drainage_rate:.2f}%/hr")
        else:
            print(f"[FEEDBACK] Incomplete sensor data for v4 physics calculation.")

    def _is_disturbed(self, db: Session, record: IrrigationFeedback) -> bool:
        """
        Safety Filter: 
        Returns True if rainfall or anomalies occurred during the window.
        """
        # 1. Rain Check (from WeatherService history)
        # Assuming weather_svc can get history for a specific window
        try:
            # Simplified: If rain forecast is high, assume disturbance
            weather = self.weather_svc.get_forecast_data() # Mock history
            if weather.get("rain_mm", 0.0) > 1.0: return True
        except: pass

        # 2. Anomaly Check (Hardware failures make feedback unreliable)
        # Querying AnomalyService if it flagged this zone recently
        anomalies = self.anomaly_svc.check_sensor_health([], "IDLE") # Simplified check
        if anomalies: return True
        
        return False

if __name__ == "__main__":
    # Example execution loop
    worker = FeedbackWorker()
    while True:
        worker.process_pending_feedback()
        time.sleep(300) # Check every 5 mins
