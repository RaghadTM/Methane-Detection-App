import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import time
import random

# Initialize Firebase Admin
try:
    cred = credentials.Certificate('methane-guard-firebase-adminsdk-fbsvc-317639f3f5.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("[SUCCESS] Connected to Firestore successfully!")
except Exception as e:
    print(f"[ERROR] Failed to connect to Firestore: {e}")
    print("Make sure your JSON key is in the same folder as this script!")
    exit(1)

# Load the dataset
CSV_PATH = "lab_processed_dataset.csv"
try:
    df = pd.read_csv(CSV_PATH)
    print(f"[SUCCESS] Loaded dataset: {len(df)} rows")
except Exception as e:
    print(f"[ERROR] Failed to load dataset: {e}")
    exit(1)

print("\n[INFO] Starting Live Data Stream to Cloud...")
print("Press Ctrl+C to stop.\n")

current_index = 0
consecutive_anomalies = 0

while True:
    if current_index >= len(df):
        current_index = 0 # Loop dataset
    
    row = df.iloc[current_index]
    current_index += 1

    leak_type = int(row["Leak_Type"])
    is_anomaly = leak_type > 0
    
    if is_anomaly:
        consecutive_anomalies += 1
    else:
        consecutive_anomalies = 0

    is_alarm = consecutive_anomalies >= 3
    
    leak_speed = "N/A"
    if leak_type == 1:
        leak_speed = "Gradual"
    elif leak_type == 2:
        leak_speed = "Sudden / Burst"

    status_text = "Normal Operation"
    if is_alarm:
        status_text = f"ALARM: {leak_speed.upper()} LEAK"
    elif consecutive_anomalies > 0:
        status_text = f"Anomaly Detected ({consecutive_anomalies}/3)"

    voltage_display = round(row["Voltage"], 3)
    
    # Dynamic metrics
    response_time = f"{0.05 + (random.random() * 0.07):.2f}s"
    
    probability = round(1.8 + (random.random() * 0.6), 1)
    if is_alarm:
        probability = min(99.9, 85.0 + (consecutive_anomalies * 0.1) + (random.random() * 0.5))
    elif consecutive_anomalies > 0:
        probability = round(40.0 + (consecutive_anomalies * 15.0) + (random.random() * 2.0), 1)

    payload = {
        "index": int(current_index),
        "timestamp": firestore.SERVER_TIMESTAMP,
        "sent_at": int(time.time() * 1000), # Local millisecond timestamp
        "voltage": f"{voltage_display} V",
        "probability": f"{probability}%",
        "status": status_text,
        "severity": "High" if is_alarm else ("Medium" if is_anomaly else "Low"),
        "leak_speed": leak_speed,
        "is_alarm": bool(is_alarm),
        "anomaly_count": int(consecutive_anomalies),
        "response_time": response_time
    }

    try:
        # Push to Firestore collection 'sensor_stream'
        db.collection('sensor_stream').document('latest').set(payload)
        
        # Also add to a history collection for the logs page
        db.collection('sensor_stream_history').add(payload)
        
        print(f"[TX] Transmitted Row {current_index} | Voltage: {voltage_display}V | Status: {status_text}")
    except Exception as e:
        print(f"[WARNING] Failed to transmit: {e}")

    # Simulate hardware transmission delay
    time.sleep(1.5)
