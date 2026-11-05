`timescale 1ns / 1ps

// tb_fir.v - Zero-error testbench for FIR filter
//
// Tests three configurations:
//   A: All 16-bit coefficients
//   B: All 8-bit coefficients
//   C: Mixed precision DP optimal
//
// Verification:
//   - Loads test vectors from .hex files
//   - Compares RTL output bit-exact with reference
//   - Reports any mismatches with cycle number
//   - Final pass/fail status

module tb_fir;

// Include coefficient definitions
`include "coeffs_config.vh"

// Clock and reset
reg clk;
reg rst;
reg en;
reg signed [15:0] data_in;

// DUT outputs
wire signed [34:0] data_out_A, data_out_B, data_out_C;
wire valid_out_A, valid_out_B, valid_out_C;

// Reference data
reg signed [34:0] ref_out_A, ref_out_B, ref_out_C;
reg ref_valid;
reg [15:0] input_mem [0:999];
reg en_mem [0:999];
reg rst_mem [0:999];
reg [34:0] output_A_mem [0:999];
reg [34:0] output_B_mem [0:999];
reg [34:0] output_C_mem [0:999];
reg valid_mem [0:999];

integer num_cycles;
integer cycle_count;
integer errors_A, errors_B, errors_C;
integer k;

// Instantiate DUT - Configuration A (all 16-bit)
fir_direct_pipeline #(
    .COEFF_0(COEFF_A_0), .COEFF_1(COEFF_A_1), .COEFF_2(COEFF_A_2), .COEFF_3(COEFF_A_3),
    .COEFF_4(COEFF_A_4), .COEFF_5(COEFF_A_5), .COEFF_6(COEFF_A_6), .COEFF_7(COEFF_A_7),
    .WIDTH_0(16), .WIDTH_1(16), .WIDTH_2(16), .WIDTH_3(16),
    .WIDTH_4(16), .WIDTH_5(16), .WIDTH_6(16), .WIDTH_7(16)
) dut_A (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out_A), .valid_out(valid_out_A)
);

// Instantiate DUT - Configuration B (all 8-bit)
fir_direct_pipeline #(
    .COEFF_0(COEFF_B_0), .COEFF_1(COEFF_B_1), .COEFF_2(COEFF_B_2), .COEFF_3(COEFF_B_3),
    .COEFF_4(COEFF_B_4), .COEFF_5(COEFF_B_5), .COEFF_6(COEFF_B_6), .COEFF_7(COEFF_B_7),
    .WIDTH_0(8), .WIDTH_1(8), .WIDTH_2(8), .WIDTH_3(8),
    .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(8), .WIDTH_7(8)
) dut_B (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out_B), .valid_out(valid_out_B)
);

// Instantiate DUT - Configuration C (mixed precision)
fir_direct_pipeline #(
    .COEFF_0(COEFF_C_0), .COEFF_1(COEFF_C_1), .COEFF_2(COEFF_C_2), .COEFF_3(COEFF_C_3),
    .COEFF_4(COEFF_C_4), .COEFF_5(COEFF_C_5), .COEFF_6(COEFF_C_6), .COEFF_7(COEFF_C_7),
    .WIDTH_0(4), .WIDTH_1(16), .WIDTH_2(8), .WIDTH_3(8),
    .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(16), .WIDTH_7(4)
) dut_C (
    .clk(clk), .rst(rst), .en(en), .data_in(data_in),
    .data_out(data_out_C), .valid_out(valid_out_C)
);

// Clock generation - 10ns period (100 MHz)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test sequence
initial begin
    clk = 0;
    rst = 1;
    en = 0;
    data_in = 0;
    errors_A = 0;
    errors_B = 0;
    errors_C = 0;
    cycle_count = 0;

    $readmemh("input_seq.hex", input_mem);
    $readmemh("en_seq.hex", en_mem);
    $readmemh("rst_seq.hex", rst_mem);
    $readmemh("output_ref_A.hex", output_A_mem);
    $readmemh("output_ref_B.hex", output_B_mem);
    $readmemh("output_ref_C.hex", output_C_mem);
    $readmemh("valid_ref.hex", valid_mem);

    num_cycles = 0;
    while (num_cycles < 1000 && (input_mem[num_cycles] !== 16'hxxxx))
        num_cycles = num_cycles + 1;
    if (num_cycles == 0) begin
        $display("ERROR: No test vectors loaded!");
        $fatal(1, "No test vectors loaded; refusing to report a pass");
    end

    $display("========================================");
    $display("FIR Filter Zero-Error Verification");
    $display("========================================");
    $display("Test vectors loaded: %0d cycles", num_cycles);

    // Initial reset
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // Run test vectors
    for (cycle_count = 0; cycle_count < num_cycles; cycle_count = cycle_count + 1) begin
        @(negedge clk);
        rst = rst_mem[cycle_count];
        en = en_mem[cycle_count];
        data_in = $signed(input_mem[cycle_count]);

        // Load expected outputs (convert from unsigned hex representation)
        ref_out_A = $signed(output_A_mem[cycle_count]);
        ref_out_B = $signed(output_B_mem[cycle_count]);
        ref_out_C = $signed(output_C_mem[cycle_count]);
        ref_valid = valid_mem[cycle_count];

        @(posedge clk);
        #1;  // Small delay after clock edge

        // Verify Configuration A
        if (data_out_A !== ref_out_A || valid_out_A !== ref_valid) begin
            errors_A = errors_A + 1;
            if (errors_A <= 10) begin  // Limit error messages
                $display("ERROR Config A at cycle %0d:", cycle_count);
                $display("  Expected: out=%h valid=%b", ref_out_A, ref_valid);
                $display("  Got:      out=%h valid=%b", data_out_A, valid_out_A);
            end
        end

        // Verify Configuration B
        if (data_out_B !== ref_out_B || valid_out_B !== ref_valid) begin
            errors_B = errors_B + 1;
            if (errors_B <= 10) begin
                $display("ERROR Config B at cycle %0d:", cycle_count);
                $display("  Expected: out=%h valid=%b", ref_out_B, ref_valid);
                $display("  Got:      out=%h valid=%b", data_out_B, valid_out_B);
            end
        end

        // Verify Configuration C
        if (data_out_C !== ref_out_C || valid_out_C !== ref_valid) begin
            errors_C = errors_C + 1;
            if (errors_C <= 10) begin
                $display("ERROR Config C at cycle %0d:", cycle_count);
                $display("  Expected: out=%h valid=%b", ref_out_C, ref_valid);
                $display("  Got:      out=%h valid=%b", data_out_C, valid_out_C);
            end
        end
    end

    // Final report
    $display("");
    $display("========================================");
    $display("Verification Complete");
    $display("========================================");
    $display("Total cycles tested: %0d", num_cycles);
    $display("");
    $display("Config A errors: %0d", errors_A);
    $display("Config B errors: %0d", errors_B);
    $display("Config C errors: %0d", errors_C);
    $display("");

    if (num_cycles > 0 && errors_A == 0 && errors_B == 0 && errors_C == 0) begin
        $display("*** ALL TESTS PASSED ***");
    end else begin
        $display("*** TESTS FAILED ***");
        $fatal(1, "Bit-exact verification failed");
    end
    $display("========================================");

    $finish;
end

// Timeout watchdog
initial begin
    #1000000;  // 1ms timeout
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
