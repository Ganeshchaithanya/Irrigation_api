from sqlalchemy.orm import Session
from application.models.analytics import DailyAggregate, MonthlyAggregate, YearlyAggregate, PlantHealthScore, ETData
from pydantic import UUID4
from datetime import date

def get_latest_et_data(db: Session, zone_id: UUID4, limit: int = 10):
    return db.query(ETData).filter(ETData.zone_id == zone_id).order_by(ETData.timestamp.desc()).limit(limit).all()

def get_daily_aggregates(db: Session, zone_id: UUID4, limit: int = 30):
    return db.query(DailyAggregate).filter(DailyAggregate.zone_id == zone_id).order_by(DailyAggregate.date.desc()).limit(limit).all()

def get_monthly_aggregates(db: Session, zone_id: UUID4, limit: int = 12):
    return db.query(MonthlyAggregate).filter(MonthlyAggregate.zone_id == zone_id).order_by(MonthlyAggregate.month.desc()).limit(limit).all()

def get_yearly_aggregates(db: Session, zone_id: UUID4):
    return db.query(YearlyAggregate).filter(YearlyAggregate.zone_id == zone_id).order_by(YearlyAggregate.year.desc()).all()

def get_plant_health_scores(db: Session, zone_id: UUID4, limit: int = 7):
    return db.query(PlantHealthScore).filter(PlantHealthScore.zone_id == zone_id).order_by(PlantHealthScore.date.desc()).limit(limit).all()
