function run_robustness()
% Robustness extension: run DP/greedy/frequency-check on multiple FIR specs
% to test whether the 48-tap base case observation generalises.
%
% Five cases:
%   A: 48-tap, pb 0-0.3pi, sb 0.4-pi, -40 dB  (base case, re-run for audit)
%   B: 48-tap, pb 0-0.3pi, sb 0.4-pi, -50 dB  (stricter attenuation)
%   C: 48-tap, pb 0-0.2pi, sb 0.3-pi, -40 dB  (narrower transition band)
%   D: 36-tap, pb 0-0.3pi, sb 0.4-pi, -40 dB  (fewer taps, same spec)
%   E: 64-tap, pb 0-0.3pi, sb 0.4-pi, -40 dB  (more taps, same spec)
%
% For each case and each quota, DP, greedy, and MILP are run.
% All results are reported, including cases where DP does not meet spec.
% Quotas for each case are scaled proportionally to tap count (rounded even).
%
% Output: robustness_study_corrected/  (refused if directory exists)

case_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(case_dir);
addpath(fullfile(project_dir, 'extended_validation'));

out_dir = fullfile(case_dir, 'robustness_study_corrected');
if exist(out_dir, 'dir')
    error('Output directory already exists; preserve prior evidence: %s', out_dir);
end
mkdir(out_dir);

% -------------------------------------------------------------------------
% Case definitions
% -------------------------------------------------------------------------
% Each case: label, n_taps, f_pass_edge, f_stop_edge, stop_limit_db
% pass_limit_db fixed at 0.25 dB for all cases.
pass_limit_db = 0.25;

cases = {
    'A', 48, 0.3, 0.4, -40;
    'B', 48, 0.3, 0.4, -50;
    'C', 48, 0.2, 0.3, -40;
    'D', 36, 0.3, 0.4, -40;
    'E', 64, 0.3, 0.4, -40;
};

% Base quotas for 48 taps: [24,16,8], [16,24,8], [12,24,12]
% Scaled proportionally for other tap counts (rounded to even, sum = n_taps).
base_n = 48;
base_quotas_frac = [24 16 8; 16 24 8; 12 24 12] / base_n;

opts = optimoptions('intlinprog', 'Display', 'off', ...
    'RelativeGapTolerance', 0, 'AbsoluteGapTolerance', 0, ...
    'ConstraintTolerance', 1e-9);

nfft = 65536;
all_rows = struct('case_label',{},'n_taps',{},'pass_edge',{},'stop_edge',{}, ...
    'stop_limit_db',{},'quota_id',{},'n16',{},'n8',{},'n4',{}, ...
    'method',{},'coefficient_sse',{},'stopband_peak_db',{}, ...
    'passband_max_abs_db',{},'meets_spec',{});

for ci = 1:size(cases, 1)
    label     = cases{ci,1};
    n_taps    = cases{ci,2};
    f_pass    = cases{ci,3};
    f_stop    = cases{ci,4};
    stop_lim  = cases{ci,5};

    fprintf('\n===== Case %s: %d-tap, pb 0-%.1fpi, sb %.1fpi-pi, %.0f dB =====\n', ...
        label, n_taps, f_pass, f_stop, stop_lim);

    % Design filter
    f_edges = [0 f_pass f_stop 1];
    % Match run_case.m: 0.5 dB peak-to-peak equiripple corresponds to
    % approximately +/-0.25 dB about unity gain.
    delta_p = (10^(0.5/20) - 1) / (10^(0.5/20) + 1);
    delta_s = 10^(stop_lim/20);
    weights = [1, delta_p/abs(delta_s)];
    h = firpm(n_taps-1, f_edges, [1 1 0 0], weights);
    h = h(:).';
    assert(numel(h) == n_taps);

    % Frequency grid
    [~, omega] = freqz(h, 1, nfft);
    f = omega / pi;
    pass_idx = f <= f_pass;
    stop_idx = f >= f_stop;

    % Check floating-point design
    ref = response_metrics(h, pass_idx, stop_idx, nfft, pass_limit_db, stop_lim);
    fprintf('  Float ref: passband max |dB| %.4f, stopband peak %.4f dB, meets_spec=%d\n', ...
        ref.pass_max_abs_db, ref.stop_peak_db, ref.meets_spec);
    if ~ref.meets_spec
        fprintf('  WARNING: floating-point design does not satisfy spec; case %s skipped.\n', label);
        continue
    end

    % Scale quotas to this tap count (round to nearest even, fix rounding)
    raw = round(base_quotas_frac * n_taps / 2) * 2;  % round to even
    % Adjust any row whose sum differs from n_taps (add/subtract from n8 col)
    for qi = 1:size(raw, 1)
        diff = n_taps - sum(raw(qi,:));
        raw(qi, 2) = raw(qi, 2) + diff;  % adjust 8-bit count
    end
    quotas = raw;
    assert(all(quotas(:) >= 0), 'Negative quota after rounding; adjust scaling logic.');
    assert(all(sum(quotas, 2) == n_taps));

    fprintf('  Quotas [n16 n8 n4]:\n');
    disp(quotas);

    % Run allocation methods for each quota
    for qi = 1:size(quotas, 1)
        quota = quotas(qi,:);
        fprintf('  Quota %d [%d %d %d]:\n', qi, quota(1), quota(2), quota(3));

        [w_dp,  q_dp,  info_dp] = adaptive_precision_dp(h, quota);
        [w_gr,  q_gr]           = adaptive_precision_error_greedy(h, quota);
        [w_ml,  q_ml,  fval]    = solve_assignment(h, quota, opts);

        assert(isequal(width_counts(w_dp), quota));
        assert(isequal(width_counts(w_gr), quota));
        assert(isequal(width_counts(w_ml), quota));

        sse_dp = sum((h - q_dp).^2);
        sse_gr = sum((h - q_gr).^2);
        sse_ml = sum((h - q_ml).^2);

        assert(abs(sse_dp - info_dp.dp_optimal_cost) < 1e-10);
        assert(abs(sse_dp - sse_ml) < 1e-10);
        assert(abs(sse_ml - fval)   < 1e-10);
        assert(sse_gr >= sse_dp - 1e-10);

        for mm = 1:3
            if mm==1; w=w_dp; q=q_dp; mname='DP';
            elseif mm==2; w=w_gr; q=q_gr; mname='greedy';  %#ok<ALIGN>
            else;         w=w_ml; q=q_ml; mname='MILP';     %#ok<ALIGN>
            end
            met = response_metrics(q, pass_idx, stop_idx, nfft, pass_limit_db, stop_lim);
            row = struct('case_label', label, 'n_taps', n_taps, ...
                'pass_edge', f_pass, 'stop_edge', f_stop, ...
                'stop_limit_db', stop_lim, 'quota_id', qi, ...
                'n16', quota(1), 'n8', quota(2), 'n4', quota(3), ...
                'method', string(mname), ...
                'coefficient_sse', sum((h-q).^2), ...
                'stopband_peak_db', met.stop_peak_db, ...
                'passband_max_abs_db', met.pass_max_abs_db, ...
                'meets_spec', met.meets_spec);
            all_rows(end+1) = row; %#ok<AGROW>
            fprintf('    %s: SSE %.5g, stop %.2f dB, meets=%d\n', ...
                mname, row.coefficient_sse, row.stopband_peak_db, row.meets_spec);
        end
    end

    % Save per-case design data
    case_file = fullfile(out_dir, sprintf('case_%s_data.mat', label));
    save(case_file, 'h', 'quotas', 'f_edges', 'pass_limit_db', 'stop_lim', ...
        'n_taps', 'label', 'ref');
