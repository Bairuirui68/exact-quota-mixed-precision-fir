%% Adaptive Precision Allocation: Error-Reduction Greedy
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 基于平方误差减量的贪心分配算法

function [bit_allocation, quantized_coeffs, info] = ...
    adaptive_precision_error_greedy(coeffs, dsp_budget)
% ADAPTIVE_PRECISION_ERROR_GREEDY 基于平方误差减量的贪心分配
%
% 输入：
%   coeffs      - 原始 FIR 系数（浮点，1×N 向量）
%   dsp_budget  - 位宽配额 [n_16bit, n_8bit, n_4bit]
%
% 输出：
%   bit_allocation   - 位宽分配方案（1×N 向量，元素为 16/8/4）
%   quantized_coeffs - 量化后的系数（1×N 向量）
%   info             - 详细信息结构体
%
% 算法：
%   1. 初始所有系数分配最低精度（4-bit）
%   2. 计算每个系数从当前精度升级到下一级的平方误差减量
%   3. 贪心选择误差减量最大的升级
%   4. 重复直到满足配额约束

    N = length(coeffs);
    total_dsp = sum(dsp_budget);

    if N ~= total_dsp
        error('系数数量 (%d) 必须等于配额总数 (%d)', N, total_dsp);
    end

    
    
    
    
    
    

    %% 步骤 1: 初始化 - 所有系数分配最低精度（4-bit）
    bit_allocation = 4 * ones(1, N);
    available = [dsp_budget(1), dsp_budget(1)+dsp_budget(2), dsp_budget(3)];  % [n_16bit, n_8bit, n_4bit]
    available(3) = 0;  % 4-bit 已全部分配

    

    %% 计算每个系数在不同位宽下的量化误差平方
    error_sq = zeros(3, N);  % [16-bit; 8-bit; 4-bit]

    for i = 1:N
        for w_idx = 1:3
            w = [16, 8, 4];
            scale = 2^(w(w_idx)-1);
            h_q = round(coeffs(i) * scale) / scale;
            error_sq(w_idx, i) = (coeffs(i) - h_q)^2;
        end
    end

    %% 步骤 2: 贪心升级
    % 优先级: 4→8 或 8→16，取决于误差减量

    upgrade_log = {};

    while sum(available(1:2)) > 0
        % 计算所有可能的升级及其误差减量
        gains = inf(1, N);  % 误差减量（负值表示误差减少）
        upgrade_to = zeros(1, N);  % 目标位宽

        for i = 1:N
            current_w = bit_allocation(i);

            if current_w == 4 && available(2) > 0
                % 可以从 4-bit 升级到 8-bit
                gains(i) = error_sq(2, i) - error_sq(3, i);  % 减量（负值）
                upgrade_to(i) = 8;
            elseif current_w == 8 && available(1) > 0
                % 可以从 8-bit 升级到 16-bit
                gains(i) = error_sq(1, i) - error_sq(2, i);  % 减量（负值）
                upgrade_to(i) = 16;
            end
        end

        % 选择误差减量最大（最负）的升级
        [max_gain, best_idx] = min(gains);  % min 因为减量是负值

        if ~isfinite(max_gain)
            break;  % 没有可升级的了
        end

        % 执行升级
        old_w = bit_allocation(best_idx);
        new_w = upgrade_to(best_idx);
        bit_allocation(best_idx) = new_w;

        % 更新配额
        if new_w == 8
            available(2) = available(2) - 1;
        elseif new_w == 16
            available(1) = available(1) - 1;
        end

        % 记录日志
        upgrade_log{end+1} = sprintf('系数 %d: %d-bit → %d-bit (误差减量: %.6e)', ...
            best_idx, old_w, new_w, max_gain);
    end

    %% 步骤 3: 验证配额约束
    n_16 = sum(bit_allocation == 16);
    n_8  = sum(bit_allocation == 8);
    n_4  = sum(bit_allocation == 4);

    if n_16 ~= dsp_budget(1) || n_8 ~= dsp_budget(2) || n_4 ~= dsp_budget(3)
        error('配额约束违反: 实际 [%d,%d,%d], 期望 [%d,%d,%d]', ...
            n_16, n_8, n_4, dsp_budget(1), dsp_budget(2), dsp_budget(3));
    end

    %% 步骤 4: 量化系数
    quantized_coeffs = zeros(1, N);
    quantization_error = zeros(1, N);

    for i = 1:N
        w = bit_allocation(i);
        scale = 2^(w-1);
        quantized_coeffs(i) = round(coeffs(i) * scale) / scale;
        quantization_error(i) = coeffs(i) - quantized_coeffs(i);
    end

    %% 步骤 5: 计算指标
    mse = mean(quantization_error.^2);

    %% 整理输出信息
    info.bit_allocation = bit_allocation;
    info.group_16bit = find(bit_allocation == 16);
    info.group_8bit  = find(bit_allocation == 8);
    info.group_4bit  = find(bit_allocation == 4);
    info.quantization_error = quantization_error;
    info.mse = mse;
    info.upgrade_log = upgrade_log;

    %% 打印结果
    
    
    
    
    
    
    
    
    

    
    for i = 1:length(upgrade_log)
        
    end
    
end
