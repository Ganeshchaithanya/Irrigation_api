"""
Multi-channel WebSocket Manager for AquaSol.
Channels:
  /ws/telemetry      - live ESP32 sensor readings
  /ws/alerts         - anomaly & hardware alerts
  /ws/ai-decisions   - AI recommendations pushed proactively
  /ws/system-status  - heartbeat & connectivity status
"""
import asyncio
import json
from fastapi import WebSocket
from typing import Dict, List


class ChannelManager:
    def __init__(self):
        self.channels: Dict[str, List[WebSocket]] = {
            "telemetry": [],
            "alerts": [],
            "ai-decisions": [],
            "system-status": [],
        }

    async def connect(self, channel: str, ws: WebSocket):
        await ws.accept()
        self.channels.setdefault(channel, []).append(ws)

    def disconnect(self, channel: str, ws: WebSocket):
        if channel in self.channels:
            self.channels[channel].discard(ws) if hasattr(self.channels[channel], "discard") else None
            try:
                self.channels[channel].remove(ws)
            except ValueError:
                pass

    async def broadcast(self, channel: str, payload: dict):
        message = json.dumps(payload)
        dead = []
        for ws in list(self.channels.get(channel, [])):
            try:
                await ws.send_text(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(channel, ws)


# Global singleton
ws_manager = ChannelManager()
