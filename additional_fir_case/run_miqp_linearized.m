function run_miqp_linearized()
% Decisive 48-tap experiment: band-weighted response allocation via
% linearized MIQP solved with intlinprog.
%
% Formulation
% -----------
% For N taps, K=3 width choices, the stopband-weighted objective is
%   e' * R * e  where e_i = q(h_i, w_i) - h_i.
%
% Each tap i has K binary variables x_{i,k} in {0,1} with sum_k x_{i,k}=1.
% The quantization error for tap i is:
%   e_i = sum_k x_{i,k} * d_{i,k}   where d_{i,k} = Q(h_i, choices(k)) - h_i
%
% The quadratic objective becomes:
%   e'Re = sum_{i,j} R_{ij} * e_i * e_j
%        = sum_{i,j} R_{ij} * sum_k x_{i,k} d_{i,k} * sum_l x_{j,l} d_{j,l}
%        = sum_{i,k} sum_{j,l} (R_{ij} d_{i,k} d_{j,l}) * x_{i,k} * x_{j,l}
%
% For (i,k)=(j,l), terms x_{i,k}*x_{i,k} = x_{i,k} (binary).
% For (i,k)!=(j,l), terms x_{i,k}*x_{j,l} = y_{ikjl} in {0,1}.
%
% Product variable linearization (y = x_a * x_b, x_a,x_b in {0,1}):
%   y <= x_a, y <= x_b, y >= x_a + x_b - 1, y >= 0.
%
% This gives a MILP. We restrict to only the cross-terms where i<j
% (using symmetry R_{ij}=R_{ji}, and dropping terms where coefficient
% is near-zero to keep model size tractable).
%
% Stopping conditions (predeclared):
%   PASS:  solver proves global optimum AND allocation differs from SSE-DP
%          AND stopband peak improves by >= 0.5 dB AND both pass/stop specs met
%   STOP:  time limit exceeded, optimality not proved, or specs not met
%
% Time limit: 3600 seconds (1 hour).

case_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(case_dir);
addpath(fullfile(project_dir, 'extended_validation'));

out_dir = fullfile(case_dir, 'miqp_linearized_exact_v2');
if exist(out_dir, 'dir')
    error('Output directory exists; preserve prior evidence: %s', out_dir);
end
mkdir(out_dir);

% --- Filter and specification (48-tap case A) ---
n_taps = 48;
f_pass = 0.3; f_stop = 0.4;
pass_limit_db = 0.25; stop_limit_db = -40;
case_a = load(fullfile(case_dir, 'robustness_study_corrected', 'case_A_data.mat'), 'h');
h = case_a.h(:).';
assert(numel(h) == n_taps);
quota = [24 16 8];
choices = [16 8 4];
N = n_taps; K = 3;

% Verify floating-point design meets spec
nfft = 65536;
[~, om] = freqz(h, 1, nfft);
f_grid = om/pi;
pass_idx = f_grid <= f_pass;
stop_idx = f_grid >= f_stop;
H_float = freqz(h, 1, nfft);
pass_db_float = 20*log10(max(abs(H_float(pass_idx)), realmin));
stop_peak_float = 20*log10(max(abs(H_float(stop_idx))));
fprintf('Float design: pass max|dev|=%.4f dB, stop peak=%.4f dB\n', ...
    max(abs(pass_db_float)), stop_peak_float);
assert(max(abs(pass_db_float)) <= pass_limit_db && stop_peak_float <= stop_limit_db, ...
    'Float design does not meet spec');

% --- Compute R matrix and per-tap per-width quantization errors ---
W_mask = double(f_grid >= f_stop);
R = zeros(N, N);
for i = 1:N
    for j = 1:N
        R(i,j) = mean(W_mask .* cos(om*(i-j)));
    end
end
fprintf('R diagonal: min=%.6f max=%.6f\n', min(diag(R)), max(diag(R)));

