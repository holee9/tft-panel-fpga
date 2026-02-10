// =============================================================================
// TFT Panel FPGA Controller - Top Module
// =============================================================================
// Purpose: Top-level module for TFT panel leakage reduction control
// Author: TFT Leakage Reduction Project
// Date: 2026-02-10
// =============================================================================

module fpga_panel_controller (
    // System Clock and Reset
    input  logic clk,
    input  logic rst_n,

    // SPI Slave Interface
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,

    // Panel Control Outputs
    output logic [2:0] bias_sel,
    output logic gate_en,
    output logic data_en,
    output logic scan_start,

    // ADC Interface
    output logic adc_cs_n,
    output logic adc_sclk,
    output logic adc_mosi,
    input  logic adc_miso,

    // Status LED
    output logic led_idle,
    output logic led_active
);

    // ========================================================================
    // Parameters
    // ========================================================================
    localparam CTRL_IDLE     = 8'h00;
    localparam CTRL_ACTIVE   = 8'h01;
    localparam CTRL_BIAS_SEL = 8'h02;

    // ========================================================================
    // Internal Signals
    // ========================================================================
    logic [7:0] reg_addr;
    logic [31:0] reg_wdata;
    logic [31:0] reg_rdata;
    logic reg_write;
    logic reg_read;

    logic [2:0] bias_sel_reg;
    logic idle_mode;

    // ========================================================================
    // SPI Slave Interface Instance
    // ========================================================================
    spi_slave_interface u_spi_slave (
        .clk(clk),
        .rst_n(rst_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_cs_n(spi_cs_n),
        .reg_addr(reg_addr),
        .reg_wdata(reg_wdata),
        .reg_rdata(reg_rdata),
        .reg_write(reg_write),
        .reg_read(reg_read)
    );

    // ========================================================================
    // Register File Instance
    // ========================================================================
    register_file u_reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .reg_addr(reg_addr),
        .reg_wdata(reg_wdata),
        .reg_rdata(reg_rdata),
        .reg_write(reg_write),
        .reg_read(reg_read),
        .bias_sel(bias_sel_reg),
        .idle_mode(idle_mode)
    );

    // ========================================================================
    // Output Assignments
    // ========================================================================
    assign bias_sel    = bias_sel_reg;
    assign gate_en     = ~idle_mode;
    assign data_en     = ~idle_mode;
    assign scan_start  = idle_mode;
    assign led_idle    = idle_mode;
    assign led_active  = ~idle_mode;

    // ========================================================================
    // ADC Interface (Placeholder)
    // ========================================================================
    assign adc_cs_n  = 1'b1;
    assign adc_sclk  = 1'b0;
    assign adc_mosi  = 1'b0;

    // ========================================================================
    // Assertions
    // ========================================================================

    // Bias selection should be 3-bit value
    `pragma protect begin
    initial begin
        covergroup bias_sel_cg;
            coverpoint bias_sel_reg {
                bins low   = {3'b000};
                bins mid   = {3'b001, 3'b010, 3'b011};
                bins high  = {3'b100, 3'b101, 3'b110};
                bins off   = {3'b111};
            }
        endgroup
    end
    `pragma protect end

endmodule
