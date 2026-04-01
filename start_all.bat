@echo off
echo [1/3] Starting AquaSol Backend (Port 8000)...
start "AquaSol Backend" cmd /k "call venv\Scripts\activate.bat && cd backend\application && uvicorn main:app --port 8000 --reload"

echo [2/3] Starting AquaSol AI Engine (Port 8001)...
start "AquaSol AI Engine" cmd /k "call venv\Scripts\activate.bat && cd ai_engine && uvicorn main:app --port 8001 --reload"

echo.
echo [3/3] System services launched! 
echo To run the Flutter Mobile App, open a new terminal and run:
echo cd aquasol_app
echo flutter run
