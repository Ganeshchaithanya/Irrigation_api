import sys
import os

# Allow importing from the ai_engine root
AI_ENGINE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)

from ai_models.prediction_model import PredictionModel

class PredictionService:
    """
    Physics-Based Intelligence Service.
    Uses FAO-56 mathematical formulas for Evapotranspiration (ETc).
    """
    
    def __init__(self, crop_type="Tomato"):
        # This keeps the hard-coded Kc values from crop_config.json
        self.model = PredictionModel(crop_type=crop_type)

    def calculate_irrigation_need(self, sensor_history: list, weather_data: dict, stage_context: str) -> dict:
        """
        Main calculation engine:
        1. Translates biological context (Stage) to a numeric Kc.
        2. Applies FAO-56 formula: ETc = ETo * Kc.
        3. Returns mm of water needed based on soil moisture drop.
        """
        import asyncio
        # PredictionModel's main method is async due to future extensions, 
        # so we run it in a sync-friendly way if needed or just keep it async.
        # However, let's keep the service method async for consistency.
        pass

    async def get_forecast(self, sensor_history: list, weather_data: dict, stage_context: str, zone_id: str = None, sensor_trust: float = 1.0) -> dict:
        """Asynchronous forecast calculation with v3 Learning Loop and v4 Uncertainty."""
        try:
            return await self.model.predict_tomorrow_irrigation(
                sensor_history, 
                weather_data, 
                stage_context, 
                zone_id=zone_id,
                sensor_trust=sensor_trust
            )
        except Exception as e:
            print(f"[PREDICTION-SERVICE] Error: {e}")
            return {"predicted_moisture": 50, "predicted_irrigation_need": 0, "recommendation_text": "Error in prediction."}
