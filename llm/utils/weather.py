import httpx
import os
from datetime import datetime

class WeatherService:
    def __init__(self):
        # Open-Meteo is free (No API Key Required)
        # AgroMonitoring / OpenWeather (Requires appid)
        self.agro_api_key = os.getenv("OPENWEATHER_API_KEY")
        self.lat = os.getenv("FARM_LAT", "12.9716") # Default: Bengaluru
        self.lon = os.getenv("FARM_LON", "77.5946")
        
        # Base URLs
        self.open_meteo_url = "https://api.open-meteo.com/v1/forecast"
        self.agro_url = "https://api.agromonitoring.com/agro/1.0/weather"

    async def get_forecast_data(self):
        """Fetches 24h weather context. Prioritizes AgroMonitoring if Key is available."""
        if self.agro_api_key:
            return await self._get_agro_weather()
        return await self._get_open_meteo_weather()

    async def _get_agro_weather(self):
        """Fetches current weather from AgroMonitoring (High Fidelity)."""
        params = {
            "lat": self.lat,
            "lon": self.lon,
            "appid": self.agro_api_key,
            "units": "metric"
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(self.agro_url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
                
                return {
                    "temp": data.get('main', {}).get('temp', 25.0),
                    "max_temp": data.get('main', {}).get('temp_max', 30.0),
                    "humidity": data.get('main', {}).get('humidity', 60.0),
                    "rain_mm": data.get('rain', {}).get('1h', 0.0),
                    "condition": data.get('weather', [{}])[0].get('main', 'Clear'),
                    "source": "AgroMonitoring (Satellite Context)"
                }
            except Exception as e:
                print(f"[WEATHER] Agro API failed, falling back: {e}")
                return await self._get_open_meteo_weather()

    async def _get_open_meteo_weather(self):
        """Fallback to Open-Meteo (Open Source)."""
        params = {
            "latitude": self.lat,
            "longitude": self.lon,
            "hourly": "temperature_2m,rain,relative_humidity_2m",
            "timezone": "auto",
            "forecast_days": 1
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(self.open_meteo_url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
                
                hourly = data.get('hourly', {})
                temps = hourly.get('temperature_2m', [])
                rain_list = hourly.get('rain', [])
                humidity_list = hourly.get('relative_humidity_2m', [])
                
                return {
                    "temp": sum(temps) / len(temps) if temps else 25.0,
                    "max_temp": max(temps) if temps else 30.0,
                    "humidity": sum(humidity_list) / len(humidity_list) if humidity_list else 60.0,
                    "rain_mm": sum(rain_list) if rain_list else 0.0,
                    "condition": "Cloudy" if sum(rain_list) > 0 else "Clear",
                    "source": "Open-Meteo (Fallback)"
                }
            except Exception as e:
                print(f"[WEATHER] Critical weather failure: {e}")
                return {"temp": 25.0, "rain_mm": 0.0, "condition": "Unknown", "source": "Internal Fallback"}
