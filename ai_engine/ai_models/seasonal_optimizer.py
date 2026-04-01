import os
import sys
from datetime import datetime
from sqlalchemy import func

# Allow importing from the ai_engine/backend roots
AI_ENGINE_PATH = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(AI_ENGINE_PATH)
if PROJECT_ROOT not in sys.path: sys.path.insert(0, PROJECT_ROOT)

from backend.application.core.database import SessionLocal
from backend.application.models.feedback import IrrigationFeedback
from backend.application.models.farm import Zone

class SeasonalOptimizer:
    """
    The v5 Strategic Decision Layer.
    Evolves per-event control to seasonal yield maximization.
    """

    def get_strategy_adjustment(self, zone_id: str, current_stage: dict) -> dict:
        """
        Calculates the strategic adjustment based on water budget health.
        
        Logic:
          1. Calculate Remaining Budget vs. Expected Future Need.
          2. If scarcity detected AND current stage is low-sensitivity:
             Apply 'Deficit Irrigation' (Target Moisture *= 0.9).
          3. If current stage is CRITICAL (Yield Sensitivity = 1.0):
             Never allow deficit irrigation.
        """
        db = SessionLocal()
        try:
            zone = db.query(Zone).filter(Zone.id == zone_id).first()
            if not zone: return {"multiplier": 1.0, "reason": "Zone not found"}

            # 1. Calculate Cumulative Usage (mm)
            usage_mm = db.query(func.sum(IrrigationFeedback.predicted_need_mm)).filter(
                IrrigationFeedback.zone_id == zone_id,
                IrrigationFeedback.created_at >= zone.sowing_date
            ).scalar() or 0.0

            # 2. Budget Health
            budget_left = zone.seasonal_water_budget_mm - usage_mm
            
            # Simple forecast: Days left in season
            # Assuming average 110 days season for now
            days_grown = (datetime.now() - zone.sowing_date).days
            days_left = max(0, 110 - days_grown)
            
            # 3. Decision Logic (The Seasonal Optimizer)
            sensitivity = current_stage.get("yield_sensitivity", 0.5)
            multiplier = 1.0
            reason = "Budget healthy. Normal irrigation."

            # Scarcity Threshold: If budget < 5mm per day remaining
            if days_left > 0 and (budget_left / days_left) < 4.0:
                # Scarcity detected
                if sensitivity < 0.7:
                    # Low Sensitivity Stage -> Apply Deficit Irrigation (v5 Strategic Stress)
                    multiplier = 0.90 # 10% reduction in moisture trigger
                    reason = f"Water Scarcity Detected ({budget_left:.1f}mm left). Preserving for Critical stages."
                else:
                    reason = "Scarcity ignored: Current stage is CRITICAL for yield."
            
            return {
                "multiplier": multiplier,
                "reason": reason,
                "budget_left_mm": budget_left,
                "sensitivity": sensitivity
            }
        except Exception as e:
            print(f"[SEASONAL-OPTIMIZER] Error: {e}")
            return {"multiplier": 1.0, "reason": "Error calculating seasonal strategy"}
        finally:
            db.close()
