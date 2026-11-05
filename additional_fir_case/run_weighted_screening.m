function run_weighted_screening()
% Small-scale screening: does band-weighted response error change the
% optimal allocation compared to coefficient SSE, and if so, does the
% changed allocation improve actual frequency response?
%
% Stopping conditions:
%   STOP if no allocation difference is found across all test cases.
%   CONTINUE (to 48-tap MIQP) only if:
%     - At least 3 cases show different allocations, AND
%     - The weighted-optimal allocation has better stopband peak in
%       each of those cases.
%   Otherwise: record "no meaningful difference" and stop this branch.
%
% Test cases: 5 different 8-tap filters with varied coefficient profiles.
% For each, use quota [4,2,2] (same as first prototype) and also [3,3,2].
% Exhaustive search is fast for N=8 (~70-420 feasible assignments).

case_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(case_dir);
addpath(fullfile(project_dir, 'extended_validation'));

out_dir = fullfile(case_dir, 'weighted_screening_v3');
if exist(out_dir, 'dir')
    error('Output directory exists; preserve prior evidence: %s', out_dir);
end
mkdir(out_dir);

% =========================================================================
% Define 5 test filters (all 8-tap, varied spectral profiles)
% =========================================================================
% Each row: [type, passband_edge, stopband_edge, pass_ripple_db]
% Design uses firpm; if firpm fails or spec is infeasible, use fir1 fallback.

nfft = 32768;
choices = [16 8 4];

filters = {
    'LP_narrow', 'firpm', {7, [0 0.2 0.3 1], [1 1 0 0], [1 3]}, 0.2, 0.3, [0.3 1];
    'LP_wide',   'firpm', {7, [0 0.3 0.5 1], [1 1 0 0], [1 2]}, 0.3, 0.5, [0.5 1];
    'LP_tight',  'fir1',  {7, 0.25, 'low', hamming(8)}, 0.2, 0.3, [0.3 1];
    'HP_LS',     'ls_hp', {}, 0.6, NaN, [0 0.4];
    'BP',        'firpm', {7, [0 0.2 0.3 0.6 0.7 1], [0 0 1 1 0 0], [1 1 1]}, [0.3 0.6], NaN, [0 0.2; 0.7 1];
};

quotas = {[4 2 2], [3 3 2]};

results = struct('filter',{},'quota',{},'n16',{},'n8',{},'n4',{}, ...
    'sse_alloc',{},'wt_alloc',{},'same_alloc',{}, ...
    'sse_stop_db',{},'wt_stop_db',{},'wt_better_stop',{}, ...
    'n_feasible',{});

summary_rows = {};

