// ADC Controller Testbench
`timescale 1ns/1ps
module tb_adc_controller;
    logic clk, rst_n;
    logic adc_start, adc_test_pattern_en;
    logic [7:0] adc_test_pattern_val;
    logic adc_cs_n, adc_sclk, adc_mosi, adc_miso;
    logic adc_clk;
    logic [13:0] adc_data;
    logic adc_busy, adc_data_valid;
    logic [13:0] adc_data_reg;
    logic fifo_overflow;

    adc_controller dut (
        .clk, .rst_n, .adc_start, .adc_test_pattern_en, .adc_test_pattern_val,
        .adc_cs_n, .adc_sclk, .adc_mosi, .adc_miso, .adc_clk,
        .adc_data, .adc_busy, .adc_data_valid, .adc_data_reg, .fifo_overflow
    );

    logic [13:0] adc_data_sim;
    assign adc_data = adc_data_sim;
    assign adc_miso = adc_cs_n ? 1'b0 : adc_data_sim[13];

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== ADC Controller Test Started ===");
        rst_n = 0; adc_start = 0; adc_test_pattern_en = 0; adc_test_pattern_val = 8'hAA;
        adc_data_sim = 14'h1234;
        #100; rst_n = 1; #100;

        $display("[TEST 1] Basic ADC conversion");
        adc_start = 1;
        #20; adc_start = 0;
        wait(adc_busy);
        wait(adc_data_valid);
        $display("[INFO] ADC_DATA_REG = 0x%h", adc_data_reg);
        if (adc_data_valid)
            $display("[PASS] Basic ADC conversion test");
        else
            $display("[FAIL] ADC conversion test");

        #1000;
        $display("[TEST 2] Test pattern mode");
        adc_test_pattern_en = 1;
        adc_test_pattern_val = 8'h55;
        #100;
        adc_start = 1;
        #20; adc_start = 0;
        wait(adc_data_valid);
        if (adc_data_reg[7:0] == 8'h55)
            $display("[PASS] Test pattern mode test");
        else
            $display("[FAIL] Test pattern test");

        #1000;
        $display("=== All Tests Completed ===");
        $finish;
    end

    initial begin #100000 $display("ERROR: Test timeout!"); $finish; end
endmodule
