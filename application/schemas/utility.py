from pydantic import BaseModel
from typing import Union, Dict, Any

class TranslationRequest(BaseModel):
    content: Union[str, Dict[str, Any]]
    target_language: str

class TranslationResponse(BaseModel):
    translated_content: Union[str, Dict[str, Any]]
