function run_assignment_baseline()
% Compare the existing quota DP with an exact binary assignment MILP.
root = fileparts(mfilename('fullpath'));
addpath(root);
data = load(fullfile(root, 'extended_validation_results.mat'), 'filter_results');
results = data.filter_results;
outdir = fullfile(root, 'assignment_baseline_final_20261104');
if exist(outdir, 'dir')
    error('Output directory already exists; preserving prior evidence: %s', outdir);
end
mkdir(outdir);

rows = cell(numel(results), 1);
milp_times = zeros(numel(results), 1);
dp_times = zeros(numel(results), 1);
objective_gaps = zeros(numel(results), 1);
milp_opts = optimoptions('intlinprog', 'Display', 'off', ...
    'RelativeGapTolerance', 0, 'AbsoluteGapTolerance', 0, ...
    'ConstraintTolerance', 1e-9);

for k = 1:numel(results)
    h = results(k).coeffs(:);
    cfg = results(k).config;
    quota = cfg.budget(:);
    n = numel(h);

    % Warm up the full baseline operation before recorded runs.
    solve_assignment(h,quota,milp_opts);
    t = zeros(1,5);
    fval = NaN;
    for rep = 1:5
        tic;
        [fval,output] = solve_assignment(h,quota,milp_opts);
        t(rep) = toc;
        if ~isfield(output,'exitflag') || output.exitflag <= 0 || ...
                ~isfield(output,'absolutegap') || output.absolutegap > 1e-12
            error('MILP did not certify optimality at case %d.',k);
        end
    end
    milp_times(k) = median(t);

    % Time current DP over the identical input-to-allocation operation.
    adaptive_precision_dp(h', quota');
    t = zeros(1,5);
    for rep = 1:5
        tic;
        [~,~,info] = adaptive_precision_dp(h',quota');
        t(rep) = toc;
    end
    dp_times(k) = median(t);
    objective_gaps(k) = abs(fval - info.dp_optimal_cost);
    if objective_gaps(k) > 1e-12 + 1e-10*max(abs(fval),abs(info.dp_optimal_cost))
        error('Objective mismatch at case %d: MILP %.17g DP %.17g',k,fval,info.dp_optimal_cost);
    end
    rows{k} = {k, string(cfg.filter_type), cfg.fc, n, quota(1), quota(2), quota(3), ...
        fval, info.dp_optimal_cost, objective_gaps(k), milp_times(k), dp_times(k), ...
        output.absolutegap, output.relativegap, output.numnodes};
    fprintf('Case %3d/%3d: n=%d, MILP %.4g ms, DP %.4g ms, gap %.3g\n', ...
        k,numel(results),n,milp_times(k)*1e3,dp_times(k)*1e3,objective_gaps(k));
end

headers = {'case_id','filter_type','fc','taps','quota_16','quota_8','quota_4', ...
    'milp_objective','dp_objective','absolute_gap','milp_median_s','dp_median_s', ...
    'milp_abs_gap_certificate','milp_rel_gap_certificate','milp_branch_nodes'};
T = cell2table(vertcat(rows{:}),'VariableNames',headers);
writetable(T,fullfile(outdir,'assignment_baseline_results.csv'));
summary = struct('matlab_version',version,'optimization_toolbox',ver('optim'), ...
    'method','binary assignment MILP via intlinprog','cases',numel(results), ...
    'all_objectives_match',true,'max_abs_objective_gap',max(objective_gaps), ...
    'median_milp_ms',median(milp_times)*1e3,'median_dp_ms',median(dp_times)*1e3, ...
    'median_milp_over_dp',median(milp_times./dp_times), ...
    'timing','warmup then 5 repetitions; median; both full operations include cost construction and result extraction');
save(fullfile(outdir,'assignment_baseline_summary.mat'),'T','summary');
fid=fopen(fullfile(outdir,'SUMMARY.md'),'w');
fprintf(fid,'# Exact assignment baseline\n\n');
fprintf(fid,'- Baseline: binary assignment MILP solved by MATLAB intlinprog (%s).\n',version);
fprintf(fid,'- Cases: %d existing FIR configurations.\n',numel(results));
fprintf(fid,'- All certified objective values match DP within stated numerical tolerance: yes.\n');
fprintf(fid,'- Maximum absolute objective gap: %.17g.\n',max(objective_gaps));
fprintf(fid,'- Median solver-call time: %.6g ms; median DP function time: %.6g ms.\n',median(milp_times)*1e3,median(dp_times)*1e3);
fprintf(fid,'- Timing: warmup then five repetitions, median; each method includes cost construction, optimization and result extraction. MATLAB function/JIT overhead is included.\n');
fprintf(fid,'- All per-case times, quotas and solver certificates are in `assignment_baseline_results.csv`.\n');
fclose(fid);
disp(summary);
end

function [fval, output] = solve_assignment(h,quota,opts)
n = numel(h);
widths = [16 8 4];
cost = zeros(n,3);
for j = 1:3
    scale = 2^(widths(j)-1);
    q = round(h*scale)/scale;
    cost(:,j) = (h-q).^2;
end
Aeq = zeros(n+3,n*3);
beq = [ones(n,1);quota(:)];
for i = 1:n
    Aeq(i,i:n:n*3)=1;
end
for j=1:3
    Aeq(n+j,(j-1)*n+(1:n))=1;
end
[~,fval,exitflag,output] = intlinprog(cost(:),1:n*3,[],[],Aeq,beq, ...
    zeros(n*3,1),ones(n*3,1),opts);
output.exitflag = exitflag;
end
