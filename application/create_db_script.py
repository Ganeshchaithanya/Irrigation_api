import sys
import os

# Ensure the project root is in path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from application.core.database import Base, engine

# Import all models strictly so they get registered on the Base metadata
import application.models.user
import application.models.farm
import application.models.device
import application.models.sensor
import application.models.irrigation
import application.models.analytics
import application.models.ai
import application.models.command
import application.models.chat
import application.models.feedback
import application.models.report
import application.models.notification

def setup_fresh_db():
    print("Dropping all existing tables to guarantee fresh start...")
    Base.metadata.drop_all(bind=engine)
    print("Creating complete DB structures for Backend, AI & App mapping...")
    Base.metadata.create_all(bind=engine)
    print("Success: ESP32 Mapping Schema initialized.")

if __name__ == "__main__":
    setup_fresh_db()
