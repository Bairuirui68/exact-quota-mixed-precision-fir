%% Extended Validation: Part 2 - Filter Test Matrix
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 108 个滤波器测试配置

function filter_results = run_filter_test_matrix()
    fprintf('========================================\n');
    fprintf('第 2 部分：滤波器测试矩阵（108 个配置）\n');
    fprintf('========================================\n\n');

    rng(42);  % 固定随机种子

    %% 测试矩阵定义
    filter_types = {'lowpass', 'highpass', 'bandpass'};
    cutoff_freqs = [0.2, 0.3, 0.4, 0.5];
    tap_configs = {
        8,  {[2,4,2], [4,2,2], [1,2,5]};  % N=8
        16, {[4,8,4], [8,4,4], [2,4,10]};  % N=16
        32, {[8,16,8], [16,8,8], [4,8,20]};  % N=32
    };

    %% 生成所有测试配置
    configs = {};
    count = 0;

    for fi = 1:length(filter_types)
        for ci = 1:length(cutoff_freqs)
            for ti = 1:size(tap_configs, 1)
                N = tap_configs{ti, 1};
                budgets = tap_configs{ti, 2};

                for bi = 1:length(budgets)
                    count = count + 1;
                    configs{count} = struct(...
                        'id', count, ...
                        'filter_type', filter_types{fi}, ...
                        'fc', cutoff_freqs(ci), ...
                        'N', N, ...
                        'budget', budgets{bi});
                end
            end
        end
    end

    fprintf('总配置数: %d\n\n', count);

    %% 执行测试
    results = struct('config', {}, 'coeffs', {}, ...
                    'greedy_mse', {}, 'dp_mse', {}, ...
                    'excess_error_pct', {}, 'absolute_diff', {}, ...
                    'greedy_optimal', {}, ...
                    'greedy_time', {}, 'dp_time', {}, 'greedy_allocation', {}, 'dp_allocation', {});

    fprintf('开始测试...\n');
    progress_step = 10;

    for i = 1:count
        cfg = configs{i};

        % 生成系数
        if strcmp(cfg.filter_type, 'bandpass')
            % 带通：双边缘频率
            fc1 = cfg.fc - 0.1;
            fc2 = cfg.fc + 0.1;
            fc1 = max(fc1, 0.05);
            fc2 = min(fc2, 0.95);
            coeffs = generate_test_fir(cfg.filter_type, cfg.N-1, ...
                'fc1', fc1, 'fc2', fc2);
        else
            coeffs = generate_test_fir(cfg.filter_type, cfg.N-1, ...
                'fc', cfg.fc);
        end

        % 验证配额合法性
        validate_budget(cfg.budget, cfg.N);

        % 运行测试（预热 + 重复测量）
        [greedy_mse, greedy_time] = measure_method(...
            @() adaptive_precision_error_greedy(coeffs, cfg.budget));
        [dp_mse, dp_time] = measure_method(...
            @() adaptive_precision_dp(coeffs, cfg.budget));

        [ga,~,gi] = adaptive_precision_error_greedy(coeffs,cfg.budget);
        [da,~,di] = adaptive_precision_dp(coeffs,cfg.budget);
        assert(numel(coeffs)==cfg.N);
        assert(isequal([sum(ga==16),sum(ga==8),sum(ga==4)],cfg.budget));
        assert(isequal([sum(da==16),sum(da==8),sum(da==4)],cfg.budget));
        assert(abs(sum((coeffs-round(coeffs.*2.^(da-1))./2.^(da-1)).^2)-di.dp_optimal_cost)<1e-18+1e-12*sum(coeffs.^2));
        results(i).greedy_allocation=ga;
        results(i).dp_allocation=da;
        % 计算指标
        TOL = 1e-20 + 1e-12 * max(sum(coeffs.^2), 1e-12);
        greedy_optimal = abs(greedy_mse - dp_mse) < TOL;

        if dp_mse == 0
            % 最优 MSE ≈ 0
            excess_error_pct = NaN;
            absolute_diff = greedy_mse - dp_mse;
        else
            excess_error_pct = (greedy_mse - dp_mse) / dp_mse * 100;
            absolute_diff = greedy_mse - dp_mse;
        end

        % 存储结果
        results(i).config = cfg;
        results(i).coeffs = coeffs;
        results(i).greedy_mse = greedy_mse;
        results(i).dp_mse = dp_mse;
        results(i).excess_error_pct = excess_error_pct;
        results(i).absolute_diff = absolute_diff;
        results(i).greedy_optimal = greedy_optimal;
        results(i).greedy_time = greedy_time;
        results(i).dp_time = dp_time;

        % 进度报告
        if mod(i, progress_step) == 0
            fprintf('  完成 %d / %d (%.1f%%)\n', i, count, i/count*100);
        end
    end

    fprintf('✅ 测试完成！\n\n');

    %% 统计汇总
    fprintf('========================================\n');
    fprintf('滤波器测试汇总\n');
    fprintf('========================================\n');

    % 最优命中率
    hit_rate = mean([results.greedy_optimal]) * 100;
    fprintf('贪心达到最优: %d / %d (%.1f%%)\n', ...
        sum([results.greedy_optimal]), count, hit_rate);

    % 超额误差分布（排除 MSE=0）
    valid_excess = [results.excess_error_pct];
    valid_excess = valid_excess(~isnan(valid_excess));

    if ~isempty(valid_excess)
        fprintf('\n超额误差分布（排除 DP MSE ≈ 0）:\n');
        fprintf('  最小值: %.2f%%\n', min(valid_excess));
        fprintf('  中位数: %.2f%%\n', median(valid_excess));
        fprintf('  最大值: %.2f%%\n', max(valid_excess));
        fprintf('  均值:   %.2f%%\n', mean(valid_excess));

        % 标记明显/严重失败
        n_significant = sum(valid_excess > 50);
        n_severe = sum(valid_excess > 100);
        fprintf('  > 50%% (明显失败): %d\n', n_significant);
        fprintf('  > 100%% (严重失败): %d\n', n_severe);
    end

    % 绝对 MSE 差
    abs_diff = [results.absolute_diff];
    fprintf('\n绝对 MSE 差:\n');
    fprintf('  最小值: %.3e\n', min(abs_diff));
    fprintf('  中位数: %.3e\n', median(abs_diff));
    fprintf('  最大值: %.3e\n', max(abs_diff));

    % 运行时间
    fprintf('\n运行时间（中位数）:\n');
    fprintf('  贪心: %.3f ms\n', median([results.greedy_time]) * 1000);
    fprintf('  DP:   %.3f ms\n', median([results.dp_time]) * 1000);
    fprintf('  加速比: %.2fx\n', median([results.dp_time]) / median([results.greedy_time]));

    fprintf('========================================\n\n');

    filter_results = results;
end

function validate_budget(budget, N)
    if any(budget < 0)
        error('配额包含负数');
    end

    if sum(budget) ~= N
        error('配额总和 (%d) ≠ 抽头数 (%d)', sum(budget), N);
    end

    if any(mod(budget, 1) ~= 0)
        error('配额包含非整数');
    end
end

function [mse, time_median] = measure_method(method_func)
    % 预热
    [~, ~, info] = method_func();

    % 重复测量（排除打印和绘图时间）
    N_REPEAT = 5;
    times = zeros(1, N_REPEAT);

    for i = 1:N_REPEAT
        tic;
        [~, ~, info] = method_func();
        times(i) = toc;
    end

    mse = info.mse;
    time_median = median(times);
end
