import os
import psycopg2
from dotenv import load_dotenv

def apply_schema():
    load_dotenv()
    db_url = os.getenv("DATABASE_URL")
    
    if not db_url:
        print("Error: DATABASE_URL not found in .env")
        return

    sql = """
-- ================================
-- 0. BACKUP OLD DATA (OPTIONAL)
-- ================================
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sensor_data') THEN
        EXECUTE 'CREATE TABLE IF NOT EXISTS sensor_data_backup AS SELECT * FROM sensor_data';
    END IF;
END $$;

-- ================================
-- 1. DROP OLD TABLE
-- ================================
DROP TABLE IF EXISTS sensor_data CASCADE;

-- ================================
-- 2. NODE DATA TABLE
-- ================================
CREATE TABLE IF NOT EXISTS node_data (
    id SERIAL PRIMARY KEY,

    device_id VARCHAR(50) REFERENCES devices(device_uid), -- Changed to device_uid to match current setup if needed, but let's check first
    zone_id VARCHAR(50),

    soil_moisture DOUBLE PRECISION,

    battery_percentage DOUBLE PRECISION,
    solar_voltage DOUBLE PRECISION,
    solar_efficiency DOUBLE PRECISION,

    valve_status BOOLEAN,
    commanded_state BOOLEAN,

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- 3. ZONE DATA TABLE
-- ================================
CREATE TABLE IF NOT EXISTS zone_data (
    id SERIAL PRIMARY KEY,

    zone_id VARCHAR(50),

    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION,

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- 4. MASTER DATA TABLE
-- ================================
CREATE TABLE IF NOT EXISTS master_data (
    id SERIAL PRIMARY KEY,

    flow_rate DOUBLE PRECISION,
    water_consumed DOUBLE PRECISION,

    is_raining BOOLEAN,

    battery_percentage DOUBLE PRECISION,
    solar_voltage DOUBLE PRECISION,
    solar_efficiency DOUBLE PRECISION,

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- 5. RAW LOG TABLE (OPTIONAL)
-- ================================
CREATE TABLE IF NOT EXISTS sensor_data_raw (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50),
    type VARCHAR(20),
    payload JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================
-- 6. INDEXES
-- ================================
CREATE INDEX IF NOT EXISTS idx_node_device ON node_data(device_id);
CREATE INDEX IF NOT EXISTS idx_node_zone ON node_data(zone_id);
CREATE INDEX IF NOT EXISTS idx_zone_zone ON zone_data(zone_id);

-- ================================
-- 7. CONSTRAINTS
-- ================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE table_name='node_data' AND constraint_name='soil_range'
    ) THEN
        ALTER TABLE node_data
        ADD CONSTRAINT soil_range CHECK (soil_moisture BETWEEN 0 AND 100);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.constraint_column_usage
        WHERE table_name='node_data' AND constraint_name='battery_range'
    ) THEN
        ALTER TABLE node_data
        ADD CONSTRAINT battery_range CHECK (battery_percentage BETWEEN 0 AND 100);
    END IF;
END $$;
"""

    # Wait, the user had: device_id VARCHAR(50) REFERENCES devices(device_id)
    # But in our model devices table has 'device_uid'. 
    # Let's check the current devices table columns before running.
    
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # Check column name in devices table
        cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'device_id'")
        has_device_id = cur.fetchone()
        
        if not has_device_id:
            print("Notice: 'devices' table uses 'device_uid' or other column. Adjusting SQL to match 'device_uid'.")
            sql = sql.replace("REFERENCES devices(device_id)", "REFERENCES devices(device_uid)")

        print("Applying SQL Schema...")
        cur.execute(sql)
        conn.commit()
        print("Schema applied successfully!")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error applying schema: {e}")

if __name__ == "__main__":
    apply_schema()
