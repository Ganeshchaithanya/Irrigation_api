import sys
import os

# Allow importing from the ai_engine root
AI_ENGINE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)

from llm.stage_awareness_model import StageAwarenessModel

class StageService:
    """
    Biological Intelligence Service.
    Uses the High-Precision Knowledge Resolver to extract scientific growth stages and protocols.
    """
    
    def __init__(self):
        # Local JSON-Based Knowledge Resolver (Kharif/Rabi/Zaid)
        self.model = StageAwarenessModel()

    async def get_biological_context(self, crop_type: str, day_of_growth: int, season: str = "Kharif"):
        """
        Fetches the current growth stage and biological needs.
        Returns a StageContext dict for internal use by PredictionService.
        """
        try:
            # Model method is now deterministic and sync
            return self.model.get_stage_context(crop_type, day_of_growth, season)
        except Exception as e:
            print(f"[STAGE-SERVICE] Error: {e}")
            return {"crop": crop_type, "stage": "Unknown", "kc": 1.0, "moisture_min": 40.0}
