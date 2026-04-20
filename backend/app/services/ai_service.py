from pathlib import Path
from collections import deque
import pandas as pd
from sklearn.ensemble import RandomForestClassifier, IsolationForest

BASE_DIR = Path(__file__).resolve().parents[2]   # backend/
WINDOW_SIZE = 10

recent_voltages = deque(maxlen=WINDOW_SIZE)

rf_model = None
iso_model = None
rf_classes = None


def train_ai_models():
    global rf_model, iso_model, rf_classes

    dataset_path = BASE_DIR / "lab_processed_dataset.csv"
    df = pd.read_csv(dataset_path, low_memory=False)

    # خلي أسماء الأعمدة بدون فراغات زيادة
    df.columns = df.columns.str.strip()

    # لو الداتا فيها عمودين فقط، نشتغل عليهم مباشرة
    # المتوقّع: واحد للقراءة/الفولت وواحد لليبل
    value_col = None
    label_col = None

    possible_value_cols = ["voltage", "Voltage", "sensor_reading", "reading", "value"]
    possible_label_cols = ["label", "Label", "Leak_Type", "Leak Type", "status", "Status"]

    for col in possible_value_cols:
        if col in df.columns:
            value_col = col
            break

    for col in possible_label_cols:
        if col in df.columns:
            label_col = col
            break

    if value_col is None:
        # إذا أول عمود هو القراءة
        value_col = df.columns[0]

    if label_col is None:
        # إذا ثاني عمود هو الليبل
        if len(df.columns) < 2:
            raise ValueError("Dataset must contain at least 2 columns")
        label_col = df.columns[1]

    df = df[[value_col, label_col]].copy()
    df[value_col] = pd.to_numeric(df[value_col], errors="coerce")
    df = df.dropna()

    # نولّد نفس فكرة النوتبوك: ميزات مشتقة من القراءة
    df["rolling_mean"] = df[value_col].rolling(window=3, min_periods=1).mean()
    df["diff"] = df[value_col].diff().fillna(0)
    df["rolling_std"] = df[value_col].rolling(window=3, min_periods=1).std().fillna(0)

    X = df[[value_col, "rolling_mean", "diff", "rolling_std"]]
    y = df[label_col].astype(str)

    rf_model = RandomForestClassifier(
        n_estimators=100,
        random_state=42
    )
    rf_model.fit(X, y)
    rf_classes = list(rf_model.classes_)

    iso_model = IsolationForest(
        contamination=0.1,
        random_state=42
    )
    iso_model.fit(X)


def predict_with_ai(voltage: float):
    global rf_model, iso_model, rf_classes

    if rf_model is None or iso_model is None:
        raise ValueError("AI models are not trained yet")

    recent_voltages.append(voltage)

    values = list(recent_voltages)
    rolling_mean = sum(values) / len(values)
    diff = 0.0 if len(values) == 1 else values[-1] - values[-2]

    if len(values) > 1:
        mean_val = rolling_mean
        variance = sum((v - mean_val) ** 2 for v in values) / len(values)
        rolling_std = variance ** 0.5
    else:
        rolling_std = 0.0

    sample = pd.DataFrame([{
        "voltage": voltage,
        "rolling_mean": rolling_mean,
        "diff": diff,
        "rolling_std": rolling_std
    }])

    # أثناء التدريب استخدمنا اسم العمود الحقيقي من الداتا
    trained_feature_names = list(rf_model.feature_names_in_)
    rename_map = {"voltage": trained_feature_names[0]}
    sample = sample.rename(columns=rename_map)
    sample = sample[trained_feature_names]

    prediction = rf_model.predict(sample)[0]
    probabilities = rf_model.predict_proba(sample)[0]
    confidence = float(max(probabilities) * 100)

    anomaly_flag = iso_model.predict(sample)[0]
    anomaly_score = float(-iso_model.score_samples(sample)[0])

    leak_probability = confidence if prediction.lower() != "no leak" else max(0.0, 100 - confidence)

    if confidence >= 85:
        severity = "High"
    elif confidence >= 60:
        severity = "Medium"
    else:
        severity = "Low"

    return {
        "status": str(prediction),
        "severity": severity,
        "confidence": round(confidence, 2),
        "leak_probability": round(leak_probability, 2),
        "anomaly_score": round(anomaly_score, 2),
        "alert_active": prediction.lower() != "no leak" or anomaly_flag == -1,
        "consecutive_abnormal_samples": len([v for v in values if v < rolling_mean]) if values else 0
    }