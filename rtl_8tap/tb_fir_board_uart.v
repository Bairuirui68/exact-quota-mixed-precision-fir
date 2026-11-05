`timescale 1ns / 1ps

module tb_fir_board_uart;
    localparam integer BIT_CYCLES = 434;
    reg FPGA_CLK = 1'b0;
    reg S0_N = 1'b0;
    reg UART_RXD = 1'b1;
    wire UART_TXD;
    wire [8:0] LED;
    integer signed history [0:7];
    integer i;
    integer phase;
    integer vector_index;
    reg [15:0] input_vectors [0:156];
    reg signed [15:0] sample;
    reg [39:0] received;
    reg [7:0] b0, b1, b2, b3, b4;
    reg [15:0] sample_bits;

    fir_board_uart #(.CONFIG(2), .CLK_HZ(50000000), .BAUD(115200)) dut (
        .FPGA_CLK(FPGA_CLK), .S0_N(S0_N), .UART_RXD(UART_RXD),
        .UART_TXD(UART_TXD), .LED(LED)
    );

    always #10 FPGA_CLK = ~FPGA_CLK;
    always @(posedge FPGA_CLK) begin
        if (dut.rx_valid) $display("RX valid byte %h at %0t", dut.rx_byte, $time);
        if (dut.sample_en) $display("sample accepted %h at %0t", dut.sample_data, $time);
    end

    task send_byte;
        input [7:0] value;
        integer bit_no;
        begin
            @(negedge FPGA_CLK); UART_RXD = 1'b0;
            repeat (BIT_CYCLES) @(posedge FPGA_CLK);
            for (bit_no = 0; bit_no < 8; bit_no = bit_no + 1) begin
                @(negedge FPGA_CLK); UART_RXD = value[bit_no];
                repeat (BIT_CYCLES) @(posedge FPGA_CLK);
            end
            @(negedge FPGA_CLK); UART_RXD = 1'b1;
            repeat (BIT_CYCLES) @(posedge FPGA_CLK);
        end
    endtask

    task receive_byte;
        output [7:0] value;
        integer bit_no;
        begin
            @(negedge UART_TXD);
            repeat (BIT_CYCLES + BIT_CYCLES/2) @(posedge FPGA_CLK);
            for (bit_no = 0; bit_no < 8; bit_no = bit_no + 1) begin
                value[bit_no] = UART_TXD;
                repeat (BIT_CYCLES) @(posedge FPGA_CLK);
            end
            if (UART_TXD !== 1'b1) $fatal(1, "UART stop bit error");
        end
    endtask

    function [39:0] expected_result;
        input dummy;
        integer j;
        integer shift;
        reg signed [15:0] coefficient;
        reg signed [31:0] product;
        reg signed [63:0] total;
        reg signed [34:0] result35;
        begin
            total = 0;
            for (j = 0; j < 8; j = j + 1) begin
                case (j)
                    0: begin coefficient = 0; shift = 12; end
                    1: begin coefficient = 16'sh0360; shift = 0; end
                    2: begin coefficient = 8'sh14; shift = 8; end
                    3: begin coefficient = 8'sh29; shift = 8; end
                    4: begin coefficient = 8'sh29; shift = 8; end
                    5: begin coefficient = 8'sh14; shift = 8; end
                    6: begin coefficient = 16'sh0360; shift = 0; end
                    default: begin coefficient = 0; shift = 12; end
                endcase
                product = history[j] * coefficient;
                total = total + (product <<< shift);
            end
            result35 = total[34:0];
            expected_result = {{5{result35[34]}}, result35};
        end
    endfunction

    task run_sample;
        input signed [15:0] value;
        reg [39:0] expected;
        begin
            sample_bits = value;
            phase = 1;
            send_byte(sample_bits[7:0]);
            phase = 2;
            send_byte(sample_bits[15:8]);
            phase = 3;
            for (i = 7; i > 0; i = i - 1) history[i] = history[i-1];
            history[0] = value;
            expected = expected_result(1'b0);
            $display("sample %0d sent", value);
            receive_byte(b0); $display("  rx byte 0=%h", b0);
            receive_byte(b1); $display("  rx byte 1=%h", b1);
            receive_byte(b2); $display("  rx byte 2=%h", b2);
            receive_byte(b3); $display("  rx byte 3=%h", b3);
            receive_byte(b4); $display("  rx byte 4=%h", b4);
            received = {b0, b1, b2, b3, b4};
            if (received !== expected)
                $fatal(1, "UART FIR mismatch: input=%0d expected=%h received=%h", value, expected, received);
            $display("PASS input=%0d output=%h", value, received);
        end
    endtask

    initial begin
        for (i = 0; i < 8; i = i + 1) history[i] = 0;
        phase = 0;
        repeat (5) @(posedge FPGA_CLK);
        @(negedge FPGA_CLK); S0_N = 1'b1;
        $readmemh("input_seq.hex", input_vectors);
        for (vector_index = 0; vector_index < 157; vector_index = vector_index + 1)
            run_sample(input_vectors[vector_index]);
        $display("UART board-wrapper simulation passed: 157 samples, CONFIG C, 50 MHz / 115200.");
        $finish;
    end

    initial begin
        #200000000;
        $fatal(1, "UART timeout phase=%0d rx_valid=%b byte=%h busy=%b bit=%d count=%d sync=%b have_low=%b sample_en=%b fir_valid=%b tx_busy=%b tx_state=%d",
               phase, dut.rx_valid, dut.rx_byte, dut.receiver.busy, dut.receiver.bit_index,
               dut.receiver.count, dut.receiver.rx_sync, dut.have_low, dut.sample_en,
               dut.fir_valid, dut.tx_busy, dut.tx_state);
    end
endmodule
