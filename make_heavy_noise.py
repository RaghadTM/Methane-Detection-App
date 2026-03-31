import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, f1_score

# Load
path = r'C:\Users\maram\OneDrive\Desktop\methane\lab_processed_dataset.csv'
df = pd.read_csv(path)

# HEAVY NOISE (Simulating industrial interference)
np.random.seed(42)
# Adding 10% noise relative to the baseline
noise = np.random.normal(0, 0.15, len(df)) 
df['Voltage'] = df['Voltage'] + noise

# Recalculate Absorbance
df['Absorbance'] = np.log(3.069 / df['Voltage'].clip(lower=0.1))
df['Absorbance'] = df['Absorbance'].clip(lower=0)

# Re-engineer rolling features on the NOISY signal
df['rolling_mean'] = df['Absorbance'].rolling(window=5).mean()
df['diff'] = df['Absorbance'].diff()
df['rolling_std'] = df['Absorbance'].rolling(window=5).std()
df = df.dropna()

# Eval
X = df[["Absorbance", "rolling_mean", "diff", "rolling_std"]]
y = df["Leak_Type"]
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

rf = RandomForestClassifier(n_estimators=100, random_state=42)
rf.fit(X_train, y_train)

y_pred = rf.predict(X_test)
acc = accuracy_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred, pos_label=2)

# Save
df.to_csv(path, index=False)

print("--- HEAVY NOISE RESULTS ---")
print(f"Testing Accuracy: {acc*100:.2f}%")
print(f"Testing F1-Score: {f1*100:.2f}%")
