# Exact Assignment Baseline Analysis

Date: 2026-11-04

## Formulation and baseline

For each coefficient `i` and width `j` in `{16,8,4}`, the cost is
`c(i,j) = (h(i)-Q(h(i),j))^2`. Binary `x(i,j)` minimizes the sum of these
costs, subject to one selected width per coefficient and exact width counts.
This is a unit-capacity transportation / bipartite min-cost-flow formulation:
source-to-coefficient arcs have capacity one, coefficient-to-width arcs have
capacity one and cost `c(i,j)`, and width-to-sink arcs have capacity equal to
the corresponding quota. Sending `N` units satisfies all exact quotas.

The tested generic exact baseline was MATLAB R2025a Optimization Toolbox
`intlinprog` on the equivalent binary assignment MILP. This is a solver
baseline, not a hand-coded min-cost-flow implementation. The same 108 saved
coefficient/quota cases from `extended_validation_results.mat` were used.

## Results

- All 108 MILP solves returned positive solver status and zero reported
  absolute and relative MIP gap; all solves used one branch-and-bound node.
- DP and MILP objective values agreed within floating-point evaluation
  difference; maximum absolute difference was `4.3368e-19`.
- Median of per-case five-repeat runtimes: MILP `2.3322 ms`, DP `0.02615 ms`.
- Median per-case MILP/DP runtime ratio: `78.94x`; DP was faster in all 108
  cases, with ratios from `5.84x` to `191.66x`.
- Each method was warmed up, then timed for five repetitions. Both timed
  operations include cost calculation, model/DP construction, solve, and
  result extraction. Times include MATLAB/JIT overhead and describe these
  implementations on this machine only.

Raw per-case data and solver certificates are in
`assignment_baseline_results.csv`; script: `../run_assignment_baseline.m`.
The earlier pilot folder `../assignment_baseline_20261104/` used an option
removed by the active MATLAB solver algorithm and emitted a warning. Its data
are retained as an audit trail but are superseded by this clean final run.

## Interpretation limits

This comparison confirms the model's exact assignment interpretation and
shows a runtime advantage for this DP implementation on the tested 8-, 16-,
and 32-tap cases relative to MATLAB `intlinprog`. It does not establish a
general runtime advantage over min-cost-flow algorithms, specialized
assignment solvers, other MILP solvers, or larger problem sizes. It does not
establish algorithmic novelty. A separate OR-Tools/network-simplex baseline
was not run. The board tests address hardware functional agreement and do not
serve as evidence for solver quality or runtime.
