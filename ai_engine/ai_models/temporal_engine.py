import numpy as np
from datetime import datetime

class TemporalEngine:
    """
    The v6 Temporal Feature Extractor.
    Converts raw time-series sensor data into actionable 'Signals'.
    """

    def extract_features(self, history: list) -> dict:
        """
        Calculates temporal signals over the last 24h window.
        
        Signals:
          - drying_rate: % moisture drop per hour.
          - trend: STABLE | DECLINING | RAPID_DROP.
          - stability: Variance-based score (1.0 = Clean, 0.0 = Jittery).
        """
        if len(history) < 3:
            return {"drying_rate": 0.0, "trend": "STABLE", "stability": 1.0}

        try:
            # 1. Stability Check (Standard Deviation of last 5)
            moistures = [float(r.get('moisture', 50.0)) for r in history[-5:]]
            stability = max(0.0, 1.0 - (np.std(moistures) / 10.0))

            # 2. Drying Rate Calculation (Last 3 hours)
            # Assuming readings are every 15-30 mins
            latest = float(history[-1].get('moisture', 50.0))
            prev = float(history[-3].get('moisture', 50.0))
            
            # Simple rate: (p2 - p1) / hours
            # Mocking 1 hour interval for now
            rate = prev - latest # Positive means drying
            
            # 3. Trend Classification
            trend = "STABLE"
            if rate > 4.0: trend = "RAPID_DROP"
            elif rate > 0.5: trend = "DECLINING"
            elif rate < -0.5: trend = "RECOVERING" # e.g. after irrigation

            return {
                "drying_rate": round(rate, 2),
                "trend": trend,
                "stability": round(stability, 2),
                "is_abnormal": rate > 4.0
            }
        except Exception as e:
            print(f"[TEMPORAL-ENGINE] Extraction Error: {e}")
            return {"drying_rate": 0.0, "trend": "STABLE", "stability": 0.5}

    def calculate_drift(self, history: list) -> dict:
        """
        Audit Layer: Compares Physics Model (Theoretical) vs. Live Sensor (Actual).
        High drift indicates a need for recalibration (Kc or Soil Physics).
        """
        if not history: return {"drift_mm": 0.0, "status": "UNKNOWN"}
        
        last = history[-1]
        actual = float(last.get('moisture', 50.0))
        theoretical = float(last.get('predicted_prev', actual))
        
        drift = actual - theoretical
        status = "HEALTHY"
        if abs(drift) > 10.0: status = "CALIBRATION_REQUIRED" # >10% drift
        
        return {
            "drift_pct": round(drift, 2),
            "status": status,
            "error_magnitude": "HIGH" if abs(drift) > 10.0 else "LOW"
        }
