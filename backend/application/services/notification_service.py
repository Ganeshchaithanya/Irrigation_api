from sqlalchemy.orm import Session
from models.notification import Notification
from pydantic import UUID4

class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def create(self, notif_type: str, title: str, message: str, user_id=None, zone_id=None):
        notif = Notification(
            user_id=user_id,
            zone_id=zone_id,
            type=notif_type,
            title=title,
            message=message
        )
        self.db.add(notif)
        self.db.commit()
        self.db.refresh(notif)
        return notif

    def get_unread(self, user_id: UUID4):
        return (
            self.db.query(Notification)
            .filter(Notification.user_id == user_id, Notification.is_read == False)
            .order_by(Notification.created_at.desc())
            .all()
        )

    def get_all(self, user_id: UUID4, limit: int = 50):
        return (
            self.db.query(Notification)
            .filter(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(limit)
            .all()
        )

    def mark_read(self, notification_id: UUID4):
        notif = self.db.query(Notification).filter(Notification.id == notification_id).first()
        if notif:
            notif.is_read = True
            self.db.commit()
        return notif

    def mark_all_read(self, user_id: UUID4):
        self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False
        ).update({"is_read": True})
        self.db.commit()
