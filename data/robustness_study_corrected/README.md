# FIR allocation robustness study

This MATLAB batch compares the existing coefficient-SSE DP, the existing greedy allocator, and the same `intlinprog` assignment baseline across five FIR designs and three exact width quotas per design. It records coefficient SSE, passband deviation, stopband peak, and the pass/fail result for the stated response limits. Raw rows are in `robustness_results.csv`; each `case_*_data.mat` stores the ideal coefficients, quotas, and reference response.

## Designs

| Case | Taps | Passband edge | Stopband edge | Stopband limit | Floating-point stopband peak |
|---|---:|---:|---:|---:|---:|
| A | 48 | 0.3 pi | 0.4 pi | -40 dB | -49.6705 dB |
| B | 48 | 0.3 pi | 0.4 pi | -50 dB | -56.0952 dB |
| C | 48 | 0.2 pi | 0.3 pi | -40 dB | -51.1866 dB |
| D | 36 | 0.3 pi | 0.4 pi | -40 dB | -40.6194 dB |
| E | 64 | 0.3 pi | 0.4 pi | -40 dB | -62.4633 dB |

All five floating-point prototypes satisfy their stated passband and stopband limits. The originally planned 32-tap case was replaced with 36 taps: with the same equiripple design weighting, the 32-tap floating-point prototype did not meet -40 dB, so it could not isolate quantization-allocation effects under that specification.

The A case reproduces the original 48-tap baseline. The passband design weight uses 0.5 dB peak-to-peak equiripple ripple, corresponding to approximately +/-0.25 dB about unity; this matches `run_case.m`. An initial trial used the wrong ripple interpretation and generated different coefficients. Its outputs are preserved separately under `robustness_study/` and are not part of the corrected results.

## Results

The batch contains 45 rows (5 designs x 3 quotas x 3 methods). DP and MILP coefficient-SSE optima agree in every case within the script's asserted tolerance. The quotas are proportional width counts, rounded to even counts and corrected to sum to the tap count.

| Case | Quota [16,8,4] | DP SSE | Greedy SSE | DP stopband | Greedy stopband | DP passes? | Greedy passes? |
|---|---|---:|---:|---:|---:|---|---|
| A | [24,16,8] | 1.8594e-5 | 6.6658e-5 | -41.30 dB | -35.78 dB | Yes | No |
| A | [16,24,8] | 5.6140e-5 | 1.0712e-4 | -35.32 dB | -33.21 dB | No | No |
| A | [12,24,12] | 9.9346e-5 | 1.2477e-4 | -31.45 dB | -31.06 dB | No | No |
| B | [24,16,8] | 4.0223e-5 | 8.4150e-5 | -35.55 dB | -33.16 dB | No | No |
| B | [16,24,8] | 9.3461e-5 | 1.2359e-4 | -34.02 dB | -31.17 dB | No | No |
| B | [12,24,12] | 1.5603e-4 | 1.5603e-4 | -32.42 dB | -32.42 dB | No | No |
| C | [24,16,8] | 5.4671e-5 | 9.6196e-5 | -34.86 dB | -35.37 dB | No | No |
| C | [16,24,8] | 8.1762e-5 | 1.1573e-4 | -35.32 dB | -32.92 dB | No | No |
| C | [12,24,12] | 1.3172e-4 | 1.5105e-4 | -31.85 dB | -31.87 dB | No | No |
| D | [18,12,6] | 2.2248e-5 | 2.2248e-5 | -35.60 dB | -35.60 dB | No | No |
| D | [12,18,6] | 5.9417e-5 | 5.9417e-5 | -30.75 dB | -30.75 dB | No | No |
| D | [10,16,10] | 3.0234e-4 | 3.0234e-4 | -28.16 dB | -28.16 dB | No | No |
| E | [32,22,10] | 2.2032e-5 | 7.6665e-5 | -40.76 dB | -36.86 dB | Yes | No |
| E | [22,32,10] | 5.4994e-5 | 8.0759e-5 | -36.78 dB | -35.75 dB | No | No |
| E | [16,32,16] | 8.6790e-5 | 9.6841e-5 | -32.85 dB | -34.41 dB | No | No |

## Interpretation and limits

- DP meets both response limits in 2 of 15 design/quota combinations; greedy meets them in 0 of 15. The two DP passes occur for the highest-precision quota in cases A and E.
- This is not a universal frequency-response advantage. In case C's first quota, greedy has a slightly lower stopband peak than DP (-35.37 vs. -34.86 dB), although both fail the -40 dB limit. In case E's third quota, greedy also has a lower stopband peak, while both fail.
- Lower coefficient SSE does not imply a lower stopband peak or compliance with a response specification. This experiment supports a bounded observation about these five prototypes and these proportional quotas only.
- These are software frequency-response calculations. This batch does not synthesize or route the 36-/64-tap variants, measure board behavior, power, Fmax, or throughput. The existing routed 48-tap results apply only to the original case A design and its stated allocation.
- It does not establish a general advantage over standard assignment solvers; MILP is used here to verify the DP objective values, not as a performance study.
