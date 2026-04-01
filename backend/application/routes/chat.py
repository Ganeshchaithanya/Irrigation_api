from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from schemas.chat import ChatLogCreate, ChatLogResponse, MessageTemplateResponse
from services import chat_service
from llm.agent import AgriExpertAgent
from pydantic import UUID4
from typing import List

router = APIRouter()
agent = AgriExpertAgent()

@router.post("/message", response_model=ChatLogResponse)
async def save_chat_message(data: ChatLogCreate, db: Session = Depends(get_db)):
    # 1. Fetch REAL context from the DB (Tiers: Critical, Essential, Supplemental)
    farm_context = chat_service.get_farmer_context(db, data.user_id)
    
    # 2. Prepare Agent Context (Language + Farm State)
    agent_context = {
        "language": data.language,
        "farm_state": farm_context
    }
    
    # 3. Generate intelligent response via Llama 3 Agent
    ai_response = await agent.get_expert_response(data.query, agent_context)
    
    # 4. Handle ACTIVE INTENTS (Feature 5)
    if "INTENT_ACTION:CHANGE_LANGUAGE" in ai_response:
        new_lang_code = ai_response.split(":")[-1].strip()
        chat_service.update_user_language(db, data.user_id, new_lang_code)
        
        # Re-generate response in the NEW language to confirm the action
        data.language = new_lang_code
        agent_context["language"] = new_lang_code
        ai_response = await agent.get_expert_response(f"I have successfully switched your language. How else can I help?", agent_context)

    # 5. Update data with AI response
    data.response = ai_response
    
    # 6. Log to DB
    return chat_service.log_chat_interaction(db, data)

@router.get("/history/{user_id}", response_model=List[ChatLogResponse])
def get_user_chat_history(user_id: UUID4, limit: int = 20, db: Session = Depends(get_db)):
    return chat_service.get_chat_history(db, user_id=user_id, limit=limit)

@router.get("/templates", response_model=List[MessageTemplateResponse])
def get_all_message_templates(db: Session = Depends(get_db)):
    return chat_service.get_all_templates(db)

@router.get("/templates/{code}", response_model=MessageTemplateResponse)
def get_template_by_code(code: str, db: Session = Depends(get_db)):
    template = chat_service.get_message_template(db, code)
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template
