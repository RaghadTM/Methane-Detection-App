from app.firebase_config import db


def save_raw_reading(data: dict):
    db.collection("raw_readings").add(data)


def save_detection_result(data: dict):
    db.collection("detections").add(data)


def update_live_status(data: dict):
    db.collection("system").document("live_status").set(data)


def get_recent_results(limit: int = 3):
    docs = (
        db.collection("detections")
        .order_by("created_at", direction="DESCENDING")
        .limit(limit)
        .stream()
    )

    return [doc.to_dict() for doc in docs]


def get_all_detection_logs():
    docs = (
        db.collection("detections")
        .order_by("created_at", direction="DESCENDING")
        .stream()
    )

    return [doc.to_dict() for doc in docs]