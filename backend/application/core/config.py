from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Irrigation API"
    DATABASE_URL: str = "sqlite:///./irrigation.db" # Local fallback
    SECRET_KEY: str = "supersecretkey"

    class Config:
        env_file = ".env"
        extra = "ignore" # Allow extra env variables like RAILWAY_ ones

settings = Settings()


