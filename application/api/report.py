from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.models.report import Report, ReportType, ReportStatus
from application.services.report_service import ReportService
from application.schemas.report import DynamicReportRequest
from pydantic import UUID4
from typing import List
from datetime import datetime

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.post("/generate/monthly/{farm_id}")
def generate_monthly_report(
    farm_id: UUID4,
    year: int = Query(default=datetime.now().year),
    month: int = Query(default=datetime.now().month),
    db: Session = Depends(get_db)
):
    try:
        report = ReportService.get_monthly_report(db, farm_id, year, month)
        return {"message": "Monthly report generated successfully", "report_id": report.id, "file_path": report.file_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate/yearly/{farm_id}")
def generate_yearly_report(
    farm_id: UUID4,
    year: int = Query(default=datetime.now().year),
    db: Session = Depends(get_db)
):
    try:
        report = ReportService.get_yearly_report(db, farm_id, year)
        return {"report_id": report.id, "file_path": report.file_path, "title": report.title}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate/custom/{farm_id}")
def generate_custom_report(
    farm_id: UUID4,
    start_date: datetime,
    end_date: datetime,
    db: Session = Depends(get_db)
):
    try:
        if start_date >= end_date:
            raise HTTPException(status_code=400, detail="start_date must be before end_date")
        report = ReportService.get_custom_report(db, farm_id, start_date, end_date)
        return {"report_id": report.id, "file_path": report.file_path, "title": report.title}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/generate/dynamic")
def generate_dynamic_report(
    request: DynamicReportRequest,
    db: Session = Depends(get_db)
):
    try:
        report = ReportService.generate_dynamic_report(db, request)
        return {"report_id": report.id, "file_path": report.file_path, "title": report.title}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/farm/{farm_id}", response_model=List[dict])
def list_reports(farm_id: UUID4, db: Session = Depends(get_db)):
    reports = db.query(Report).filter(Report.farm_id == farm_id).order_by(Report.created_at.desc()).all()
    # Simple dict conversion for sub-sampling
    return [
        {
            "id": r.id,
            "title": r.title,
            "status": r.status,
            "report_type": r.report_type,
            "file_path": r.file_path,
            "created_at": r.created_at
        } for r in reports
    ]

@router.post("/{report_id}/submit")
def submit_report(report_id: UUID4, db: Session = Depends(get_db)):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    if report.status != ReportStatus.GENERATED:
        raise HTTPException(status_code=400, detail="Report is not in GENERATED state")
    
    report.status = ReportStatus.SUBMITTED
    report.submitted_at = datetime.now()
    db.commit()
    
    return {"message": "Report submitted to government successfully", "submitted_at": report.submitted_at}
