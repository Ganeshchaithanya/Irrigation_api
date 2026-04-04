from fastapi import APIRouter, Request, Depends
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.models.farm import Farm, Zone
from application.models.sensor import NodeData, ZoneData
from application.models.device import Device
import os

router = APIRouter()

# Get the absolute path to the templates directory
TEMPLATES_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "templates")
templates = Jinja2Templates(directory=TEMPLATES_PATH)

@router.get("/")
@router.get("/dashboard")
async def get_dashboard(request: Request, db: Session = Depends(get_db)):
    """The master 'Agri-Expert' Dashboard load."""
    farms = db.query(Farm).all()
    # For now, we take the first farm as default (Production would use current_user)
    first_farm = farms[0] if farms else None
    
    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "farm": first_farm,
        "title": "Agri-Expert Dashboard"
    })

@router.get("/dashboard/zones")
async def get_zone_updates(request: Request, db: Session = Depends(get_db)):
    """HTMX partial for real-time Zone Card updates."""
    from services import sensor_service
    # We resolve all active zones and their latest readings
    zones = db.query(Zone).all()
    zone_data = []
    
    for zone in zones:
        latest = sensor_service.get_latest_by_zone(db, zone_id=zone.id)
        zone_data.append({
            "zone": zone,
            "readings": latest
        })
        
    return templates.TemplateResponse("partials/zone_grid.html", {
        "request": request,
        "zones": zone_data
    })
