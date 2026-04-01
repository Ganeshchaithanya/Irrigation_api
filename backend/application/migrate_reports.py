from sqlalchemy import text
from core.database import engine

def migrate():
    with engine.connect() as conn:
        print("Adding harvest_date column to zones table...")
        conn.execute(text('ALTER TABLE zones ADD COLUMN IF NOT EXISTS harvest_date TIMESTAMP'))
        
        print("Creating reports table if not exists...")
        # Actually, let's just let metadata.create_all handle new tables, 
        # but we need to ensure the reports table is created since it's new.
        from models.report import Report
        Report.__table__.create(engine, checkfirst=True)
        
        print("Adding CUSTOM value to reporttype enum...")
        try:
            conn.execute(text("ALTER TYPE reporttype ADD VALUE 'CUSTOM'"))
        except Exception as e:
            print(f"Note: Could not add CUSTOM to enum (might already exist): {e}")
        
        conn.commit()
    print("Migration complete!")

if __name__ == "__main__":
    migrate()
