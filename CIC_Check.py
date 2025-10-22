import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load input and output logs
inp = pd.read_csv("input.txt", header=None, names=["value"], sep="\s+")
out = pd.read_csv("output.txt", header=None, names=["value"], sep="\s+")

# --- Optional: Decimation check ---
D_py = len(inp) / len(out)
print(f"Input samples : {len(inp)}")
print(f"Output samples: {len(out)}")
print(f"Measured Decimation Factor ≈ {D_py:.2f}")

# --- Plot Input and Output ---
fig, axes = plt.subplots(2, 1, figsize=(8, 5), sharex=False)

axes[0].plot(inp["value"],'blue')
axes[0].set_title("Input Quantized Sine Wave (6 MHz Sampling)")
axes[0].set_ylabel("Amplitude")
axes[0].grid(True)

axes[1].plot(out["value"],'red')
axes[1].set_title("CIC Filter Output (Decimated)")
axes[1].set_xlabel("Sample Index")
axes[1].set_ylabel("Amplitude")
axes[1].grid(True)

plt.tight_layout()
plt.show()


