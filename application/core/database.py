from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from application.core.config import settings

import os

print("DATABASE_URL:", settings.DATABASE_URL)

DATABASE_URL = settings.DATABASE_URL

if not DATABASE_URL or DATABASE_URL.startswith("sqlite"):
    raise ValueError("DATABASE_URL not set or is using SQLite fallback! Set the PostgreSQL URL in your environment.")

if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine_kwargs = {
    "pool_pre_ping": True,
    "pool_size": 5,
    "max_overflow": 10,
}
if "localhost" not in DATABASE_URL:
    engine_kwargs["connect_args"] = {"sslmode": "require"}

engine = create_engine(
    DATABASE_URL,
    **engine_kwargs
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
