"""
StageAwarenessModel — AquaSol Deterministic Crop Stage Lookup
=============================================================
ARCHITECTURAL DECISION:
  Growth stage is a mathematical function of (days_since_sowing, crop, season).
  It is DETERMINISTIC. An LLM is NOT required and should NOT be used here.

  This module reads from the fine_tune_model JSON guides and returns
  a structured StageContext dict. No network calls. No hallucination risk.
  Zero latency overhead.

  LLM Use: ONLY from the Chat/RAG system when a farmer asks "explain my crop stage"
           in plain language. That call is out-of-pipeline.
"""
import json
import os
from typing import Optional


# Type alias for clarity
StageContext = dict


class StageAwarenessModel:
    """
    Pure JSON lookup table for crop growth stages.
    Resolves: (crop_name, day_of_growth, season) → StageContext
    """

    GUIDE_DIR = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..",
        "fine_tune_model",
        "llama3_model",
    )

    # Fallback Kc values if crop not found in guide
    DEFAULT_KC = 1.0
    DEFAULT_MOISTURE_MIN = 40.0
    DEFAULT_MOISTURE_MAX = 70.0

    def _load_guide(self, season: str) -> dict:
        guide_path = os.path.join(self.GUIDE_DIR, f"{season.lower()}_cropguide.json")
        try:
            with open(guide_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"[STAGE] Guide not found: {guide_path}")
            return {}
        except Exception as e:
            print(f"[STAGE] Guide load error: {e}")
            return {}

    def _find_crop(self, guide: dict, crop_name: str) -> Optional[dict]:
        for crop in guide.get("crops", []):
            if crop.get("crop_name", "").lower() == crop_name.lower():
                return crop
        return None

    def _parse_timing(self, timing_str: str) -> tuple[int, int]:
        """Parse 'Day 36-70' or 'Day 36–70' into (36, 70)."""
        try:
            range_str = (
                timing_str.replace("Day", "")
                .replace("–", "-")
                .replace("—", "-")
                .strip()
                .split("-")
            )
            return int(range_str[0].strip()), int(range_str[1].strip())
        except Exception:
            return 0, 9999  # If unparseable, match all days

    def _default_context(self, crop_name: str, day_of_growth: int) -> StageContext:
        return {
            "crop": crop_name,
            "stage": "Unknown",
            "day": day_of_growth,
            "kc": self.DEFAULT_KC,
            "moisture_min": self.DEFAULT_MOISTURE_MIN,
            "moisture_max": self.DEFAULT_MOISTURE_MAX,
            "yield_sensitivity": 0.5,
            "water_priority": "NORMAL",
            "steps": [],
            "source": "FALLBACK_DEFAULT",
        }

    # -------------------------------------------------------------------------
    # PUBLIC API
    # -------------------------------------------------------------------------

    def get_stage_context(
        self, crop_name: str, day_of_growth: int, season: str = "Kharif"
    ) -> StageContext:
        """
        Main lookup. Returns a structured StageContext dict.
        This is synchronous — no async, no I/O wait, no LLM.

        Returns:
            {
                "crop": str,
                "stage": str,           # e.g. "Vegetative Growth"
                "day": int,
                "kc": float,            # FAO-56 crop coefficient
                "moisture_min": float,  # Soil moisture trigger threshold (%)
                "moisture_max": float,  # Soil moisture upper bound (%)
                "steps": list[str],     # Protocol steps from the guide
                "source": str,          # "LOOKUP_TABLE" | "FALLBACK_DEFAULT"
            }
        """
        guide = self._load_guide(season)
        if not guide:
            return self._default_context(crop_name, day_of_growth)

        crop = self._find_crop(guide, crop_name)
        if not crop:
            print(f"[STAGE] Crop '{crop_name}' not found in {season} guide.")
            return self._default_context(crop_name, day_of_growth)

        farming_guide = crop.get("complete_farming_guide", {})

        for step_key, step_info in farming_guide.items():
            timing = step_info.get("timing", "")
            if "Day" not in timing:
                continue
            start, end = self._parse_timing(timing)
            if start <= day_of_growth <= end:
                return {
                    "crop": crop_name,
                    "stage": step_info.get("title", "Unknown Stage"),
                    "day": day_of_growth,
                    # Pull Kc from guide if present, else use mid-season default
                    "kc": float(step_info.get("kc", self.DEFAULT_KC)),
                    "moisture_min": float(
                        step_info.get("moisture_min", self.DEFAULT_MOISTURE_MIN)
                    ),
                    "moisture_max": float(
                        step_info.get("moisture_max", self.DEFAULT_MOISTURE_MAX)
                    ),
                    "yield_sensitivity": float(step_info.get("yield_sensitivity", 0.5)),
                    "water_priority": step_info.get("water_priority", "NORMAL"),
                    "steps": step_info.get("steps", []),
                    "source": "LOOKUP_TABLE",
                }

        # Day is out of range for all steps — use final stage or default
        print(f"[STAGE] Day {day_of_growth} out of range for crop '{crop_name}'.")
        return self._default_context(crop_name, day_of_growth)

    # Legacy async wrapper — kept for backward compatibility with ai_engine services
    async def get_stage_context_async(
        self, crop_name: str, day_of_growth: int, season: str = "Kharif"
    ) -> str:
        """
        Backward-compatible async wrapper. Returns a condensed string
        for any code that still expects the old string format.
        """
        ctx = self.get_stage_context(crop_name, day_of_growth, season)
        return (
            f"[{ctx['crop']} Day {ctx['day']}] "
            f"Stage: {ctx['stage']} | "
            f"Kc={ctx['kc']} | "
            f"Moisture target: {ctx['moisture_min']}–{ctx['moisture_max']}% "
            f"| Source: {ctx['source']}"
        )
