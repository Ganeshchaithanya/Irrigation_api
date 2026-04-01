import sys
import os

# Allow importing from the ai_engine root
AI_ENGINE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)

from ai_models.anomaly_model import AnomalyModel

class AnomalyService:
    """
    Diagnostic Intelligence Service.
    Wraps the rule-engine + Llama-3.2-3B on Groq for hardware health checks.
    """
    
    def __init__(self, rules_path=None):
        # Uses anomaly.json and GroqClient with llama-3.2-3b-preview
        self.model = AnomalyModel(rules_path=rules_path)

    async def get_trust_score(self, sensor_history: list) -> float:
        """
        Probabilistic Trust Model (v4):
        Calculates how much the AI should trust the live sensor data.
        Factors: Variance (Noise) and recent Anomaly flags.
        """
        if len(sensor_history) < 3: return 0.5 # Low trust for sparse data
        
        try:
            # 1. Variance Check (High noise = Low trust)
            moistures = [float(r.get('moisture', 50)) for r in sensor_history[-5:]]
            variance = max(moistures) - min(moistures)
            noise_penalty = min(0.4, variance / 20.0) # Penalty up to 0.4
            
            # 2. Anomaly Check
            anomalies = await self.model.detect_anomalies(sensor_history, "IDLE")
            anomaly_penalty = 0.5 if anomalies else 0.0
            
            trust = 1.0 - noise_penalty - anomaly_penalty
            return max(0.2, min(1.0, trust))
        except:
            return 0.5
