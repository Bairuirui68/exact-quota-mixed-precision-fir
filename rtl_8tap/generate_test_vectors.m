function generate_test_vectors()
% GENERATE_TEST_VECTORS - Generate test vectors for FIR RTL verification
%
% Generates input sequences and reference outputs for three configurations:
% A: All 16-bit coefficients
% B: All 8-bit coefficients
% C: Mixed precision DP optimal [2×16, 4×8, 2×4]
%
% Output files:
%   input_seq.hex         - Input samples (16-bit hex)
%   en_seq.hex            - Enable flags
%   rst_seq.hex           - Reset flags
%   output_ref_A.hex      - Expected output for config A (35-bit hex, 9 digits)
%   output_ref_B.hex      - Expected output for config B
%   output_ref_C.hex      - Expected output for config C
%   valid_ref.hex         - Expected output valid flags
%   coeffs_config.vh      - Verilog header with coefficient values
%   test_vectors.mat      - MATLAB data for analysis

addpath('extended_validation');

%% FIR specification (7th order, 8 taps)
N = 7;
fc = 0.3;
win = hamming(N + 1);
win = win(:).';
coeffs = fir1(N, fc, 'low', win);

fprintf('Original FIR coefficients (8 taps):\n');
for i = 1:length(coeffs)
    fprintf('  h[%d] = % .10f\n', i-1, coeffs(i));
end

%% Bit allocations
% A: All 16-bit
widths_A = ones(1, 8) * 16;

% B: All 8-bit
widths_B = ones(1, 8) * 8;

% C: DP optimal [2×16, 4×8, 2×4] - indices [2,7] get 16-bit
widths_C = ones(1, 8) * 8;
widths_C([2, 7]) = 16;
widths_C([1, 8]) = 4;

fprintf('\nConfiguration A (all 16-bit): [%s]\n', sprintf('%d ', widths_A));
fprintf('Configuration B (all 8-bit):  [%s]\n', sprintf('%d ', widths_B));
fprintf('Configuration C (DP optimal):  [%s]\n', sprintf('%d ', widths_C));

%% Fixed-point parameters
input_width = 16;
input_frac = 14;
coeff_fracs = [15, 7, 3];  % For 16-bit, 8-bit, 4-bit

%% Generate test input sequences
N_WARMUP = 20;
N_IMPULSE = 1;
N_MAX_POS = 3;
N_MAX_NEG = 3;
N_ALTERNATING = 10;
N_RANDOM = 50;
N_EN_GAP = 20;
N_RESET_TEST = 30;
N_COOLDOWN = 20;

rng(42);  % Reproducible random

% Full-scale values for Q1.14
FS_POS = (2^(input_width-1) - 1) / 2^input_frac;  % 1.99994
FS_NEG = -2^(input_width-1) / 2^input_frac;       % -2.0

% Build sequences
seq_warmup = zeros(1, N_WARMUP);
seq_impulse = [FS_POS, zeros(1, N_IMPULSE-1)];
seq_max_pos = ones(1, N_MAX_POS) * FS_POS;
seq_max_neg = ones(1, N_MAX_NEG) * FS_NEG;
seq_alternating = repmat([FS_POS, FS_NEG], 1, N_ALTERNATING/2);
seq_random = (rand(1, N_RANDOM) * 2 - 1) * FS_POS;

% Enable-gap section: data remains arbitrary while enable introduces bubbles.
seq_en_gap = (rand(1, N_EN_GAP) * 2 - 1) * FS_POS;

% Reset during processing test
seq_reset_test = (rand(1, N_RESET_TEST) * 2 - 1) * FS_POS;

seq_cooldown = zeros(1, N_COOLDOWN);

% Concatenate
in_seq = [seq_warmup, seq_impulse, seq_max_pos, seq_max_neg, ...
          seq_alternating, seq_random, seq_en_gap, seq_reset_test, seq_cooldown];

N_TOTAL = length(in_seq);

%% Generate enable and reset sequences
en_seq = ones(1, N_TOTAL);
rst_seq = zeros(1, N_TOTAL);

% Enable gaps during en_gap section
en_gap_start = N_WARMUP + N_IMPULSE + N_MAX_POS + N_MAX_NEG + N_ALTERNATING + N_RANDOM + 1;
en_gap_pattern = [1 1 0 0 1 0 1 1 1 0];  % Mix of enables and holds
for i = 1:min(length(en_gap_pattern), N_EN_GAP)
    en_seq(en_gap_start + i - 1) = en_gap_pattern(i);
end

% Reset during reset_test section (pulse at 1/3 and 2/3 through)
reset_start = en_gap_start + N_EN_GAP;
rst_seq(reset_start + floor(N_RESET_TEST/3)) = 1;
rst_seq(reset_start + floor(2*N_RESET_TEST/3)) = 1;

fprintf('\nTest sequence summary:\n');
fprintf('  Warmup:            %4d cycles\n', N_WARMUP);
fprintf('  Impulse:           %4d cycles\n', N_IMPULSE);
fprintf('  Max positive:      %4d cycles\n', N_MAX_POS);
fprintf('  Max negative:      %4d cycles\n', N_MAX_NEG);
fprintf('  Alternating:       %4d cycles\n', N_ALTERNATING);
fprintf('  Random:            %4d cycles\n', N_RANDOM);
fprintf('  Enable gaps:       %4d cycles\n', N_EN_GAP);
fprintf('  Reset test:        %4d cycles\n', N_RESET_TEST);
fprintf('  Cooldown:          %4d cycles\n', N_COOLDOWN);
fprintf('  TOTAL:             %4d cycles\n', N_TOTAL);

