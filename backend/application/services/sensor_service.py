from sqlalchemy.orm import Session
from models.sensor import SensorData
from models.device import Device
from models.analytics import ETData
from schemas.sensor import SensorDataCreate
from fastapi import HTTPException

# Basic proxy for Evapotranspiration
def calculate_et_proxy(temperature: float, humidity: float) -> float:
    base_et = 0.1
    temp_factor = max(0.01, (temperature - 10) * 0.02)
    humid_factor = max(0.01, (100 - humidity) * 0.01)
    proxy = base_et + temp_factor * humid_factor
    return max(0.0, proxy)

def create_sensor_data(db: Session, data: SensorDataCreate):
    # Lookup the exact UUID based on the string the hardware transmitted (esp_test_002)
    device = db.query(Device).filter(Device.device_uid == data.device_id).first()
    if not device:
        # If the device isn't registered on the Farm yet, block it
        raise HTTPException(status_code=404, detail=f"Device identifier '{data.device_id}' not found in the Database! Please register this device to a Zone first.")

    db_data = SensorData(
        device_id=device.id,
        timestamp=data.timestamp,
        soil_moisture=data.soil_moisture,
        temperature=data.temperature,
        humidity=data.humidity,
        flow=data.flow,
        water_consumed=data.water_consumed,
        solar_voltage=data.solar_voltage,
        battery_percentage=data.battery_percentage
    )
    db.add(db_data)
    db.commit()
    db.refresh(db_data)
    
    # Calculate and store ET derived from this reading
    if device.zone_id:
        et_val = calculate_et_proxy(data.temperature, data.humidity)
        db_et = ETData(
            zone_id=device.zone_id,
            timestamp=data.timestamp,
            et_value=et_val
        )
        db.add(db_et)
        db.commit()

    return db_data

def get_latest_sensor_data(db: Session, device_id):
    return db.query(SensorData).filter(SensorData.device_id == device_id).order_by(SensorData.timestamp.desc()).first()

def get_sensor_history(db: Session, device_id, limit: int = 48):
    """Return last N readings for chart display, oldest first."""
    return (
        db.query(SensorData)
        .filter(SensorData.device_id == device_id)
        .order_by(SensorData.timestamp.desc())
        .limit(limit)
        .all()
    )

def get_latest_by_zone(db: Session, zone_id):
    """Return latest reading from each device in a zone."""
    from models.device import Device
    devices = db.query(Device).filter(Device.zone_id == zone_id).all()
    results = []
    for device in devices:
        latest = get_latest_sensor_data(db, device.id)
        if latest:
            results.append(latest)
    return results
