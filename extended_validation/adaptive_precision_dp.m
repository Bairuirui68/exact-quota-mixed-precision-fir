%% Adaptive Precision Allocation: Dynamic Programming
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 动态规划求解固定配额下的最优分配

function [bit_allocation, quantized_coeffs, info] = ...
    adaptive_precision_dp(coeffs, dsp_budget)
% ADAPTIVE_PRECISION_DP 动态规划求解最优位宽分配
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
%   目标: minimize Σ (h[i] - h_q[i])²
%   约束: 恰好使用 n1 个 16-bit, n2 个 8-bit, n3 个 4-bit
%   方法: 动态规划（背包问题变种）

    N = length(coeffs);
    n1 = dsp_budget(1);  % 16-bit
    n2 = dsp_budget(2);  % 8-bit
    n3 = dsp_budget(3);  % 4-bit

    if N ~= n1 + n2 + n3
        error('系数数量 (%d) 必须等于配额总数 (%d)', N, n1+n2+n3);
    end

    
    
    
    
    
    

    %% 步骤 1: 计算每个系数在不同位宽下的量化误差平方
    cost = zeros(N, 3);  % cost(i, w) = 系数 i 在位宽 w 下的平方误差
    % w: 1=16-bit, 2=8-bit, 3=4-bit

    for i = 1:N
        for w_idx = 1:3
            w = [16, 8, 4];
            scale = 2^(w(w_idx)-1);
            h_q = round(coeffs(i) * scale) / scale;
            cost(i, w_idx) = (coeffs(i) - h_q)^2;
        end
    end

    
    
    

    %% 步骤 2: 动态规划
    % 状态: dp(i, j1, j2, j3) = 前 i 个系数，使用 j1 个 16-bit、j2 个 8-bit、j3 个 4-bit 的最小总误差
    % 转移:
    %   dp(i+1, j1+1, j2, j3) = min(dp(i+1, j1+1, j2, j3), dp(i, j1, j2, j3) + cost(i, 1))
    %   dp(i+1, j1, j2+1, j3) = min(..., dp(i, j1, j2, j3) + cost(i, 2))
    %   dp(i+1, j1, j2, j3+1) = min(..., dp(i, j1, j2, j3) + cost(i, 3))

    

    % 初始化 DP 表（使用 inf 表示不可达状态）
    dp = inf(N+1, n1+1, n2+1, n3+1);
    dp(1, 1, 1, 1) = 0;  % 0 个系数，0 个资源，代价为 0

    % 记录转移路径（用于回溯）
    choice = zeros(N+1, n1+1, n2+1, n3+1);  % 0=未定义, 1=16-bit, 2=8-bit, 3=4-bit

    % DP 填表
    for i = 1:N
        for j1 = 0:min(i, n1)
            for j2 = 0:min(i-j1, n2)
                for j3 = 0:min(i-j1-j2, n3)
                    if dp(i, j1+1, j2+1, j3+1) == inf
                        continue;  % 不可达状态
                    end

                    current_cost = dp(i, j1+1, j2+1, j3+1);

                    % 尝试分配 16-bit
                    if j1 < n1
                        new_cost = current_cost + cost(i, 1);
                        if new_cost < dp(i+1, j1+2, j2+1, j3+1)
                            dp(i+1, j1+2, j2+1, j3+1) = new_cost;
                            choice(i+1, j1+2, j2+1, j3+1) = 1;
                        end
                    end

                    % 尝试分配 8-bit
                    if j2 < n2
                        new_cost = current_cost + cost(i, 2);
                        if new_cost < dp(i+1, j1+1, j2+2, j3+1)
                            dp(i+1, j1+1, j2+2, j3+1) = new_cost;
                            choice(i+1, j1+1, j2+2, j3+1) = 2;
                        end
                    end

                    % 尝试分配 4-bit
                    if j3 < n3
                        new_cost = current_cost + cost(i, 3);
                        if new_cost < dp(i+1, j1+1, j2+1, j3+2)
                            dp(i+1, j1+1, j2+1, j3+2) = new_cost;
                            choice(i+1, j1+1, j2+1, j3+2) = 3;
                        end
                    end
                end
            end
        end
    end

    optimal_cost = dp(N+1, n1+1, n2+1, n3+1);

    if optimal_cost == inf
        error('无法找到满足配额约束的分配方案');
    end

    
    
    

    %% 步骤 3: 回溯获得最优分配方案
    bit_allocation = zeros(1, N);
    j1 = n1; j2 = n2; j3 = n3;

    for i = N:-1:1
        w_choice = choice(i+1, j1+1, j2+1, j3+1);

        if w_choice == 1
            bit_allocation(i) = 16;
            j1 = j1 - 1;
        elseif w_choice == 2
            bit_allocation(i) = 8;
            j2 = j2 - 1;
        elseif w_choice == 3
            bit_allocation(i) = 4;
            j3 = j3 - 1;
        else
            error('回溯失败: 系数 %d 无有效选择', i);
        end
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

    mse = mean(quantization_error.^2);

    %% 整理输出信息
    info.bit_allocation = bit_allocation;
    info.group_16bit = find(bit_allocation == 16);
    info.group_8bit  = find(bit_allocation == 8);
    info.group_4bit  = find(bit_allocation == 4);
    info.quantization_error = quantization_error;
    info.mse = mse;
    info.dp_optimal_cost = optimal_cost;

    %% 打印结果
    
    
    
    
    
    
    
    
    
    

    if abs(mse * N - optimal_cost) < 1e-12
        
    else
        
    end
    
end
