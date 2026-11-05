%% Extended Validation: Main Script
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 扩展验证主脚本

clear; close all; clc;

fprintf('========================================\n');
fprintf('扩展验证实验\n');
fprintf('========================================\n');
fprintf('日期: %s\n', datestr(now));
fprintf('MATLAB 版本: %s\n', version);
fprintf('随机种子: 42\n');
fprintf('========================================\n\n');

%% 第 1 部分：小规模穷举校验
fprintf('执行第 1 部分...\n\n');
small_scale_results = run_small_scale_verification();

% 检查 DP 是否全部通过
if ~all([small_scale_results.dp_correct])
    error('❌ DP 实现存在错误，请先修正后再运行第 2 部分');
end

fprintf('✅ 第 1 部分完成，DP 实现全部通过验证\n\n');
pause(2);

%% 第 2 部分：滤波器测试矩阵
fprintf('执行第 2 部分...\n\n');
filter_results = run_filter_test_matrix();

fprintf('✅ 第 2 部分完成\n\n');

%% 保存结果
metadata=struct('matlab_version',version,'seed',42,'highpass','modulated windowed-sinc lowpass; Type IV for even taps','timing','5 repeats after warmup; algorithm fprintf and plots removed','tolerance','1e-20 + 1e-12*max(sum(h.^2),1e-12)');
results_file = 'extended_validation_results.mat';
save(results_file, 'small_scale_results', 'filter_results', 'metadata', ...
    '-v7.3');

fprintf('========================================\n');
fprintf('结果已保存: %s\n', results_file);
fprintf('========================================\n\n');

%% 生成报告
generate_validation_report(small_scale_results, filter_results);

fprintf('✅ 扩展验证实验完成！\n');
