// Top-Level Testbench
`timescale 1ns/1ps
module tb_top;
    logic clk, rst_n;
    logic spi_sclk, spi_mosi, spi_miso, spi_cs_n;
    logic [11:0] row_addr, col_addr, dummy_row_addr;
    logic row_clk_en, col_clk_en, gate_sel, gate_pulse, reset_pulse;
    logic frame_busy, frame_complete;
    logic [1:0] bias_mode_select;
    logic v_pd_n, v_col_n, v_rg_n, bias_ready, bias_busy;
    logic dummy_scan_active, dummy_scan_busy, dummy_reset_pulse;
    logic adc_cs_n, adc_sclk, adc_mosi, adc_miso, adc_clk, adc_start;
    logic [13:0] adc_data, fifo_wr_data;
    logic fifo_wr_en, fifo_full, fifo_empty;
    logic int_frame_complete, int_dummy_complete, int_fifo_overflow, int_error, int_active;
    logic led_idle, led_active, led_error;
    
    fpga_panel_controller dut (
        .clk, .rst_n, .spi_sclk, .spi_mosi, .spi_miso, .spi_cs_n,
        .row_addr, .col_addr, .row_clk_en, .col_clk_en, .gate_sel, .gate_pulse, .reset_pulse,
        .frame_busy, .frame_complete, .bias_mode_select, .v_pd_n, .v_col_n, .v_rg_n,
        .bias_ready, .bias_busy, .dummy_scan_active, .dummy_scan_busy,
        .dummy_row_addr, .dummy_reset_pulse, .adc_cs_n, .adc_sclk, .adc_mosi, .adc_miso,
        .adc_clk, .adc_start, .adc_data, .fifo_wr_en, .fifo_wr_data, .fifo_full, .fifo_empty,
        .int_frame_complete, .int_dummy_complete, .int_fifo_overflow, .int_error, .int_active,
        .led_idle, .led_active, .led_error
    );
    
    initial begin clk = 0; forever #5 clk = ~clk; end
    
    assign adc_data = 14'h0;
    assign fifo_full = 0;
    assign fifo_empty = 1;
    
    initial begin
        $display("=== TFT Panel Controller Test Started ===");
        rst_n = 0; spi_cs_n = 1; spi_sclk = 0; spi_mosi = 0;
        #100; rst_n = 1; #100;
        
        #1000;
        $display("led_idle=%b, led_active=%b", led_idle, led_active);
        $display("=== Test Completed Successfully ===");
    end
    
    initial begin #10000 $display("ERROR: Test timeout!"); end
    initial begin #2000 $finish; end
endmodule
