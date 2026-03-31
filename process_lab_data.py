import pandas as pd
import numpy as np
import os

# Configuration
data_dir = r'C:\Users\maram\OneDrive\Desktop\methane\newdataset'
baseline_v = 3.069  # Target baseline from students

def process_lab_file(filename, label):
    path = os.path.join(data_dir, filename)
    # Skip the metadata rows (header is Time,Channel A)
    df = pd.read_csv(path, skiprows=2, names=['Time', 'Voltage'])
    
    # 1. Downsample for efficiency (1.25M rows is overkill for AI trend analysis)
    # We take every 500th sample
    df = df.iloc[::500, :].copy()
    
    # 2. Transform to Absorbance (Beer-Lambert)
    # A = ln(V_baseline / V_measured)
    # Use baseline_v as reference
    df['Absorbance'] = np.log(baseline_v / df['Voltage'].clip(lower=0.1))
    
    # 3. Handle noise (Clip negative absorbance if voltage fluctuates slightly above baseline)
    df['Absorbance'] = df['Absorbance'].clip(lower=0)
    
    # 4. Feature Engineering
    df['rolling_mean'] = df['Absorbance'].rolling(window=5).mean()
    df['diff'] = df['Absorbance'].diff()
    df['rolling_std'] = df['Absorbance'].rolling(window=5).std()
    
    df['Leak_Type'] = label
    return df.dropna()

# Process all files
print("Processing Baseline...")
df_baseline = process_lab_file('00.csv', 0)

print("Processing Leaks 0-4...")
leak_dfs = []
for i in range(5):
    # For now, let's treat these as "Lab Leaks" (Label 2 for Sudden/Strong)
    # because the drop is quite sharp in the files
    leak_dfs.append(process_lab_file(f'{i}.csv', 2))

# Combine for training
df_final = pd.concat([df_baseline] + leak_dfs, ignore_index=True)

# Save processed dataset
output_path = r'C:\Users\maram\OneDrive\Desktop\methane\lab_processed_dataset.csv'
df_final.to_csv(output_path, index=False)

print(f"SUCCESS: Created processed lab dataset with {len(df_final)} samples.")
print(f"Location: {output_path}")
