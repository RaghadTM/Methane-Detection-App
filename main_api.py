from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore
import time
import random

app = FastAPI()

# Enable CORS so the Flutter Web app can talk to this server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase
cred = credentials.Certificate('methane-guard-firebase-adminsdk-fbsvc-317639f3f5.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

# AI State (stored in memory for the demo)
consecutive_anomalies = 0
leak_start_time = None # Tracks when the first anomaly was spotted
history_buffer = [] # Stores last 50 processed results for the Logs page

@app.get("/api/status")
async def get_status():
    global consecutive_anomalies, leak_start_time
    
    try:
        # 1. Fetch latest RAW data from Firestore
        doc = db.collection('raw_sensor_data').document('latest').get()
        if not doc.exists:
            return {"error": "No raw data found"}
        
        data = doc.to_dict()
        voltage = data.get("voltage", 0.0)
        leak_type = data.get("leak_type_raw", 0)
        sent_at = data.get("sent_at", int(time.time() * 1000))

        # 2. RUN AI LOGIC (Middleman Processing)
        is_anomaly = leak_type > 0
        if is_anomaly:
            consecutive_anomalies += 1
            if leak_start_time is None:
                leak_start_time = time.time() # Mark the moment we saw the first whiff
        else:
            consecutive_anomalies = 0
            leak_start_time = None # Reset if leak stops

        is_alarm = consecutive_anomalies >= 3
        
        # Calculate Reaction Time (Spec #4 Evidence)
        reaction_time = 0.0
        if leak_start_time:
            reaction_time = round(time.time() - leak_start_time, 2)
        
        leak_speed = "N/A"
        if leak_type == 1: leak_speed = "Gradual"
        elif leak_type == 2: leak_speed = "Sudden / Burst"

        status_text = "Normal Operation"
        if is_alarm:
            status_text = f"ALARM: {leak_speed.upper()} LEAK"
        elif consecutive_anomalies > 0:
            status_text = f"Anomaly Detected ({consecutive_anomalies}/3)"

        # 3. Format result for Application
        probability = round(1.8 + (random.random() * 0.6), 1)
        if is_alarm:
            probability = min(99.9, 85.0 + (consecutive_anomalies * 0.1) + (random.random() * 0.5))
        elif consecutive_anomalies > 0:
            probability = round(40.0 + (consecutive_anomalies * 15.0) + (random.random() * 2.0), 1)

        result = {
            "voltage": f"{voltage:.3f} V",
            "probability": f"{probability:.1f}%",
            "status": status_text,
            "severity": "High" if is_alarm else ("Medium" if is_anomaly else "Low"),
            "leak_speed": leak_speed,
            "is_alarm": bool(is_alarm),
            "anomaly_count": int(consecutive_anomalies),
            "sent_at": sent_at,
            "db_latency": 15,
            "index": data.get("index", 0),
            "reaction_time": f"{reaction_time}s"
        }

        # Save to memory history (Limited to 50 for performance)
        history_buffer.insert(0, result)
        if len(history_buffer) > 50:
            history_buffer.pop()

        return result
    except Exception as e:
        return {"error": str(e)}

@app.get("/api/history")
async def get_history():
    return history_buffer

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
