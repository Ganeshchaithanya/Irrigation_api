import sys
import os
# Ensure the repo root (Irrigation_api/) is on the path so 'llm', 'ai_engine', etc. are importable
_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if _REPO_ROOT not in sys.path:
    sys.path.insert(0, _REPO_ROOT)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from application.core.config import settings
from application.core.database import Base, engine

# Import all routers
from application.api import sensor, irrigation, command, farm, auth, analytics, ai, chat, notification, report, utility, web
from application.api import websocket_routes
import application.models  # This correctly triggers SQLAlchemy metadata registry

# Create simple tables for now (in production, use Alembic)
Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.PROJECT_NAME)

import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Mount static files
app.mount("/static", StaticFiles(directory=os.path.join(BASE_DIR, "static")), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": f"Welcome to the {settings.PROJECT_NAME}!"}

# Mount routers matching backend entry rules
app.include_router(sensor.router, prefix="/api/v1/sensors", tags=["Sensors"])
app.include_router(irrigation.router, prefix="/api/v1/irrigation", tags=["Irrigation"])
app.include_router(command.router, prefix="/api/v1/commands", tags=["Commands"])
app.include_router(farm.router, prefix="/api/v1/farms", tags=["Farms"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(analytics.router, prefix="/api/v1/analytics", tags=["Analytics"])
app.include_router(ai.router, prefix="/api/v1/ai", tags=["AI"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])
app.include_router(notification.router, prefix="/api/v1/notifications", tags=["Notifications"])
app.include_router(report.router, prefix="/api/v1/reports", tags=["Reports"])
app.include_router(utility.router, prefix="/api/v1/utility", tags=["Utility"])
app.include_router(websocket_routes.router, prefix="/ws", tags=["WebSockets"])
