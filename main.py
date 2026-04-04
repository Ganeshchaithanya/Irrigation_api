# Unified Entry Point for AquaSol
import sys
import os

# Ensure the root directory is in sys.path (standard practice)
_ROOT = os.path.dirname(os.path.abspath(__file__))
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

# Import the FastAPI application from the unified structure
from application.main import app

if __name__ == "__main__":
    import uvicorn
    # Use environment port for deployment (Railway/Heroku)
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
