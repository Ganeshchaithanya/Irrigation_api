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
            conn.execute(text("ALTER TABLE users ADD COLUMN hashed_password VARCHAR;"))
            print("Added hashed_password to users")
        except Exception as e:
            print(f"hashed_password column: {e}")
            
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN auth_provider VARCHAR DEFAULT 'local';"))
            print("Added auth_provider to users")
        except Exception as e:
            print(f"auth_provider column: {e}")

if __name__ == "__main__":
    apply_migration()
