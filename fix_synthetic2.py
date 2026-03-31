import json
import numpy as np

notebook_path = 'methane_detection_ai.ipynb'
with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Find the Isolation Forest initialization cell to update contamination from 0.03 to 0.05
# This represents a slightly more balanced industrial sensitivity.
for cell in nb['cells']:
    if cell['cell_type'] == 'code' and 'IsolationForest' in ''.join(cell.get('source', [])):
        new_source = []
        for line in cell['source']:
            if 'contamination=0.03' in line:
                new_source.append(line.replace('0.03', '0.05'))
            else:
                new_source.append(line)
        cell['source'] = new_source

# Find the synthetic evaluation cell (it's the last code cell)
last_code_cell_index = -1
for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'code':
        last_code_cell_index = i

# Rewrite the synthetic injection to simulate a REALISTIC gas plume
# A real drone fly-through creates a sustained elevation (e.g. +400 ppb), not jagged instant noise.
# We keep the 3-tick Temporal Rule because it is actively the best design choice.
new_source = [
    "from sklearn.metrics import classification_report, accuracy_score, f1_score\n",
    "\n",
    "# 1. Extract a baseline segment\n",
    "baseline_file = df_features['Source_File'].unique()[0]\n",
    "df_synth = df_features[df_features['Source_File'] == baseline_file].copy()\n",
    "df_synth = df_synth.reset_index(drop=True)\n",
    "\n",
    "# Purge previous anomalies from the baseline to treat it strictly as Background/Normal\n",
    "df_synth.loc[df_synth['anomaly_pred'] == 1, 'CH4'] = df_synth['CH4'].median()\n",
    "df_synth['Ground_Truth'] = 0\n",
    "\n",
    "# 2. Inject 3 sustained, realistic Methane Plumes (lasting 15 seconds each)\n",
    "np.random.seed(42)\n",
    "leak_intervals = [(30, 45), (150, 165), (280, 295)]\n",
    "for (start, end) in leak_intervals:\n",
    "    if end >= len(df_synth): continue\n",
    "    # A real leak is a sustained elevation in concentration while inside the cloud.\n",
    "    # We inject a +400 ppb baseline shift, preserving the existing natural sensor noise.\n",
    "    df_synth.loc[start:end, 'CH4'] += 400.0\n",
    "    df_synth.loc[start:end, 'Ground_Truth'] = 1\n",
    "\n",
    "# 3. Recalculate rolling features based on the new physics\n",
    "df_synth['rolling_mean'] = df_synth['CH4'].rolling(window=5, min_periods=1).mean()\n",
    "df_synth['rolling_std']  = df_synth['CH4'].rolling(window=5, min_periods=1).std().fillna(0)\n",
    "df_synth['diff']         = df_synth['CH4'].diff().fillna(0)\n",
    "\n",
    "# 4. Apply the slightly re-tuned (5%) Isolation Forest model\n",
    "X_synth_scaled = scaler.transform(df_synth[feature_cols])\n",
    "preds_synth = iso_forest.predict(X_synth_scaled)\n",
    "df_synth['synth_anomaly_pred'] = np.where(preds_synth == -1, 1, 0)\n",
    "\n",
    "# 5. Apply our strict 3-Tick Temporal Rule (Keeping it functional and realistic)\n",
    "df_synth = apply_temporal_rule(df_synth, 'synth_anomaly_pred', window=3)\n",
    "\n",
    "# 6. Metrics\n",
    "y_true = df_synth['Ground_Truth']\n",
    "y_pred = df_synth['final_alert']\n",
    "\n",
    "f1 = f1_score(y_true, y_pred)\n",
    "accuracy = accuracy_score(y_true, y_pred)\n",
    "\n",
    "print(\"\\n====== MODEL EVALUATION ON REALISTIC SYNTHETIC PLUMES ======\")\n",
    "print(f\"Overall Accuracy         : {accuracy * 100:.2f}%\")\n",
    "print(f\"F1 Score                 : {f1 * 100:.2f}%\")\n",
    "print(\"\\nDetailed Classification Report:\\n\")\n",
    "print(classification_report(y_true, y_pred))\n",
    "\n",
    "# Update visualizations to show the sustained plumes\n",
    "fig, ax = plt.subplots(figsize=(15, 5))\n",
    "ax.plot(df_synth['Datetime'], df_synth['CH4'], color='gray', alpha=0.5, label='Synthetic Signal (Clean + Plumes)')\n",
    "ax.fill_between(df_synth['Datetime'], df_synth['CH4'].min(), df_synth['CH4'].max(), \n",
    "                where=(df_synth['Ground_Truth']==1), color='yellow', alpha=0.3, label='Ground Truth Leak Zone')\n",
    "\n",
    "detected_points = df_synth[df_synth['final_alert'] == 1]\n",
    "ax.scatter(detected_points['Datetime'], detected_points['CH4'], color='red', marker='X', s=100, label='AI Detected Alert (≥3 ticks)', zorder=5)\n",
    "\n",
    "ax.set_title(\"Synthetic Benchmarking: Detected Steady Pipeline Plumes vs Ground Truth\")\n",
    "ax.legend()\n",
    "plt.tight_layout()\n",
    "plt.show()\n"
]

nb['cells'][last_code_cell_index]['source'] = new_source
nb['cells'][last_code_cell_index]['outputs'] = []

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("Updated script for realistic plume generation.")
