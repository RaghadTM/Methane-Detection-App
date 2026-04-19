import math
from collections import deque

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest, RandomForestClassifier
from sklearn.model_selection import train_test_split

BASELINE_VOLTAGE = 3.069943
WINDOW_SIZE = 10

recent_voltages = deque(maxlen=WINDOW_SIZE)

rf_model = None
iso_model = None
rf_classes = None


def train_ai_models():
    global rf_model, iso_model, rf_classes

    df = pd.read_csv("Lab_processed_dataset.csv")

    required_columns = ["Absorbance", "rolling_mean", "diff", "rolling_std", "Leak_Type"]
    for col in required_columns:
        if col not in df.columns:
            raise ValueError(f"Missing required column in dataset: {col}")

    X = df[["Absorbance", "rolling_mean", "diff", "rolling_std"]]
    y = df["Leak_Type"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
    rf_model.fit(X_train, y_train)

    iso_model = IsolationForest(contamination=0.1, random_state=42)
    iso_model.fit(X)

    rf_classes = list(rf_model.classes_)

    print("AI models trained successfully.")
    print(f"RandomForest classes: {rf_classes}")


def extract_features(voltage: float):
    recent_voltages.append(voltage)

    absorbance = math.log(BASELINE_VOLTAGE / voltage) if voltage > 0 else 0.0
    diff = 0.0 if len(recent_voltages) < 2 else voltage - list(recent_voltages)[-2]
    rolling_mean = float(np.mean(recent_voltages))
    rolling_std = float(np.std(recent_voltages))

    return {
        "Absorbance": absorbance,
        "rolling_mean": rolling_mean,
        "diff": diff,
        "rolling_std": rolling_std,
    }


def map_prediction_to_status_and_severity(prediction_label: str, confidence: float):
    label = str(prediction_label).strip().lower()

    if "no leak" in label or "normal" in label or "safe" in label:
        return "No Leak", "Low"

    if "high" in label or confidence >= 85:
        return "Leak Detected", "High"

    return "Leak Detected", "Medium"


def predict_with_ai(voltage: float):
    if rf_model is None or iso_model is None:
        raise RuntimeError("AI models are not trained yet. Call train_ai_models() first.")

    features = extract_features(voltage)

    feature_vector = [[
        features["Absorbance"],
        features["rolling_mean"],
        features["diff"],
        features["rolling_std"],
    ]]

    rf_prediction = rf_model.predict(feature_vector)[0]

    if hasattr(rf_model, "predict_proba"):
        probs = rf_model.predict_proba(feature_vector)[0]
        confidence = float(np.max(probs) * 100)
        leak_probability = confidence if "leak" in str(rf_prediction).lower() else 100 - confidence
    else:
        confidence = 85.0
        leak_probability = 85.0 if "leak" in str(rf_prediction).lower() else 15.0

    iso_prediction = iso_model.predict(feature_vector)[0]
    iso_score_raw = float(iso_model.decision_function(feature_vector)[0])


    anomaly_score = round(max(0.0, min(1.0, 0.5 - iso_score_raw)), 4)

    status, severity = map_prediction_to_status_and_severity(rf_prediction, confidence)


    if iso_prediction == -1 and status == "No Leak":
        status = "Leak Detected"
        severity = "Medium"
        leak_probability = max(leak_probability, 60.0)
        confidence = max(confidence, 75.0)

    drop_percentage = ((BASELINE_VOLTAGE - voltage) / BASELINE_VOLTAGE) * 100

    return {
        "status": status,
        "severity": severity,
        "leak_probability": round(float(leak_probability), 2),
        "confidence": round(float(confidence), 2),
        "anomaly_score": anomaly_score,
        "drop_percentage": round(float(drop_percentage), 2),
        "ai_prediction": str(rf_prediction),
        "features": features,
    }