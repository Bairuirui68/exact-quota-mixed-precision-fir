`timescale 1ns / 1ps

// fir_direct_pipeline.v - 8-tap FIR filter with configurable coefficient widths
//
// Architecture:
//   Input taps -> 8 parallel multipliers -> 3-stage adder tree -> output
//
// Pipeline:
//   Cycle 0: Input capture, tap shift
//   Cycle 1: Multiply and align (registered)
//   Cycle 2: First adder stage 8->4 (registered)
//   Cycle 3: Second adder stage 4->2 (registered)
//   Cycle 4: Third adder stage 2->1 (registered)
//
// Total latency: 5 cycles from accepted tap update to aligned output-valid.
//
// Enable behavior:
//   en=1: Capture new input, shift taps, propagate valid
//   en=0: Hold taps, pipeline continues without new data
//
// Reset: Synchronous, clears all state
//
// Fixed-point format:
//   Input:  16-bit signed Q1.14
//   Output: 35-bit signed Q5.29

module fir_direct_pipeline #(
    parameter signed [15:0] COEFF_0 = 16'sd0,
    parameter signed [15:0] COEFF_1 = 16'sd0,
    parameter signed [15:0] COEFF_2 = 16'sd0,
    parameter signed [15:0] COEFF_3 = 16'sd0,
    parameter signed [15:0] COEFF_4 = 16'sd0,
    parameter signed [15:0] COEFF_5 = 16'sd0,
    parameter signed [15:0] COEFF_6 = 16'sd0,
    parameter signed [15:0] COEFF_7 = 16'sd0,

    parameter [4:0] WIDTH_0 = 16,
    parameter [4:0] WIDTH_1 = 16,
    parameter [4:0] WIDTH_2 = 16,
    parameter [4:0] WIDTH_3 = 16,
    parameter [4:0] WIDTH_4 = 16,
    parameter [4:0] WIDTH_5 = 16,
    parameter [4:0] WIDTH_6 = 16,
    parameter [4:0] WIDTH_7 = 16
) (
    input wire clk,
    input wire rst,
    input wire en,
    input wire signed [15:0] data_in,
    output reg signed [34:0] data_out,
    output reg valid_out
);

// Tap delay line
reg signed [15:0] taps [0:7];

// Pipeline registers
reg signed [31:0] products [0:7];     // After multiply & align (stage 1)
reg signed [32:0] stage2_sums [0:3];  // After first adds (stage 2)
reg signed [33:0] stage3_sums [0:1];  // After second adds (stage 3)

// en=0 inserts a valid bubble; arithmetic registers continue advancing.
reg [4:0] valid_pipe;

// Multiplier outputs (combinational)
wire signed [31:0] mult_out [0:7];

// Instantiate 8 multipliers
fir_multiplier #(.COEFF_WIDTH(WIDTH_0), .COEFF_VALUE(COEFF_0)) mult_0 (.tap_in(taps[0]), .product_aligned(mult_out[0]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_1), .COEFF_VALUE(COEFF_1)) mult_1 (.tap_in(taps[1]), .product_aligned(mult_out[1]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_2), .COEFF_VALUE(COEFF_2)) mult_2 (.tap_in(taps[2]), .product_aligned(mult_out[2]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_3), .COEFF_VALUE(COEFF_3)) mult_3 (.tap_in(taps[3]), .product_aligned(mult_out[3]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_4), .COEFF_VALUE(COEFF_4)) mult_4 (.tap_in(taps[4]), .product_aligned(mult_out[4]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_5), .COEFF_VALUE(COEFF_5)) mult_5 (.tap_in(taps[5]), .product_aligned(mult_out[5]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_6), .COEFF_VALUE(COEFF_6)) mult_6 (.tap_in(taps[6]), .product_aligned(mult_out[6]));
fir_multiplier #(.COEFF_WIDTH(WIDTH_7), .COEFF_VALUE(COEFF_7)) mult_7 (.tap_in(taps[7]), .product_aligned(mult_out[7]));

integer i;

always @(posedge clk) begin
    if (rst) begin
        // Reset all state
        for (i = 0; i < 8; i = i + 1) begin
            taps[i] <= 16'sd0;
            products[i] <= 32'sd0;
        end
        for (i = 0; i < 4; i = i + 1) begin
            stage2_sums[i] <= 33'sd0;
        end
        for (i = 0; i < 2; i = i + 1) begin
            stage3_sums[i] <= 34'sd0;
        end
        data_out <= 35'sd0;
        valid_pipe <= 5'b00000;
        valid_out <= 1'b0;
    end else begin
        // === Stage 0: Input capture and tap shift ===
        if (en) begin
            taps[0] <= data_in;
            for (i = 1; i < 8; i = i + 1) begin
                taps[i] <= taps[i-1];
            end
            valid_pipe <= {valid_pipe[3:0], 1'b1};
        end else begin
            // Hold taps, propagate valid without new input
            valid_pipe <= {valid_pipe[3:0], 1'b0};
        end

        // === Stage 1: Multiply and align (registered) ===
        for (i = 0; i < 8; i = i + 1) begin
            products[i] <= mult_out[i];
        end

        // === Stage 2: First adder stage 8->4 (registered) ===
        stage2_sums[0] <= {products[0][31], products[0]} + {products[1][31], products[1]};
        stage2_sums[1] <= {products[2][31], products[2]} + {products[3][31], products[3]};
        stage2_sums[2] <= {products[4][31], products[4]} + {products[5][31], products[5]};
        stage2_sums[3] <= {products[6][31], products[6]} + {products[7][31], products[7]};

        // === Stage 3: Second adder stage 4->2 (registered) ===
        stage3_sums[0] <= {stage2_sums[0][32], stage2_sums[0]} + {stage2_sums[1][32], stage2_sums[1]};
        stage3_sums[1] <= {stage2_sums[2][32], stage2_sums[2]} + {stage2_sums[3][32], stage2_sums[3]};

        // === Stage 4: Third adder stage 2->1 (registered) ===
        data_out <= {stage3_sums[0][33], stage3_sums[0]} + {stage3_sums[1][33], stage3_sums[1]};
        valid_out <= valid_pipe[4];
    end
end

endmodule
