import json
from datetime import datetime, timedelta
from typing import List, Dict

class RiskEngine:
    """
    Biological Contextual Risk Engine.
    Calculates agricultural risks (Heat Stress, Drought, Fungal)
    using physics-based thresholds and crop-specific biology.
    """
    
    # Threshold Mapping from Agronomy Guides
    CROP_THRESHOLDS = {
        "Wheat": {
            "optimal_temp": {"min": 12, "max": 25},
            "critical_moisture": 35, # %
            "critical_stages": ["CRI", "Flowering"]
        },
        "Rice": {
            "optimal_temp": {"min": 22, "max": 32},
            "critical_moisture": 45,
            "critical_stages": ["Panicle Initiation", "Flowering"]
        },
        "Maize": {
            "optimal_temp": {"min": 21, "max": 30},
            "critical_moisture": 30,
            "critical_stages": ["Tasseling", "Silking"]
        }
    }

    def calculate_risks(self, crop: str, stage: str, sensor_history: List[Dict]) -> Dict:
        """
        Main Risk Assessment Logic.
        Returns: {risk_level: 'LOW'|'MED'|'HIGH', flags: List[str], reason: str}
        """
        thresholds = self.CROP_THRESHOLDS.get(crop, self.CROP_THRESHOLDS["Wheat"])
        flags = []
        
        if not sensor_history:
            return {"level": "UNKNOWN", "flags": [], "reason": "No sensor history available."}

        latest = sensor_history[0]
        temp = latest.get("temperature", 0)
        moisture = latest.get("soil_moisture", 100)
        
        # 1. HEAT STRESS (Temp + Stage + Duration)
        is_critical_stage = any(s.lower() in stage.lower() for s in thresholds["critical_stages"])
        temp_max = thresholds["optimal_temp"]["max"]
        
        if temp > temp_max:
            # Check duration of exposure (simplified: if last 3 readings were high)
            high_temp_duration = all(r.get("temperature", 0) > temp_max for r in sensor_history[:3])
            if high_temp_duration:
                severity = "HIGH" if is_critical_stage else "MEDIUM"
                flags.append(f"{severity}_HEAT_STRESS")

        # 2. DROUGHT RISK (Moisture + Stage)
        if moisture < thresholds["critical_moisture"]:
            severity = "HIGH" if is_critical_stage else "MEDIUM"
            flags.append(f"{severity}_DROUGHT_RISK")

        # 3. FUNGAL RISK (Humidity/Temp Pattern)
        # Note: Humidity > 85% is generic fungal trigger.
        humidity = latest.get("humidity", 0)
        if humidity > 85 and temp > 22:
            flags.append("MEDIUM_FUNGAL_RISK")

        # Determine overall level
        level = "LOW"
        if any("HIGH" in f for f in flags): level = "HIGH"
        elif any("MEDIUM" in f for f in flags): level = "MEDIUM"

        return {
            "level": level,
            "flags": flags,
            "reason": self._generate_reason(flags, crop, stage),
            "confidence": 0.95 # Higher confidence due to deterministic rules
        }

    def _generate_reason(self, flags: List[str], crop: str, stage: str) -> str:
        if not flags: return "Farm parameters within biological safety limits."
        return f"Detected {', '.join(flags)} for {crop} at {stage} stage. Immediate investigation recommended."
