import json
from datetime import datetime
from application.ai.specialists.client import GroqClient
from application.ai.specialists.vector_db import VectorDB
from application.ai.specialists.research_agent import WebResearcher

class CropPlanModel:
    """
    Crop Planning Intelligence.
    
    Flow:
    1. WebResearcher fetches real weather + builds crop records → saves to ChromaDB (Discovery).
    2. RAG retrieves scientific protocols from JSON guides (expert_guides).
    3. Base Mistral:latest reasons over RAG context + farm history to produce a full crop plan.
    """
    def __init__(self):
        # We use Groq (Cloud) as the primary brain for the final Crop Plan generation.
        # This avoids local GPU OOM issues and provides faster reasoning.
        self.llm = GroqClient()
        self.kb = VectorDB()
        self.researcher = WebResearcher()

    async def generate_optimized_plan(self, profile: dict):
        """
        RAG-Driven Reasoning:
        1. Refresh ChromaDB with latest weather + crop intel.
        2. Retrieve market discovery and scientific guide data.
        3. Mistral:latest generates the full plan.
        """
        soil = profile.get("soil", "Red Soil")
        location = profile.get("location", "Unknown Region")
        zone_id = profile.get("zone_id", "unknown")
        current_crop = profile.get("current_crop", "None")
        language = profile.get("language", "English")
        lat = profile.get("lat", 17.0)
        lon = profile.get("lon", 78.0)

        current_month = datetime.now().month
        season = self._get_season(current_month)

        # 1. Refresh Dynamic Discovery (Weather + Soil based)
        # This populates the 'crop_strategies' collection with real-world profit data
        await self.researcher.discover_gold_crops(soil, location)

        # 2. RAG LAYER 1: Market Intelligence (Discovery)
        market_docs = await self.researcher.get_rag_context(soil, season, n=2)
        market_context = "\n".join(market_docs) if market_docs else "No specific market records found."

        # 3. RAG LAYER 2: Scientific Protocols (Expert Guides)
        expert_docs = self.kb.retrieve_expert_knowledge(
            f"Farming guide for {soil} in {season}", 
            collection_type="expert", 
            n_results=3
        )
        expert_context = "\n".join(expert_docs) if expert_docs else "No expert protocols found."

        # 4. Local Reasoning prompt
        system_prompt = f"""You are 'Agri-Expert Mistral', an expert agricultural advisor.
You generate structured agricultural plans in JSON format.
STRICT REQUIREMENT: All non-technical text fields (recommended_crop, reasoning, strategy descriptions, fertilizer names, etc.) MUST be written in the following language: {language}.
Each plan MUST include:
- irrigation_strategy: A JSON object with timing, quantity (mm), and method.
- fertilizer_plan: A JSON object with stage, type, and dosage.
- pesticide_plan: A JSON object with pest name and recommended organic/chemical control.
- risk_score: A float from 0.0 to 1.0.
- expected_yield: A float (tonnes/hectare).
- recommended_crop: String.
Ensure all outputs are valid JSON."""

        user_prompt = f"""FARM PROFILE:
- Location: {location} | Soil: {soil} | Season: {season}
- Target Language: {language} (Explain everything in this language)

MARKET DISCOVERY (RAG):
{market_context}

SCIENTIFIC PROTOCOLS (EXPERT RAG):
{expert_context}

Generate a complete plan for {current_crop if current_crop != "None" else "the best suited crop"}.
Format precisely:
{{
  "recommended_crop": "...",
  "reasoning": "...",
  "expected_yield": 0.0,
  "risk_score": 0.15,
  "irrigation_strategy": {{ "method": "...", "schedule": "..." }},
  "fertilizer_plan": {{ "basal": "...", "top_dressing": "..." }},
  "pesticide_plan": {{ "preventative": "...", "curative": "..." }}
}}"""

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]

        try:
            raw = await self.llm.get_completion(messages, temperature=0.2)
            start = raw.find('{')
            end = raw.rfind('}') + 1
            if start != -1 and end > start:
                plan = json.loads(raw[start:end])
                return {
                    "recommended_crop": plan.get("recommended_crop", "Unknown"),
                    "expected_yield": float(plan.get("expected_yield", 0.0)),
                    "risk_score": float(plan.get("risk_score", 0.1)),
                    "irrigation_strategy": plan.get("irrigation_strategy", {"error": "Missing"}),
                    "fertilizer_plan": plan.get("fertilizer_plan", {"error": "Missing"}),
                    "pesticide_plan": plan.get("pesticide_plan", {"error": "Missing"}),
                    "reasoning": plan.get("reasoning", "")
                }
            return {"error": "Could not parse LLM JSON output"}
        except Exception as e:
            print(f"[CROP-PLAN] Failed: {e}")
            return {"error": str(e)}

    def _get_season(self, month: int) -> str:
        if month in [6, 7, 8, 9, 10]:
            return "Kharif"
        elif month in [11, 12, 1, 2, 3]:
            return "Rabi"
        return "Zaid"
