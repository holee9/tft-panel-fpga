// Register File Testbench
`timescale 1ns/1ps
module tb_register_file;
    logic clk, rst_n;
    logic [7:0] reg_addr;
    logic [31:0] reg_wdata, reg_rdata;
    logic reg_write, reg_read;
    logic [15:0] integration_time;
    logic frame_start, frame_reset;
    logic [1:0] bias_mode_select;
    logic [15:0] dummy_period;
    logic dummy_enable, dummy_trigger;
    logic adc_test_pattern_en;
    logic [7:0] adc_test_pattern_val;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic [7:0] row_clk_div, col_clk_div;
    logic [31:0] interrupt_mask;
    logic interrupt_clear;
    logic frame_busy, fifo_empty, fifo_full;
    logic dummy_busy, bias_ready;
    logic [31:0] interrupt_status_raw;
    logic [7:0] test_pattern_addr;
    logic [7:0] test_pattern_data;
    logic test_pattern_we;
    logic [2:0] bias_sel;
    logic idle_mode;
    logic fifo_overflow;

    register_file dut (
        .clk, .rst_n, .reg_addr, .reg_wdata, .reg_rdata, .reg_write, .reg_read,
        .integration_time, .frame_start, .frame_reset, .bias_mode_select,
        .dummy_period, .dummy_enable, .dummy_trigger, .adc_test_pattern_en,
        .adc_test_pattern_val, .row_start, .row_end, .col_start, .col_end,
        .row_clk_div, .col_clk_div, .interrupt_mask, .interrupt_clear,
        .frame_busy, .fifo_empty, .fifo_full, .dummy_busy, .bias_ready,
        .interrupt_status_raw, .test_pattern_addr, .test_pattern_data,
        .test_pattern_we, .bias_sel, .idle_mode, .fifo_overflow
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Register File Test Started ===");
        rst_n = 0; reg_write = 0; reg_read = 0;
        frame_busy = 0; fifo_empty = 1; fifo_full = 0;
        dummy_busy = 0; bias_ready = 1;
        interrupt_status_raw = 0;
        #100; rst_n = 1; #100;

        $display("[TEST 1] Control register write");
        reg_addr = 8'h00;
        reg_wdata = 32'h0F;
        reg_write = 1;
        #20; reg_write = 0;
        #20;
        if (idle_mode == 1'b1)
            $display("[PASS] Control register test");
        else
            $display("[FAIL] Control register test");

        #100;
        $display("[TEST 2] Bias select register");
        reg_addr = 8'h02;
        reg_wdata = 32'h01;
        reg_write = 1;
        #20; reg_write = 0;
        #20;
        if (bias_sel == 3'b001)
            $display("[PASS] Bias select test");
        else
            $display("[FAIL] Bias select test");

        #100;
        $display("[TEST 3] Status register read");
        reg_addr = 8'h01;
        reg_read = 1;
        #20; reg_read = 0;
        #20;
        $display("[INFO] STATUS = 0x%h", reg_rdata);
        if (reg_rdata[0] == 1'b1)
            $display("[PASS] Status register test");
        else
            $display("[FAIL] Status register test");

        #1000;
        $display("=== All Tests Completed ===");
        $finish;
    end

    initial begin #100000 $display("ERROR: Test timeout!"); $finish; end
endmodule