for fi = 1:size(filters,1)
    label = filters{fi,1};
    dfn   = filters{fi,2};
    parms = filters{fi,3};

    % Design filter
    if strcmp(dfn, 'firpm')
        h = firpm(parms{:});
    elseif strcmp(dfn, 'ls_hp')
        h = design_ls_highpass(8, 0.4, 0.6, 0.95);
    else
        h = fir1(parms{:});
    end
    h = h(:).';
    n = numel(h);
    assert(n == 8, 'Expected 8-tap filter');

    stop_spec = filters{fi,6};

    % Compute frequency grid
    omega = linspace(0, pi, nfft+1); omega = omega(2:end);
    f = omega / pi;

    % Build stopband weight mask
    if strcmp(label, 'BP')
        stop_mask = false(size(f));
        for band = 1:size(stop_spec,1)
            stop_mask = stop_mask | (f >= stop_spec(band,1) & f <= stop_spec(band,2));
        end
    else
        stop_mask = f >= stop_spec(1) & f <= stop_spec(2);
    end

    % Build R matrix (stopband-weighted response error)
    R = zeros(n, n);
    for i = 1:n
        for j = 1:n
            R(i,j) = mean(stop_mask .* cos(omega * (i-j)));
        end
    end
    diag_vals = diag(R);
    assert(max(diag_vals) - min(diag_vals) < 1e-4, ...
        'Diagonal not equal; check R computation');

    for qi = 1:numel(quotas)
        quota = quotas{qi};
        if sum(quota) ~= n
            continue;
        end

        % Exhaustive search
        best_sse = inf; best_wt = inf;
        best_sse_alloc = []; best_wt_alloc = [];
        n_feasible = 0;

        for idx = 0:3^n-1
            w_idx = zeros(1,n);
            tmp = idx;
            for k = n:-1:1
                w_idx(k) = mod(tmp, 3) + 1;
                tmp = floor(tmp / 3);
            end
            counts = [sum(w_idx==1) sum(w_idx==2) sum(w_idx==3)];
            if ~isequal(counts, quota), continue; end
            n_feasible = n_feasible + 1;

            q = arrayfun(@(i) round(h(i)*2^(choices(w_idx(i))-1))/2^(choices(w_idx(i))-1), 1:n);
            e = q - h;

            sc = sum(e.^2);
            wc = e * R * e';

            if sc < best_sse - 1e-15
                best_sse = sc; best_sse_alloc = w_idx;
            elseif abs(sc-best_sse) <= 1e-15
                if lexicographically_less(w_idx, best_sse_alloc)
                    best_sse_alloc = w_idx;
                end
            end

            if wc < best_wt - 1e-15
                best_wt = wc; best_wt_alloc = w_idx;
            elseif abs(wc-best_wt) <= 1e-15
                if lexicographically_less(w_idx, best_wt_alloc)
                    best_wt_alloc = w_idx;
                end
            end
        end

        % Compute quantized coefficients and stopband peaks
        w_sse_decoded = choices(best_sse_alloc);
        w_wt_decoded  = choices(best_wt_alloc);
        q_sse = arrayfun(@(i) round(h(i)*2^(w_sse_decoded(i)-1))/2^(w_sse_decoded(i)-1), 1:n);
        q_wt  = arrayfun(@(i) round(h(i)*2^(w_wt_decoded(i)-1))/2^(w_wt_decoded(i)-1), 1:n);

        H_sse = freqz(q_sse, 1, nfft+1); H_sse = H_sse(2:end);
        H_wt  = freqz(q_wt,  1, nfft+1); H_wt  = H_wt(2:end);

        stop_peak_sse = 20*log10(max(max(abs(H_sse(stop_mask))), realmin));
        stop_peak_wt  = 20*log10(max(max(abs(H_wt(stop_mask))),  realmin));

        same_alloc = isequal(best_sse_alloc, best_wt_alloc);
        wt_better = (~same_alloc) && (stop_peak_wt < stop_peak_sse);

        row = struct('filter', label, 'quota', mat2str(quota), ...
            'n16', quota(1), 'n8', quota(2), 'n4', quota(3), ...
            'sse_alloc', mat2str(w_sse_decoded), ...
            'wt_alloc', mat2str(w_wt_decoded), ...
            'same_alloc', same_alloc, ...
            'sse_stop_db', stop_peak_sse, ...
            'wt_stop_db', stop_peak_wt, ...
            'wt_better_stop', wt_better, ...
            'n_feasible', n_feasible);
        results(end+1) = row; %#ok<AGROW>

        status = 'SAME';
        if ~same_alloc && wt_better
            status = 'DIFFERENT+BETTER';
        elseif ~same_alloc
            status = 'DIFFERENT+NOT_BETTER';
        end
        fprintf('%-12s quota%-8s feasible=%3d  %s  stop: SSE=%.2f dB  WT=%.2f dB\n', ...
            label, mat2str(quota), n_feasible, status, stop_peak_sse, stop_peak_wt);
        summary_rows{end+1} = {label, mat2str(quota), status, stop_peak_sse, stop_peak_wt, n_feasible}; %#ok<AGROW>
    end
end

% =========================================================================
% Stopping-condition evaluation
% =========================================================================
n_diff_better = sum([results.wt_better_stop]);
n_diff_any    = sum(~[results.same_alloc]);
n_total       = numel(results);

fprintf('\n=== Stopping-condition evaluation ===\n');
fprintf('Total cases:                    %d\n', n_total);
fprintf('Cases with different alloc:     %d\n', n_diff_any);
fprintf('Cases with diff + better stop:  %d\n', n_diff_better);

if n_diff_better >= 3
    decision = 'CONTINUE: >= 3 cases show different allocation AND better stopband. Proceed to 48-tap MIQP.';
else
    decision = 'STOP: Fewer than 3 cases with meaningful allocation difference and improvement. Do not proceed to 48-tap MIQP.';
end
fprintf('\nDecision: %s\n', decision);

% Save
T = struct2table(results);
writetable(T, fullfile(out_dir, 'screening_results.csv'));
save(fullfile(out_dir, 'screening_data.mat'), 'results', 'filters', 'quotas', ...
    'n_diff_better', 'n_diff_any', 'n_total', 'decision');
fprintf('\nResults saved to: %s\n', out_dir);
end

function tf = lexicographically_less(a, b)
if isempty(b)
    tf = true;
    return
end
k = find(a ~= b, 1, 'first');
tf = ~isempty(k) && a(k) < b(k);
end

function h = design_ls_highpass(n_taps, stop_edge, pass_edge, pass_end)
% Real-coefficient least-squares FIR; not constrained to linear phase.
omega = linspace(0, pi, 8193).';
f = omega/pi;
use = (f <= stop_edge) | (f >= pass_edge & f <= pass_end);
target = double(f(use) >= pass_edge);
A = exp(-1j * omega(use) * (0:n_taps-1));
Ar = [real(A); imag(A)];
br = [target; zeros(size(target))];
h = (Ar \ br).';
end
