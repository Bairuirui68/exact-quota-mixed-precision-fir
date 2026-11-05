`timescale 1ns / 1ps

module fir_synth_A (
    input wire clk,
    input wire rst,
    input wire en,
    input wire signed [15:0] data_in,
    output wire signed [34:0] data_out,
    output wire valid_out
);
`include "coeffs_config.vh"
fir_direct_pipeline #(
    .COEFF_0(COEFF_A_0), .COEFF_1(COEFF_A_1), .COEFF_2(COEFF_A_2), .COEFF_3(COEFF_A_3),
    .COEFF_4(COEFF_A_4), .COEFF_5(COEFF_A_5), .COEFF_6(COEFF_A_6), .COEFF_7(COEFF_A_7),
    .WIDTH_0(16), .WIDTH_1(16), .WIDTH_2(16), .WIDTH_3(16),
    .WIDTH_4(16), .WIDTH_5(16), .WIDTH_6(16), .WIDTH_7(16)
) dut (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out), .valid_out(valid_out)
);
endmodule

module fir_synth_B (
    input wire clk,
    input wire rst,
    input wire en,
    input wire signed [15:0] data_in,
    output wire signed [34:0] data_out,
    output wire valid_out
);
`include "coeffs_config.vh"
fir_direct_pipeline #(
    .COEFF_0(COEFF_B_0), .COEFF_1(COEFF_B_1), .COEFF_2(COEFF_B_2), .COEFF_3(COEFF_B_3),
    .COEFF_4(COEFF_B_4), .COEFF_5(COEFF_B_5), .COEFF_6(COEFF_B_6), .COEFF_7(COEFF_B_7),
    .WIDTH_0(8), .WIDTH_1(8), .WIDTH_2(8), .WIDTH_3(8),
    .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(8), .WIDTH_7(8)
) dut (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out), .valid_out(valid_out)
);
endmodule

module fir_synth_C (
    input wire clk,
    input wire rst,
    input wire en,
    input wire signed [15:0] data_in,
    output wire signed [34:0] data_out,
    output wire valid_out
);
`include "coeffs_config.vh"
fir_direct_pipeline #(
    .COEFF_0(COEFF_C_0), .COEFF_1(COEFF_C_1), .COEFF_2(COEFF_C_2), .COEFF_3(COEFF_C_3),
    .COEFF_4(COEFF_C_4), .COEFF_5(COEFF_C_5), .COEFF_6(COEFF_C_6), .COEFF_7(COEFF_C_7),
    .WIDTH_0(4), .WIDTH_1(16), .WIDTH_2(8), .WIDTH_3(8),
    .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(16), .WIDTH_7(4)
) dut (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out), .valid_out(valid_out)
);
endmodule
