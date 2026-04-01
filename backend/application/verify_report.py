from core.database import SessionLocal
from services.report_service import ReportService
from uuid import UUID

import os
from datetime import datetime, timedelta

def verify_report():
    db = SessionLocal()
    farm_id = UUID("21762915-deeb-4b01-bd76-914adbc1f384")
    
    # Test Custom Dynamic Report
    print(f"Generating custom dynamic report for farm: {farm_id}")
    try:
        start = datetime.now() - timedelta(days=30)
        end = datetime.now()
        report = ReportService.get_custom_report(db, farm_id, start, end)
        print(f"Success! Dynamic Report generated: {report.title}")
        print(f"File path: {report.file_path}")
        
        # Check if file exists and has size
        abs_path = os.path.dirname(os.path.abspath(__file__))
        file_disk_path = os.path.join(abs_path, "static", "reports", os.path.basename(report.file_path))
        if os.path.exists(file_disk_path):
            print(f"File exists on disk. Size: {os.path.getsize(file_disk_path)} bytes")
        else:
            print(f"Warning: File not found at {file_disk_path}")
            
    except Exception as e:
        print(f"Failed to generate report: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    verify_report()
