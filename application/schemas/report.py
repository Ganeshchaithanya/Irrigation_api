from pydantic import BaseModel, UUID4
from datetime import datetime
from typing import List, Optional
from enum import Enum

class ReportModule(str, Enum):
    HEADER = "HEADER"
    STAT_CARDS = "STAT_CARDS"
    CHART_WATER = "CHART_WATER"
    CHART_MOISTURE = "CHART_MOISTURE"
    TABLE_ZONES = "TABLE_ZONES"
    TABLE_LOGS = "TABLE_LOGS"
    AI_INSIGHTS = "AI_INSIGHTS"
    CERTIFICATION = "CERTIFICATION"

class ReportTheme(str, Enum):
    DETAILED = "DETAILED"
    COMPACT = "COMPACT"
    MINIMAL = "MINIMAL"

class DynamicReportRequest(BaseModel):
    farm_id: UUID4
    start_date: datetime
    end_date: datetime
    modules: List[ReportModule] = [
        ReportModule.HEADER,
        ReportModule.STAT_CARDS,
        ReportModule.CHART_WATER,
        ReportModule.TABLE_ZONES,
        ReportModule.CERTIFICATION
    ]
    theme: ReportTheme = ReportTheme.DETAILED
    title_suffix: Optional[str] = None
