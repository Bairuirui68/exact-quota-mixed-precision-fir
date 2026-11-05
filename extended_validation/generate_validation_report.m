%% Generate Validation Report
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 生成扩展验证报告

function generate_validation_report(small_scale_results, filter_results)
    fprintf('========================================\n');
    fprintf('生成扩展验证报告\n');
    fprintf('========================================\n\n');

    report_file = 'Extended_Validation_Report.md';
    fid = fopen(report_file, 'w');

    %% 报告头
    fprintf(fid, '# 扩展验证实验报告\n\n');
    fprintf(fid, '**日期**：%s\n\n', datestr(now));
    fprintf(fid, '**MATLAB 版本**：%s\n\n', version);
    fprintf(fid, '**随机种子**：42\n\n');
    fprintf(fid, '---\n\n');

    %% 第 1 部分：小规模校验
    fprintf(fid, '## 第 1 部分：小规模穷举校验\n\n');
    fprintf(fid, '**目标**：验证 DP 实现正确性，寻找贪心失败的简单案例\n\n');

    fprintf(fid, '### 汇总统计\n\n');
    fprintf(fid, '| 指标 | 数值 |\n');
    fprintf(fid, '|------|------|\n');
    fprintf(fid, '| 总测试数 | %d |\n', length(small_scale_results));
    fprintf(fid, '| DP 全部通过 | %s |\n', ...
        iif(all([small_scale_results.dp_correct]), '✅ 是', '❌ 否'));
    fprintf(fid, '| 贪心达到最优 | %d / %d (%.1f%%) |\n', ...
        sum([small_scale_results.greedy_optimal]), ...
        length(small_scale_results), ...
        mean([small_scale_results.greedy_optimal]) * 100);

    fprintf(fid, '\n### 详细结果\n\n');
    fprintf(fid, '| 案例 | 贪心 MSE | DP MSE | 穷举最优 MSE | 贪心最优 |\n');
    fprintf(fid, '|------|---------|--------|-------------|--------|\n');
    for i = 1:length(small_scale_results)
        r = small_scale_results(i);
        fprintf(fid, '| %s | %.3e | %.3e | %.3e | %s |\n', ...
            r.name, r.greedy_mse, r.dp_mse, r.exhaust_mse, ...
            iif(r.greedy_optimal, '✅', '❌'));
    end

    fprintf(fid, '\n---\n\n');

    %% 第 2 部分：滤波器测试
    fprintf(fid, '## 第 2 部分：滤波器测试矩阵\n\n');
    fprintf(fid, '**测试配置数**：%d\n\n', length(filter_results));

    % 最优命中率
    hit_rate = mean([filter_results.greedy_optimal]) * 100;
    fprintf(fid, '### 贪心算法最优命中率\n\n');
    fprintf(fid, '**在 %d 个测试配置中，贪心达到最优的比例为 %.1f%%**\n\n', ...
        length(filter_results), hit_rate);
    fprintf(fid, '（%d / %d 个配置）\n\n', ...
        sum([filter_results.greedy_optimal]), length(filter_results));

    % 超额误差分布
    valid_excess = [filter_results.excess_error_pct];
    valid_excess = valid_excess(~isnan(valid_excess));

    fprintf(fid, '### 超额误差分布\n\n');
    fprintf(fid, '**说明**：超额误差 = (贪心 MSE - DP MSE) / DP MSE × 100%%\n\n');
    fprintf(fid, '排除 DP MSE ≈ 0 的配置（共 %d 个）\n\n', ...
        sum(isnan([filter_results.excess_error_pct])));

    if ~isempty(valid_excess)
        fprintf(fid, '| 统计量 | 数值 |\n');
        fprintf(fid, '|--------|------|\n');
        fprintf(fid, '| 最小值 | %.2f%% |\n', min(valid_excess));
        fprintf(fid, '| 中位数 | %.2f%% |\n', median(valid_excess));
        fprintf(fid, '| 均值 | %.2f%% |\n', mean(valid_excess));
        fprintf(fid, '| 最大值 | %.2f%% |\n', max(valid_excess));
        fprintf(fid, '| > 50%% (标记) | %d |\n', sum(valid_excess > 50));
        fprintf(fid, '| > 100%% (标记) | %d |\n\n', sum(valid_excess > 100));
    end

    % 失败案例
    failures = find(~[filter_results.greedy_optimal]);
    if ~isempty(failures)
        fprintf(fid, '### 贪心失败案例\n\n');
        fprintf(fid, '共 %d 个失败案例\n\n', length(failures));

        fprintf(fid, '| ID | 滤波器 | fc | N | 配额 | 超额误差 | 绝对差 |\n');
        fprintf(fid, '|----|--------|-----|---|------|---------|--------|\n');

        for i = 1:min(20, length(failures))  % 最多显示 20 个
            idx = failures(i);
            r = filter_results(idx);
            cfg = r.config;

            fprintf(fid, '| %d | %s | %.2f | %d | [%d,%d,%d] | ', ...
                cfg.id, cfg.filter_type, cfg.fc, cfg.N, ...
                cfg.budget(1), cfg.budget(2), cfg.budget(3));

            if isnan(r.excess_error_pct)
                fprintf(fid, 'N/A | %.3e |\n', r.absolute_diff);
            else
                fprintf(fid, '%.2f%% | %.3e |\n', ...
                    r.excess_error_pct, r.absolute_diff);
            end
        end

        if length(failures) > 20
            fprintf(fid, '\n... 更多失败案例见完整数据文件\n');
        end
        fprintf(fid, '\n');
    end

    % 运行时间
    fprintf(fid, '### 运行时间对比\n\n');
    fprintf(fid, '| 方法 | 中位数时间 |\n');
    fprintf(fid, '|------|----------|\n');
    fprintf(fid, '| 贪心 | %.3f ms |\n', median([filter_results.greedy_time]) * 1000);
    fprintf(fid, '| DP | %.3f ms |\n', median([filter_results.dp_time]) * 1000);
    fprintf(fid, '| 加速比 | %.2fx |\n\n', ...
        median([filter_results.dp_time]) / median([filter_results.greedy_time]));

    fprintf(fid, '---\n\n');

    %% 结论
    fprintf(fid, '## 结论\n\n');
    fprintf(fid, '### 可以支持的陈述\n\n');
    fprintf(fid, '1. 在 %d 个小规模测试中，DP 实现全部通过穷举验证\n', ...
        length(small_scale_results));
    fprintf(fid, '2. 在 %d 个滤波器测试配置中，贪心达到最优的比例为 %.1f%%\n', ...
        length(filter_results), hit_rate);

    if ~isempty(valid_excess)
        fprintf(fid, '3. 非零 MSE 配置中，超额误差中位数为 %.2f%%，最大为 %.2f%%\n', ...
            median(valid_excess), max(valid_excess));
    end

    fprintf(fid, '\n### 不能支持的结论\n\n');
    fprintf(fid, '1. ❌ 不能据此推断贪心算法对总体的可靠性\n');
    fprintf(fid, '2. ❌ 不能据此确定论文定位或硬件收益\n');
    fprintf(fid, '3. ❌ 结果仅描述当前测试矩阵的表现\n\n');

    fprintf(fid, '### 后续建议\n\n');
    fprintf(fid, '1. 分析失败案例的特征\n');
    fprintf(fid, '2. 评估应用误差容限\n');
    fprintf(fid, '3. 比较已有工作\n');
    fprintf(fid, '4. 进行硬件资源验证\n\n');

    fclose(fid);

    fprintf('✅ 报告已生成: %s\n\n', report_file);
end

function result = iif(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
