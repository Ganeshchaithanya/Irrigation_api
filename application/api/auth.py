from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.schemas.auth import UserCreate, UserResponse, OTPRequest, OTPVerify, SessionResponse, UserPreferenceUpdate, UserLogin, GoogleAuth
from application.models.user import User
from application.services import auth_service
from pydantic import UUID4

router = APIRouter()
@router.post("/register", response_model=UserResponse)
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    pwd_hash = auth_service.get_password_hash(data.password)
    db_user = User(
        name=data.name,
        phone=data.phone,
        email=data.email,
        hashed_password=pwd_hash
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/login", response_model=SessionResponse)
def login(data: UserLogin, db: Session = Depends(get_db)):
    return auth_service.login_user(db, email=data.email, password=data.password)

@router.post("/google", response_model=SessionResponse)
def google_signin(data: GoogleAuth, db: Session = Depends(get_db)):
    return auth_service.google_login(db, email=data.email, name=data.name, google_id=data.google_id)

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

