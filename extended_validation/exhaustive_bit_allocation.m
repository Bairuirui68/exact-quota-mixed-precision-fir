%% Exhaustive Search for Optimal Bit Allocation
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 穷举搜索最优位宽分配，验证启发式策略的差距

function [optimal_allocation, all_results] = exhaustive_bit_allocation(coeffs, dsp_budget)
% EXHAUSTIVE_BIT_ALLOCATION 穷举搜索最优位宽分配
%
% 输入：
%   coeffs      - 原始 FIR 系数（浮点，1×N 向量）
%   dsp_budget  - 位宽配额 [n_16bit, n_8bit, n_4bit]
%
% 输出：
%   optimal_allocation - 最优分配方案（结构体）
%   all_results        - 所有方案的结果（结构体数组）

    N = length(coeffs);
    total_dsp = sum(dsp_budget);

    if N ~= total_dsp
        error('系数数量 (%d) 必须等于配额总数 (%d)', N, total_dsp);
    end

    
    
    
    
    

    %% 生成所有可能的分配方案
    % 使用组合数学：从 N 个位置中选择 n1 个给 16-bit，
    % 再从剩余 N-n1 个中选择 n2 个给 8-bit，剩余给 4-bit

    n1 = dsp_budget(1);  % 16-bit 数量
    n2 = dsp_budget(2);  % 8-bit 数量
    n3 = dsp_budget(3);  % 4-bit 数量

    % 总方案数: C(N, n1) × C(N-n1, n2)
    total_combinations = nchoosek(N, n1) * nchoosek(N - n1, n2);
    
    

    % 生成所有 16-bit 位置组合
    idx_16bit_all = nchoosek(1:N, n1);

    % 预分配结果数组
    all_results = struct('allocation', {}, 'mse', {}, ...
                        'idx_16', {}, 'idx_8', {}, 'idx_4', {});

    count = 0;

    % 遍历所有 16-bit 位置组合
    for i = 1:size(idx_16bit_all, 1)
        idx_16 = idx_16bit_all(i, :);
        remaining = setdiff(1:N, idx_16);

        % 从剩余位置生成所有 8-bit 组合
        if n2 > 0
            idx_8bit_all = nchoosek(remaining, n2);
        else
            idx_8bit_all = [];
        end

        for j = 1:max(1, size(idx_8bit_all, 1))
            if n2 > 0
                idx_8 = idx_8bit_all(j, :);
            else
                idx_8 = [];
            end

            % 剩余位置分配给 4-bit
            idx_4 = setdiff(remaining, idx_8);

            % 构建分配方案
            allocation = zeros(1, N);
            allocation(idx_16) = 16;
            allocation(idx_8) = 8;
            allocation(idx_4) = 4;

            % 计算此方案的 MSE
            quantized_coeffs = zeros(1, N);
            for k = 1:N
                w = allocation(k);
                scale = 2^(w-1);
                quantized_coeffs(k) = round(coeffs(k) * scale) / scale;
            end

            mse = mean((coeffs - quantized_coeffs).^2);

            % 存储结果
            count = count + 1;
            all_results(count).allocation = allocation;
            all_results(count).mse = mse;
            all_results(count).idx_16 = idx_16;
            all_results(count).idx_8 = idx_8;
            all_results(count).idx_4 = idx_4;
        end
    end

    

    %% 找出最优方案
    all_mse = [all_results.mse];
    [min_mse, min_idx] = min(all_mse);
    optimal_allocation = all_results(min_idx);

    
    
    
    
    
    
    
    

    %% 统计分析
    
    
    
    
    
    
    
    
    

end
