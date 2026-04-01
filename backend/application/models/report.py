import uuid
from enum import Enum
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from core.database import Base

class ReportType(str, Enum):
    MONTHLY = "MONTHLY"
    YEARLY = "YEARLY"
    CUSTOM = "CUSTOM"

class ReportStatus(str, Enum):
    GENERATING = "GENERATING"
    GENERATED = "GENERATED"
    FAILED = "FAILED"
    SUBMITTED = "SUBMITTED"

class Report(Base):
    __tablename__ = "reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id"))
    
    report_type = Column(SQLEnum(ReportType), default=ReportType.MONTHLY)
    status = Column(SQLEnum(ReportStatus), default=ReportStatus.GENERATING)
    
    title = Column(String)
    file_path = Column(String, nullable=True) # Relative path from storage root
    
    # Range of data covered
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    
    created_at = Column(DateTime, default=func.now())
    submitted_at = Column(DateTime, nullable=True)
