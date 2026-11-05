function run_case()
% Reproducible larger FIR coefficient-allocation case, independent of the
% historical 8-tap implementation and 108-case validation matrix.

case_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(case_dir);
addpath(fullfile(project_dir, 'extended_validation'));

% Normalized frequency is f/(pi rad/sample). Design specification:
% passband 0..0.3, stopband 0.4..1, passband gain within +/-0.25 dB,
% stopband peak <= -40 dB. The floating-point design must pass first;
% quantized allocations are evaluated against the same specification.
n_taps = 48;
f_edges = [0 0.3 0.4 1];
pass_limit_db = 0.25;
stop_limit_db = -40;
delta_p = (10^(0.5/20)-1)/(10^(0.5/20)+1);
delta_s = 10^(stop_limit_db/20);
weights = [1 delta_p/delta_s];
h = firpm(n_taps-1, f_edges, [1 1 0 0], weights);
h = h(:).';
assert(numel(h)==n_taps && max(abs(h))<1);

% Quotas are counts of 16-, 8-, and 4-bit coefficients, not measured
% FPGA resource budgets. All counts are even so symmetric allocations
% are possible, but the current DP does not enforce symmetry.
quotas = [24 16 8; 16 24 8; 12 24 12];
assert(all(sum(quotas,2)==n_taps));

nfft = 65536;
[~, omega] = freqz(h, 1, nfft);
f = omega/pi;
pass_idx = f<=f_edges(2);
stop_idx = f>=f_edges(3);
reference = response_metrics(h, pass_idx, stop_idx, nfft, ...
    pass_limit_db, stop_limit_db);
if ~reference.meets_spec
    error('Floating-point 48-tap design does not satisfy the stated specification.');
end

opts = optimoptions('intlinprog','Display','off', ...
    'RelativeGapTolerance',0,'AbsoluteGapTolerance',0, ...
    'ConstraintTolerance',1e-9);
method_rows = struct('quota_id',{},'n16',{},'n8',{},'n4',{}, ...
    'method',{},'coefficient_sse',{},'passband_max_abs_db',{}, ...
    'passband_peak_to_peak_db',{},'stopband_peak_db',{}, ...
    'max_symmetry_error',{},'meets_spec',{});
allocation_rows = zeros(n_taps*size(quotas,1), 11);

for k = 1:size(quotas,1)
    quota = quotas(k,:);
    [w_dp,q_dp,info_dp] = adaptive_precision_dp(h,quota);
    [w_greedy,q_greedy] = adaptive_precision_error_greedy(h,quota);
    [w_milp,q_milp,fval] = solve_assignment(h,quota,opts);

    assert(isequal(width_counts(w_dp),quota));
    assert(isequal(width_counts(w_greedy),quota));
    assert(isequal(width_counts(w_milp),quota));
    sse_dp = sum((h-q_dp).^2);
    sse_greedy = sum((h-q_greedy).^2);
    sse_milp = sum((h-q_milp).^2);
    fprintf('Quota %d [%d %d %d]: DP %.12g, greedy %.12g, MILP %.12g, solver %.12g, gap %.12g\n', ...
        k,quota(1),quota(2),quota(3),sse_dp,sse_greedy,sse_milp, ...
        fval,sse_milp-sse_dp);
    assert(abs(sse_dp-info_dp.dp_optimal_cost)<1e-10);
    assert(abs(sse_dp-sse_milp)<1e-10);  % optima, not necessarily allocations
    assert(abs(sse_milp-fval)<1e-10);
    assert(sse_greedy>=sse_dp-1e-10);

    widths = {w_dp,w_greedy,w_milp};
    coeffs = {q_dp,q_greedy,q_milp};
    names = {'DP','greedy','MILP'};
    for m = 1:3
        metrics = response_metrics(coeffs{m}, pass_idx, stop_idx, ...
            nfft, pass_limit_db, stop_limit_db);
        row = struct('quota_id',k,'n16',quota(1),'n8',quota(2), ...
            'n4',quota(3),'method',string(names{m}), ...
            'coefficient_sse',sum((h-coeffs{m}).^2), ...
            'passband_max_abs_db',metrics.pass_max_abs_db, ...
            'passband_peak_to_peak_db',metrics.pass_peak_to_peak_db, ...
            'stopband_peak_db',metrics.stop_peak_db, ...
            'max_symmetry_error',max(abs(coeffs{m}-fliplr(coeffs{m}))), ...
            'meets_spec',metrics.meets_spec);
        method_rows(end+1) = row; %#ok<AGROW>
    end
    ix = (k-1)*n_taps+(1:n_taps);
    allocation_rows(ix,:) = [repmat(k,n_taps,1), (1:n_taps).', ...
        h(:), w_dp(:), q_dp(:), w_greedy(:), q_greedy(:), ...
        w_milp(:), q_milp(:), (h(:)-q_dp(:)).^2, ...
        (h(:)-q_greedy(:)).^2];