end

% -------------------------------------------------------------------------
% Write combined results
% -------------------------------------------------------------------------
if isempty(all_rows)
    fprintf('\nNo cases completed.\n');
    return
end
T = struct2table(all_rows);
writetable(T, fullfile(out_dir, 'robustness_results.csv'));

% Summary: for each case/quota, does DP meet spec and does greedy?
fprintf('\n===== Summary =====\n');
fprintf('%-6s %-5s %-12s %-8s %-10s %-12s %-12s\n', ...
    'Case','Quota','[n16,n8,n4]','DP_stop','DP_meets','Greedy_stop','Greedy_meets');
cases_run = unique(T.case_label, 'stable');
for ci = 1:numel(cases_run)
    cl = cases_run{ci};
    sub = T(strcmp(T.case_label, cl), :);
    for qi = unique(sub.quota_id)'
        qsub = sub(sub.quota_id==qi, :);
        dp_row = qsub(qsub.method=="DP", :);
        gr_row = qsub(qsub.method=="greedy", :);
        quota_str = sprintf('[%d,%d,%d]', dp_row.n16(1), dp_row.n8(1), dp_row.n4(1));
        fprintf('%-6s %-5d %-12s %-8.2f %-10d %-12.2f %-12d\n', ...
            cl, qi, quota_str, dp_row.stopband_peak_db(1), dp_row.meets_spec(1), ...
            gr_row.stopband_peak_db(1), gr_row.meets_spec(1));
    end
end

fprintf('\nResults saved to: %s\n', out_dir);
end

% =========================================================================
function counts = width_counts(w)
counts = [sum(w==16), sum(w==8), sum(w==4)];
end

% =========================================================================
function metrics = response_metrics(h, pass_idx, stop_idx, nfft, ...
        pass_limit_db, stop_limit_db)
H = freqz(h, 1, nfft);
pass_db = 20*log10(max(abs(H(pass_idx)), realmin));
stop_peak_db = 20*log10(max(max(abs(H(stop_idx))), realmin));
metrics.pass_max_abs_db  = max(abs(pass_db));
metrics.pass_peak_to_peak_db = max(pass_db) - min(pass_db);
metrics.stop_peak_db     = stop_peak_db;
metrics.meets_spec = (metrics.pass_max_abs_db <= pass_limit_db) && ...
    (stop_peak_db <= stop_limit_db);
end

% =========================================================================
function [widths, quantized, fval] = solve_assignment(h, quota, opts)
n = numel(h);
choices = [16 8 4];
cost = zeros(n, 3);
for j = 1:3
    s = 2^(choices(j)-1);
    cost(:,j) = (h(:) - round(h(:)*s)/s).^2;
end
Aeq  = zeros(n+3, 3*n);
beq  = [ones(n,1); quota(:)];
for i = 1:n
    Aeq(i, i:n:3*n) = 1;
end
for j = 1:3
    Aeq(n+j, (j-1)*n+(1:n)) = 1;
end
[x, fval, flag] = intlinprog(cost(:), 1:3*n, [], [], Aeq, beq, ...
    zeros(3*n,1), ones(3*n,1), opts);
assert(flag > 0 && all(abs(Aeq*x - beq) < 1e-8));
X = reshape(x, n, 3);
assert(all(sum(X > 0.5, 2) == 1));
[~, choice_index] = max(X, [], 2);
widths    = reshape(choices(choice_index), 1, []);
quantized = round(h .* 2.^(widths-1)) ./ 2.^(widths-1);
assert(isequal(size(widths), size(h)) && isequal(size(quantized), size(h)));
end
