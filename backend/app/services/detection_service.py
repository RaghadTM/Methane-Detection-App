def evaluate_reading(voltage: float):
    baseline_voltage = 3.069943
    drop = baseline_voltage - voltage
    drop_percentage = (drop / baseline_voltage) * 100

    if voltage >= 2.90:
        return {
            "status": "No Leak",
            "severity": "Low",
            "leak_probability": 5.0,
            "confidence": 90.0,
            "anomaly_score": 0.10,
            "drop_percentage": round(drop_percentage, 2),
        }

    elif voltage >= 2.40:
        return {
            "status": "Leak Detected",
            "severity": "Medium",
            "leak_probability": 65.0,
            "confidence": 82.0,
            "anomaly_score": 0.65,
            "drop_percentage": round(drop_percentage, 2),
        }

    else:
        return {
            "status": "Leak Detected",
            "severity": "High",
            "leak_probability": 92.0,
            "confidence": 88.0,
            "anomaly_score": 0.91,
            "drop_percentage": round(drop_percentage, 2),
        }