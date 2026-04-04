import traceback
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from models.user import User
    from models.farm import Farm, Acre, Zone
    from models.device import Device
    from models.sensor import SensorData
    from models.irrigation import IrrigationLog
    from models.command import ValveCommand
    from models.state import ZoneState
    from models.analytics import DailyAggregate, MonthlyAggregate, YearlyAggregate, PlantHealthScore, ETData
    from models.ai import AiValidationLog, Prediction, CropPlan
    from models.chat import ChatLog, MessageTemplate
    from models.notification import Notification
    from models.feedback import IrrigationFeedback
    print("Import successful")
except Exception as e:
    with open('import_error.txt', 'w', encoding='utf-8') as f:
        traceback.print_exc(file=f)
    print("Import failed. Check import_error.txt")
