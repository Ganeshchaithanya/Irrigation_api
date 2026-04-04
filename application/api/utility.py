from fastapi import APIRouter, HTTPException, Depends
from application.schemas.utility import TranslationRequest, TranslationResponse
from application.ai.specialists.agent import AgriExpertAgent
import json

router = APIRouter()
agent = AgriExpertAgent()

@router.post("/translate", response_model=TranslationResponse)
async def translate_app_content(req: TranslationRequest):
    """
    App-Wide Multilingual Utility:
    Translates UI strings, crop guides, or notification templates on-demand.
    """
    try:
        # Convert dict to string if needed
        content_to_translate = req.content
        if isinstance(content_to_translate, dict):
            content_to_translate = json.dumps(content_to_translate)
            
        translated_raw = await agent.translate_content(content_to_translate, req.target_language)
        
        # 1. Try to parse as JSON if the input was JSON
        if isinstance(req.content, dict):
            try:
                # Clean up potential LLM markdown artifacts (```json ... ```)
                clean_json = translated_raw.replace("```json", "").replace("```", "").strip()
                return {"translated_content": json.loads(clean_json)}
            except Exception:
                # Fallback to raw string if JSON parsing fails
                return {"translated_content": translated_raw}
                
        # 2. Return as string
        return {"translated_content": translated_raw}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Translation failed: {str(e)}")
