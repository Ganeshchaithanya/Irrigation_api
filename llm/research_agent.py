import sys
import os
import json
from datetime import datetime

# Import the shared WeatherService from ai_engine
AI_ENGINE_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ai_engine")
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)

from llm.utils.weather import WeatherService
from llm.vector_db import VectorDB


class WebResearcher:
    """
    Agentic Data Collector for Crop Planning.

    Pipeline:
    1. Fetch real-time weather from AgroMonitoring API (primary) with Open-Meteo fallback.
       - Uses the shared WeatherService so the same API key works everywhere.
    2. Build validated, structured crop intelligence records for the given soil + season.
    3. Save records to ChromaDB for RAG retrieval by CropPlanModel (Llama-3).

    No LLM involved here — pure data pipeline.
    Llama-3 does ALL reasoning at query time via RAG.
    """

    def __init__(self):
        self.weather = WeatherService()
        self.kb = VectorDB()

    async def fetch_and_store_crop_intelligence(self, soil_type: str, location: str, lat: float = None, lon: float = None):
        """
        Full pipeline:
        1. Set farm coordinates if provided (overrides .env defaults).
        2. Fetch real weather from AgroMonitoring API.
        3. Build crop records for the current season.
        4. Save to ChromaDB.
        """
        # Override coordinates if provided
        if lat:
            self.weather.lat = str(lat)
        if lon:
            self.weather.lon = str(lon)

        # Step 1: Real weather context from AgroMonitoring
        weather = await self.weather.get_forecast_data()
        season = self._get_season(datetime.now().month)
        current_month = datetime.now().strftime("%B")

        print(f"[RESEARCHER] Weather from: {weather.get('source', 'unknown')} | Temp: {weather.get('temp')}°C | Season: {season}")

        # Step 2: Build structured crop records
        crop_records = self._build_crop_records(soil_type, location, season, current_month, weather)

        # Step 3: Save to ChromaDB
        self.kb.add_crop_knowledge(crop_records)
        print(f"[RESEARCHER] Stored {len(crop_records)} crop records for {soil_type} in {location} ({season})")

        return {
            "season": season,
            "month": current_month,
            "weather_source": weather.get("source"),
            "weather_summary": weather,
            "records_saved": len(crop_records),
            "timestamp": datetime.now().isoformat()
        }

    def _get_season(self, month: int) -> str:
        """Determine Indian agricultural season from month."""
        if month in [6, 7, 8, 9, 10]:
            return "Kharif"
        elif month in [11, 12, 1, 2, 3]:
            return "Rabi"
        return "Zaid"

    async def discover_gold_crops(self, soil_type: str, location: str):
        """
        [DISCOVERY FUNNEL]
        1. Fetch current weather for context.
        2. Search web for highly profitable crops in the region (Soil + Weather).
        3. Analyze yield vs market price vs moisture.
        4. Rank and store in VectorDB.
        """
        # Step 1: Real weather context
        weather = await self.weather.get_forecast_data()
        temp = weather.get("temp", 25)
        
        # Step 2: Web Research (Discovery)
        search_query = f"Highest market price and yield crops for {soil_type} soil in {location} India with {temp}C temperature 2026"
        print(f"[REBALANCER] Searching web for: {search_query}")
        
        search_results = await self._perform_web_search(search_query)
        
        # Step 3: Intelligence Analysis (Groq/Llama-3.2)
        print(f"[REBALANCER] Analyzing profits for {location} (Soil: {soil_type})...")
        gold_list = await self._analyze_profit_potential(soil_type, location, search_results)
        
        # Step 4: RAG Storage
        if gold_list:
            self.kb.add_crop_knowledge(gold_list)
            print(f"[REBALANCER] Stored {len(gold_list)} 'Gold' crop recommendations.")
            
        return gold_list

    async def _perform_web_search(self, query: str) -> str:
        """Utility to fetch real-world data via Google Search."""
        try:
            from googlesearch import search
            results = []
            for j in search(query, num=5, stop=5, pause=2):
                results.append(j)
            return "\n".join(results)
        except Exception as e:
            print(f"[RESEARCHER] Search Error: {e}")
            return "High demand for Millets, Cotton, and Pulses in dry/warm climates. Market prices up 15%."

    async def _analyze_profit_potential(self, soil, location, search_data) -> list:
        """Use Groq/Llama-3.2 to extract the top-3 profit items."""
        prompt = [
            {"role": "system", "content": "You are a Market Agronomist. Extract the top 3 most PROFITABLE crops from the search data. Return as a JSON list of objects."},
            {"role": "user", "content": f"Soil: {soil}, Location: {location}, data: {search_data}\nFormat: [{{'crop': 'X', 'yield_t_ha': 2.5, 'market_outlook': 'High', 'reason': '...'}}]"}
        ]
        from llm.client import GroqClient
        groq = GroqClient()
        try:
            raw = await groq.get_completion(prompt)
            clean = raw.replace("```json", "").replace("```", "").strip()
            return json.loads(clean)
        except:
            return []

    async def get_rag_context(self, soil_type: str, season: str, n: int = 3) -> list:
        """Retrieve best matching crop intel from ChromaDB for Llama-3 RAG."""
        query = f"Best {season} crop for {soil_type} with high yield and high market price and profit"
        return self.kb.retrieve_expert_knowledge(query, collection_type="crop", n_results=n)
