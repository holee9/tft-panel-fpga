// Bias Mux Controller Testbench
`timescale 1ns/1ps
module tb_bias_mux_controller;
    logic clk, rst_n;
    logic [1:0] bias_mode_select;
    logic bias_busy, bias_ready;
    logic v_pd_n, v_col_n, v_rg_n;

    bias_mux_controller dut (
        .clk, .rst_n, .bias_mode_select,
        .bias_busy, .bias_ready, .v_pd_n, .v_col_n, .v_rg_n
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Bias Mux Controller Test Started ===");
        rst_n = 0; bias_mode_select = 2'b00;
        #100; rst_n = 1; #100;

        $display("[TEST 1] NORMAL_BIAS mode");
        bias_mode_select = 2'b00;
        #1000;
        if (v_pd_n === 1'b0 && v_col_n === 1'b0 && v_rg_n === 1'b0)
            $display("[PASS] NORMAL mode test");
        else
            $display("[FAIL] NORMAL mode test");

        #5000;
        $display("[TEST 2] IDLE_LOW_BIAS mode");
        bias_mode_select = 2'b01;
        #10000;
        if (v_pd_n === 1'b0 && v_col_n === 1'b0)
            $display("[PASS] IDLE_LOW mode test");
        else
            $display("[FAIL] IDLE_LOW mode test");

        #5000;
        $display("[TEST 3] SLEEP_BIAS mode");
        bias_mode_select = 2'b10;
        #10000;
        if (v_pd_n === 1'b1 && v_col_n === 1'b1 && v_rg_n === 1'b1)
            $display("[PASS] SLEEP mode test");
        else
            $display("[FAIL] SLEEP mode test");

        #1000;
        $display("=== All Tests Completed ===");
        $finish;
    end

    initial begin #100000 $display("ERROR: Test timeout!"); $finish; end
endmodule
