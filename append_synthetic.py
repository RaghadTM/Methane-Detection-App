import json

notebook_path = 'methane_detection_ai.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Create Markdown cell for the Introduction to Synthetic Evaluation
md_cell = {
    "cell_type": "markdown",
    "metadata": {},
    "source": [
        "## 10. Quantitative Evaluation via Synthetic Leak Injection\n",
        "\n",
        "As established, the real `MATRIX_Dataset` lacks per-millisecond \"Ground Truth\" labels mapping exactly where a methane pipeline leak started and stopped. Therefore, applying standard supervised metrics (Accuracy/F1) to the raw data is scientifically invalid, as it lacks a $y_{true}$ array.\n",
        "\n",
        "To provide a rigorous **Score out of 100** suitable for an academic software engineering evaluation, we perform **Synthetic Anomaly Injection**. \n",
        "1. We extract a baseline \"clean\" signal (noise, wind, drone movement, but no leaks).\n",
        "2. We computationally inject mathematically known, severe methane spikes representing real physical pipeline breaches.\n",
        "3. Since we injected them, we now possess the perfect Ground Truth label array.\n",
        "4. We evaluate our pre-configured Unsupervised Isolation Forest pipeline against these known anomalies to derive an F1 score and Accuracy %."
    ]
}

# Create Code cell to perform the injection and evaluation
code_cell = {
    "cell_type": "code",
    "execution_count": None,
    "metadata": {},
    "outputs": [],
    "source": [
        "from sklearn.metrics import classification_report, accuracy_score, f1_score\n",
        "\n",
        "# 1. Extract a baseline segment of relatively clean data\n",
        "baseline_file = df_features['Source_File'].unique()[0]\n",
        "df_synth = df_features[df_features['Source_File'] == baseline_file].copy()\n",
        "\n",
        "# Make sure we start strictly clean by wiping out earlier accidental anomalies from the baseline\n",
        "median_baseline = df_synth['CH4'].median()\n",
        "df_synth['CH4'] = np.where(df_synth['anomaly_pred'] == 1, median_baseline, df_synth['CH4'])\n",
        "\n",
        "# Initialize Ground Truth strictly as Normal (0)\n",
        "df_synth['Ground_Truth'] = 0\n",
        "\n",
        "# 2. Inject Artificial Leaks at specific intervals (simulating sudden pipeline ruptures)\n",
        "np.random.seed(42)\n",
        "n_samples = len(df_synth)\n",
        "num_leaks = 5  # Synthesize 5 separate leak events\n",
        "leak_duration = 8  # ticks/seconds per leak\n",
        "\n",
        "for i in range(num_leaks):\n",
        "    # Randomly select a start point avoiding boundaries\n",
        "    start_idx = np.random.randint(10, n_samples - 20)\n",
        "    end_idx = start_idx + leak_duration\n",
        "    \n",
        "    # Inject a massive step-function spike simulating a sudden 1500+ ppb concentration rise\n",
        "    # plus some random noise typical of sensor saturation\n",
        "    spike_profile = 2000 + np.random.normal(scale=100, size=leak_duration)\n",
        "    df_synth.iloc[start_idx:end_idx, df_synth.columns.get_loc('CH4')] += spike_profile\n",
        "    \n",
        "    # Annotate our absolute Ground Truth\n",
        "    df_synth.iloc[start_idx:end_idx, df_synth.columns.get_loc('Ground_Truth')] = 1\n",
        "\n",
        "# 3. Re-run our established Feature Engineering pipeline to extract rolling dynamics of the injected signal\n",
        "df_synth['rolling_mean'] = df_synth['CH4'].rolling(window=5, min_periods=1).mean()\n",
        "df_synth['rolling_std']  = df_synth['CH4'].rolling(window=5, min_periods=1).std().fillna(0)\n",
        "df_synth['diff']         = df_synth['CH4'].diff().fillna(0)\n",
        "\n",
        "# 4. Evaluate with our Pre-trained Isolation Forest Model\n",
        "X_synth_scaled = scaler.transform(df_synth[feature_cols])\n",
        "preds_synth = iso_forest.predict(X_synth_scaled)\n",
        "df_synth['synth_anomaly_pred'] = np.where(preds_synth == -1, 1, 0)\n",
        "\n",
        "# Apply our crucial 3-Tick Temporal Consistency Filter just like the main pipeline\n",
        "df_synth = apply_temporal_rule(df_synth, 'synth_anomaly_pred', window=3)\n",
        "\n",
        "# 5. Generate Scoring Metrics against Ground Truth\n",
        "y_true = df_synth['Ground_Truth']\n",
        "y_pred = df_synth['final_alert']\n",
        "\n",
        "f1 = f1_score(y_true, y_pred)\n",
        "accuracy = accuracy_score(y_true, y_pred)\n",
        "\n",
        "print(\"====== MODEL EVALUATION ON SYNTHETIC LEAK INJECTION ======\")\n",
        "print(f\"Overall Accuracy         : {accuracy * 100:.2f}%\")\n",
        "print(f\"F1 Score (Harmonic Mean) : {f1 * 100:.2f}%\")\n",
        "print(\"\\nDetailed Classification Report:\\n\")\n",
        "print(classification_report(y_true, y_pred))\n",
        "\n",
        "# For the final plot, show the injected leaks overlaid with our detections\n",
        "fig, ax = plt.subplots(figsize=(15, 5))\n",
        "ax.plot(df_synth['Datetime'], df_synth['CH4'], color='gray', alpha=0.5, label='Synthetic Signal (Clean + Injected)')\n",
        "ax.fill_between(df_synth['Datetime'], df_synth['CH4'].min(), df_synth['CH4'].max(), \n",
        "                where=(df_synth['Ground_Truth']==1), color='yellow', alpha=0.3, label='Ground Truth Leak Zone')\n",
        "\n",
        "detected_points = df_synth[df_synth['final_alert'] == 1]\n",
        "ax.scatter(detected_points['Datetime'], detected_points['CH4'], color='red', marker='X', s=100, label='AI Detected Alert', zorder=5)\n",
        "\n",
        "ax.set_title(\"Synthetic Benchmarking: Detected Pipeline Leaks vs Ground Truth\")\n",
        "ax.legend()\n",
        "plt.tight_layout()\n",
        "plt.show()\n"
    ]
}

# Find the conclusion cell, we want to insert these before the final markdown conclusion or at the end.
# We'll just append it to the end for simplicity
nb['cells'].append(md_cell)
nb['cells'].append(code_cell)

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("Successfully injected Synthetic Evaluation Protocol into methane_detection_ai.ipynb")
