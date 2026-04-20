import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import time

# Initialize Firebase Admin
try:
    cred = credentials.Certificate('methane-guard-firebase-adminsdk-fbsvc-317639f3f5.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("[SUCCESS] Connected to Firestore (Raw Data Mode)")
except Exception as e:
    print(f"[ERROR] {e}")
    exit(1)

# Load the dataset
CSV_PATH = "lab_processed_dataset.csv"
df = pd.read_csv(CSV_PATH)

print("\n[INFO] Sensor Simulator: Pushing RAW data to Firestore...")
current_index = 2470 # Start near the leak for the demo

while True:
    if current_index >= len(df):
        current_index = 0
    
    row = df.iloc[current_index]
    
    # RAW PAYLOAD ONLY (No AI logic here)
    payload = {
        "voltage": float(row["Voltage"]),
        "leak_type_raw": int(row["Leak_Type"]), # We keep this for the API to verify
        "sent_at": int(time.time() * 1000),
        "timestamp": firestore.SERVER_TIMESTAMP
    }

    try:
        # Push to the 'raw_sensor_data' collection
        db.collection('raw_sensor_data').document('latest').set(payload)
        print(f"[RAW TX] Row {current_index} | Voltage: {payload['voltage']}V | Sent to 'raw_sensor_data'")
    except Exception as e:
        print(f"[ERROR] {e}")

    current_index += 1
    time.sleep(1.5)
