from contextlib import asynccontextmanager
from datetime import datetime
from app.services.ai_service import train_ai_models, predict_with_ai
import time

from fastapi import FastAPI

from app.models import SensorReadingIn
from app.services.ai_service import train_ai_models, predict_with_ai
from app.services.firestore_service import (
    save_raw_reading,
    save_detection_result,
    update_live_status,
    get_recent_results,
    get_all_detection_logs,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    print("AI training started...")
    train_ai_models()
    print("AI training finished.")
    yield


app = FastAPI(title="MethaneGuard API", lifespan=lifespan)


@app.get("/")
def root():
    return {"message": "MethaneGuard backend is running"}


@app.post("/sensor-reading")
def receive_sensor_reading(reading: SensorReadingIn):
    start_time = time.time()

    raw_data = {
        "timestamp": reading.timestamp,
        "voltage": reading.voltage,
        "sensor_id": reading.sensor_id,
        "created_at": datetime.utcnow(),
    }
    save_raw_reading(raw_data)

    result = predict_with_ai(reading.voltage)

    detection_doc = {
        "timestamp": reading.timestamp,
        "sensor_reading": reading.voltage,
        "status": result["status"],
        "severity": result["severity"],
        "leak_probability": result["leak_probability"],
        "confidence": result["confidence"],
        "anomaly_score": result["anomaly_score"],
        "drop_percentage": result["drop_percentage"],
        "ai_prediction": result["ai_prediction"],
        "features": result["features"],
        "sensor_id": reading.sensor_id,
        "created_at": datetime.utcnow(),
    }
    save_detection_result(detection_doc)

    recent_results = get_recent_results(limit=3)

    abnormal_count = 0
    for item in recent_results:
        if item.get("status") == "Leak Detected":
            abnormal_count += 1

    alert_active = abnormal_count >= 3
    response_time_ms = int((time.time() - start_time) * 1000)

    live_status = {
        "last_updated": reading.timestamp,
        "sensor_reading": reading.voltage,
        "status": "Leak Detected" if alert_active else result["status"],
        "severity": "High" if alert_active else result["severity"],
        "leak_probability": result["leak_probability"],
        "confidence": result["confidence"],
        "anomaly_score": result["anomaly_score"],
        "drop_percentage": result["drop_percentage"],
        "ai_prediction": result["ai_prediction"],
        "response_time_ms": response_time_ms,
        "alert_active": alert_active,
        "consecutive_abnormal_samples": abnormal_count,
        "sensor_id": reading.sensor_id,
        "features": result["features"],
    }

    update_live_status(live_status)

    return live_status


@app.get("/live-status")
def get_live_status():
    recent = get_recent_results(limit=1)
    if recent:
        return recent[0]
    return {"message": "No data available yet"}


@app.get("/logs")
def get_logs():
    return get_all_detection_logs()