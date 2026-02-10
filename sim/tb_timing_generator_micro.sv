// Test with Microsecond Integration Time
`timescale 1ns/1ps
module tb_timing_generator_micro;
    logic clk, rst_n;
    logic frame_start, frame_reset;
    logic [15:0] integration_time;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic frame_busy, frame_complete;

    timing_generator dut (
        .clk, .rst_n, .frame_start, .frame_reset, .integration_time,
        .row_start, .row_end, .col_start, .col_end,
        .frame_busy, .frame_complete
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Microsecond Test Started ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 1; // 1ms
        row_start = 0; row_end = 2; col_start = 0; col_end = 2;
        #100; rst_n = 1; #100;

        // Test with very short integration time first
        $display("[TEST 1] Very short integration (1us equivalent)");
        integration_time = 1; // 1ms in real terms, but let's see the behavior
        frame_start = 1;
        #20; frame_start = 0;

        // Monitor state changes
        $display("Waiting for frame busy...");
        wait(frame_busy);
        $display("[TIME] %0t ns: Frame busy", $time);

        $display("Waiting for frame complete...");
        wait(!frame_busy);
        $display("[TIME] %0t ns: Frame complete", $time);
        $display("[PASS] Test completed!");

        $finish;
    end

    initial begin #2000000 $display("ERROR: Timeout!"); $finish; end
endmodule
