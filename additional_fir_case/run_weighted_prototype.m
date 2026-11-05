function run_weighted_prototype()
% Prototype: band-weighted frequency-response error allocation under exact quotas.
%
% The band-weighted objective e^T R e has cross-terms between taps.
% R_ij = integral of W(omega) * exp(j*omega*(i-j)) over the weighted bands.
% This is NOT separable, so the existing DP cannot be used directly.
%
% This prototype:
% 1. Computes R for a given filter and band weights
% 2. For small N (8 taps), does exhaustive search under exact quotas
%    to find the band-weighted-optimal allocation
% 3. Compares against the coefficient-SSE-DP allocation on actual
%    passband/stopband metrics
% 4. Reports whether handling cross-terms changes the allocation
%    and improves frequency response

case_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(case_dir);
addpath(fullfile(project_dir, 'extended_validation'));

out_dir = fullfile(case_dir, 'weighted_prototype_v2');
if exist(out_dir, 'dir')
    error('Output directory exists; preserve prior evidence: %s', out_dir);
end
mkdir(out_dir);

% Reuse the corrected case-A coefficients to keep comparisons reproducible.
n_taps = 48;
f_pass = 0.3;
f_stop = 0.4;
stop_limit_db = -40;
pass_limit_db = 0.25;
case_a_file = fullfile(case_dir, 'robustness_study_corrected', 'case_A_data.mat');
case_a = load(case_a_file, 'h');
h = case_a.h(:).';
assert(numel(h) == n_taps);

% --- Compute R matrix for band-weighted objective ---
% W(omega) = 1 in stopband, 0 elsewhere (stopband-weighted error)
% R_ij = (1/2pi) * integral over stopband of cos(omega*(i-j)) d(omega)
%       = (sin(omega_stop*(i-j)) - sin(omega_pass*(i-j))) / (2*pi*(i-j))  for i!=j
%       = (omega_stop - omega_pass) / (2*pi)                          for i==j

nfft = 65536;
[~, omega] = freqz(h, 1, nfft);
f = omega / pi;
stop_idx = f >= f_stop;

% Compute R via DFT of weight function
W = zeros(nfft, 1);
W(stop_idx) = 1;
% R_ij = (1/nfft) * sum_k W_k * cos(omega_k * (i-j))
% (real part of IDFT of W applied to error vector)
N = n_taps;
R = zeros(N, N);
for i = 1:N
    for j = 1:N
        R(i,j) = mean(W .* cos(omega(:) * (i-j)));
    end
end

fprintf('R matrix size: %dx%d\n', N, N);
fprintf('R diagonal (should all be equal): min=%.6f max=%.6f\n', min(diag(R)), max(diag(R)));
R_off = R - diag(diag(R));
off_values = abs(R_off(:));
off_values = off_values(off_values > 1e-12);
fprintf('R off-diagonal nonzero magnitude range: [%.6f, %.6f]\n', ...
    min(off_values), max(off_values));

% --- Small case for exhaustive search ---
% Use the original project's 8-tap Hamming-window low-pass prototype.
n_small = 8;
h_small = fir1(n_small-1, 0.3, 'low', hamming(n_small));
h_small = h_small(:).';
R_small = R(1:n_small, 1:n_small);

% Quota: [4,2,2] for 8 taps
quota_small = [4 2 2];
assert(sum(quota_small) == n_small);

% Exhaustive search: find allocation minimizing e^T R e
% and separately minimizing sum(e^2) (coefficient SSE)
choices = [16 8 4];
best_weighted_cost = inf;
best_weighted_alloc = [];
best_sse_cost = inf;
best_sse_alloc = [];

% Generate all assignments: 3^8 = 6561 raw assignments; 420 satisfy [4,2,2].
count = 0;
for w1 = 1:3
for w2 = 1:3
for w3 = 1:3
for w4 = 1:3
for w5 = 1:3
for w6 = 1:3
for w7 = 1:3
for w8 = 1:3
    w_vec = [w1 w2 w3 w4 w5 w6 w7 w8];
    counts = [sum(w_vec==1) sum(w_vec==2) sum(w_vec==3)];
    if ~isequal(counts, quota_small)
        continue;
    end
    count = count + 1;

    % Compute quantized coefficients
    q = zeros(1, n_small);
    for i = 1:n_small
        s = 2^(choices(w_vec(i))-1);
        q(i) = round(h_small(i)*s)/s;
    end
    e = q - h_small;

    % Weighted cost: e^T R e
    wc = e * R_small * e';
    if wc < best_weighted_cost
        best_weighted_cost = wc;
        best_weighted_alloc = w_vec;
    end

    % SSE cost: sum(e^2)
    sc = sum(e.^2);
    if sc < best_sse_cost
        best_sse_cost = sc;
        best_sse_alloc = w_vec;
    end
