from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from application.core.database import get_db
from application.schemas.notification import NotificationResponse
from application.services.notification_service import NotificationService
from pydantic import UUID4
from typing import List

router = APIRouter()

@router.get("/", response_model=List[NotificationResponse])
def get_my_notifications(user_id: UUID4, limit: int = 50, db: Session = Depends(get_db)):
    """Get all notifications for a user (newest first)."""
    return NotificationService(db).get_all(user_id, limit)

@router.get("/unread", response_model=List[NotificationResponse])
def get_unread_notifications(user_id: UUID4, db: Session = Depends(get_db)):
    """Get only unread notifications."""
    return NotificationService(db).get_unread(user_id)

@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(notification_id: UUID4, db: Session = Depends(get_db)):
    """Mark a single notification as read."""
    notif = NotificationService(db).mark_read(notification_id)
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notif

@router.patch("/read-all")
def mark_all_read(user_id: UUID4, db: Session = Depends(get_db)):
    """Mark all user notifications as read."""
    NotificationService(db).mark_all_read(user_id)
    return {"status": "ok", "message": "All notifications marked as read"}
