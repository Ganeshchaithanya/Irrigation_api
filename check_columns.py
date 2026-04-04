import os
import psycopg2
from dotenv import load_dotenv

def check_columns():
    load_dotenv()
    db_url = os.getenv("DATABASE_URL")
    
    if not db_url:
        print("Error: DATABASE_URL not found in .env")
        return
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'devices'")
        columns = [c[0] for c in cur.fetchall()]
        print(f"Columns in 'devices' table: {columns}")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error checking columns: {e}")

if __name__ == "__main__":
    check_columns()
