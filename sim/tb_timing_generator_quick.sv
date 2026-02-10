// Quick Test with Short Integration Time
`timescale 1ns/1ps
module tb_timing_generator_quick;
    logic clk, rst_n;
    logic frame_start, frame_reset;
    logic [15:0] integration_time;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic frame_busy, frame_complete;
    logic [11:0] row_addr, col_addr;

    timing_generator dut (
        .clk, .rst_n, .frame_start, .frame_reset, .integration_time,
        .row_start, .row_end, .col_start, .col_end,
        .frame_busy, .frame_complete, .row_addr, .col_addr
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Quick Test Started ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 1; // 1ms
        row_start = 0; row_end = 2; col_start = 0; col_end = 2;
        #100; rst_n = 1; #100;

        $display("[TEST] Starting frame capture");
        frame_start = 1;
        #20; frame_start = 0;

        wait(frame_busy);
        $display("[INFO] Frame busy at %0t ns", $time);

        wait(!frame_busy);
        $display("[INFO] Frame complete at %0t ns", $time);
        $display("[PASS] Test completed successfully!");
        $finish;
    end

    initial begin #10000000 $display("ERROR: Timeout!"); $finish; end
endmodule
