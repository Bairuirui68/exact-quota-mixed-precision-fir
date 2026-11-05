"""Reproduce the preliminary equiripple length screen for the stated bands."""

import numpy as np
from scipy.signal import freqz, remez


delta_p = (10**(0.5/20)-1)/(10**(0.5/20)+1)
delta_s = 0.01
weights = [1, delta_p/delta_s]

print("taps,passband_peak_to_peak_dB,stopband_peak_dB")
for taps in (16, 32, 48):
    h = remez(taps, [0, 0.3, 0.4, 1], [1, 0], weight=weights, fs=2)
    f, response = freqz(h, worN=65536, fs=2)
    passband = np.abs(response[f <= 0.3])
    stopband = np.abs(response[f >= 0.4])
    pass_pp_db = 20*np.log10(passband.max()/passband.min())
    stop_peak_db = 20*np.log10(stopband.max())
    print(f"{taps},{pass_pp_db:.6f},{stop_peak_db:.6f}")
