function [out, out_valid] = fir_fixed_point_reference(in_seq, en_seq, rst_seq, coeffs, widths, input_frac, coeff_fracs, clk_cycles)
% FIR_FIXED_POINT_REFERENCE - Integer arithmetic reference model for FIR filter
%
% Cycle-accurate integer reference for the FIR RTL.
% - Input: 16-bit signed Q1.14 (14 fractional bits)
% - Coefficients: variable width with specified fractional bits
% - Products aligned to 29 fractional bits via sign-extension and left-shift
% - Accumulation: 35-bit signed Q5.29
% - 5-cycle aligned valid delay (input captured at cycle N, output valid at N+5)
% - en=0: taps hold, datapath pipeline advances, valid inserts a bubble
%
% Parameters:
%   in_seq      - Input sequence (floating point, will be quantized to Q1.14)
%   en_seq      - Enable sequence (1=accept input, 0=hold last captured)
%   rst_seq     - Reset sequence (1=reset, 0=normal operation)
%   coeffs      - FIR coefficients (floating point, length N_TAPS)
%   widths      - Bit widths for each coefficient [16, 8, or 4]
%   input_frac  - Input fractional bits (14)
%   coeff_fracs - Coefficient fractional bits for each width [15, 7, 3]
%   clk_cycles  - Total clock cycles to simulate
%
% Returns:
%   out         - 35-bit signed integer output sequence (length clk_cycles)
%   out_valid   - Output valid flags (1=valid, 0=invalid)

N_TAPS = length(coeffs);
PIPELINE_DELAY = 5;

% Fixed-point parameters
INPUT_WIDTH = 16;
OUTPUT_WIDTH = 35;
PRODUCT_WIDTH = 32;
PRODUCT_FRAC = 29;
OUTPUT_FRAC = 29;

% Quantize input to Q1.14 (as integers)
in_quantized = int64(round(in_seq * 2^input_frac));
in_quantized = max(min(in_quantized, 2^(INPUT_WIDTH-1)-1), -2^(INPUT_WIDTH-1));

% Quantize coefficients to specified widths (as integers)
coeff_quantized = zeros(1, N_TAPS, 'int64');
for i = 1:N_TAPS
    w = widths(i);
    if w == 16
        frac = coeff_fracs(1);
    elseif w == 8
        frac = coeff_fracs(2);
    else % w == 4
        frac = coeff_fracs(3);
    end
    c_int = int64(round(coeffs(i) * 2^frac));
    c_int = max(min(c_int, 2^(w-1)-1), -2^(w-1));
    coeff_quantized(i) = c_int;
end

% Initialize state
taps = zeros(1, N_TAPS, 'int64');          % Tap delay line
products = zeros(1, N_TAPS, 'int64');      % After multiplication & alignment
stage1 = zeros(1, 4, 'int64');             % After first add stage
stage2 = zeros(1, 2, 'int64');             % After second add stage
stage3 = int64(0);                         % Registered output sum

% Valid pipeline
valid_pipe = zeros(1, PIPELINE_DELAY, 'logical');

% Output arrays
out = zeros(1, clk_cycles, 'int64');
out_valid = false(1, clk_cycles);

% Simulation loop
for cycle = 1:clk_cycles
    % Current inputs
    if cycle <= length(rst_seq)
        rst = rst_seq(cycle);
    else
        rst = 0;
    end

    if cycle <= length(en_seq)
        en = en_seq(cycle);
    else
        en = 0;
    end

    if cycle <= length(in_quantized)
        in_current = in_quantized(cycle);
    else
        in_current = int64(0);
    end

    % Reset logic
    if rst
        taps = zeros(1, N_TAPS, 'int64');
        products = zeros(1, N_TAPS, 'int64');
        stage1 = zeros(1, 4, 'int64');
        stage2 = zeros(1, 2, 'int64');
        stage3 = int64(0);
        valid_pipe = false(1, PIPELINE_DELAY);
        out(cycle) = int64(0);
        out_valid(cycle) = false;
        continue;
    end

    % Snapshot old registers: Verilog nonblocking assignments update together.
    old_taps = taps;
    old_products = products;
    old_stage1 = stage1;
    old_stage2 = stage2;
    old_valid_pipe = valid_pipe;

    % Stage 0: capture input and shift taps only when enabled.
    if en
        for i = N_TAPS:-1:2
            taps(i) = taps(i-1);
        end
        taps(1) = in_current;
        valid_in = true;
    else
        valid_in = false;
    end

    % Stage 1: products use the pre-edge tap values.
    for i = 1:N_TAPS
        prod_raw = int64(old_taps(i)) * int64(coeff_quantized(i));

        % Determine shift amount based on coefficient width
        w = widths(i);
        if w == 16
            shift = 0;
        elseif w == 8
            shift = 8;
        else % w == 4
            shift = 12;
        end

        % Align to 32-bit with 29 fractional bits
        if shift > 0
            prod_aligned = bitshift(prod_raw, shift);
        else
            prod_aligned = prod_raw;
        end

        products(i) = prod_aligned;
    end

    % Each following stage consumes the old value of the prior stage.
    stage1(1) = old_products(1) + old_products(2);
    stage1(2) = old_products(3) + old_products(4);
    stage1(3) = old_products(5) + old_products(6);
    stage1(4) = old_products(7) + old_products(8);

    stage2(1) = old_stage1(1) + old_stage1(2);
    stage2(2) = old_stage1(3) + old_stage1(4);

    stage3 = old_stage2(1) + old_stage2(2);
    max_val = int64(2^34 - 1);
    min_val = int64(-2^34);
    if stage3 > max_val || stage3 < min_val
        error('35-bit accumulator overflow at cycle %d', cycle);
    end
    out(cycle) = stage3;

    valid_pipe = [valid_in, old_valid_pipe(1:end-1)];
    out_valid(cycle) = old_valid_pipe(end);
end

end
