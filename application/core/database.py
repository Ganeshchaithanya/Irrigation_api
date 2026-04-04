from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from application.core.config import settings

# For TimescaleDB/PostgreSQL, pool configuration is essential
engine_kwargs = {
    "pool_pre_ping": True,
}

# Only use postgres-specific pooling/ssl if it's actual postgres
if settings.DATABASE_URL.startswith("postgres"):
    engine_kwargs["pool_size"] = 5
    engine_kwargs["max_overflow"] = 10
    if "localhost" not in settings.DATABASE_URL:
        engine_kwargs["connect_args"] = {"sslmode": "require"}

engine = create_engine(
    settings.DATABASE_URL.replace("postgres://", "postgresql://", 1),
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
