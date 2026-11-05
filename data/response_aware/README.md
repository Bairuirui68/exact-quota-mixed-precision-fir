# Small exhaustive screening for a stopband-weighted objective

Run from MATLAB at the project root with `addpath('additional_fir_case'); run_weighted_screening`. The script exhaustively checks all assignments for five 8-tap coefficient vectors and two quotas, comparing the coefficient-SSE optimum with the optimum of a sampled stopband-integrated squared complex-response error, `e' * R * e`. The frequency-response stopband peak is measured separately.

## Filter definitions

- `LP_narrow`: `firpm(7,[0 0.2 0.3 1],[1 1 0 0],[1 3])`; stopband 0.3 pi to pi.
- `LP_wide`: `firpm(7,[0 0.3 0.5 1],[1 1 0 0],[1 2])`; stopband 0.5 pi to pi.
- `LP_tight`: 8-tap Hamming-window low-pass from `fir1(7,0.25,...)`; evaluated stopband 0.3 pi to pi.
- `HP_LS`: an 8-tap real-coefficient least-squares high-pass fit, not constrained to linear phase; evaluated stopband 0 to 0.4 pi and passband target region 0.6 to 0.95 pi. A conventional even-length symmetric linear-phase FIR cannot have nonzero response at Nyquist, so this replaces the originally planned windowed high-pass.
- `BP`: `firpm` band-pass with stopbands 0 to 0.2 pi and 0.7 pi to pi.

Each filter uses exact quotas [4,2,2] and [3,3,2]. There are 420 and 560 feasible assignments, respectively. Equal-cost ties use a deterministic lexicographic rule; the script compares the selected optimum allocations, not the full sets of tied optima.

## Results

| Filter | Quota | SSE stop peak | Weighted-opt stop peak | Allocation differs and peak improves? |
|---|---|---:|---:|---|
| LP_narrow | [4,2,2] | -18.00 dB | -18.00 dB | No |
| LP_narrow | [3,3,2] | -17.99 dB | -17.99 dB | No |
| LP_wide | [4,2,2] | -19.65 dB | -20.32 dB | Yes |
| LP_wide | [3,3,2] | -19.49 dB | -20.28 dB | Yes |
| LP_tight | [4,2,2] | -5.59 dB | -5.59 dB | No |
| LP_tight | [3,3,2] | -5.60 dB | -5.60 dB | No |
| HP_LS | [4,2,2] | -5.10 dB | -5.29 dB | Yes |
| HP_LS | [3,3,2] | -5.10 dB | -5.26 dB | Yes |
| BP | [4,2,2] | -10.33 dB | -11.48 dB | Yes |
| BP | [3,3,2] | -10.34 dB | -11.47 dB | Yes |

The predeclared screening threshold (at least 3 of 10 cases with a different selected allocation and a lower stopband peak) is met in 6 of 10 cases. This is an exploratory screening result, not evidence that a 48-tap MIQP will improve results or that the objective meets response specifications. The 8-tap stopband peaks remain poor in absolute terms; the test only compares relative peaks. There are five filter designs, not ten independent designs, because each design is tested at two quotas. The HP_LS filter is a custom non-linear-phase least-squares design. No passband compliance, hardware cost, timing, power, or larger-filter solution is established by this screening.

Full allocations and metrics: `screening_results.csv`; saved MATLAB objects: `screening_data.mat`.