%% Run reference models
fprintf('\nRunning integer reference models...\n');

[out_A, valid_A] = fir_fixed_point_reference(in_seq, en_seq, rst_seq, ...
                                               coeffs, widths_A, input_frac, coeff_fracs, N_TOTAL);
fprintf('  Config A complete\n');

[out_B, valid_B] = fir_fixed_point_reference(in_seq, en_seq, rst_seq, ...
                                               coeffs, widths_B, input_frac, coeff_fracs, N_TOTAL);
fprintf('  Config B complete\n');

[out_C, valid_C] = fir_fixed_point_reference(in_seq, en_seq, rst_seq, ...
                                               coeffs, widths_C, input_frac, coeff_fracs, N_TOTAL);
fprintf('  Config C complete\n');

% Verify valid sequences are identical
assert(all(valid_A == valid_B) && all(valid_B == valid_C), ...
       'Valid sequences must be identical across configs');

%% Quantize coefficients for Verilog header
function c_int = quantize_coeff(c_float, width, frac)
    c_int = round(c_float * 2^frac);
    c_int = max(min(c_int, 2^(width-1)-1), -2^(width-1));
end

coeffs_A_int = zeros(1, 8);
coeffs_B_int = zeros(1, 8);
coeffs_C_int = zeros(1, 8);

for i = 1:8
    coeffs_A_int(i) = quantize_coeff(coeffs(i), 16, 15);
    coeffs_B_int(i) = quantize_coeff(coeffs(i), 8, 7);

    w = widths_C(i);
    if w == 16
        coeffs_C_int(i) = quantize_coeff(coeffs(i), 16, 15);
    elseif w == 8
        coeffs_C_int(i) = quantize_coeff(coeffs(i), 8, 7);
    else
        coeffs_C_int(i) = quantize_coeff(coeffs(i), 4, 3);
    end
end

%% Write output files
fprintf('\nWriting output files...\n');

% Quantize input to 16-bit signed integers
in_quantized = round(in_seq * 2^input_frac);
in_quantized = max(min(in_quantized, 2^15-1), -2^15);

% Convert to unsigned representation for hex output
in_unsigned = mod(int64(in_quantized) + 2^16, 2^16);
out_A_unsigned = mod(int64(out_A) + 2^35, 2^35);
out_B_unsigned = mod(int64(out_B) + 2^35, 2^35);
out_C_unsigned = mod(int64(out_C) + 2^35, 2^35);

% Write hex files
fid = fopen('input_seq.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%04X\n', in_unsigned(i));
end
fclose(fid);
fprintf('  input_seq.hex written\n');

fid = fopen('en_seq.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%X\n', en_seq(i));
end
fclose(fid);
fprintf('  en_seq.hex written\n');

fid = fopen('rst_seq.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%X\n', rst_seq(i));
end
fclose(fid);
fprintf('  rst_seq.hex written\n');

fid = fopen('output_ref_A.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%09X\n', out_A_unsigned(i));
end
fclose(fid);
fprintf('  output_ref_A.hex written\n');

fid = fopen('output_ref_B.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%09X\n', out_B_unsigned(i));
end
fclose(fid);
fprintf('  output_ref_B.hex written\n');

fid = fopen('output_ref_C.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%09X\n', out_C_unsigned(i));
end
fclose(fid);
fprintf('  output_ref_C.hex written\n');

fid = fopen('valid_ref.hex', 'w');
for i = 1:N_TOTAL
    fprintf(fid, '%X\n', valid_A(i));
end
fclose(fid);
fprintf('  valid_ref.hex written\n');

% Write Verilog coefficient header
fid = fopen('coeffs_config.vh', 'w');
fprintf(fid, '// Auto-generated coefficient configuration\n');
fprintf(fid, '// Generated: %s\n\n', datestr(now));

fprintf(fid, '// Configuration A: All 16-bit\n');
for i = 1:8
    coeff_hex = dec2hex(mod(coeffs_A_int(i), 2^16), 4);
    fprintf(fid, 'localparam signed [15:0] COEFF_A_%d = 16''h%s;\n', i-1, coeff_hex);
end

fprintf(fid, '\n// Configuration B: All 8-bit\n');
for i = 1:8
    coeff_hex = dec2hex(mod(coeffs_B_int(i), 2^8), 2);
    fprintf(fid, 'localparam signed [7:0] COEFF_B_%d = 8''h%s;\n', i-1, coeff_hex);
end

fprintf(fid, '\n// Configuration C: Mixed precision\n');
for i = 1:8
    w = widths_C(i);
    coeff_hex = dec2hex(mod(coeffs_C_int(i), 2^w), ceil(w/4));
    fprintf(fid, 'localparam signed [%d:0] COEFF_C_%d = %d''h%s;', w-1, i-1, w, coeff_hex);
    fprintf(fid, '  // %d-bit\n', w);
end

fclose(fid);
fprintf('  coeffs_config.vh written\n');

% Save MATLAB workspace
save('test_vectors.mat', 'coeffs', 'widths_A', 'widths_B', 'widths_C', ...
     'in_seq', 'en_seq', 'rst_seq', 'out_A', 'out_B', 'out_C', 'valid_A', ...
     'coeffs_A_int', 'coeffs_B_int', 'coeffs_C_int', 'N_TOTAL');
fprintf('  test_vectors.mat written\n');

fprintf('\nTest vector generation complete!\n');
fprintf('Total test cycles: %d\n', N_TOTAL);

end
