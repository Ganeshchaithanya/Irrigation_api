import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base

class ChatSession(Base):
    __tablename__ = "chat_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    title = Column(String, default="New Chat")
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    logs = relationship("ChatLog", back_populates="session", cascade="all, delete-orphan")

class ChatLog(Base):
    __tablename__ = "chat_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), ForeignKey("chat_sessions.id"))
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    
    query = Column(String)
    response = Column(String)
    language = Column(String(5))
    
    created_at = Column(DateTime, default=func.now())

    session = relationship("ChatSession", back_populates="logs")
class MessageTemplate(Base):
    __tablename__ = "message_templates"

    code = Column(String, primary_key=True)
    en = Column(String)
    hi = Column(String)
    kn = Column(String)
    te = Column(String)
