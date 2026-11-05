# Exact assignment baseline

- Baseline: binary assignment MILP solved by MATLAB intlinprog (25.1.0.2943329 (R2025a)); all 108 solves reported zero absolute/relative optimality gap and one branch-and-bound node.
- Cases: 108 existing FIR configurations.
- All certified objective values match DP within stated numerical tolerance: yes.
- Maximum absolute objective gap: 4.3368086899420177e-19.
- Median full-operation time: 2.3322 ms for MILP; 0.02615 ms for DP. Median per-case MILP/DP ratio: 78.94x; DP faster in 108/108 cases.
- Timing: warmup then five repetitions, median; each method includes cost construction, optimization and result extraction. MATLAB function/JIT overhead is included.
- All per-case times, quotas and solver certificates are in `assignment_baseline_results.csv`.
- This is implementation-specific evidence for MATLAB R2025a and the tested 108 small cases, not a general complexity advantage or novelty result. See `BASELINE_ANALYSIS.md`.
