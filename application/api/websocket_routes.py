"""
WebSocket routes for multi-channel real-time communication.
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from application.services.ws_manager import ws_manager

router = APIRouter()

@router.websocket("/telemetry")
async def ws_telemetry(websocket: WebSocket):
    await ws_manager.connect("telemetry", websocket)
    try:
        while True:
            # Keep alive – client can send pings or just receive pushes
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect("telemetry", websocket)

@router.websocket("/alerts")
async def ws_alerts(websocket: WebSocket):
    await ws_manager.connect("alerts", websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect("alerts", websocket)

@router.websocket("/ai-decisions")
async def ws_ai_decisions(websocket: WebSocket):
    await ws_manager.connect("ai-decisions", websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect("ai-decisions", websocket)

@router.websocket("/system-status")
async def ws_system_status(websocket: WebSocket):
    await ws_manager.connect("system-status", websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect("system-status", websocket)
