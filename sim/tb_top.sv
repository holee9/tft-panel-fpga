// =============================================================================
// Top-Level Testbench
// =============================================================================
// Purpose: Top-level testbench for TFT panel controller
// Author: TFT Leakage Reduction Project
// Date: 2026-02-10
// =============================================================================

module tb_top;

    // ========================================================================
    // Clock and Reset
    // ========================================================================
    logic clk;
    logic rst_n;

    // ========================================================================
    // SPI Interface
    // ========================================================================
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;
    logic spi_cs_n;

    // ========================================================================
    // Panel Control Outputs
    // ========================================================================
    logic [2:0] bias_sel;
    logic gate_en;
    logic data_en;
    logic scan_start;

    // ========================================================================
    // ADC Interface
    // ========================================================================
    logic adc_cs_n;
    logic adc_sclk;
    logic adc_mosi;
    logic adc_miso;

    // ========================================================================
    // Status LEDs
    // ========================================================================
    logic led_idle;
    logic led_active;

    // ========================================================================
    // DUT Instance
    // ========================================================================
    fpga_panel_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        .bias_sel(bias_sel),
        .gate_en(gate_en),
        .data_en(data_en),
        .scan_start(scan_start),
        .adc_cs_n(adc_cs_n),
        .adc_sclk(adc_sclk),
        .adc_mosi(adc_mosi),
        .adc_miso(adc_miso),
        .led_idle(led_idle),
        .led_active(led_active)
    );

    // ========================================================================
    // Clock Generation (100MHz)
    // ========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ========================================================================
    // SPI Driver Task
    // ========================================================================
    task spi_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            spi_cs_n = 0;
            // Send address
            for (int i = 7; i >= 0; i--) begin
                spi_sclk = 0;
                spi_mosi = addr[i];
                #10;
                spi_sclk = 1;
                #10;
            end
            // Send data
            for (int i = 31; i >= 0; i--) begin
                spi_sclk = 0;
                spi_mosi = data[i];
                #10;
                spi_sclk = 1;
                #10;
            end
            spi_cs_n = 1;
            spi_sclk = 0;
            spi_mosi = 0;
            @(posedge clk);
        end
    endtask

    // ========================================================================
    // Main Test Sequence
    // ========================================================================
    initial begin
        // Initialize
        rst_n = 0;
        spi_cs_n = 1;
        spi_sclk = 0;
        spi_mosi = 0;
        adc_miso = 0;

        // Reset
        #100;
        rst_n = 1;
        #100;

        $display("=== TFT Panel Controller Test Started ===");
        $display("Time: %0t", $time);

        // Test 1: Write Bias Select Register
        $display("\n[Test 1] Write Bias Select Register");
        spi_write(8'h02, 32'h5);

        // Test 2: Enable Idle Mode
        $display("\n[Test 2] Enable Idle Mode");
        spi_write(8'h00, 32'h1);

        // Test 3: Check Outputs
        #100;
        $display("\n[Test 3] Check Outputs");
        $display("  bias_sel = %b", bias_sel);
        $display("  gate_en  = %b", gate_en);
        $display("  data_en  = %b", data_en);
        $display("  scan_start = %b", scan_start);
        $display("  led_idle = %b", led_idle);
        $display("  led_active = %b", led_active);

        // Finish
        #1000;
        $display("\n=== Test Completed ===");
        $finish;
    end

    // ========================================================================
    // Timeout Watchdog
    // ========================================================================
    initial begin
        #100000;
        $display("ERROR: Test timeout!");
        $finish;
    end

    // ========================================================================
    // Waveform Dump
    // ========================================================================
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
