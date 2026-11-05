function run_radix_quota_dp()
% Verify scalar integer-cost encoding of exact width quotas on saved cases.
root = fileparts(mfilename('fullpath'));
data = load(fullfile(root,'extended_validation_results.mat'),'filter_results');
outdir = fullfile(root,'radix_quota_dp_20261104');
if exist(outdir,'dir'), error('Preserving existing output directory: %s',outdir); end
mkdir(outdir);
cases=data.filter_results; rows=cell(numel(cases),1);
for k=1:numel(cases)
    h=cases(k).coeffs(:); q=cases(k).config.budget(:); N=numel(h);
    [alloc,J]=radix_solver(h,q);
    if any([sum(alloc==16);sum(alloc==8);sum(alloc==4)]~=q)
        error('Decoded quotas mismatch in case %d',k);
    end
    if abs(J-cases(k).dp_mse*N)>1e-18+1e-12*sum(h.^2)
        error('Objective mismatch in case %d',k);
    end
    radix_times=zeros(1,5); direct_times=zeros(1,5);
    for r=1:5
        tic; [~,~]=radix_solver(h,q); radix_times(r)=toc;
        tic; [~,~,info]=adaptive_precision_dp(h',q'); direct_times(r)=toc;
    end
    rows{k}={k,N,q(1),q(2),q(3),N+(N+1)*q(1)+q(2),J, ...
        median(radix_times),median(direct_times),median(radix_times)/median(direct_times)};
    fprintf('Case %3d/%3d cost=%d, radix %.4g ms, quota-DP %.4g ms\n', ...
        k,numel(cases),N+(N+1)*q(1)+q(2),median(radix_times)*1e3,median(direct_times)*1e3);
end
T=cell2table(vertcat(rows{:}),'VariableNames', ...
    {'case_id','N','n16','n8','n4','encoded_exact_cost','objective','radix_median_s','quota_dp_median_s','radix_over_quota_dp'});
writetable(T,fullfile(outdir,'radix_quota_dp_results.csv'));
fid=fopen(fullfile(outdir,'ENCODING_PROOF.md'),'w');
fprintf(fid,['# Radix encoding of exact width quotas\n\nLet `B=N+1` and assign integer ' ...
    'resource costs `r16=B+1`, `r8=2`, `r4=1` to each coefficient option. ' ...
    'For any assignment, total cost is `R=N+B*n16+n8`. Since `0<=n8<=N<B`, ' ...
    '`R` uniquely determines `n16=floor((R-N)/B)` and ' ...
    '`n8=(R-N) mod B`; `n4=N-n16-n8`. Thus exact quota vector `q` is equivalent ' ...
    'to exact scalar cost `R*=N+B*q16+q8`.\n\nThe scalar-cost DP stores minimum error separately for each exact cost. ' ...
    'Selecting state `R*` enforces the quota vector exactly. A budget-only ' ...
    'condition `R<=R*` does not enforce those quotas: cheaper non-target ' ...
    'vectors may also be feasible.\n\nTested all 108 saved cases; see CSV. The recurrence uses only three ' ...
    'cost increments per coefficient, giving `O(N R*)` transitions and ' ...
    '`O(R*)` rolling cost memory, or `O(N R*)` predecessor storage when retaining traceback.\n']);
fclose(fid);
end

function [allocation,best]=radix_solver(h,quota)
N=numel(h); B=N+1; rc=[B+1,2,1]; target=N+B*quota(1)+quota(2);
widths=[16,8,4]; errors=zeros(N,3);
for j=1:3
    s=2^(widths(j)-1); e=h-round(h*s)/s; errors(:,j)=e.^2;
end
prev=inf(1,target+1); prev(1)=0;
choice=zeros(N+1,target+1,'uint8');
prev_cost=zeros(N+1,target+1,'uint32');
for i=1:N
    cur=inf(1,target+1);
    for c=0:target
        if isinf(prev(c+1)), continue; end
        for j=1:3
            nc=c+rc(j);
            if nc>target, continue; end
            v=prev(c+1)+errors(i,j);
            if v<cur(nc+1)
                cur(nc+1)=v;
                choice(i+1,nc+1)=j;
                prev_cost(i+1,nc+1)=c;
            end
        end
    end
    prev=cur;
end
best=prev(target+1);
if isinf(best), error('Exact encoded cost is unreachable'); end
allocation=zeros(N,1); c=target;
for i=N:-1:1
    j=choice(i+1,c+1);
    if j==0, error('Backtracking failed'); end
    allocation(i)=widths(j);
    c=double(prev_cost(i+1,c+1));
end
if c~=0, error('Backtracking did not return to zero cost'); end
end