D = zeros(N, K);
for k = 1:K
    s = 2^(choices(k)-1);
    D(:,k) = round(h'*s)/s - h';
end

% --- SSE-DP baseline ---
[w_dp, q_dp] = adaptive_precision_dp(h, quota);
e_dp = q_dp - h;
sse_dp = sum(e_dp.^2);
wc_dp = e_dp * R * e_dp';
H_dp = freqz(q_dp, 1, nfft);
stop_peak_dp = 20*log10(max(abs(H_dp(stop_idx))));
pass_db_dp = 20*log10(max(abs(H_dp(pass_idx)), realmin));
pass_dev_dp = max(abs(pass_db_dp));
fprintf('SSE-DP: sse=%.6g, wc=%.6g, stop=%.2f dB, pass_dev=%.4f dB\n', ...
    sse_dp, wc_dp, stop_peak_dp, pass_dev_dp);

% --- Build MILP ---
% Variable layout:
%   x(i,k): tap i, width k, binary  [N*K vars, indices 1..N*K]
%   y(i,k,j,l): product x(i,k)*x(j,l) for i<j, all k,l [N*(N-1)/2*K^2 vars]
%   Include every nonzero y term; zero coefficients need no product variable.

tol = 0;  % retain every nonzero cross-term; no objective truncation

fprintf('Building product variables...\n');
nx = N*K;

% Count product variables needed
prod_count = 0;
prod_map = zeros(N*(N-1)/2*K^2, 3);  % xa index, xb index, coefficient
for i = 1:N
    for j = i+1:N
        for k = 1:K
            for l = 1:K
                c = 2 * R(i,j) * D(i,k) * D(j,l);  % factor 2 for symmetry i<j
                if abs(c) > tol
                    prod_count = prod_count + 1;
                    xi_idx = (i-1)*K + k;
                    xj_idx = (j-1)*K + l;
                    prod_map(prod_count,:) = [xi_idx, xj_idx, c];
                end
            end
        end
    end
end

ny = prod_count;
prod_map = prod_map(1:prod_count,:);
ntot = nx + ny;
fprintf('Variables: %d x-vars, %d product-vars, total %d\n', nx, ny, ntot);

% Objective: c'*z where z = [x; y]
% Linear part from diagonal terms x(i,k)^2 = x(i,k):
f_obj = zeros(ntot, 1);
for i = 1:N
    for k = 1:K
        xi_idx = (i-1)*K + k;
        f_obj(xi_idx) = R(i,i) * D(i,k)^2;
    end
end
% Cross-term part from product variables:
for p = 1:prod_count
    y_idx = nx + p;
    f_obj(y_idx) = prod_map(p,3);
end

% Integer variable indices (all are binary):
intcon = 1:ntot;

% Bounds:
lb = zeros(ntot, 1);
ub = ones(ntot, 1);

% Equality constraints:
% (1) Assignment: sum_k x(i,k) = 1 for each i  [N constraints]
% (2) Quota: sum_i x(i,k) = quota(k) for each k [K constraints]
n_eq = N + K;
Aeq = sparse(n_eq, ntot);
beq = zeros(n_eq, 1);
% Assignment:
for i = 1:N
    for k = 1:K
        Aeq(i, (i-1)*K+k) = 1;
    end
    beq(i) = 1;
end
% Quota:
for k = 1:K
    for i = 1:N
        Aeq(N+k, (i-1)*K+k) = 1;
    end
    beq(N+k) = quota(k);
end

% Inequality constraints for product variables:
% For each y = x_a * x_b: y <= x_a, y <= x_b, y >= x_a + x_b - 1
% => -y + x_a >= 0 (y <= x_a means x_a - y >= 0, i.e. -x_a + y <= 0)
% => -x_a + y <= 0
% => -x_b + y <= 0
% => x_a + x_b - y <= 1
n_ineq = 3 * prod_count;
ineq_i = zeros(7*prod_count,1);
ineq_j = zeros(7*prod_count,1);
ineq_v = zeros(7*prod_count,1);
bineq = zeros(n_ineq, 1);
for p = 1:prod_count
    xa = prod_map(p,1);
    xb = prod_map(p,2);
    yi = nx + p;
    row1 = 3*(p-1)+1;
    row2 = 3*(p-1)+2;
    row3 = 3*(p-1)+3;
    ix = 7*(p-1);
    % y <= x_a
    ineq_i(ix+(1:2)) = [row1; row1];
    ineq_j(ix+(1:2)) = [xa; yi];
    ineq_v(ix+(1:2)) = [-1; 1];
    % y <= x_b
    ineq_i(ix+(3:4)) = [row2; row2];
    ineq_j(ix+(3:4)) = [xb; yi];
    ineq_v(ix+(3:4)) = [-1; 1];
    % y >= x_a + x_b - 1  =>  x_a + x_b - y <= 1
    ineq_i(ix+(5:7)) = [row3; row3; row3];
    ineq_j(ix+(5:7)) = [xa; xb; yi];
    ineq_v(ix+(5:7)) = [1; 1; -1];
    bineq(row3) = 1;
end
Aineq = sparse(ineq_i, ineq_j, ineq_v, n_ineq, ntot);

fprintf('Constraint sizes: Aeq %dx%d, Aineq %dx%d\n', ...
    size(Aeq,1), size(Aeq,2), size(Aineq,1), size(Aineq,2));

% Seed intlinprog with the known-feasible SSE-DP allocation and its products.
x0 = zeros(ntot,1);
for i = 1:N
    k = find(choices == w_dp(i), 1);
    x0((i-1)*K+k) = 1;
end
for p = 1:prod_count
    x0(nx+p) = x0(prod_map(p,1)) * x0(prod_map(p,2));
end
assert(max(abs(Aeq*x0-beq)) < 1e-10);
assert(max(Aineq*x0-bineq) < 1e-10);
seed_objective = f_obj' * x0;
assert(abs(seed_objective-wc_dp) < 1e-12, ...
    'Linearized model objective does not reproduce the DP response cost.');
fprintf('DP warm-start objective: %.12g (direct e''Re: %.12g)\n', ...
    seed_objective, wc_dp);

% --- Solve ---
opts = optimoptions('intlinprog', ...
    'Display', 'iter', ...
    'MaxTime', 3600, ...          % 1-hour limit
    'RelativeGapTolerance', 1e-6, ...
    'AbsoluteGapTolerance', 1e-12);

fprintf('\nStarting intlinprog... (time limit: 3600 s)\n');
t_start = tic;
[z_sol, fval, exitflag, output] = intlinprog(f_obj, intcon, Aineq, bineq, ...
    Aeq, beq, lb, ub, x0, opts);
t_elapsed = toc(t_start);
fprintf('Elapsed: %.1f s, exitflag: %d\n', t_elapsed, exitflag);
fprintf('Output: %s\n', output.message);

% --- Evaluate stopping conditions ---
proved_optimal = (exitflag == 1);  % exitflag=1: optimal found within tolerances
fprintf('\nProved optimal: %d\n', proved_optimal);

has_solution = ~isempty(z_sol);
if ~has_solution
    fprintf('No solution returned. STOP: cannot evaluate.\n');
    result_status = 'STOP_NO_SOLUTION';
else
    % Extract x variables
    x = z_sol(1:nx);
    X = reshape(x, K, N)';  % N x K
    % Assign widths
    [~, k_chosen] = max(X, [], 2);
    w_miqp = choices(k_chosen)';
    assert(isequal([sum(w_miqp==16) sum(w_miqp==8) sum(w_miqp==4)], quota));

    q_miqp = zeros(1, N);
    for i = 1:N
        s = 2^(w_miqp(i)-1);
        q_miqp(i) = round(h(i)*s)/s;
    end
    e_miqp = q_miqp - h;
    wc_miqp = e_miqp * R * e_miqp';
    sse_miqp = sum(e_miqp.^2);

    H_miqp = freqz(q_miqp, 1, nfft);
    stop_peak_miqp = 20*log10(max(abs(H_miqp(stop_idx))));
    pass_db_miqp = 20*log10(max(abs(H_miqp(pass_idx)), realmin));
    pass_dev_miqp = max(abs(pass_db_miqp));

    actually_same = isequal(w_miqp, w_dp);
    stop_improvement_db = stop_peak_dp - stop_peak_miqp;  % positive = better

    fprintf('\n--- MIQP result ---\n');
    fprintf('Weighted cost: MIQP=%.6g, SSE-DP=%.6g\n', wc_miqp, wc_dp);
    fprintf('SSE: MIQP=%.6g, SSE-DP=%.6g\n', sse_miqp, sse_dp);
    fprintf('Stop peak: MIQP=%.2f dB, SSE-DP=%.2f dB (improvement: %.2f dB)\n', ...
        stop_peak_miqp, stop_peak_dp, stop_improvement_db);
    fprintf('Pass dev: MIQP=%.4f dB, SSE-DP=%.4f dB\n', pass_dev_miqp, pass_dev_dp);
    fprintf('MIQP meets stop spec (<=%.0f dB): %d\n', stop_limit_db, stop_peak_miqp <= stop_limit_db);
    fprintf('MIQP meets pass spec (<=%.2f dB): %d\n', pass_limit_db, pass_dev_miqp <= pass_limit_db);
    fprintf('Allocation same as SSE-DP: %d\n', actually_same);

    % Stopping-condition evaluation
    if ~proved_optimal
        result_status = 'STOP_NOT_PROVED_OPTIMAL';
    elseif stop_peak_miqp > stop_limit_db || pass_dev_miqp > pass_limit_db
        result_status = 'STOP_SPEC_NOT_MET';
    elseif actually_same
        result_status = 'STOP_SAME_ALLOCATION';
    elseif stop_improvement_db < 0.5
        result_status = 'STOP_INSUFFICIENT_IMPROVEMENT';
    else
        result_status = 'PASS';
    end
    fprintf('\nDecision: %s\n', result_status);

    % Save
    save(fullfile(out_dir, 'miqp_result.mat'), ...
        'h', 'quota', 'R', 'D', 'choices', ...
        'w_dp', 'q_dp', 'sse_dp', 'wc_dp', 'stop_peak_dp', 'pass_dev_dp', ...
        'w_miqp', 'q_miqp', 'sse_miqp', 'wc_miqp', 'stop_peak_miqp', 'pass_dev_miqp', ...
        'stop_improvement_db', 'proved_optimal', 'exitflag', 'fval', ...
        'result_status', 't_elapsed', 'output');
end

% Write README
fid = fopen(fullfile(out_dir, 'README.md'), 'w');
fprintf(fid, '# 48-tap linearized MIQP experiment\n\n');
fprintf(fid, 'Run: %s\n\n', datetime('now'));
fprintf(fid, '## Problem\n\n');
fprintf(fid, 'Minimize stopband-integrated squared response error e^T R e under exact quota\n');
fprintf(fid, '[24,16,8] for 16/8/4-bit widths. R is the stopband-weighted cross-correlation\n');
fprintf(fid, 'matrix (stopband: 0.4pi to pi). Linearized with product variables and solved\n');
fprintf(fid, 'with MATLAB intlinprog (1-hour limit, gap tolerance 1e-4).\n\n');
fprintf(fid, '## Variables and constraints\n\n');
fprintf(fid, '- x-vars: %d binary (N=%d taps x K=%d widths)\n', nx, N, K);
fprintf(fid, '- Product y-vars: %d (all nonzero cross-terms retained; tol=%.0e)\n', ny, tol);
fprintf(fid, '- Equality constraints: %d\n', n_eq);
fprintf(fid, '- Inequality constraints (product bounds): %d\n', n_ineq);
fprintf(fid, '\n## Stopping conditions\n\n');
fprintf(fid, '- PASS: proved optimal + allocation differs + stop improves >=0.5 dB + specs met\n');
fprintf(fid, '- STOP: time exceeded, not optimal, allocation same, or specs not met\n\n');
fprintf(fid, '## Result\n\n');
if has_solution
    fprintf(fid, 'Decision: **%s**\n\n', result_status);
    fprintf(fid, '| Metric | SSE-DP | MIQP |\n|---|---|---|\n');
    fprintf(fid, '| Weighted cost | %.6g | %.6g |\n', wc_dp, wc_miqp);
    fprintf(fid, '| SSE | %.6g | %.6g |\n', sse_dp, sse_miqp);
    fprintf(fid, '| Stopband peak | %.2f dB | %.2f dB |\n', stop_peak_dp, stop_peak_miqp);
    fprintf(fid, '| Passband dev | %.4f dB | %.4f dB |\n', pass_dev_dp, pass_dev_miqp);
    fprintf(fid, '| Proved optimal | - | %d |\n', proved_optimal);
    fprintf(fid, '| Elapsed time | - | %.1f s |\n', t_elapsed);
else
    fprintf(fid, 'Decision: **%s**\n\n', result_status);
    fprintf(fid, 'No integer-feasible incumbent was returned before termination.\n');
end
fclose(fid);

fprintf('\nResults saved to: %s\n', out_dir);
end
