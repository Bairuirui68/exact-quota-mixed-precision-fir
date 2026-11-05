# Exact-Quota Mixed-Precision FIR Coefficient Quantization

This repository accompanies the technical report in [`paper/`](paper/). It contains the report source, selected scripts, and the data tables and test vectors needed to inspect or reproduce the reported experiments. The report is deliberately bounded: it does not claim a new optimization class, and it documents negative results and hardware limitations.

## Author

Ruirui Bai, Shanxi University, Taiyuan, China. Contact: `bairuirui0924@163.com`.

## Contents

- `paper/`: seven-page technical report, LaTeX source, bibliography, IEEEtran class, and compiled PDF.
- `extended_validation/`: MATLAB DP/greedy/exhaustive validation source and saved validation data.
- `data/assignment_baseline/`: saved 108-case MILP-versus-DP result tables.
- `additional_fir_case/`: 48-tap MATLAB scripts, allocation data, generated RTL and independent simulation vectors, plus compact routed result summaries.
- `data/robustness_study_corrected/`: saved results for five filter specifications and fifteen quota configurations.
- `data/board_8tap/`: raw board UART functional-comparison CSVs for the 942 reported checks.
- `data/fpga_8tap/`: compact 8-tap routed-resource and timing summaries.
- `data/response_aware/`: screening results and the stopped MIQP run record; the incomplete solve is not presented as an optimum.
- `rtl_8tap/`: selected 8-tap RTL, testbench, constraints, and bit-exact reference vectors.

## Reproducing Key Checks

### MATLAB software validation

Requires MATLAB R2025a or compatible releases; the exact-assignment baselines require Optimization Toolbox (`intlinprog`), and filter design/response functions require Signal Processing Toolbox.

From the repository root, in MATLAB:

```matlab
addpath('extended_validation');
run_small_scale_verification;
run_filter_test_matrix;
run_assignment_baseline;
```

The baseline script writes fresh results to `extended_validation/assignment_baseline_final_20261104/` and stops if that directory already exists, to avoid overwriting evidence.

### 48-tap FIR allocation and response checks

From the repository root, in MATLAB:

```matlab
addpath('extended_validation');
cd additional_fir_case;
run_case;
```

The checked-in allocation data remain in `additional_fir_case/results_matlab/`. The rerun script writes to `results_matlab_recomputed/` and preserves the checked-in data. `run_case` and `run_robustness` use `intlinprog` for exact assignment baselines.

With Python 3, NumPy, SciPy, and Matplotlib installed:

```text
python additional_fir_case/verify_case.py
python additional_fir_case/plot_case.py
python additional_fir_case/plot_paper_response.py
python additional_fir_case/plot_workflow.py
python additional_fir_case/screen_lengths.py
```

The publication figure is generated from the saved coefficient CSVs with
SciPy/Matplotlib and exported as vector PDF/SVG plus a PNG preview in
`paper/figures/`. It uses the same 65,536-point response grid as the reported
metrics; peak values are checked against the saved result table.

### 48-tap RTL simulation and implementation

Requires Xilinx Vivado with XSim and the XC7A35T part support. From Vivado Tcl batch mode, run `additional_fir_case/simulate.tcl` for functional simulation or `additional_fir_case/implement.tcl` for the isolated FIR route. Each script creates a new output directory and refuses to overwrite an existing one. The saved functional vectors and RTL are in `additional_fir_case/rtl/`.

### 8-tap board data

The CSVs in `data/board_8tap/` contain the observations behind the functional-comparison claim. Repeating physical board tests requires the ACX750 board and the separate lab setup; no credentials, bitstreams, or Vivado machine logs are included.

## Important Result Boundaries

- Across five filter designs and fifteen quotas, DP met the stated −40 dB stopband threshold in 2 cases; greedy met it in 0.
- For the 48-tap routed design, overall WNS was negative under the documented I/O assumptions. This was not full timing closure.
- The 48-tap design was simulated and routed, not board-tested; no power, measured Fmax, or sustained-throughput data were collected.
- The response-aware binary-product MILP run was manually stopped after about 93 seconds without proving optimality or returning a final allocation.
- The allocation DP is presented as a structure-specific implementation of a known cost-constrained DP formulation, not as a new optimization principle.

## Software and Data Licensing

Repository code and original data are released under the MIT License in [`LICENSE`](LICENSE). The bundled `paper/IEEEtran.cls` is third-party material and retains its upstream LPPL notices; the repository MIT license does not replace that license.
