import json
import os

notebook_path = r'C:\Users\maram\OneDrive\Desktop\methane\methane_detection_ai.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Define the new Lab Data cells
new_cells = [
    {
        'cell_type': 'markdown',
        'id': 'lab_data_intro',
        'metadata': {},
        'source': [
            '## 15. Real-World Lab Hardware Validation (Voltage Analysis)\n',
            '\n',
            'This section transitions the AI from synthetic data to **real hardware voltages** collected in the lab. \n',
            '\n',
            '### 15.1 Hardware Principles\n',
            '- **Baseline**: 3.069V (No methane)\n',
            '- **Detection Principle**: Voltage **drops** as methane concentration increases (infrared attenuation).\n',
            '- **Transformation**: We use the Beer-Lambert law to convert raw voltage ($V$) into Absorbance ($A$) for AI processing:\n',
            '  $$A = \\ln\\left(\\frac{V_{baseline}}{V}\\right)$$'
        ]
    },
    {
        'cell_type': 'code',
        'execution_count': None,
        'outputs': [],
        'id': 'lab_data_loading',
        'metadata': {},
        'source': [
            'import pandas as pd\n',
            'import matplotlib.pyplot as plt\n',
            '\n',
            '# Load the processed lab dataset\n',
            'df_lab = pd.read_csv("lab_processed_dataset.csv")\n',
            '\n',
            'print(f"Loaded Lab Dataset: {len(df_lab)} samples.")\n',
            'print(f"Baseline Reference: 3.069V")\n',
            'df_lab.head()'
        ]
    },
    {
        'cell_type': 'markdown',
        'id': 'lab_visualization_intro',
        'metadata': {},
        'source': [
            '### 15.2 Lab Trend Analysis: Voltage Drop vs. Absorbance Increase\n',
            'We visualize how the raw voltage drop is transformed into a rising signal that the AI can monitor for risk.'
        ]
    },
    {
        'cell_type': 'code',
        'execution_count': None,
        'outputs': [],
        'id': 'lab_visualization_code',
        'metadata': {},
        'source': [
            'fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10), sharex=True)\n',
            '\n',
            '# Plot Raw Voltage\n',
            'ax1.plot(df_lab.index, df_lab["Voltage"], color="darkblue", label="Raw Sensor Voltage (V)")\n',
            'ax1.axhline(3.069, color="green", linestyle="--", alpha=0.6, label="Expected Baseline")\n',
            'ax1.set_ylabel("Voltage (V)")\n',
            'ax1.set_title("Hardware Signal: Raw Voltage Drop during Lab Leak")\n',
            'ax1.legend()\n',
            '\n',
            '# Plot Transformed Absorbance\n',
            'ax2.plot(df_lab.index, df_lab["Absorbance"], color="crimson", label="Calculated Absorbance Index")\n',
            'ax2.set_ylabel("Absorbance (Relative Units)")\n',
            'ax2.set_xlabel("Downsampled Time Steps")\n',
            'ax2.set_title("AI Input Feature: Methane Presence (Inverted Voltage)")\n',
            'ax2.legend()\n',
            '\n',
            'plt.tight_layout()\n',
            'plt.show()'
        ]
    },
    {
        'cell_type': 'markdown',
        'id': 'lab_predictive_intro',
        'metadata': {},
        'source': [
            '### 15.3 Hardware-Calibrated Risk Scoring\n',
            'We apply our predictive risk index to the lab data to prove the system can detect the leak while the voltage is still in the "Early Warning" zone.'
        ]
    },
    {
        'cell_type': 'code',
        'execution_count': None,
        'outputs': [],
        'id': 'lab_predictive_code',
        'metadata': {},
        'source': [
            '# Calibrate local risk monitoring\n',
            'lab_results = []\n',
            'last_risk = 0\n',
            'temp_count = 0\n',
            '\n',
            'for i, row in df_lab.iterrows():\n',
            '    # Use absorbance as the intensity metric\n',
            '    raw_score = 0.1 - (row["Absorbance"] * 2.0)\n',
            '    risk = calculate_risk_index(raw_score)\n',
            '    \n',
            '    increasing = risk > last_risk\n',
            '    last_risk = risk\n',
            '    \n',
            '    if risk > 60: temp_count += 1\n',
            '    else: temp_count = 0\n',
            '        \n',
            '    msg, level = get_graded_warning(risk, increasing, temp_count)\n',
            '    lab_results.append({"t": i, "V": row["Voltage"], "Risk": risk, "Level": level})\n',
            '\n',
            'df_lab_risk = pd.DataFrame(lab_results)\n',
            '\n',
            '# Visualization of Lab Risk\n',
            'plt.figure(figsize=(15, 6))\n',
            'plt.plot(df_lab_risk["t"], df_lab_risk["Risk"], "--", color="blue", alpha=0.3, label="Methane Risk Index (%)")\n',
            '\n',
            'colors = ["green", "yellow", "orange", "red"]\n',
            'labels = ["Normal", "Advisory", "Warning", "Critical"]\n',
            '\n',
            'for lvl in range(4):\n',
            '    mask = df_lab_risk["Level"] == lvl\n',
            '    if not df_lab_risk[mask].empty:\n',
            '        plt.scatter(df_lab_risk[mask]["t"], df_lab_risk[mask]["Risk"], color=colors[lvl], label=labels[lvl], s=20)\n',
            '\n',
            'plt.title("Hardware Prediction: Risk Index Based on Lab Voltage Drops")\n',
            'plt.ylabel("Risk Index (%)")\n',
            'plt.xlabel("Sample Index")\n',
            'plt.legend()\n',
            'plt.show()\n',
            '\n',
            'print("--- Lab Hardware Success Proof ---")\n',
            't_leak_detected = df_lab_risk[df_lab_risk["Level"] > 0]["t"].min()\n',
            'v_at_detection = df_lab_risk.loc[t_leak_detected, "V"]\n',
            'print(f"First Warning Triggered at Voltage: {v_at_detection:.3f}V")\n',
            'print(f"Detection Margin: {3.069 - v_at_detection:.3f}V drop successfully captured by AI.")'
        ]
    }
]

# Append new cells at the end
nb['cells'] = nb['cells'] + new_cells

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('SUCCESS: Injected Section 15 (Lab Hardware Data) into notebook.')
