import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import firwin, remez, lfilter, freqz
import pandas as pd

# ---------------------------------------------------------------
# CIC Impulse Response
# ---------------------------------------------------------------
def cic_decimator_impulse_response(D=8, N=5, M=1, apply_fir_comp=False):
    """
    Generate the impulse response of an N-stage CIC decimator.
    """
    L = 1024 * D
    x = np.zeros(L)
    x[0] = 1.0

    # Integrator chain
    y = np.copy(x)
    for _ in range(N):
        y = np.cumsum(y)

    # Downsample
    y = y[::D]

    # Comb chain
    for _ in range(N):
        y = np.concatenate(([0], np.diff(y, n=M)))

    # Normalize
    y /= np.max(np.abs(y))

    # Optional FIR comp (not needed here)
    if apply_fir_comp and D > 1:
        fir_coeffs = firwin(240, 1 / D, window="hamming")
        y = lfilter(fir_coeffs, 1.0, y)

    return y


# ---------------------------------------------------------------
# Compute Filter Metrics
# ---------------------------------------------------------------
def compute_metrics(h, D=8, passband_edge=None):
    """
    Compute passband ripple and stopband attenuation.
    """
    h = np.asarray(h).flatten()  # ensure 1D filter response

    w, H = freqz(h, worN=16384)
    mag = np.abs(H)
    mag_db = 20 * np.log10(mag + 1e-12)

    output_nyq = 0.5 / D
    if passband_edge is None:
        passband_edge = 0.8 * output_nyq

    freqs = w / (2 * np.pi)
    pass_idx = freqs <= passband_edge
    stop_idx = freqs >= output_nyq

    pb_mag = mag_db[pass_idx]
    passband_ripple_db = np.max(pb_mag) - np.min(pb_mag)

    stop_mag = mag_db[stop_idx]
    stopband_att_db = -np.min(stop_mag)

    return {
        "passband_ripple_db": passband_ripple_db,
        "stopband_att_db": stopband_att_db,
        "output_nyq": output_nyq,
        "passband_edge": passband_edge
    }


# ---------------------------------------------------------------
# Main Analysis Routine
# ---------------------------------------------------------------
def cic_fir_analysis(D=8, N=5, fir_taps=401):
    """
    Full CIC + FIR compensation analysis.
    """
    # Generate CIC impulse (h)
    h_cic = cic_decimator_impulse_response(D=D, N=N, M=1, apply_fir_comp=True)

    # Compute CIC metrics
    cic_metrics = compute_metrics(h_cic, D)
    print(f"CIC only (N={N}, D={D}):")
    print(f"  Passband ripple = {cic_metrics['passband_ripple_db']:.4f} dB")
    print(f"  Stopband attenuation = {cic_metrics['stopband_att_db']:.4f} dB\n")

    # Design equiripple FIR compensation
    output_nyq = cic_metrics["output_nyq"]
    passband_edge = cic_metrics["passband_edge"]

    bands = [0, passband_edge, output_nyq, 0.5]
    desired = [1, 0]
    weights = [1, 50]

    try:
        h_fir = remez(fir_taps, bands, desired, weight=weights, fs=1.0)
    except Exception:
        print("⚠️ remez failed, fallback to firwin")
        h_fir = firwin(fir_taps, passband_edge * 2, window="hamming")

    # Apply FIR to CIC response
    h_total = lfilter(h_fir, 1.0, h_cic)
    metrics_total = compute_metrics(h_total, D)

    print(f"CIC + {fir_taps}-tap FIR Compensation:")
    print(f"  Passband ripple = {metrics_total['passband_ripple_db']:.4f} dB (limit <= 0.5 dB)")
    print(f"  Stopband attenuation = {metrics_total['stopband_att_db']:.4f} dB (limit >= 60 dB)")

    # Plot response
    w, H = freqz(h_cic, worN=32768)
    plt.figure(figsize=(9, 4))
    plt.plot(w / (2 * np.pi), 20 * np.log10(np.abs(H) + 1e-12),'b')
    plt.axvline(metrics_total["output_nyq"], color="r", linestyle="--", label="Output Nyquist")
    plt.axvline(metrics_total["passband_edge"], color="g", linestyle=":", label="Passband Edge")
    plt.title(f"CIC + FIR Compensation (N={N}, D={D}, FIR={fir_taps} taps)")
    plt.xlabel("Normalized Frequency")
    plt.ylabel("Magnitude (dB)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()

    # Save FIR coefficients as a Pandas DataFrame
    coeffs_path = "fir_compensation_coeffs.csv"
    pd.DataFrame(h_fir, columns=["coeff"]).to_csv(coeffs_path, index=False)
    print(f"\n✅ FIR coefficients saved to {coeffs_path}")

    return metrics_total


# ---------------------------------------------------------------
# Run example
# ---------------------------------------------------------------
if __name__ == "__main__":
    results = cic_fir_analysis(D=2, N=4)
    with open("Specs_Check.txt", "w") as f:
        f.write(str(results))

