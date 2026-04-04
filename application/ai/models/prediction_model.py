import os
import json
import math
from application.ai.specialists.client import GroqClient
from application.core.database import SessionLocal
from application.models.feedback import IrrigationFeedback
from application.ai.models.seasonal_optimizer import SeasonalOptimizer
from application.ai.models.temporal_engine import TemporalEngine

class PredictionModel:
    def __init__(self, crop_type="default"):
        self.groq = GroqClient()
        self.seasonal_opt = SeasonalOptimizer()
        self.temporal_eng = TemporalEngine()
        self.crop_type = crop_type
        self.crop_config = self._load_crop_config()

    def _load_crop_config(self) -> dict:
        config_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "crop_config.json"
        )
        try:
            with open(config_path, "r") as f:
                return json.load(f)
        except Exception:
            return {"default": {"Kc_mid": 1.0, "root_depth": 0.6, "depletion_fraction": 0.5}}

    # =========================================================================
    # STEP 1: ET0 — Reference Evapotranspiration
    # =========================================================================

    def calculate_et0(self, temp: float, humidity: float, wind_speed: float = 2.0) -> float:
        """
        Hargreaves-Samani simplified FAO-56 approximation.
        Returns ET0 in mm/day.

        Assumptions for mid-latitude India (15°–30° N):
          - Ra (extraterrestrial radiation) ≈ 25 MJ/m²/day average
          - Daily temp range approximated as ±5°C from mean
        """
        t_max = temp + 5.0
        t_min = temp - 5.0
        ra = 25.0  # MJ/m²/day — representative for Peninsular India

        # Hargreaves: ET0 = 0.0023 × (Tavg + 17.8) × √(Tmax − Tmin) × Ra
        et0 = 0.0023 * (temp + 17.8) * math.sqrt(max(t_max - t_min, 0.1)) * (ra / 2.45)

        # Humidity adjustment (high humidity suppresses, low humidity amplifies ET)
        if humidity > 70:
            et0 *= 0.85
        elif humidity < 30:
            et0 *= 1.15

        # Wind adjustment (high wind increases ET at crop surface)
        if wind_speed > 5.0:
            et0 *= 1.10

        return round(et0, 3)

    # =========================================================================
    # STEP 2: ETc — Crop Evapotranspiration
    # =========================================================================

    def _get_kc_adjustment(self, zone_id: str) -> float:
        """
        Learning Loop v4 (Elite): 
        Uses Exponentially Weighted Moving Average (EWMA) with alpha=0.2.
        Records with actual_moisture_after = -1.0 are skipped (Disturbance Rejection).
        Returns: A multiplier clamped between 0.8 and 1.2.
        """
        if not zone_id: return 1.0
        db = SessionLocal()
        alpha = 0.2 # Smoothing Factor (Elite Grade)
        
        try:
            # Query the last 5 relevant feedback events
            recent = (
                db.query(IrrigationFeedback)
                .filter(IrrigationFeedback.zone_id == zone_id)
                .filter(IrrigationFeedback.delta_moisture != None)
                .filter(IrrigationFeedback.actual_moisture_after > 0) # Skip -1.0 (Rain/Anomaly)
                .order_by(IrrigationFeedback.created_at.asc()) # Compute from oldest to newest
                .limit(5)
                .all()
            )
            
            if not recent: return 1.0
            
            # Apply EWMA calculation
            calibrated_multiplier = 1.0
            for record in recent:
                # 1% error ≈ 2% Kc shift
                current_raw_adj = 1.0 + (record.delta_moisture / 50.0)
                calibrated_multiplier = (calibrated_multiplier * (1 - alpha)) + (current_raw_adj * alpha)
            
            # Phase 1: Hard Clamping (±20% Safety Bound)
            final_adj = max(0.8, min(1.2, calibrated_multiplier))
            print(f"[PREDICTION] Zone {zone_id} Calibration: {final_adj:.4f} (EWMA)")
            return final_adj
        except Exception as e:
            print(f"[PREDICTION] Calibration Error: {e}")
            return 1.0
        finally:
            db.close()

    def _compute_etc(self, et0: float, kc: float) -> float:
        """
        FAO-56: ETc = ET0 × Kc
        Kc here is the CALIBRATED Kc (Standard Kc * Feedback Adjustment).
        """
        return round(et0 * kc, 3)

    # =========================================================================
    # STEP 3: Decision — VALVE_ON vs IDLE (Pure Math)
    # =========================================================================

    def _make_decision(
        self,
        current_moisture: float,
        etc_mm: float,
        stage_ctx: dict,
        weather: dict,
        projected_moisture: float = None,
        trend: str = "STABLE"
    ) -> dict:
        """
        Deterministic irrigation decision.
        Refined v6: Pre-emptive logic based on temporal projection.

        Rules (in priority order):
          1. If soil moisture ≤ stage moisture_min → irrigate (moisture deficit)
          2. If ETc > 5mm/day → pre-emptive irrigation (high evaporation day)
          3. If forecast rain > 5mm → stay IDLE
          4. Otherwise → IDLE
        """
        moisture_min = stage_ctx.get("moisture_min", 40.0)
        forecast_rain = weather.get("rain_mm", 0.0)

        reasons = []
        action = "IDLE"
        deficit = 0.0

        # Priority 0: Daily Water Budget Check
        water_used_today = weather.get("water_used_today", 0.0)
        daily_limit = stage_ctx.get("daily_water_limit", 1000.0) # 1000L default
        
        if water_used_today >= daily_limit:
            reasons.append(f"Daily water budget ({daily_limit}L) reached. Current usage: {water_used_today}L. Skipping irrigation.")
            return {
                "action": "IDLE",
                "duration_mm": 0.0,
                "reasons": reasons,
                "moisture_deficit": max(0.0, moisture_min - current_moisture),
            }

        # Priority 1: Rain forecast blocks irrigation
        if forecast_rain > 5.0:
            reasons.append(f"Rain forecast {forecast_rain:.1f}mm — holding irrigation.")
            return {
                "action": "IDLE",
                "duration_mm": 0.0,
                "reasons": reasons,
                "moisture_deficit": max(0.0, moisture_min - current_moisture),
            }

        # Priority 2: Pre-emptive check (v6 Temporal Projection)
        elif projected_moisture and projected_moisture < moisture_min:
            action = "VALVE_ON"
            reasons.append(
                f"Trend: {trend}. Projected moisture {projected_moisture:.1f}% in 4h "
                f"below stage min {moisture_min:.1f}%. Pre-empting irrigation."
            )

        # Priority 3: Moisture deficit
        elif moisture_min - current_moisture > 0:
            deficit = moisture_min - current_moisture
            action = "VALVE_ON"
            reasons.append(
                f"Moisture {current_moisture:.1f}% below stage min {moisture_min:.1f}% "
                f"(deficit={deficit:.1f}%)."
            )

        # Priority 3: High-ETc day (pre-emptive)
        elif etc_mm > 5.0:
            action = "VALVE_ON"
            reasons.append(
                f"High ETc day ({etc_mm:.2f}mm) — pre-emptive irrigation to prevent deficit."
            )
        else:
            reasons.append("Moisture adequate and ETc within normal range.")

        # Hours until moisture reaches critical level (if not irrigating)
        hours_until_needed = 0.0
        if action == "IDLE" and etc_mm > 0:
            daily_drop_pct = etc_mm * 2  # rough: 1mm ETc ≈ 2% moisture drop/day
            hours_until_crit = ((current_moisture - moisture_min) / daily_drop_pct) * 24
            hours_until_needed = round(max(0.0, hours_until_crit), 1)

        return {
            "action": action,
            "duration_mm": round(etc_mm, 2) if action == "VALVE_ON" else 0.0,
            "hours_until_needed": hours_until_needed,
            "moisture_deficit": round(max(0.0, deficit), 2),
            "reasons": reasons,
        }

    # =========================================================================
    # PUBLIC API
    # =========================================================================

    async def predict_tomorrow_irrigation(
        self,
        historical_data: list,
        weather_forecast: dict,
        stage_context,
        zone_id: str = None,
        sensor_trust: float = 1.0,
    ) -> dict:
        """
        Main prediction entry point.
        v4 Elite: Probabilistic Decision Handling.
        Uses sensor_trust to weight physical sensors vs. theoretical physics predictions.
        """
        if not historical_data:
            return {"status": "INSUFFICIENT_DATA"}

        last_reading = historical_data[-1]
        raw_moisture = float(last_reading.get("moisture", 50.0))
        
        # ── Step 0: Uncertainty Handling (v4 Weighting) ──────────────────
        # If we don't trust the sensor (noise/anomaly), we blend with the 
        # last predicted moisture to stay within physics-based bounds.
        # 'predicted_prev' is the moisture we expected at this timestamp.
        theoretical_moisture = float(last_reading.get("predicted_prev", raw_moisture))
        current_moisture = (raw_moisture * sensor_trust) + (theoretical_moisture * (1 - sensor_trust))
        
        # ── Step 0.1: Temporal Feature Extraction (v6 Intelligence) ────
        # Extract drying rate (%/hr), trend (STABLE|RAPID_DROP), and stability.
        temporal = self.temporal_eng.extract_features(historical_data)
        drift = self.temporal_eng.calculate_drift(historical_data)
        
        # 4-Hour Prediction Curve (Pre-emptive)
        projected_4h_moisture = current_moisture - (temporal.get("drying_rate", 0.0) * 4)
        
        print(f"[PREDICTION] Zone {zone_id} Probabilistic: {current_moisture:.2f}% | Drift: {drift['drift_pct']}% | Trend: {temporal['trend']}")

        temp = float(weather_forecast.get("temp", 25.0))
        humidity = float(weather_forecast.get("humidity", 60.0))
        wind_speed = float(weather_forecast.get("wind_speed", 2.0))

        # ── Step 1: ET0 ─────────────────────────────────────────────────────
        et0 = self.calculate_et0(temp, humidity, wind_speed)

        # ── Normalise stage_context (new dict OR legacy string) ──────────────
        if isinstance(stage_context, dict):
            kc = float(stage_context.get("kc", 1.0))
            stage_str = stage_context.get("stage", "Unknown")
            moisture_min = float(stage_context.get("moisture_min", 40.0))
            stage_ctx = stage_context
        else:
            # Legacy str passed — extract Kc if present, else use 1.0
            import re
            kc_match = re.search(r"Kc[=:\s]+([\d.]+)", str(stage_context))
            kc = float(kc_match.group(1)) if kc_match else 1.0
            stage_str = str(stage_context)[:80]
            stage_ctx = {"stage": stage_str, "kc": kc, "moisture_min": 40.0}

        # ── Step 1.1: Learning Loop Calibration (v3) ────────────────────────
        adjustment = self._get_kc_adjustment(zone_id)
        calibrated_kc = kc * adjustment

        # ── Step 1.2: Seasonal Strategy (v5 Optimizer) ──────────────
        strategy = self.seasonal_opt.get_strategy_adjustment(zone_id, stage_ctx)
        
        # Apply Deficit Irrigation Multiplier to Target Moisture
        original_min = stage_ctx.get("moisture_min", 40.0)
        stage_ctx["moisture_min"] = original_min * strategy.get("multiplier", 1.0)
        
        if strategy.get("multiplier", 1.0) < 1.0:
            print(f"[PREDICTION] v5 Strategic Refinement: Moisture target {original_min}% -> {stage_ctx['moisture_min']}%")

        # ── Step 2: ETc ─────────────────────────────────────────────────────
        etc = self._compute_etc(et0, calibrated_kc)

        # ── Step 3: Decision (deterministic, sync) ────────────────────────
        # v6 refinement: Pass projected moisture and trend to the decision engine.
        decision = self._make_decision(
            current_moisture, 
            etc, 
            stage_ctx, 
            weather_forecast,
            projected_moisture=projected_4h_moisture,
            trend=temporal["trend"]
        )

        # ── Step 4: LLM Reasoning (advisory text, async) ─────────────────
        reasoning = await self._generate_reasoning(
            current_moisture, et0, etc, calibrated_kc, stage_str, decision, weather_forecast, sensor_trust, strategy, temporal
        )

        return {
            "predicted_moisture": round(current_moisture - (etc / 10), 2),
            "predicted_irrigation_need": decision["duration_mm"],
            "hours_until_needed": decision["hours_until_needed"],
            "tomorrow_mm_needed": etc,
            "et0": et0,
            "etc": etc,
            "kc_used": kc,
            "stage_context": stage_str,
            "ai_reasoning": reasoning,         # Advisory text — not the decision
            "decision_reasons": decision["reasons"],  # Deterministic reasons
            "backend_action": decision["action"],
            "is_virtual_sensing_active": last_reading.get("is_virtual", False),
            "sensor_trust_score": sensor_trust,
            "seasonal_strategy": strategy.get("reason", "Standard Strategy"),
            "temporal_trend": temporal["trend"],
            "drying_rate": temporal["drying_rate"],
            "drift_status": drift["status"],
            "status": "PROCESS_COMPLETE",
        }

    # =========================================================================
    # STEP 4: LLM Reasoning (Advisory Only)
    # =========================================================================

    async def _generate_reasoning(
        self,
        moisture: float,
        et0: float,
        etc: float,
        kc: float,
        stage: str,
        decision: dict,
        weather: dict,
        trust: float = 1.0,
        strategy: dict = {},
        temporal: dict = {}
    ) -> str:
        """
        Generates a plain-English explanation of why the system made its decision.
        DOES NOT affect the decision. Called after _make_decision() returns.
        """
        prompt = [
            {
                "role": "system",
                "content": (
                    "You are AquaSol's agronomist AI. In 1-2 sentences, explain the irrigation "
                    "decision to a farmer in simple language. You CANNOT change the decision. "
                    "Just explain it clearly."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Crop Stage: {stage} (Sensitivity: {strategy.get('sensitivity', 0.5)})\n"
                    f"Soil Moisture (Blended): {moisture:.1f}% | Sensor Trust: {trust:.2f}\n"
                    f"Temporal Signal: {temporal.get('trend', 'STABLE')} (Drying: {temporal.get('drying_rate', 0.0)}%/hr)\n"
                    f"ET0: {et0:.2f}mm | ETc: {etc:.2f}mm | Kc: {kc:.2f}\n"
                    f"Seasonal Goal: {strategy.get('reason', 'None')}\n"
                    f"Weather: {json.dumps(weather)}\n"
                    f"Decision: {decision['action']} | Reasons: {decision['reasons']}"
                ),
            },
        ]
        try:
            return await self.groq.get_completion(prompt)
        except Exception:
            return (
                f"Decision based on FAO-56 ETc={etc:.2f}mm, "
                f"soil moisture={moisture:.1f}%, "
                f"crop stage={stage}."
            )
