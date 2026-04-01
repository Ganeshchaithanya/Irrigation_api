import httpx

class OllamaClient:
    """
    Local Ollama Client for the Agriculture AI.
    - 'mistral:latest' -> Primary High-Precision Local Agronomist (Stage & Planning)
    """
    def __init__(self, model="mistral:latest"):
        self.base_url = "http://localhost:11434/api/chat"
        # Validate that the requested model is one of our specialists
        allowed_models = ["mistral:latest", "llama3:latest"]
        if model not in allowed_models:
            print(f"[WARNING] Model {model} is not standard. Defaulting to mistral:latest")
            self.model = "mistral:latest"
        else:
            self.model = model

    async def get_completion(self, messages, temperature=0.7):
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {"temperature": temperature}
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.base_url,
                json=payload,
                timeout=60.0
            )
            response.raise_for_status()
            return response.json()['message']['content']
