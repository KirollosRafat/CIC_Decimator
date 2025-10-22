import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# --- Parameters ---
fs = 6_000_000        # Sampling frequency = 6 MHz
f_sine = 100_000      # Input sine frequency = 100 kHz
num_samples = 2000    # Total samples
amplitude = 64        # Peak amplitude for 8-bit signed
bit_width = 8         # Match Verilog INPUTWIDTH

# --- Time base ---
t = np.arange(num_samples) / fs

# --- Generate sine wave ---
sine_wave = amplitude * np.sin(2 * np.pi * f_sine * t)

# --- Quantize to signed integer range ---
max_val = 2**(bit_width-1) - 1
min_val = -2**(bit_width-1)
sine_wave_q = np.clip(np.round(sine_wave), min_val, max_val).astype(int)

# --- Save to file for Verilog testbench ---
np.savetxt("input.txt", sine_wave_q, fmt="%d")

# --- Optional check ---
print(f"Generated {len(sine_wave_q)} samples in range [{sine_wave_q.min()}, {sine_wave_q.max()}]")

# --- Plot ---
plt.figure(figsize=(10,4))
plt.plot(sine_wave_q, 'b')
plt.title("Quantized 100 kHz Sine Wave (5000 samples @ 6 MHz)")
plt.xlabel("Sample Index")
plt.ylabel("Amplitude")
plt.grid(True)
plt.tight_layout()
plt.show()
