@echo off
echo Automatically building environment and launching server...
call venv\Scripts\activate.bat
cd backend\application
uvicorn main:app --reload
