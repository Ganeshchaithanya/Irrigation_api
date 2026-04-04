import os
import sys

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

from sqlalchemy import text
from application.core.database import engine

def apply_migration():
    with engine.begin() as conn:
        try:
            conn.execute(text("ALTER TABLE zones ADD COLUMN start_node VARCHAR DEFAULT 'Unknown';"))
            print("Added start_node")
        except Exception as e:
            print(f"start_node column error: {e}")
            
        try:
            conn.execute(text("ALTER TABLE zones ADD COLUMN mid_node VARCHAR DEFAULT 'Unknown';"))
            print("Added mid_node")
        except Exception as e:
            print(f"mid_node column error: {e}")
            
        try:
            conn.execute(text("ALTER TABLE zones ADD COLUMN end_node VARCHAR DEFAULT 'Unknown';"))
            print("Added end_node")
        except Exception as e:
            print(f"end_node column error: {e}")

if __name__ == "__main__":
    apply_migration()
