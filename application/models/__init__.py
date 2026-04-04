from .user import User, OtpVerification, UserSession
from .farm import Farm, Acre, Zone
from .device import Device
from .sensor import ZoneData, NodeData, MasterData
from .irrigation import IrrigationLog
from .command import ValveCommand
from .state import ZoneState
from .analytics import DailyAggregate, MonthlyAggregate, YearlyAggregate, PlantHealthScore, ETData
from .ai import AiValidationLog, Prediction, CropPlan
from .chat import ChatLog, MessageTemplate
from .notification import Notification
from .feedback import IrrigationFeedback
from .report import Report, ReportType, ReportStatus
