# 48-tap exact linearized MIQP run status

## Formulation checks

- Uses the saved corrected case-A 48-tap coefficient vector and quota `[24,16,8]`.
- The objective is the sampled stopband-integrated squared complex-response error `e' * R * e`, with all nonzero pairwise terms retained. Product variables enforce exact binary products with the three standard linear inequalities.
- The model has 144 width-selection binaries, 10,152 product binaries, 51 equalities, and 30,456 product inequalities. HiGHS presolve reported 30,507 rows, 10,296 columns, and 71,352 nonzeros.
- A known-feasible SSE-DP allocation was supplied as an `intlinprog` initial point. Its linearized objective was `7.46026156513e-6`, matching direct `e' * R * e` to the script assertion tolerance. An independent expansion check differed from the direct objective by `5.08e-21`; the sampled matrix's minimum eigenvalue was approximately `1.95e-16`.

## Run outcome

The warm-started solve was manually interrupted after approximately 93 seconds of solver time because the root lower bound remained near `-5.637e-4` while the incumbent stayed at `7.4603e-6`; the reported relative gap was about 7,656%, with no branch-and-bound nodes explored. The run did not establish global optimality and did not emit the MATLAB `exitflag` or the script's final `Decision` line because Ctrl+C terminated the MATLAB batch process. Record this as **incomplete / optimality not proved**, not as a completed MIQP result.

The initially attempted unseeded run was also interrupted early and is superseded by the warm-started run. No response-aware allocation or improvement claim follows from either run. The weak relaxation indicates that this direct pairwise-product MILP is not practically certifying the 48-tap optimum in its current form.

The script is `additional_fir_case/run_miqp_linearized.m`. Its configured maximum remains one hour, but the tested run was stopped early under the agreed slow-progress condition. No output allocation was saved.
