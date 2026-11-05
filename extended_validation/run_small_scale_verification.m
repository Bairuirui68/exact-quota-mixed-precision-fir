%% Extended Validation: Part 1 - Small Scale Verification
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 小规模验证，用穷举检查 DP 和贪心

function small_scale_results = run_small_scale_verification()
    fprintf('========================================\n');
    fprintf('第 1 部分：小规模校验（穷举验证）\n');
    fprintf('========================================\n\n');

    %% 配置
    N = 8;
    BASE_BUDGET = [2, 4, 2];
    rng(42);  % 固定随机种子

    results = struct('name', {}, 'coeffs', {}, 'budget', {}, ...
                    'greedy_mse', {}, 'dp_mse', {}, 'exhaust_mse', {}, ...
                    'dp_correct', {}, 'greedy_optimal', {});
    count = 0;

    %% 1.1 随机系数测试
    fprintf('[1/3] 随机系数测试（20 组）\n');
    for i = 1:10
        % Uniform[-1, 1]
        coeffs = 2 * rand(1, N) - 1;
        count = count + 1;
        results(count) = run_single_test(sprintf('Uniform_%d', i), coeffs, BASE_BUDGET);
    end

    for i = 1:10
        % Normal(0, 0.3)
        coeffs = 0.3 * randn(1, N);
        coeffs = max(min(coeffs, 1), -1);  % 截断到 [-1, 1]
        count = count + 1;
        results(count) = run_single_test(sprintf('Normal_%d', i), coeffs, BASE_BUDGET);
    end

    %% 1.2 边界情况测试
    fprintf('\n[2/3] 边界情况测试\n');

    % 全零系数
    coeffs = zeros(1, N);
    count = count + 1;
    results(count) = run_single_test('AllZero', coeffs, BASE_BUDGET);

    % 单个非零系数
    coeffs = zeros(1, N);
    coeffs(4) = 0.5;
    count = count + 1;
    results(count) = run_single_test('SingleNonZero', coeffs, BASE_BUDGET);

    % 量化网格上（8-bit）
    coeffs = [0, 0.125, 0.25, 0.375, -0.25, -0.125, 0, 0];
    count = count + 1;
    results(count) = run_single_test('OnGrid_8bit', coeffs, BASE_BUDGET);

    % 量化网格中点（8-bit，最大舍入误差）
    scale_8 = 2^7;
    coeffs = (rand(1, N) * 2 - 1) * 0.5;
    coeffs = (floor(coeffs * scale_8) + 0.5) / scale_8;  % 中点
    count = count + 1;
    results(count) = run_single_test('MidGrid_8bit', coeffs, BASE_BUDGET);

    %% 1.3 不同配额测试
    fprintf('\n[3/3] 不同配额测试\n');
    test_coeffs = generate_test_fir('lowpass', N-1, 'fc', 0.3);

    budgets = {
        [0, 0, N], 'AllMatch4bit';
        [0, N, 0], 'All8bit';
        [N, 0, 0], 'All16bit';
        [1, 6, 1], 'Unbalanced';
        [3, 2, 3], 'Reverse';
    };

    for i = 1:size(budgets, 1)
        count = count + 1;
        results(count) = run_single_test(budgets{i,2}, test_coeffs, budgets{i,1});
    end

    %% 统计汇总
    fprintf('\n========================================\n');
    fprintf('小规模校验汇总\n');
    fprintf('========================================\n');
    fprintf('总测试数: %d\n', count);
    fprintf('DP 正确数: %d\n', sum([results.dp_correct]));
    fprintf('贪心最优数: %d\n', sum([results.greedy_optimal]));
    fprintf('DP 正确率: %.1f%%\n', mean([results.dp_correct]) * 100);
    fprintf('贪心命中率: %.1f%%\n', mean([results.greedy_optimal]) * 100);

    if all([results.dp_correct])
        fprintf('✅ DP 实现全部通过验证\n');
    else
        fprintf('❌ DP 实现存在错误！\n');
        failed = find(~[results.dp_correct]);
        for i = failed
            fprintf('   失败案例: %s\n', results(i).name);
        end
    end

    fprintf('========================================\n\n');

    small_scale_results = results;
end

function result = run_single_test(name, coeffs, budget)
    TOL = 1e-20 + 1e-12 * max(sum(coeffs.^2), 1e-12);  % 数值容差

    % 运行三种方法（不计时，不打印）
    [~, ~, info_greedy] = adaptive_precision_error_greedy(coeffs, budget);
    [~, ~, info_dp] = adaptive_precision_dp(coeffs, budget);
    [optimal, ~] = exhaustive_bit_allocation(coeffs, budget);

    % 验证分配合法性
    validate_allocation(info_greedy.bit_allocation, budget, 'Greedy');
    validate_allocation(info_dp.bit_allocation, budget, 'DP');

    % 验证 DP 回溯代价一致性
    dp_cost_from_trace = info_dp.mse * length(coeffs);
    dp_cost_from_dp = info_dp.dp_optimal_cost;
    dp_cost_match = abs(dp_cost_from_trace - dp_cost_from_dp) < TOL;

    % 判定最优（按代价，不要求分配相同）
    dp_correct = abs(info_dp.mse - optimal.mse) < TOL;
    greedy_optimal = abs(info_greedy.mse - optimal.mse) < TOL;

    fprintf('  %20s: Greedy=%.3e, DP=%.3e, Exhaust=%.3e | DP OK=%d, Greedy Opt=%d\n', ...
        name, info_greedy.mse, info_dp.mse, optimal.mse, dp_correct, greedy_optimal);

    result.name = name;
    result.coeffs = coeffs;
    result.budget = budget;
    result.greedy_mse = info_greedy.mse;
    result.dp_mse = info_dp.mse;
    result.exhaust_mse = optimal.mse;
    result.dp_correct = dp_correct && dp_cost_match;
    result.greedy_optimal = greedy_optimal;
end

function validate_allocation(alloc, budget, method_name)
    n_16 = sum(alloc == 16);
    n_8  = sum(alloc == 8);
    n_4  = sum(alloc == 4);

    if n_16 ~= budget(1) || n_8 ~= budget(2) || n_4 ~= budget(3)
        error('%s 分配非法: 实际 [%d,%d,%d], 期望 [%d,%d,%d]', ...
            method_name, n_16, n_8, n_4, budget(1), budget(2), budget(3));
    end

    if any(alloc ~= 16 & alloc ~= 8 & alloc ~= 4)
        error('%s 分配包含非法位宽', method_name);
    end
end
