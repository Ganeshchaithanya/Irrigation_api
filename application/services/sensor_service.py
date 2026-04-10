from sqlalchemy.orm import Session
from application.models.sensor import ZoneData, NodeData, MasterData, SensorDataRaw
from application.models.device import Device
from application.models.analytics import ETData
from application.schemas.sensor import SensorDataCreate
from fastapi import HTTPException

# Basic proxy for Evapotranspiration
def calculate_et_proxy(temperature: float, humidity: float) -> float:
    base_et = 0.1
    temp_factor = max(0.01, (temperature - 10) * 0.02)
    humid_factor = max(0.01, (100 - humidity) * 0.01)
    proxy = base_et + temp_factor * humid_factor
    return max(0.0, proxy)

def create_sensor_data(db: Session, data: SensorDataCreate):
    # 0. Raw Log for Hardware Audits
    raw_log = SensorDataRaw(
        device_id=data.device_id,
        type="TELEMETRY",
        payload=data.model_dump()
    )
    db.add(raw_log)

    # Lookup the exact UUID based on the string the hardware transmitted (esp_test_002)
    device = db.query(Device).filter(Device.device_uid == data.device_id).first()
    if not device:
        # If the device isn't registered on the Farm yet, block it
        raise HTTPException(status_code=404, detail=f"Device identifier '{data.device_id}' not found in the Database! Please register this device to a Zone first.")

    # 1. Route data based on Device Role
    result_obj = None

    if device.role == "MASTER":
        # Master device handles system-level metrics
        db_master = MasterData(
            flow_rate=data.flow,
            water_consumed=data.water_consumed,
            is_raining=data.is_raining,
            battery_percentage=data.battery_percentage,
            solar_voltage=data.solar_voltage,
            solar_efficiency=data.solar_efficiency,
            valve_status=bool(data.valve_status),
            timestamp=data.timestamp
        )
        db.add(db_master)
        result_obj = db_master
    
    else:
        # Both LEADER and WORKER nodes send soil data
        db_node = NodeData(
            device_id=device.device_uid, # Use the hardware string identifier
            zone_id=str(device.zone_id),  # Store zone UUID as string for loose coupling
            soil_moisture=data.soil_moisture,
            battery_percentage=data.battery_percentage,
            solar_voltage=data.solar_voltage,
            solar_efficiency=data.solar_efficiency,
            valve_status=bool(data.valve_status),
            commanded_state=bool(data.commanded_state),
            timestamp=data.timestamp
        )
        db.add(db_node)
        result_obj = db_node

        # ONLY the Leader node updates environmental data (per zone)
        if device.role == "LEADER":
            db_zone = ZoneData(
                zone_id=str(device.zone_id),
                temperature=data.temperature,
                humidity=data.humidity,
                timestamp=data.timestamp
            )
            db.add(db_zone)

            # Calculate and store ET derived from this zone-level reading
            if device.zone_id:
                et_val = calculate_et_proxy(data.temperature, data.humidity)
                db_et = ETData(
                    zone_id=str(device.zone_id),
                    timestamp=data.timestamp,
                    et_value=et_val
                )
                db.add(db_et)

    db.commit()
    if result_obj:
        db.refresh(result_obj)
    
    return result_obj

def get_latest_sensor_data(db: Session, device_id):
    """Retrieve latest reading for a specific device (NodeData). Handles UUID or string IDs."""
    target_id = str(device_id)
    # If it's a UUID, we need to find the device_uid first because NodeData stores uids
    if "-" in target_id and len(target_id) > 30:
        device = db.query(Device).filter(Device.id == device_id).first()
        if device:
            target_id = device.device_uid
            
    return db.query(NodeData).filter(NodeData.device_id == target_id).order_by(NodeData.timestamp.desc()).first()

def get_sensor_history(db: Session, device_id, limit: int = 48):
    """Return last N readings for chart display, newest first. Handles UUID or string IDs."""
    target_id = str(device_id)
    if "-" in target_id and len(target_id) > 30:
        device = db.query(Device).filter(Device.id == device_id).first()
        if device:
            target_id = device.device_uid

    return (
        db.query(NodeData)
        .filter(NodeData.device_id == target_id)
        .order_by(NodeData.timestamp.desc())
        .limit(limit)
        .all()
    )

def get_latest_by_zone(db: Session, zone_id):
    """Return latest reading from each device in a zone."""
    devices = db.query(Device).filter(Device.zone_id == zone_id).all()
    results = []
    for device in devices:
        latest = get_latest_sensor_data(db, device.device_uid)
        if latest:
            results.append(latest)
    return results


def get_latest_zone_data(db: Session, zone_id):
    """Return the latest ZoneData (temp/humidity) entry for a zone."""
    return (
        db.query(ZoneData)
        .filter(ZoneData.zone_id == str(zone_id))
        .order_by(ZoneData.timestamp.desc())
        .first()
    )


def get_latest_master_data(db: Session):
    """Return the latest MasterData entry (system-level metrics)."""
    return (
        db.query(MasterData)
        .order_by(MasterData.timestamp.desc())
        .first()
    )

