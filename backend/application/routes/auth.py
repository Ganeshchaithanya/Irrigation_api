from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from schemas.auth import UserCreate, UserResponse, OTPRequest, OTPVerify, SessionResponse, UserPreferenceUpdate
from models.user import User
from services import auth_service
from pydantic import UUID4

router = APIRouter()

@router.post("/register", response_model=UserResponse)
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    db_user = User(**data.model_dump())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/request-otp")
def generate_otp(data: OTPRequest, db: Session = Depends(get_db)):
    return auth_service.request_otp(db, phone=data.phone)

@router.post("/verify-otp", response_model=SessionResponse)
def verify_phone_otp(data: OTPVerify, db: Session = Depends(get_db)):
    return auth_service.verify_otp(db, phone=data.phone, otp_code=data.otp_code)

@router.patch("/preference/{user_id}")
def update_user_preference(user_id: UUID4, data: UserPreferenceUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.preferred_language = data.preferred_language
    db.commit()
    return {"status": "success", "language": data.preferred_language}

