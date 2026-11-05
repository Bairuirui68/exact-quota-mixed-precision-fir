`timescale 1ns / 1ps

// ACX750 board test: send one signed 16-bit sample (low byte, then high byte)
// over 115200-8-N-1 UART; receive one sign-extended 40-bit FIR result.
module fir_board_uart #(
    parameter integer CONFIG = 2,
    parameter integer CLK_HZ = 50000000,
    parameter integer BAUD = 115200
) (
    input wire FPGA_CLK,
    input wire S0_N,
    input wire UART_RXD,
    output wire UART_TXD,
    output wire [8:0] LED
);

`include "coeffs_config.vh"

    wire rst = ~S0_N;
    wire [7:0] rx_byte;
    wire rx_valid;
    reg [7:0] sample_low;
    reg have_low;
    reg signed [15:0] sample_data;
    reg sample_en;
    wire signed [34:0] fir_data;
    wire fir_valid;

    generate
        if (CONFIG == 0) begin : config_a
            fir_direct_pipeline #(
                .COEFF_0(COEFF_A_0), .COEFF_1(COEFF_A_1), .COEFF_2(COEFF_A_2), .COEFF_3(COEFF_A_3),
                .COEFF_4(COEFF_A_4), .COEFF_5(COEFF_A_5), .COEFF_6(COEFF_A_6), .COEFF_7(COEFF_A_7),
                .WIDTH_0(16), .WIDTH_1(16), .WIDTH_2(16), .WIDTH_3(16),
                .WIDTH_4(16), .WIDTH_5(16), .WIDTH_6(16), .WIDTH_7(16)
            ) dut (.clk(FPGA_CLK), .rst(rst), .en(sample_en), .data_in(sample_data),
                   .data_out(fir_data), .valid_out(fir_valid));
        end else if (CONFIG == 1) begin : config_b
            fir_direct_pipeline #(
                .COEFF_0(COEFF_B_0), .COEFF_1(COEFF_B_1), .COEFF_2(COEFF_B_2), .COEFF_3(COEFF_B_3),
                .COEFF_4(COEFF_B_4), .COEFF_5(COEFF_B_5), .COEFF_6(COEFF_B_6), .COEFF_7(COEFF_B_7),
                .WIDTH_0(8), .WIDTH_1(8), .WIDTH_2(8), .WIDTH_3(8),
                .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(8), .WIDTH_7(8)
            ) dut (.clk(FPGA_CLK), .rst(rst), .en(sample_en), .data_in(sample_data),
                   .data_out(fir_data), .valid_out(fir_valid));
        end else begin : config_c
            fir_direct_pipeline #(
                .COEFF_0(COEFF_C_0), .COEFF_1(COEFF_C_1), .COEFF_2(COEFF_C_2), .COEFF_3(COEFF_C_3),
                .COEFF_4(COEFF_C_4), .COEFF_5(COEFF_C_5), .COEFF_6(COEFF_C_6), .COEFF_7(COEFF_C_7),
                .WIDTH_0(4), .WIDTH_1(16), .WIDTH_2(8), .WIDTH_3(8),
                .WIDTH_4(8), .WIDTH_5(8), .WIDTH_6(16), .WIDTH_7(4)
            ) dut (.clk(FPGA_CLK), .rst(rst), .en(sample_en), .data_in(sample_data),
                   .data_out(fir_data), .valid_out(fir_valid));
        end
    endgenerate

    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) receiver (
        .clk(FPGA_CLK), .rst(rst), .serial_in(UART_RXD), .data_out(rx_byte), .data_valid(rx_valid)
    );

    reg [39:0] result_shift;
    reg [2:0] tx_index;
    reg [1:0] tx_state;
    reg [7:0] tx_byte;
    reg tx_start;
    wire tx_busy;
    localparam TX_IDLE = 2'd0, TX_START = 2'd1, TX_BUSY = 2'd2, TX_WAIT = 2'd3;

    always @* begin
        case (tx_index)
            3'd0: tx_byte = result_shift[39:32];
            3'd1: tx_byte = result_shift[31:24];
            3'd2: tx_byte = result_shift[23:16];
            3'd3: tx_byte = result_shift[15:8];
            default: tx_byte = result_shift[7:0];
        endcase
    end

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) transmitter (
        .clk(FPGA_CLK), .rst(rst), .data_in(tx_byte), .start(tx_start), .serial_out(UART_TXD), .busy(tx_busy)
    );

    always @(posedge FPGA_CLK) begin
        if (rst) begin
            sample_low <= 8'd0;
            sample_data <= 16'sd0;
            have_low <= 1'b0;
            sample_en <= 1'b0;
            result_shift <= 40'd0;
            tx_index <= 3'd0;
            tx_state <= TX_IDLE;
            tx_start <= 1'b0;
        end else begin
            sample_en <= 1'b0;
            tx_start <= 1'b0;

            if (rx_valid) begin
                if (!have_low) begin
                    sample_low <= rx_byte;
                    have_low <= 1'b1;
                end else begin
                    sample_data <= {rx_byte, sample_low};
                    sample_en <= 1'b1;
                    have_low <= 1'b0;
                end
            end

            case (tx_state)
                TX_IDLE: if (fir_valid) begin
                    result_shift <= {{5{fir_data[34]}}, fir_data};
                    tx_index <= 3'd0;
                    tx_state <= TX_START;
                end
                TX_START: if (!tx_busy) begin
                    tx_start <= 1'b1;
                    tx_state <= TX_BUSY;
                end
                TX_BUSY: if (tx_busy) tx_state <= TX_WAIT;
                TX_WAIT: if (!tx_busy) begin
                    if (tx_index == 3'd4) begin
                        tx_state <= TX_IDLE;
                    end else begin
                        tx_index <= tx_index + 1'b1;
                        tx_state <= TX_START;
                    end
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end

    assign LED = {8'd0, have_low};
endmodule

module uart_rx #(
    parameter integer CLK_HZ = 50000000,
    parameter integer BAUD = 115200
) (
    input wire clk,
    input wire rst,
    input wire serial_in,
    output reg [7:0] data_out,
    output reg data_valid
);
    localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD;
    localparam integer HALF = DIV / 2;
    (* ASYNC_REG = "TRUE" *) reg rx_meta, rx_sync;
    reg [15:0] count;
    reg [3:0] bit_index;
    reg [7:0] shift;
    reg busy;
    reg start_pending;
    reg stop_pending;

    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
            count <= 16'd0;
            bit_index <= 4'd0;
            shift <= 8'd0;
            data_out <= 8'd0;
            data_valid <= 1'b0;
            busy <= 1'b0;
            start_pending <= 1'b0;
            stop_pending <= 1'b0;
        end else begin
            rx_meta <= serial_in;
            rx_sync <= rx_meta;
            data_valid <= 1'b0;
            if (!busy) begin
                if (!rx_sync) begin
                    busy <= 1'b1;
                    count <= HALF;
                    bit_index <= 4'd0;
                    start_pending <= 1'b1;
                    stop_pending <= 1'b0;
                end
            end else if (count != 0) begin
                count <= count - 1'b1;
            end else if (start_pending) begin
                if (!rx_sync) begin
                    start_pending <= 1'b0;
                    count <= DIV - 1;
                end else begin
                    start_pending <= 1'b0;
                    busy <= 1'b0;
                end
            end else if (bit_index < 8) begin
                shift[bit_index] <= rx_sync;
                bit_index <= bit_index + 1'b1;
                count <= DIV - 1;
            end else if (!stop_pending) begin
                if (rx_sync) begin
                    stop_pending <= 1'b1;
                    count <= HALF - 1;
                end else begin
                    busy <= 1'b0;
                end
            end else begin
                busy <= 1'b0;
                stop_pending <= 1'b0;
                data_out <= shift;
                data_valid <= 1'b1;
            end
        end
    end
endmodule

module uart_tx #(
    parameter integer CLK_HZ = 50000000,
    parameter integer BAUD = 115200
) (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire start,
    output reg serial_out,
    output reg busy
);
    localparam integer DIV = (CLK_HZ + BAUD/2) / BAUD;
    reg [15:0] count;
    reg [3:0] bit_index;
    reg [7:0] shift;

    always @(posedge clk) begin
        if (rst) begin
            serial_out <= 1'b1;
            busy <= 1'b0;
            count <= 16'd0;
            bit_index <= 4'd0;
            shift <= 8'd0;
        end else if (!busy) begin
            serial_out <= 1'b1;
            if (start) begin
                shift <= data_in;
                serial_out <= 1'b0;
                busy <= 1'b1;
                count <= DIV - 1;
                bit_index <= 4'd0;
            end
        end else if (count != 0) begin
            count <= count - 1'b1;
        end else if (bit_index < 8) begin
            serial_out <= shift[bit_index];
            bit_index <= bit_index + 1'b1;
            count <= DIV - 1;
        end else if (bit_index == 8) begin
            serial_out <= 1'b1;
            bit_index <= 4'd9;
            count <= DIV - 1;
        end else begin
            busy <= 1'b0;
        end
    end
endmodule
