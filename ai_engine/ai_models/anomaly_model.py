"""
AnomalyModel — AquaSol Hybrid Hardware Diagnostics
===================================================
THREE-STAGE DETECTION PIPELINE (in order):

  Stage 1: Statistical Detection (StatAnomalyDetector)
    → Z-score outlier + flat-line detection
    → Catches subtle drift invisible to threshold rules
    → Pure numpy. No LLM. Zero hallucination risk.

  Stage 2: Threshold Rule Engine (anomaly.json)  
    → Binary / critical faults (pipe burst, out-of-range)
    → Deterministic. Always correct for defined conditions.

  Stage 3: LLM Expert Diagnosis (Groq / Llama-3.2)
    → ONLY called if Stage 1 or Stage 2 triggered an anomaly
    → Generates a human-readable explanation for the farmer
    → NEVER used for detection. NEVER used for decision-making.

ARCHITECTURAL RULE: LLM output is advisory text only.
"""
import json
import os
import asyncio
from llm.client import GroqClient
from ai_models.stat_anomaly_detector import StatAnomalyDetector


class AnomalyModel:
    def __init__(self, rules_path=None):
        if rules_path is None:
            rules_path = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "anomaly.json"
            )
        self.rules = self._load_rules(rules_path)
        self.groq = GroqClient()
        # Statistical detector — maintains rolling window state across calls
        self.stat_detector = StatAnomalyDetector()

    def _load_rules(self, path):
        try:
            with open(path, "r") as f:
                return json.load(f)
        except Exception as e:
            print(f"[ANOMALY] Error loading rules from {path}: {e}")
            return {}

    # =========================================================================
    # PUBLIC API
    # =========================================================================

    async def detect_anomalies(self, sensor_stream: list, current_state: str = "IDLE") -> list:
        """
        Full 3-stage anomaly detection pipeline.
        Returns a list of anomaly dicts (empty if healthy).
        """
        anomalies = []

        for reading in sensor_stream:
            device_id = str(reading.get("id", "unknown"))

            # ── Stage 1: Statistical Detection ───────────────────────────────
            stat_anomalies = self.stat_detector.check_reading(device_id, reading)

            # ── Stage 2: Threshold Rule Engine ───────────────────────────────
            rule_anomalies = self._check_rules(reading, current_state)

            # ── Merge (deduplicate by type) ───────────────────────────────────
            all_detected = stat_anomalies + [
                {"device_id": device_id, **r} for r in rule_anomalies
            ]

            if not all_detected:
                continue

            # ── Stage 3: LLM Explanation (advisory only) ──────────────────
            # Build a compact summary for the LLM to explain in one sentence
            primary = all_detected[0]
            ai_explanation = await self._get_ai_explanation(reading, all_detected)

            anomalies.append({
                "device_id": device_id,
                "type": primary.get("type", "UNKNOWN"),
                "severity": primary.get("severity", "medium"),
                "source": primary.get("source", "RULE"),
                "ai_diagnosis": ai_explanation,   # Human-readable, advisory only
                "suggested_action": primary.get("action", primary.get("suggested_action", "INSPECT")),
                "all_flags": all_detected,         # Full detail for logging
            })

        # ── Combined cross-sensor conditions ─────────────────────────────────
        combined = self._check_combined_conditions(sensor_stream, current_state)
        anomalies.extend(combined)

        return anomalies

    # =========================================================================
    # STAGE 2: THRESHOLD RULE ENGINE
    # =========================================================================

    def _check_rules(self, reading: dict, current_state: str = "IDLE") -> list:
        triggered = []

        # 1. MOISTURE
        if "moisture" in reading:
            m_rules = self.rules.get("moisture", {})
            val = reading["moisture"]
            oor = m_rules.get("out_of_range", {})
            if val < oor.get("threshold_min", 0) or val > oor.get("threshold_max", 100):
                triggered.append({"type": "MOISTURE_OUT_OF_RANGE", "source": "RULE", **oor})
            if reading.get("previous_moisture") and (
                reading["previous_moisture"] - val
            ) > m_rules.get("sudden_drop", {}).get("drop_value", 10):
                sd = m_rules.get("sudden_drop", {})
                triggered.append({"type": "MOISTURE_SUDDEN_DROP", "source": "RULE", **sd})

        # 2. FLOW
        if "flow" in reading:
            f_rules = self.rules.get("flow", {})
            val = reading["flow"]
            fth = f_rules.get("flow_too_high", {})
            if val > fth.get("threshold_max", 5.0):
                triggered.append({"type": "FLOW_TOO_HIGH", "source": "RULE", **fth})
            uf = f_rules.get("unexpected_flow_when_idle", {})
            if current_state == "IDLE" and val > uf.get("threshold_min", 0.3):
                triggered.append({"type": "LEAK_DETECTED", "source": "RULE", "severity": "critical", "description": "Flow detected while system is IDLE. Potential pipe burst or valve leak."})
            
            if current_state == "IRRIGATING" and val < 0.05:
                triggered.append({"type": "BLOCKAGE_DETECTED", "source": "RULE", "severity": "high", "description": "Zero flow detected during irrigation. Potential pump failure or pipe blockage."})

        # 3. BATTERY
        if "battery" in reading:
            b_rules = self.rules.get("battery", {})
            val = reading["battery"]
            crit = b_rules.get("critical_low", {})
            if val < crit.get("threshold", 20):
                triggered.append({"type": "BATTERY_CRITICAL", "source": "RULE", **crit})
            elif val < b_rules.get("low_warning", {}).get("threshold", 30):
                triggered.append({"type": "BATTERY_LOW", "source": "RULE",
                                  **b_rules.get("low_warning", {})})

        # 4. TEMPERATURE
        if "temp" in reading:
            t_rules = self.rules.get("temperature", {})
            val = reading["temp"]
            ex_high = t_rules.get("extreme_high", {})
            if val > ex_high.get("threshold", 45):
                triggered.append({"type": "EXTREME_HEAT", "source": "RULE", **ex_high})

        # 5. RAIN during irrigation
        if reading.get("rain", 0) > 0 and current_state == "IRRIGATING":
            rain_rules = self.rules.get("rain", {}).get("rain_during_irrigation", {})
            triggered.append({"type": "RAIN_DURING_IRRIGATION", "source": "RULE", **rain_rules})

        return triggered

    # =========================================================================
    # COMBINED CROSS-SENSOR CONDITIONS
    # =========================================================================

    def _check_combined_conditions(self, sensor_stream: list, current_state: str) -> list:
        """Detect cross-sensor logic (e.g. High Temp + Low Moisture = heat stress)."""
        if not sensor_stream:
            return []

        combined = []
        last = sensor_stream[-1]
        device_id = str(last.get("id", "unknown"))

        rules = self.rules.get("combined_conditions", {}).get(
            "high_temperature_low_moisture", {}
        )
        t_limit = rules.get("temp_threshold", 38)
        m_limit = rules.get("moisture_threshold", 20)

        if last.get("temp", 0) > t_limit and last.get("moisture", 100) < m_limit:
            combined.append({
                "device_id": device_id,
                "type": "HIGH_STRESS_CONDITION",
                "severity": rules.get("severity", "critical"),
                "source": "COMBINED_RULE",
                "ai_diagnosis": (
                    f"[{rules.get('alert_code', 'CC002')}] "
                    f"{rules.get('description', 'Heat + drought stress detected.')} "
                    f"Temp={last.get('temp')}°C, Moisture={last.get('moisture')}%."
                ),
                "suggested_action": rules.get("action", "EMERGENCY_IRRIGATION"),
                "all_flags": [],
            })

        return combined

    # =========================================================================
    # STAGE 3: LLM EXPLANATION (Advisory Only)
    # =========================================================================

    async def _get_ai_explanation(self, reading: dict, detected_anomalies: list) -> str:
        """
        Generates a human-readable 1-sentence diagnosis for the farmer's dashboard.
        This is ADVISORY ONLY — it does not affect the detection result.

        Falls back to a deterministic message if Groq is unavailable.
        """
        # Build a minimal context for the LLM
        anomaly_summary = [
            {
                "type": a.get("type"),
                "description": a.get("description", a.get("type")),
                "recommended_steps": a.get("recommended_steps", [])[:2],
            }
            for a in detected_anomalies[:3]  # Limit to top 3
        ]

        prompt = [
            {
                "role": "system",
                "content": (
                    "You are AquaSol's hardware diagnostician. "
                    "Write ONE concise sentence telling the farmer what is likely wrong "
                    "and what the most important action is. Do not list options. Be direct."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Sensor reading: {json.dumps(reading)}\n"
                    f"Detected anomalies: {json.dumps(anomaly_summary)}"
                ),
            },
        ]

        try:
            return await self.groq.get_completion(prompt)
        except Exception:
            # Deterministic fallback — never fails
            primary = detected_anomalies[0] if detected_anomalies else {}
            code = primary.get("alert_code", "ERR")
            desc = primary.get("description", primary.get("type", "Sensor anomaly detected"))
            return f"[{code}] {desc} — Please inspect the hardware and follow recommended steps."
