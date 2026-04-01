"""
ValidationModel — AquaSol Production-Grade Decision Gate
=========================================================
ARCHITECTURAL DECISION (Non-Negotiable):
  - All APPROVAL/OVERRIDE decisions are 100% deterministic (rule-based).
  - LLM (Groq) is invoked ONLY for generating human-readable explanation text.
  - LLM output NEVER controls hardware. It is purely advisory.
"""
import json
from llm.client import GroqClient


class ValidationModel:
    """
    Hard constraint validation engine. No LLM in the approval loop.
    """

    # --- Thresholds (field-validated, do not change without testing) ---
    RAIN_BLOCK_THRESHOLD_MM: float = 5.0    # Block if recent rainfall > 5mm
    MOISTURE_BLOCK_THRESHOLD: float = 75.0  # Block if soil is already wet
    MIN_ETC_FOR_IRRIGATION: float = 1.0    # Block if ETc demand is trivially small
    TEMP_FROST_THRESHOLD: float = 5.0      # Block if frost risk (temp < 5°C)

    def __init__(self):
        self.groq = GroqClient()

    def validate_decision(
        self,
        backend_decision: str,
        sensor_data: dict,
        weather_data: dict,
        etc_mm: float = 0.0,
        drift_pct: float = 0.0
    ) -> dict:
        """
        Pure deterministic validation gate. Confidence is always 1.0 (rules are exact).

        Returns:
            {
                "valid": bool,
                "action": "APPROVE" | "OVERRIDE",
                "violations": List[str],
                "confidence": float,
            }
        """
        violations = []

        # Rule 1: Block if it's raining or just rained
        rain_mm = weather_data.get("rain_mm", 0.0)
        if rain_mm > self.RAIN_BLOCK_THRESHOLD_MM:
            violations.append(
                f"RAIN_BLOCK: {rain_mm:.1f}mm rain detected — irrigation wasteful."
            )

        # Rule 2: Block if soil is already saturated
        moisture = sensor_data.get("moisture", 50.0)
        if moisture > self.MOISTURE_BLOCK_THRESHOLD:
            violations.append(
                f"WET_SOIL_BLOCK: Soil moisture {moisture:.1f}% exceeds saturation threshold."
            )

        # Rule 3: Block if ETc demand is too small to justify opening the valve
        if backend_decision not in ("IDLE",) and etc_mm < self.MIN_ETC_FOR_IRRIGATION:
            violations.append(
                f"LOW_DEMAND_BLOCK: ETc={etc_mm:.2f}mm is below minimum ({self.MIN_ETC_FOR_IRRIGATION}mm)."
            )

        # Rule 4: Block if frost risk (cold stress — irrigation could worsen frost damage)
        temp = sensor_data.get("temp", weather_data.get("temp", 25.0))
        if temp < self.TEMP_FROST_THRESHOLD:
            violations.append(
                f"FROST_BLOCK: Temperature {temp:.1f}°C below frost threshold — do not irrigate."
            )

        # Rule 5: CONFLICT GUARD (v3 Safety Halt)
        # If the model wants to irrigate but the sensor says it's already wet,
        # we flag this as a 'Model vs Sensor' conflict and block.
        moisture = sensor_data.get("moisture", 50.0)
        if backend_decision != "IDLE" and moisture > 70.0:
            violations.append(
                f"CONFLICT_SHIELD: Model recommends irrigation, but sensor shows high moisture ({moisture:.1f}%). Blocking for safety."
            )

        # Rule 6: DRIFT AUDIT (v6 Temporal Awareness)
        if abs(drift_pct) > 15.0:
            violations.append(
                f"DRIFT_ALERT: Model drift is {drift_pct:.1f}% — calibration recommended."
            )

        approved = len(violations) == 0

        return {
            "valid": approved,
            "action": "APPROVE" if approved else "OVERRIDE",
            "violations": violations,
            "confidence": 1.0,
            "risk_level": "LOW" if approved else "HIGH",
            "conflict_detected": any("CONFLICT_SHIELD" in v for v in violations),
            "drift_detected": abs(drift_pct) > 15.0
        }

    async def get_explanation(
        self,
        decision: str,
        sensor_data: dict,
        weather_data: dict,
        violations: list
    ) -> str:
        """
        Advisory-only LLM call. Generates a human-readable explanation for the dashboard.
        NOT in the approval path. Called asynchronously and non-blocking.
        """
        context = {
            "decision": decision,
            "violations": violations,
            "sensor_snapshot": sensor_data,
            "weather_snapshot": weather_data,
        }
        prompt = [
            {
                "role": "system",
                "content": (
                    "You are AquaSol's AI advisor. Write a single, plain-English sentence "
                    "explaining the irrigation decision to a farmer. Be concise and helpful."
                ),
            },
            {
                "role": "user",
                "content": f"Irrigation outcome: {json.dumps(context)}",
            },
        ]
        try:
            return await self.groq.get_completion(prompt)
        except Exception:
            if violations:
                return f"Irrigation blocked: {'; '.join(violations)}"
            return "Conditions are optimal. Irrigation approved by the AquaSol engine."
