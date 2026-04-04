from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.schemas.analytics import ETDataResponse, DailyAggregateResponse, MonthlyAggregateResponse, YearlyAggregateResponse, PlantHealthScoreResponse
from application.services import analytics_service
from pydantic import UUID4
from typing import List

router = APIRouter()

@router.get("/et/{zone_id}", response_model=List[ETDataResponse])
def get_et_data(zone_id: UUID4, limit: int = 10, db: Session = Depends(get_db)):
    return analytics_service.get_latest_et_data(db, zone_id=zone_id, limit=limit)

@router.get("/daily/{zone_id}", response_model=List[DailyAggregateResponse])
def get_daily_metrics(zone_id: UUID4, limit: int = 30, db: Session = Depends(get_db)):
    return analytics_service.get_daily_aggregates(db, zone_id=zone_id, limit=limit)

@router.get("/monthly/{zone_id}", response_model=List[MonthlyAggregateResponse])
def get_monthly_metrics(zone_id: UUID4, limit: int = 12, db: Session = Depends(get_db)):
    return analytics_service.get_monthly_aggregates(db, zone_id=zone_id, limit=limit)

@router.get("/yearly/{zone_id}", response_model=List[YearlyAggregateResponse])
def get_yearly_metrics(zone_id: UUID4, db: Session = Depends(get_db)):
    return analytics_service.get_yearly_aggregates(db, zone_id=zone_id)

@router.get("/health/{zone_id}", response_model=List[PlantHealthScoreResponse])
def get_health_scores(zone_id: UUID4, limit: int = 7, db: Session = Depends(get_db)):
    return analytics_service.get_plant_health_scores(db, zone_id=zone_id, limit=limit)
