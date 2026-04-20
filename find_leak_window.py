import pandas as pd

df = pd.read_csv('lab_processed_dataset.csv')
leaks = df[df['Leak_Type'] != 0].index.tolist()

if not leaks:
    print("No leaks found.")
else:
    blocks = []
    current_start = leaks[0]
    for i in range(len(leaks)-1):
        if leaks[i+1] != leaks[i] + 1:
            blocks.append((current_start, leaks[i]))
            current_start = leaks[i+1]
    blocks.append((current_start, leaks[-1]))

    for i, (s, e) in enumerate(blocks):
        duration_sec = (e - s + 1) * 1.5
        print(f"Block {i}: Start {s}, End {e}, Duration {duration_sec:.1f}s ({duration_sec/60:.1f} min)")
