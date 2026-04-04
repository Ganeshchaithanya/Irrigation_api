"""
StatAnomalyDetector — AquaSol Statistical Anomaly Detection Layer
=================================================================
A lightweight, dependency-free statistical engine that detects:
  1. SENSOR_STUCK   — Flat-line readings (zero variance over time)
  2. STATISTICAL_OUTLIER — Z-score deviation from rolling baseline

This runs BEFORE the threshold rule engine and BEFORE any LLM call.
No LLM involved. Pure numpy math.
"""
import numpy as np
from collections import deque
from typing import Optional


class StatAnomalyDetector:
    """
    Maintains a rolling window of sensor history per device per metric.
    Detects subtle drift and outliers that binary threshold rules miss.
    """

    # --- Tuning Constants ---
    ZSCORE_THRESHOLD_HIGH: float = 4.0   # Z > 4.0 → critical outlier
    ZSCORE_THRESHOLD_MED: float = 2.5    # Z > 2.5 → medium outlier
    STUCK_VARIANCE_THRESHOLD: float = 0.01  # σ < 0.01 = sensor is frozen
    MIN_WINDOW_SIZE: int = 6              # Minimum readings needed before scoring
    WINDOW_MAXLEN: int = 24              # Rolling window depth (24 readings ≈ 24h)

    def __init__(self):
        # Keyed by f"{device_id}_{metric}"
        self._windows: dict[str, deque] = {}

    def check(
        self, device_id: str, metric: str, value: float
    ) -> Optional[dict]:
        """
        Feed a new reading into the rolling window and evaluate.

        Returns an anomaly dict if detected, else None.
        """
        key = f"{device_id}_{metric}"
        if key not in self._windows:
            self._windows[key] = deque(maxlen=self.WINDOW_MAXLEN)

        window = self._windows[key]
        window.append(value)

        if len(window) < self.MIN_WINDOW_SIZE:
            return None  # Not enough history yet

        arr = np.array(window)
        mean = float(arr.mean())
        std = float(arr.std())

        # --- Check 1: Sensor Stuck (flat line) ---
        if std < self.STUCK_VARIANCE_THRESHOLD:
            return {
                "type": "SENSOR_STUCK",
                "metric": metric,
                "device_id": device_id,
                "value": value,
                "window_mean": round(mean, 3),
                "window_std": round(std, 4),
                "severity": "medium",
                "source": "STATISTICAL",
                "description": (
                    f"Sensor '{metric}' on device {device_id} has been reading "
                    f"{value:.2f} with near-zero variance for the last {len(window)} readings. "
                    f"Possible probe corrosion or ADC failure."
                ),
                "recommended_steps": [
                    "Clean sensor probe",
                    "Check wiring connections",
                    "Test with multimeter",
                    "Replace sensor if fault persists",
                ],
            }

        # --- Check 2: Z-score Outlier ---
        z_score = abs((value - mean) / std)
        if z_score > self.ZSCORE_THRESHOLD_MED:
            severity = "critical" if z_score > self.ZSCORE_THRESHOLD_HIGH else "high"
            return {
                "type": "STATISTICAL_OUTLIER",
                "metric": metric,
                "device_id": device_id,
                "value": value,
                "z_score": round(z_score, 2),
                "window_mean": round(mean, 2),
                "window_std": round(std, 2),
                "severity": severity,
                "source": "STATISTICAL",
                "description": (
                    f"'{metric}' reading of {value:.2f} is {z_score:.1f} standard deviations "
                    f"from the rolling mean of {mean:.2f}. Possible transient spike or hardware fault."
                ),
                "recommended_steps": [
                    "Cross-check with neighboring sensor",
                    "Verify sensor probe contact",
                    "Inspect wiring for intermittent fault",
                ],
            }

        return None

    def check_reading(self, device_id: str, reading: dict) -> list[dict]:
        """
        Convenience: checks all monitored metrics in a single sensor reading dict.
        Returns a list of any anomalies found.
        """
        METRICS_TO_MONITOR = ["moisture", "temp", "humidity", "flow", "battery"]
        anomalies = []
        for metric in METRICS_TO_MONITOR:
            if metric in reading:
                result = self.check(device_id, metric, float(reading[metric]))
                if result:
                    anomalies.append(result)
        return anomalies

    def reset_device(self, device_id: str):
        """Clear all rolling windows for a specific device (e.g., after replacement)."""
        keys_to_remove = [k for k in self._windows if k.startswith(f"{device_id}_")]
        for key in keys_to_remove:
            del self._windows[key]
