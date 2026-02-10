// Dummy Scan Engine Testbench
`timescale 1ns/1ps
module tb_dummy_scan_engine;
    logic clk, rst_n;
    logic [15:0] dummy_period;
    logic dummy_enable, dummy_trigger;
    logic dummy_active, dummy_complete;
    logic [11:0] row_addr;
    logic reset_pulse;
    logic dummy_scan_mode;

    dummy_scan_engine dut (
        .clk, .rst_n, .dummy_period, .dummy_enable, .dummy_trigger,
        .dummy_active, .dummy_complete, .row_addr, .reset_pulse, .dummy_scan_mode
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Dummy Scan Engine Test Started ===");
        rst_n = 0; dummy_enable = 0; dummy_trigger = 0; dummy_period = 100;
        #100; rst_n = 1; #100;

        $display("[TEST 1] Manual trigger");
        dummy_enable = 0;
        dummy_trigger = 1;
        #20; dummy_trigger = 0;
        wait(dummy_active);
        $display("[INFO] Dummy scan started");
        wait(!dummy_active);
        $display("[INFO] Dummy scan completed");
        $display("[PASS] Manual trigger test");

        #1000;
        $display("=== All Tests Completed ===");
        $finish;
    end

    initial begin #500000 $display("ERROR: Test timeout!"); $finish; end
endmodule
