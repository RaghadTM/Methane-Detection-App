import csv
import time
import requests
from datetime import datetime

API_URL = "http://127.0.0.1:8000/sensor-reading"
CSV_FILE = "0.csv"   # غيريه إلى 00.csv أو 1.csv حسب السيناريو
SEND_INTERVAL = 2    # كل ثانيتين

def load_voltages(csv_file):
    voltages = []

    with open(csv_file, "r", encoding="utf-8") as f:
        reader = csv.reader(f)

        for row in reader:
            if len(row) < 2:
                continue

            try:
                voltage = float(row[1])
                voltages.append(voltage)
            except:
                continue

    return voltages

def run_simulation():
    voltages = load_voltages(CSV_FILE)

    print(f"Loaded {len(voltages)} readings from {CSV_FILE}")

    for voltage in voltages:
        payload = {
            "timestamp": datetime.utcnow().isoformat(),
            "voltage": voltage,
            "sensor_id": "IR-CH4-001"
        }

        try:
            response = requests.post(API_URL, json=payload)
            print("Sent:", payload)
            print("Status:", response.status_code)
            print("Response:", response.text)
            print("-" * 50)
        except Exception as e:
            print("Request failed:", e)

        time.sleep(SEND_INTERVAL)

if __name__ == "__main__":
    run_simulation()