end

out_dir = fullfile(case_dir,'results_matlab_recomputed');
if exist(out_dir,'dir')
    error('Results directory exists; preserve previous evidence: %s',out_dir);
end
mkdir(out_dir);
method_table = struct2table(method_rows);
allocation_table = array2table(allocation_rows,'VariableNames', ...
    {'quota_id','tap_index','ideal_coefficient','dp_width','dp_coefficient', ...
     'greedy_width','greedy_coefficient','milp_width','milp_coefficient', ...
     'dp_squared_error','greedy_squared_error'});
writetable(method_table,fullfile(out_dir,'method_metrics.csv'));
writetable(allocation_table,fullfile(out_dir,'allocations.csv'));
writematrix([(1:n_taps).',h(:)],fullfile(out_dir,'ideal_coefficients.csv'));
save(fullfile(out_dir,'case_data.mat'),'h','quotas','method_table', ...
    'allocation_table','reference','f_edges','pass_limit_db', ...
    'stop_limit_db','weights','nfft');
fprintf('Reference: max passband |dB| %.4f; stopband peak %.4f dB\n', ...
    reference.pass_max_abs_db,reference.stop_peak_db);
disp(method_table);
fprintf('Results: %s\n',out_dir);
end

function counts = width_counts(w)
counts = [sum(w==16),sum(w==8),sum(w==4)];
end

function metrics = response_metrics(h, pass_idx, stop_idx, nfft, ...
        pass_limit_db, stop_limit_db)
H = freqz(h,1,nfft);
pass_db = 20*log10(max(abs(H(pass_idx)),realmin));
stop_peak_db = 20*log10(max(max(abs(H(stop_idx))),realmin));
metrics.pass_max_abs_db = max(abs(pass_db));
metrics.pass_peak_to_peak_db = max(pass_db)-min(pass_db);
metrics.stop_peak_db = stop_peak_db;
metrics.meets_spec = metrics.pass_max_abs_db<=pass_limit_db && ...
    stop_peak_db<=stop_limit_db;
end

function [widths,quantized,fval] = solve_assignment(h,quota,opts)
% Same binary assignment model and quantizer as run_assignment_baseline.m.
n = numel(h);
choices = [16 8 4];
cost = zeros(n,3);
for j = 1:3
    s = 2^(choices(j)-1);
    cost(:,j) = (h(:)-round(h(:)*s)/s).^2;
end
Aeq = zeros(n+3,3*n);
beq = [ones(n,1);quota(:)];
for i = 1:n
    Aeq(i,i:n:3*n) = 1;
end
for j = 1:3
    Aeq(n+j,(j-1)*n+(1:n)) = 1;
end
[x,fval,flag] = intlinprog(cost(:),1:3*n,[],[],Aeq,beq, ...
    zeros(3*n,1),ones(3*n,1),opts);
assert(flag>0 && all(abs(Aeq*x-beq)<1e-8));
X = reshape(x,n,3);
assert(all(sum(X>0.5,2)==1));
[~,choice_index] = max(X,[],2);
widths = reshape(choices(choice_index),1,[]);
quantized = round(h.*2.^(widths-1))./2.^(widths-1);
assert(isequal(size(widths),size(h)) && isequal(size(quantized),size(h)));
end
