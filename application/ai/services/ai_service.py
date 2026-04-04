import sys
import os
from application.ai.services.stage_service import StageService
from application.ai.specialists.utils.weather import WeatherService
from application.ai.services.prediction_service import PredictionService
from application.ai.services.anomaly_service import AnomalyService
from application.ai.services.validation_service import ValidationService
from application.ai.pipeline.data_pipeline import DataPipeline
from application.ai.models.risk_engine import RiskEngine
from application.ai.models.temporal_engine import TemporalEngine

class AIService:
    """
    High-Level AI Decision Orchestrator.
    
    Refactored to maintain separate services for each model:
    1. StageService (Mistral - Biological context)
    2. PredictionService (FAO-56 - Water need)
    3. AnomalyService (Llama-3.2-3B - Hardware health)
    4. ValidationService (Llama-3.2-3B - Audit)
    5. RiskEngine (Deterministic Biology - Stress alerts)
    """
    
    def __init__(self, crop_type="Tomato"):
        self.pipeline = DataPipeline()
        self.weather = WeatherService()
        self.risk_engine = RiskEngine()
        
        # Sub-services
        self.stage_svc = StageService()
        self.prediction_svc = PredictionService(crop_type=crop_type)
        self.anomaly_svc = AnomalyService()
        self.validation_svc = ValidationService()
        self.temporal_eng = TemporalEngine()

    async def generate_full_report(self, raw_sensor_data, weather_data, zone_id, current_state="IDLE", crop_season="Kharif", day_of_growth=45, neighbors=[]):
        """
        Main Orchestration Pipeline:
        1. Anomaly Detection -> 2. Node Surrogacy (Virtual Sensing) -> 3. Stage -> 4. Prediction
        """
        # Step 1: Detect Hardware Anomalies (Llama-3.2-3B via Groq)
        anomalies = await self.anomaly_svc.check_sensor_health(raw_sensor_data, current_state)
        
        # Step 2: Node Surrogacy / Virtual Sensing (Resilience Layer)
        # If a node is failing, mirror a healthy neighbor
        processed_data = self.pipeline.apply_surrogacy(raw_sensor_data, anomalies, neighbors)
        latest_sensor = processed_data[-1] if processed_data else {}

        # Step 3: Biological Stage (Mistral - Scientific Protocol)
        stage_context = await self.stage_svc.get_biological_context(
            self.prediction_svc.model.crop_type, 
            day_of_growth, 
            crop_season
        )

        # Step 3: Real Weather Data (AgroMonitoring / Open-Meteo)
        live_weather = await self.weather.get_forecast_data()

        # Step 4: Hardware Health Audit (Llama-3.2-3B via Groq)
        anomalies = await self.anomaly_svc.check_sensor_health(processed_data, current_state)

        # v4 Elite Upgrade: Probabilistic Trust Score
        sensor_trust = await self.anomaly_svc.get_trust_score(processed_data)

        # Step 5: Physics-Based Prediction (FAO-56 + v3 Learning Loop + v4 Uncertainty)
        # Decision is deterministic; LLM generates reasoning asynchronously
        predictions = await self.prediction_svc.get_forecast(
            processed_data, 
            live_weather, 
            stage_context, 
            zone_id=zone_id,
            sensor_trust=sensor_trust
        )

        # Step 6: Backend Decision Bridge
        backend_decision = predictions.get("backend_action", "IDLE")
        if backend_decision != "IDLE":
            duration_mm = predictions.get("predicted_irrigation_need", 0.0)
            backend_decision_str = f"VALVE_ON for {int(duration_mm * 5)} mins"
        else:
            backend_decision_str = "IDLE"
            
        # v6 Elite Upgrade: Temporal Awareness & Drift Audit
        temporal_analysis = self.temporal_eng.extract_features(processed_data)
        drift = self.temporal_eng.calculate_drift(processed_data)
        drift_pct = drift.get("drift_pct", 0.0)

        # Step 7: Second Opinion Audit (Deterministic Rules + LLM Explanation)
        validation = await self.validation_svc.get_second_opinion(
            backend_decision, 
            latest_sensor, 
            live_weather,
            etc_mm=predictions.get("etc", 0.0),
            drift_pct=drift_pct
        )
        
        # Override decision if validation fails
        if validation["action"] == "OVERRIDE":
            backend_decision_str = "IDLE (Safety Override)"
            backend_decision = "IDLE"

        # Step 7.1: Biological Risk Assessment (New v3 Contextual Engine)
        # Using processed historical data to check for duration of stressors
        risk_assessment = self.risk_engine.calculate_risks(
            self.prediction_svc.model.crop_type,
            stage_context.get("stage_name", "Vegetative"),
            processed_data[::-1] # Pass in reverse chronological order
        )

        # Step 8: Push to Backend
        final_backend_action = await self._push_prediction_to_backend(predictions, zone_id, backend_decision_str)

        return {
            "status": "HEALTHY" if not anomalies else "ANOMALY_DETECTED",
            "anomalies": anomalies,
            "predictions": predictions,
            "backend_action": final_backend_action,
            "validation": validation,
            "stage_context": stage_context,
            "risk_assessment": risk_assessment,
            "temporal_signals": temporal_analysis,
            "drift_audit": drift,
            "notes": "System operating with virtual sensing for missing nodes." if any(r.get('is_virtual') for r in processed_data) else ""
        }

    async def _push_prediction_to_backend(self, pred, zone_id, fallback_action):
        """Bridge to push recommendations to the FastAPI Backend."""
        import httpx
        from datetime import datetime, timedelta
        
        url = "http://localhost:8000/api/v1/ai/predictions"
        payload = {
            "zone_id": str(zone_id),
            "type": "DAILY_FORECAST",
            "predicted_moisture": pred['predicted_moisture'],
            "predicted_irrigation_need": pred['predicted_irrigation_need'],
            "stage_context": pred.get('stage_context', ''),
            "recommendation_text": pred['recommendation_text'],
            "prediction_time": (datetime.utcnow() + timedelta(days=1)).isoformat()
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, json=payload, timeout=5.0)
                if response.status_code == 200:
                    data = response.json()
                    decision_obj = data.get("hardware_decision", {})
                    action = decision_obj.get("action", "IDLE")
                    duration = decision_obj.get("duration_minutes", 0)
                    if action == "IDLE": return action
                    return f"{action} for {duration} mins"
                return fallback_action
        except Exception as e:
            print(f"[AI-ENGINE] Backend Communication Error: {e}")
            return fallback_action
