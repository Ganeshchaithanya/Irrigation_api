from core.database import SessionLocal
from services.report_service import ReportService
from schemas.report import DynamicReportRequest, ReportModule
from uuid import UUID
from datetime import datetime, timedelta
import os

def verify_modular_report():
    db = SessionLocal()
    farm_id = UUID("21762915-deeb-4b01-bd76-914adbc1f384")
    
    print(f"--- Testing Modular Dynamic Report Generation ---")
    
    # 1. Test "Everything Dynamic" (All modules)
    print("\n[Test 1] Monthly Summary with Charts & Zones")
    req1 = DynamicReportRequest(
        farm_id=farm_id,
        start_date=datetime.now() - timedelta(days=30),
        end_date=datetime.now(),
        modules=[
            ReportModule.HEADER,
            ReportModule.STAT_CARDS,
            ReportModule.CHART_WATER,
            ReportModule.TABLE_ZONES,
            ReportModule.CERTIFICATION
        ],
        title_suffix="Full Monthly Suite"
    )
    try:
        res1 = ReportService.generate_dynamic_report(db, req1)
        print(f"SUCCESS: {res1.title}")
        print(f"File: {res1.file_path}")
    except Exception as e:
        print(f"FAILED Req 1: {e}")

    # 2. Test "Minimalist" (Profile + Stats only)
    print("\n[Test 2] Minimalist Profile + Stats")
    req2 = DynamicReportRequest(
        farm_id=farm_id,
        start_date=datetime.now() - timedelta(days=7),
        end_date=datetime.now(),
        modules=[
            ReportModule.HEADER,
            ReportModule.STAT_CARDS
        ],
        title_suffix="Quick Glance"
    )
    try:
        res2 = ReportService.generate_dynamic_report(db, req2)
        print(f"SUCCESS: {res2.title}")
        print(f"File: {res2.file_path}")
    except Exception as e:
        print(f"FAILED Req 2: {e}")

    db.close()

if __name__ == "__main__":
    verify_modular_report()