end
end
end
end
end
end
end
end

fprintf('\n=== 8-tap exhaustive search (quota [4,2,2]) ===\n');
fprintf('Feasible assignments checked: %d\n', count);

% Decode allocations
w_sse = choices(best_sse_alloc);
w_wt = choices(best_weighted_alloc);

fprintf('SSE-optimal allocation:     %s\n', mat2str(w_sse));
fprintf('Weighted-optimal allocation: %s\n', mat2str(w_wt));
fprintf('Same allocation? %d\n', isequal(best_sse_alloc, best_weighted_alloc));

% Compute quantized coefficients and errors
q_sse = zeros(1, n_small);
q_wt = zeros(1, n_small);
for i = 1:n_small
    q_sse(i) = round(h_small(i)*2^(w_sse(i)-1))/2^(w_sse(i)-1);
    q_wt(i)  = round(h_small(i)*2^(w_wt(i)-1))/2^(w_wt(i)-1);
end
e_sse = q_sse - h_small;
e_wt  = q_wt - h_small;

fprintf('\nSSE cost:     SSE-opt=%.10g  Weighted-opt=%.10g\n', sum(e_sse.^2), sum(e_wt.^2));
fprintf('Weighted cost: SSE-opt=%.10g  Weighted-opt=%.10g\n', e_sse*R_small*e_sse', e_wt*R_small*e_wt');

% Now also run coefficient-SSE DP on the same 8-tap subset
[w_dp, q_dp] = adaptive_precision_dp(h_small, quota_small);
e_dp = q_dp - h_small;
fprintf('\nDP allocation:  %s\n', mat2str(w_dp));
fprintf('DP SSE cost:     %.10g\n', sum(e_dp.^2));
fprintf('DP weighted cost: %.10g\n', e_dp * R_small * e_dp');
fprintf('DP SSE matches exhaustive optimum? %d\n', ...
    abs(sum(e_dp.^2) - best_sse_cost) < 1e-12);
fprintf('DP weighted objective matches exhaustive optimum? %d\n', ...
    abs(e_dp * R_small * e_dp' - best_weighted_cost) < 1e-12);

% --- Also run on full 48-tap with DP and MILP for weighted objective ---
% MILP with quadratic objective: min e^T R e  s.t.  assignment + quota
% This is a MIQP (mixed-integer quadratic program)
% MATLAB intlinprog cannot handle quadratic objectives directly;
% we use a linearized approximation or note the limitation.
fprintf('\n=== 48-tap comparison (DP vs greedy, coefficient SSE) ===\n');
quota_48 = [24 16 8];
[w_dp48, q_dp48] = adaptive_precision_dp(h, quota_48);
[w_gr48, q_gr48] = adaptive_precision_error_greedy(h, quota_48);

e_dp48 = q_dp48 - h;
e_gr48 = q_gr48 - h;

wc_dp48 = e_dp48 * R * e_dp48';
wc_gr48 = e_gr48 * R * e_gr48';

fprintf('DP:     SSE=%.10g  Weighted(stopband)=%.10g\n', sum(e_dp48.^2), wc_dp48);
fprintf('Greedy: SSE=%.10g  Weighted(stopband)=%.10g\n', sum(e_gr48.^2), wc_gr48);

% Compute actual frequency response metrics
nfft_resp = 65536;
[~, omega_resp] = freqz(1, 1, nfft_resp);
f_resp = omega_resp / pi;
pass_idx = f_resp <= f_pass;
stop_idx_resp = f_resp >= f_stop;

for method = 1:3
    if method==1; q_now=q_dp48; mname='DP';
    elseif method==2; q_now=q_gr48; mname='Greedy';
    else
        % Uniform 8-bit baseline
        q_now = round(h * 2^7) / 2^7;
        mname='Uniform-8bit';
    end
    H = freqz(q_now, 1, nfft_resp);
    pass_db = 20*log10(max(abs(H(pass_idx)), realmin));
    stop_db = 20*log10(max(max(abs(H(stop_idx_resp))), realmin));
    fprintf('%s: stopband peak=%.2f dB, passband max|dev|=%.4f dB\n', ...
        mname, stop_db, max(abs(pass_db)));
end

% Save results
save(fullfile(out_dir, 'weighted_prototype_results.mat'), ...
    'h', 'h_small', 'R', 'R_small', 'quota_small', 'quota_48', ...
    'best_weighted_alloc', 'best_weighted_cost', 'best_sse_alloc', 'best_sse_cost', ...
    'w_dp', 'w_sse', 'w_wt', 'w_dp48', 'w_gr48', 'wc_dp48', 'wc_gr48');

fprintf('\nResults saved to: %s\n', out_dir);
end
