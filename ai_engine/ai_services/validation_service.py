import sys
import os

# Allow importing from the ai_engine root
AI_ENGINE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)

from ai_models.validation_model import ValidationModel

class ValidationService:
    """
    Audit Intelligence Service.
    Wraps the Llama-3.2-3B model on Groq for second-opinion checks.
    """
    
    def __init__(self):
        # Uses GroqClient with llama-3.2-3b-preview
        self.model = ValidationModel()

    async def get_second_opinion(
        self, 
        backend_decision: str, 
        sensor_data: dict, 
        weather_data: dict, 
        etc_mm: float = 0.0,
        drift_pct: float = 0.0
    ) -> dict:
        """
        Runs Deterministic Audit (v6 Temporal Awareness):
        1. Checks a hardware decision against safety rules + model-sensor drift.
        2. Generates an LLM-based explanation separately.
        """
        try:
            # Step 1: Physical Validation (Deterministic)
            validation = self.model.validate_decision(backend_decision, sensor_data, weather_data, etc_mm, drift_pct)
            
            # Step 2: Explanation (Advisory LLM - non-critical)
            explanation = await self.model.get_explanation(
                backend_decision, sensor_data, weather_data, validation.get("violations", [])
            )
            
            validation["ai_verification"] = explanation
            return validation
            
        except Exception as e:
            print(f"[VALIDATION-SERVICE] Logic Error: {e}")
            return {"valid": True, "ai_verification": "Validation error. Safety bypass active.", "action": "APPROVE"}
