from pydantic import BaseModel
from typing import Optional


class SensorReadingIn(BaseModel):
    timestamp: str
    voltage: float
    sensor_id: str = "IR-CH4-001"


class DetectionResultOut(BaseModel):
    last_updated: str
    sensor_reading: float
    status: str
    severity: str
    leak_probability: float
    confidence: float
    anomaly_score: float
    response_time_ms: int
    alert_active: bool
    consecutive_abnormal_samples: int


class LogEvent(BaseModel):
    timestamp: str
    sensor_reading: float
    status: str
    severity: str
    leak_probability: float
    confidence: float
    anomaly_score: float
    sensor_id: Optional[str] = "IR-CH4-001"