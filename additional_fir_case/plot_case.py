"""Plot the first quota's saved MATLAB coefficients without rerunning allocation."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy.signal import freqz


case_dir = Path(__file__).resolve().parent
result_dir = case_dir / "results_matlab"
ideal = np.loadtxt(result_dir / "ideal_coefficients.csv", delimiter=",")[:, 1]
rows = np.loadtxt(result_dir / "allocations.csv", delimiter=",", skiprows=1)
quota = rows[rows[:, 0] == 1]
assert len(ideal) == 48 and quota.shape[0] == 48
assert np.array_equal(quota[:, 1].astype(int), np.arange(1, 49))
assert np.allclose(quota[:, 2], ideal)

f, href = freqz(ideal, worN=65536, fs=2)
_, hdp = freqz(quota[:, 4], worN=65536, fs=2)
_, hgreedy = freqz(quota[:, 6], worN=65536, fs=2)

def magnitude_db(h):
    return 20 * np.log10(np.maximum(np.abs(h), np.finfo(float).tiny))

fig, axes = plt.subplots(2, 1, figsize=(8.2, 5.7), constrained_layout=True)
series = [("Floating-point", href, "#444444", "-"),
          ("DP, [24,16,8]", hdp, "#0067a8", "-"),
          ("Greedy, [24,16,8]", hgreedy, "#b44a26", "--")]
for label, h, color, style in series:
    db = magnitude_db(h)
    axes[0].plot(f, db, style, color=color, label=label, linewidth=1.4)
    axes[1].plot(f, db, style, color=color, label=label, linewidth=1.4)

axes[0].set(xlim=(0, 0.32), ylim=(-0.4, 0.4),
            ylabel="Magnitude (dB)", title="48-tap low-pass: passband")
axes[0].axhline(0.25, color="#888888", linestyle=":", linewidth=1)
axes[0].axhline(-0.25, color="#888888", linestyle=":", linewidth=1)
axes[0].axvline(0.3, color="#888888", linestyle=":", linewidth=1)
axes[0].legend(loc="lower left", fontsize=8)
axes[1].set(xlim=(0.4, 1.0), ylim=(-90, -25),
            xlabel="Normalized frequency (×π rad/sample)",
            ylabel="Magnitude (dB)", title="Stopband (requirement: ≤ −40 dB)")
axes[1].axhline(-40, color="#888888", linestyle=":", linewidth=1)
for ax in axes:
    ax.grid(alpha=0.2)
out = result_dir / "frequency_response_quota1.png"
fig.savefig(out, dpi=180)
print(out)
