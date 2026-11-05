%% Generate Test FIR Coefficients
% Author: Generated for EI Conference Research
% Date: 2026-11-03
% Description: 生成不同类型的 FIR 滤波器系数用于测试

function coeffs = generate_test_fir(filter_type, N, varargin)
% GENERATE_TEST_FIR 生成测试用 FIR 系数
%
% 输入：
%   filter_type - 滤波器类型：'lowpass', 'highpass', 'bandpass', 'bandstop'
%   N           - 滤波器阶数（系数数量 = N+1）
%   varargin    - 可选参数（频率等）
%
% 输出：
%   coeffs      - FIR 系数（1×(N+1) 向量）

    %% 参数解析
    p = inputParser;
    addRequired(p, 'filter_type', @ischar);
    addRequired(p, 'N', @(x) x>0 && mod(x,1)==0);
    addParameter(p, 'fc', 0.3, @(x) x>0 && x<1);  % 归一化截止频率
    addParameter(p, 'fc1', 0.2, @(x) x>0 && x<1); % 带通/带阻下限频率
    addParameter(p, 'fc2', 0.4, @(x) x>0 && x<1); % 带通/带阻上限频率
    addParameter(p, 'window', 'hamming', @ischar); % 窗函数类型
    parse(p, filter_type, N, varargin{:});

    fc = p.Results.fc;
    fc1 = p.Results.fc1;
    fc2 = p.Results.fc2;
    win_type = p.Results.window;
    win = feval(win_type, N + 1);
    win = win(:).';

    %% 生成系数
    switch lower(filter_type)
        case 'lowpass'
            % 低通滤波器
            coeffs = fir1(N, fc, 'low', win);
            fprintf('✅ 生成 %d 阶低通 FIR (fc=%.2f)\n', N, fc);

        case 'highpass'
            % 高通滤波器
            coeffs = fir1(N, 1-fc, 'low', win) .* (-1).^(0:N); % spectral modulation; even-tap Type IV highpass
            fprintf('✅ 生成 %d 阶高通 FIR (fc=%.2f)\n', N, fc);

        case 'bandpass'
            % 带通滤波器
            coeffs = fir1(N, [fc1, fc2], 'bandpass', win);
            fprintf('✅ 生成 %d 阶带通 FIR (fc=[%.2f, %.2f])\n', N, fc1, fc2);

        case 'bandstop'
            % 带阻滤波器
            coeffs = fir1(N, [fc1, fc2], 'stop', win);
            fprintf('✅ 生成 %d 阶带阻 FIR (fc=[%.2f, %.2f])\n', N, fc1, fc2);

        otherwise
            error('不支持的滤波器类型：%s', filter_type);
    end

    %% 归一化到 [-1, 1] 范围（可选）
    % coeffs = coeffs / max(abs(coeffs));
end
