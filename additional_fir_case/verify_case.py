"""Independently recheck saved MATLAB allocation and response results."""

import csv
from pathlib import Path

import numpy as np
from scipy.signal import freqz


directory = Path(__file__).resolve().parent / "results_matlab"
ideal = np.loadtxt(directory / "ideal_coefficients.csv", delimiter=",")[:, 1]
alloc = np.loadtxt(directory / "allocations.csv", delimiter=",", skiprows=1)
with (directory / "method_metrics.csv").open(newline="") as stream:
    metrics_rows = list(csv.DictReader(stream))

assert ideal.shape == (48,)
assert len(metrics_rows) == 9
assert alloc.shape == (48 * 3, 11)
def response_metrics(h):
    frequency, response = freqz(h, worN=65536, fs=2)
    pass_db = 20 * np.log10(np.maximum(np.abs(response[frequency <= 0.3]),
                                    np.finfo(float).tiny))
    stop_db = 20 * np.log10(np.max(np.abs(response[frequency >= 0.4])))
    return float(np.max(np.abs(pass_db))), float(np.max(pass_db)-np.min(pass_db)), float(stop_db)


assert response_metrics(ideal)[0] <= 0.25
assert response_metrics(ideal)[2] <= -40

column_map = {"DP": (3, 4), "greedy": (5, 6), "MILP": (7, 8)}
for row in metrics_rows:
    quota_id = int(row["quota_id"])
    selected = alloc[alloc[:, 0] == quota_id]
    assert selected.shape == (48, 11)
    assert np.array_equal(selected[:, 1].astype(int), np.arange(1, 49))
    assert np.allclose(selected[:, 2], ideal, rtol=0, atol=1e-14)
    width_col, coefficient_col = column_map[row["method"]]
    widths = selected[:, width_col].astype(int)
    quantized = selected[:, coefficient_col]
    counts = [int(np.count_nonzero(widths == bits)) for bits in (16, 8, 4)]
    assert counts == [int(row[key]) for key in ("n16", "n8", "n4")]
    scale = np.power(2.0, widths-1)
    assert np.allclose(quantized, np.round(ideal*scale)/scale,
                       rtol=0, atol=1e-14)
    assert np.isclose(np.sum((ideal-quantized)**2),
                      float(row["coefficient_sse"]), rtol=1e-10, atol=1e-14)
    pass_abs, pass_pp, stop_peak = response_metrics(quantized)
    for calculated, key in ((pass_abs, "passband_max_abs_db"),
                            (pass_pp, "passband_peak_to_peak_db"),
                            (stop_peak, "stopband_peak_db")):
        assert np.isclose(calculated, float(row[key]), rtol=1e-8, atol=1e-8), key
    assert np.isclose(np.max(np.abs(quantized-quantized[::-1])),
                      float(row["max_symmetry_error"]), atol=1e-14)
    assert (pass_abs <= 0.25 and stop_peak <= -40) == bool(int(row["meets_spec"]))

for quota_id in range(1, 4):
    rows = {row["method"]: row for row in metrics_rows
            if int(row["quota_id"]) == quota_id}
    dp = float(rows["DP"]["coefficient_sse"])
    greedy = float(rows["greedy"]["coefficient_sse"])
    milp = float(rows["MILP"]["coefficient_sse"])
    assert np.isclose(dp, milp, rtol=0, atol=1e-12)
    assert dp <= greedy + 1e-12

print("Verified 48-tap reference, 3 quotas, 9 method rows, assignments, coefficient SSE, and frequency responses.")
