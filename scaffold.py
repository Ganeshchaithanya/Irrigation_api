import os
from pathlib import Path

base = Path(r"c:\Users\chait\OneDrive\Documents\Irrigation_api\backend\application")

dirs = [
    "core",
    "models",
    "schemas",
    "routes",
    "services",
    "workers",
    "utils",
]

files = [
    "main.py",
    "core/config.py",
    "core/database.py",
    "core/security.py",
    "models/user.py",
    "models/farm.py",
    "models/device.py",
    "models/sensor.py",
    "models/irrigation.py",
    "models/command.py",
    "models/state.py",
    "schemas/sensor.py",
    "schemas/irrigation.py",
    "schemas/command.py",
    "schemas/auth.py",
    "routes/sensor.py",
    "routes/irrigation.py",
    "routes/command.py",
    "routes/farm.py",
    "routes/auth.py",
    "services/sensor_service.py",
    "services/decision_service.py",
    "services/irrigation_service.py",
    "services/command_service.py",
    "services/state_service.py",
    "services/analytics_service.py",
    "workers/tasks.py",
    "utils/helpers.py",
]

for d in dirs:
    (base / d).mkdir(parents=True, exist_ok=True)
    (base / d / "__init__.py").touch(exist_ok=True)

for f in files:
    (base / f).touch(exist_ok=True)

print("Scaffolding complete.")
