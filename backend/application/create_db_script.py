import sys
import os

# Ensure the app folder is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from core.database import Base, engine

# Import all models strictly so they get registered on the Base metadata
import models.user
import models.farm
import models.device
import models.sensor
import models.irrigation
import models.analytics
import models.ai
import models.command
import models.chat
import models.feedback
import models.report
import models.notification

def setup_fresh_db():
    print("Dropping all existing tables to guarantee fresh start...")
    Base.metadata.drop_all(bind=engine)
    print("Creating complete DB structures for Backend, AI & App mapping...")
    Base.metadata.create_all(bind=engine)
    print("Success: ESP32 Mapping Schema initialized.")

if __name__ == "__main__":
    setup_fresh_db()
