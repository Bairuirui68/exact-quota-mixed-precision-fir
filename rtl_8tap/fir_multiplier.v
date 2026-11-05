// fir_multiplier.v - Configurable width multiplier with alignment
//
// Multiplies a 16-bit signed input by a 4/8/16-bit signed coefficient.
// The exact product is sign-extended to 32 bits and aligned to 29 fraction bits.
//
// Timing: Combinational (register in parent module)

module fir_multiplier #(
    parameter COEFF_WIDTH = 16,  // 4, 8, or 16
    parameter COEFF_VALUE = 0    // Signed coefficient value
) (
    input  signed [15:0] tap_in,
    output signed [31:0] product_aligned
);

// Coefficient as signed constant
localparam signed [COEFF_WIDTH-1:0] coeff = COEFF_VALUE;

// Raw multiplication
localparam RAW_WIDTH = 16 + COEFF_WIDTH;
wire signed [RAW_WIDTH-1:0] tap_extended;
wire signed [RAW_WIDTH-1:0] coeff_extended;
`ifdef FORCE_DSP
(* use_dsp = "yes" *) wire signed [RAW_WIDTH-1:0] product_raw;
`else
wire signed [RAW_WIDTH-1:0] product_raw;
`endif
// Verilog multiplication sizing can otherwise truncate to the operand width.
assign tap_extended = {{COEFF_WIDTH{tap_in[15]}}, tap_in};
assign coeff_extended = {{16{coeff[COEFF_WIDTH-1]}}, coeff};
assign product_raw = tap_extended * coeff_extended;

// Alignment shift based on coefficient width
// 16-bit coeff: shift by 0  (already 29 frac bits: 14+15=29)
// 8-bit coeff:  shift by 8  (14+7=21, need +8 to reach 29)
// 4-bit coeff:  shift by 12 (14+3=17, need +12 to reach 29)
localparam SHIFT = (COEFF_WIDTH == 16) ? 0 :
                   (COEFF_WIDTH == 8)  ? 8 : 12;

// Sign-extend raw product to 32 bits, then shift
wire signed [31:0] product_extended;
assign product_extended = product_raw;

assign product_aligned = product_extended <<< SHIFT;

endmodule
