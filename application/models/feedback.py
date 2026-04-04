"""
IrrigationFeedback — AquaSol Feedback Learning Loop
====================================================
Stores the actual soil response after every AI-triggered irrigation event.

PURPOSE:
  Compare predicted_moisture vs actual_moisture (measured ~2h post-irrigation).
  This delta becomes the training signal for:
    1. Kc calibration per zone (adaptive crop coefficient)
    2. ETc accuracy measurement
    3. Future ML-based irrigation optimization

HOW IT GETS POPULATED:
  A background worker (workers/feedback_worker.py) reads the latest sensor data
  from a zone ~2 hours after an irrigation event ends, calculates the delta,
  and writes a FeedbackRecord here.
"""
import uuid
from datetime import datetime
from sqlalchemy import Column, Float, Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from application.core.database import Base


class IrrigationFeedback(Base):
    __tablename__ = "irrigation_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"), nullable=False, index=True)

    # ── What the AI engine predicted ─────────────────────────────────────────
    predicted_need_mm = Column(Float, nullable=False)       # ETc the AI computed
    predicted_moisture_after = Column(Float, nullable=False) # Expected post-irrigation moisture %

    # ── What actually happened (measured ~2h after irrigation ends) ──────────
    actual_moisture_after = Column(Float, nullable=True)    # Real sensor reading post-irrigation
    delta_moisture = Column(Float, nullable=True)           # actual - predicted (negative = overshot)

    # ── Effectiveness Score ──────────────────────────────────────────────────
    # 1.0 = perfect prediction, < 0 = harmful (overwatered), 0.0 = no effect
    effectiveness = Column(Float, nullable=True)

    # ── Context ─────────────────────────────────────────────────────────────
    crop_stage = Column(String(100), nullable=True)         # e.g. "Vegetative Growth"
    kc_used = Column(Float, nullable=True)                  # Kc value applied in the decision
    etc_computed = Column(Float, nullable=True)             # Raw ETc from FAO-56 (mm)
    trigger_type = Column(String(20), nullable=True)        # "AI_AUTO" | "MANUAL"

    # Whether virtual sensing was active during this event
    was_virtual_sensing = Column(Boolean, default=False)

    # ── Phase 2: Soil Physics Parameters (Multi-Parameter Learning) ───────
    # Moisture drop per hour after saturation (%)
    drainage_rate = Column(Float, nullable=True) 
    
    # Efficiency of irrigation (moisture gain / volume applied)
    retention_efficiency = Column(Float, nullable=True) 

    # ── Timestamps ───────────────────────────────────────────────────────────
    irrigation_ended_at = Column(DateTime, nullable=True)
    feedback_recorded_at = Column(DateTime, default=func.now())
    created_at = Column(DateTime, default=func.now())

    def compute_effectiveness(self) -> float:
        """
        Calculate how accurate the prediction was.
        Returns a value from -1.0 (harmful) to 1.0 (perfect).
        """
        if self.actual_moisture_after is None or self.predicted_moisture_after is None:
            return 0.0
        delta = abs(self.actual_moisture_after - self.predicted_moisture_after)
        # Perfect = delta of 0, Harmful = delta > 20%
        return round(max(-1.0, 1.0 - (delta / 20.0)), 3)
