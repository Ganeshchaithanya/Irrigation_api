from application.ai.specialists.client import GroqClient
from application.ai.specialists.ollama_client import OllamaClient
from application.ai.specialists.vector_db import VectorDB
import json
import re

class AgriExpertAgent:
    """
    Passive Multilingual Agri-Expert Chatbot.
    
    Roles:
    1. Analyst: Explains sensor data, AI validations, and alerts.
    2. Translator: Translates app content (guides, UI) on-demand.
    3. Observer: Never triggers irrigation or changes settings (Read-Only).
    
    Languages: English (en), Kannada (kn), Hindi (hi), Telugu (te).
    """

    def __init__(self):
        # We use Llama-3-70B for high-quality multilingual reasoning
        self.groq = GroqClient() 
        self.kb = VectorDB()
        
        # Mapping for explicit language instructions
        self.lang_map = {
            "kn": "Kannada (ಕನ್ನಡ)",
            "hi": "Hindi (हिन्दी)",
            "te": "Telugu (తెలుగు)",
            "en": "English"
        }
        
        # Phase 1: Hybrid Intent Regex Map
        self.intent_regex = {
            "CHANGE_LANGUAGE": [
                r"(?i)switch to (\w+)",
                r"(?i)change to (\w+)",
                r"(?i)(\w+) nalli mathadi",
                r"(?i)(\w+) mein baat karein",
                r"(?i)(\w+) lo matladandi"
            ]
        }

    async def _identify_intent(self, query: str):
        """
        Hybrid Intent Detection:
        1. Deterministic Pass (Regex) - Safest for UI actions.
        2. LLM Pass (Fallback) - For complex semantic reasoning.
        """
        # Step 1: Detect Language Change (Deterministic)
        for pattern in self.intent_regex["CHANGE_LANGUAGE"]:
            match = re.search(pattern, query)
            if match:
                lang_input = match.group(1).lower()
                # Internal reverse mapping for codes
                code_map = {"kannada": "kn", "hindi": "hi", "telugu": "te", "english": "en"}
                if lang_input in code_map:
                    return f"INTENT_ACTION:CHANGE_LANGUAGE:{code_map[lang_input]}"
        
        # Step 2: LLM Fallback (Semantic)
        prompt = [
            {"role": "system", "content": "Analyze the user query. Return 'EXPLAIN_MODE' if asking 'Why'. Return 'GENERAL' otherwise. Do not return language changes (handled by regex)."},
            {"role": "user", "content": query}
        ]
        try:
            intent = await self.groq.get_completion(prompt, temperature=0)
            return intent.strip()
        except:
            return "GENERAL"

    async def get_expert_response(self, query: str, context: dict):
        """
        Advanced Agricultural Intelligence Interface:
        1. Identifies Active Intents (e.g., Language Switch).
        2. Prioritizes Context (Critical > Essential > Supplemental).
        3. Enforces Numerical Locking and Passive Advisor rules.
        """
        lang_code = context.get("language", "en")
        target_lang = self.lang_map.get(lang_code, "English")
        
        # 1. Intent Detection (Feature 5 + 1)
        intent = await self._identify_intent(query)
        
        # Branch for Active Language Switching
        is_changing_lang = "CHANGE_LANGUAGE" in intent
        if is_changing_lang:
            new_code = intent.split(":")[-1].strip()
            # We will still generate a response but let the caller handle the flag if needed.
            return f"INTENT_ACTION:CHANGE_LANGUAGE:{new_code}"

        # 2. Tiered Context Harvesting (Fix Risk 1 & 2)
        farm_state = context.get("farm_state", {})
        critical = farm_state.get("critical", [])
        essential = farm_state.get("essential", [])
        supplemental = farm_state.get("supplemental", [])
        
        # 3. v2 Feature: Proactive Risk Assessment (Deterministic v3 Engine)
        risk_data = farm_state.get("risk_assessment", {"level": "LOW", "flags": [], "reason": "No assessment available."})
        risk_flags = risk_data.get("flags", [])
        risk_reason = risk_data.get("reason", "All systems nominal.")

        # 4. Search Knowledge (RAG)
        rag_context = ""
        if any(keyword in query.lower() for keyword in ["crop", "how", "pest", "soil"]):
            rag_context = "\n".join(self.kb.retrieve_expert_knowledge(query, collection_type="crop", n_results=2))

        # 5. Build Advanced Reasoning Prompt
        system_prompt = f"""
        You are the 'AquaSol Autonomous Agricultural Engine'.
        Your goal is to actively MANAGE and EXPLAIN farm data for the user in {target_lang}.
        
        STRICT RULES (Production Safety & Control):
        1. ACTIVE CONTROL: You CAN AND SHOULD trigger irrigation valves if a zone is nearing stress, based on weather or drying rates. Be PROACTIVE, not reactive.
        2. STRUCTURED OUTPUT: You MUST reply entirely in valid JSON format. Do not use Markdown backticks.
        3. NUMERICAL LOCKING: Dosages, numbers, and units (kg, mm, %, °C) MUST remain in English numerals.
        4. CONTINUOUS LEARNING: Analyze 'PAST ACTIONS' to see if previous irrigation increased moisture as expected. If delta was low, suggest higher duration.
        5. JSON SCHEMA:
        {{
          "message": "<your conversational response in {target_lang}>",
          "actions": [
            {{
              "type": "irrigate",
              "zone_id": "<UUID of the zone to irrigate>",
              "duration": <integer_minutes>
            }}
          ]
        }}
        If no action is needed, send an empty list for "actions".
        5. PROACTIVE SCHEDULING: If you see stress approaching, say "I will queue irrigation..." and include the action.
        
        PRIORITY FARM CONTEXT (Critical):
        {json.dumps(critical)}
        
        CURRENT STATE (Essential):
        {json.dumps(essential)}
        
        PAST ACTIONS & REASONING (Supplemental):
        {json.dumps(supplemental)}
        
        BIOLOGICAL RISK REPORT:
        - Status: {risk_data.get('level')}
        - Flags: {", ".join(risk_flags) if risk_flags else "None"}
        - Expert Reasoning: {risk_reason}
        
        RAG KNOWLEDGE:
        {rag_context}
        """
        
        if intent == "EXPLAIN_MODE":
            system_prompt += "\nSPECIAL INSTRUCTION: Focus your response on EXPLAINING the 'Why' behind recent AI decisions found in the Supplemental context."

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": query}
        ]

        # 4. Invoke Groq (Llama-3-70B or 8B depends on .env/client)
        # Force JSON response type from LLM if supported, otherwise rely on prompt
        response = await self.groq.get_completion(messages, temperature=0.2)
        
        # Safely extract JSON segment just in case the model returns markdown like ` ```json ... ``` `
        if "```json" in response:
            response = response.split("```json")[-1].split("```")[0].strip()
        elif "```" in response:
            response = response.split("```")[-1].split("```")[0].strip()
            
        return response

    async def translate_content(self, content_json: str, target_lang_code: str):
        """
        Utility for App-Wide Multilingualism.
        Translates raw app strings or JSON guides into the target language.
        """
        target_lang = self.lang_map.get(target_lang_code, "English")
        
        prompt = f"""
        Translate the following JSON or text into {target_lang}.
        Maintain the JSON structure exactly. Only translate the 'value' or 'text' fields.
        
        CONTENT:
        {content_json}
        """
        
        messages = [{"role": "user", "content": prompt}]
        return await self.groq.get_completion(messages, temperature=0.1)
