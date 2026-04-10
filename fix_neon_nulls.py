import psycopg2
import os

def fix_neon_data():
    # DATABASE_URL from your Railway/Neon logs
    db_url = "postgresql://neondb_owner:npg_xAKgmlD4w7fs@ep-nameless-dawn-a11rrj5d-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        print("Fixing NULL values in Neon Postgres (node_data)...")
        cur.execute("UPDATE node_data SET valve_status = FALSE WHERE valve_status IS NULL")
        nodes_fixed = cur.rowcount
        
        cur.execute("UPDATE node_data SET commanded_state = FALSE WHERE commanded_state IS NULL")
        commands_fixed = cur.rowcount

        print("Fixing NULL values in Neon Postgres (master_data)...")
        cur.execute("UPDATE master_data SET valve_status = FALSE WHERE valve_status IS NULL")
        master_fixed = cur.rowcount

        conn.commit()
        cur.close()
        conn.close()

        print(f"DONE! Fixed {nodes_fixed} valve_status in node_data.")
        print(f"DONE! Fixed {commands_fixed} commanded_state in node_data.")
        print(f"DONE! Fixed {master_fixed} valve_status in master_data.")
        
    except Exception as e:
        print(f"Error connecting to Neon: {e}")

if __name__ == "__main__":
    fix_neon_data()
