import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from application.core.database import Base

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    zone_id = Column(UUID(as_uuid=True), ForeignKey("zones.id"), nullable=True)

    type = Column(String(20))  # ALERT | CRITICAL | INFO | RECOMMENDATION
    title = Column(String(200))
    message = Column(String(1000))

    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
