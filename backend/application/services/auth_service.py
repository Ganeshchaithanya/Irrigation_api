import uuid
import secrets
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from models.user import User, OtpVerification, UserSession
from fastapi import HTTPException
import sys

def request_otp(db: Session, phone: str):
    # Here you would actually integrate Twilio/AWS SNS to send SMS
    # For now, we mock it by generating a random 6-digit code
    otp_code = f"{secrets.randbelow(900000) + 100000}" 
    
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    db_otp = OtpVerification(phone=phone, otp_code=otp_code, expires_at=expires_at)
    db.add(db_otp)
    db.commit()
    db.refresh(db_otp)
    
    # Mocking standard out logic
    print(f"[NATIVE SMS SIMULATION] Sent OTP {otp_code} to {phone}", file=sys.stderr)
    return {"message": "OTP sent successfully."}

def verify_otp(db: Session, phone: str, otp_code: str):
    # Check if a valid, unused OTP exists for this phone
    record = db.query(OtpVerification).filter(
        OtpVerification.phone == phone,
        OtpVerification.otp_code == otp_code,
        OtpVerification.is_used == False,
        OtpVerification.expires_at >= datetime.utcnow()
    ).first()
    
    if not record:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP.")
        
    # Mark as used
    record.is_used = True
    db.commit()
    
    # Check if user exists, if not, wait for them to hit /register with Name
    # But usually verify_otp registers them immediately. We'll simply find or create minimal user.
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        user = User(phone=phone, is_phone_verified=True, name=f"User {phone[-4:]}")
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        user.is_phone_verified = True
        db.commit()
        
    return create_session(db, user.id)

def create_session(db: Session, user_id):
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(days=30)
    
    session_record = UserSession(user_id=user_id, token=token, expires_at=expires_at)
    db.add(session_record)
    db.commit()
    
    return {"token": token, "user_id": user_id, "expires_at": expires_at}
