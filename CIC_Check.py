import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# --- Load log files (one value per line) ---
inp = pd.read_csv("input.txt", header=None, names=["value"],sep='\s+')
out = pd.read_csv("output.txt", header=None, names=["value"],sep='\s+')

#out['value'] = out['value'].replace(['x','X'],0)
out["value"] = pd.to_numeric(out["value"], errors="coerce").fillna(0)

# --- Create subplots ---
fig, axes = plt.subplots(2, 1, figsize=(10, 6), sharex=False)

# --- Input signal ---
axes[0].plot(inp["value"], color='blue')
axes[0].set_title("Input Signal")
axes[0].set_ylabel("Amplitude")
axes[0].grid(True)

# --- Output signal ---
axes[1].plot(out["value"], color='orange')
axes[1].set_title("Output Signal (Decimated)")
axes[1].set_xlabel("Sample Index")
axes[1].set_ylabel("Amplitude")
axes[1].grid(True)

# --- Layout ---
plt.tight_layout()
plt.show()

# -- Decimation Check--
D_verilog = 4 # Verilog Simulation Based
D_py = len(inp)/len(out)
error_pct = (abs(D_verilog - D_py) / D_verilog) * 100

print("Input samples :", len(inp))
print("Output samples:", len(out))
print(f"Decimation Factor Calculated = {D_py:0.2f}\n")
print(f"Decimation Factor Percenatge Error = {error_pct:0.2f} %\n")