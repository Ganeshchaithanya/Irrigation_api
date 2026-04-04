import httpx
import os
from dotenv import load_dotenv

# Load .env (looks in current working directory first, which is the project root)
load_dotenv()

class GroqClient:
    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")
        self.base_url = "https://api.groq.com/openai/v1/chat/completions"
        self.model = "llama-3.1-8b-instant"

    async def get_completion(self, messages, temperature=0.7):
        if not self.api_key:
            raise ValueError("GROQ_API_KEY not found in .env")

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": temperature
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(self.base_url, headers=headers, json=payload, timeout=30.0)
            response.raise_for_status()
            return response.json()['choices'][0]['message']['content']
