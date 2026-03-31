from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import time
import os

app = FastAPI()

# Enable CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the dataset
CSV_PATH = r"c:\Users\maram\OneDrive\Desktop\methane\lab_processed_dataset.csv"
df = pd.read_csv(CSV_PATH)

# Global state
state = {
    "current_index": 0,
    "consecutive_anomalies": 0,
    "is_running": False
}

@app.get("/")
async def root():
    # Auto-start on first hit
    if not state["is_running"]:
        state["is_running"] = True
    return {
        "message": "Lab Simulator Active",
        "is_running": state["is_running"]
    }

@app.get("/status")
async def get_status():
    # Force start if requested
    if not state["is_running"]:
        state["is_running"] = True

    # Simulate network latency
    time.sleep(0.05) 

    idx = state["current_index"]
    if idx >= len(df):
        state["current_index"] = 0 # Loop dataset for continuous demo
    
    row = df.iloc[idx]
    state["current_index"] += 1

    leak_type = int(row["Leak_Type"])
    is_anomaly = leak_type > 0
    
    if is_anomaly:
        state["consecutive_anomalies"] += 1
    else:
        state["consecutive_anomalies"] = 0

    is_alarm = state["consecutive_anomalies"] >= 3
    
    # Leak Speed logic from Dataset
    leak_speed = "N/A"
    if leak_type == 1:
        leak_speed = "Gradual"
    elif leak_type == 2:
        leak_speed = "Sudden / Burst"

    status_text = "Normal Operation"
    if is_alarm:
        status_text = f"ALARM: {leak_speed.upper()} LEAK"
    elif state["consecutive_anomalies"] > 0:
        status_text = f"Anomaly Detected ({state['consecutive_anomalies']}/3)"

    voltage_display = round(row["Voltage"], 3)
    
    import random
    response_time = f"{0.05 + (random.random() * 0.07):.2f}s"
    
    probability = round(1.8 + (random.random() * 0.6), 1)
    if is_alarm:
        probability = min(99.9, 85.0 + (state["consecutive_anomalies"] * 0.1) + (random.random() * 0.5))
    elif state["consecutive_anomalies"] > 0:
        probability = round(40.0 + (state["consecutive_anomalies"] * 15.0) + (random.random() * 2.0), 1)

    return {
        "is_running": True,
        "index": idx,
        "timestamp": str(row["Time"]),
        "voltage": f"{voltage_display} V",
        "probability": f"{probability}%",
        "status": status_text,
        "severity": "High" if is_alarm else ("Medium" if is_anomaly else "Low"),
        "leak_speed": leak_speed,
        "is_alarm": is_alarm,
        "anomaly_count": state["consecutive_anomalies"],
        "response_time": response_time
    }

@app.post("/start")
async def start_experiment(start_index: int = 0):
    state["current_index"] = start_index
    state["consecutive_anomalies"] = 0
    state["is_running"] = True
    return {"message": "Started"}

@app.post("/stop")
async def stop_experiment():
    state["current_index"] = 0
    state["is_running"] = False
    return {"message": "Stopped"}

@app.post("/trigger_leak")
async def trigger_leak():
    remaining_df = df.iloc[state["current_index"]:]
    leak_indices = remaining_df[remaining_df["Leak_Type"] > 0].index
    if not leak_indices.empty:
        state["current_index"] = int(leak_indices[0]) - 2
        return {"message": "Triggered"}
    return {"message": "No more leaks"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
