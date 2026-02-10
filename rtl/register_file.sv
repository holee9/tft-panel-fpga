// =============================================================================
// Register File Module
// =============================================================================
// Purpose: Register map for FPGA control and status
// Author: TFT Leakage Reduction Project
// Date: 2026-02-10
// =============================================================================

module register_file (
    input  logic clk,
    input  logic rst_n,

    // Register Interface
    input  logic [7:0]  reg_addr,
    input  logic [31:0] reg_wdata,
    output logic [31:0] reg_rdata,
    input  logic        reg_write,
    input  logic        reg_read,

    // Control Outputs
    output logic [2:0] bias_sel,
    output logic       idle_mode
);

    // ========================================================================
    // Register Addresses
    // ========================================================================
    localparam ADDR_CTRL        = 8'h00;
    localparam ADDR_STATUS      = 8'h01;
    localparam ADDR_BIAS_SEL    = 8'h02;
    localparam ADDR_SCAN_CONFIG = 8'h04;
    localparam ADDR_TIMER_L     = 8'h10;
    localparam ADDR_TIMER_H     = 8'h11;
    localparam ADDR_ADC_DATA    = 8'h20;
    localparam ADDR_VERSION     = 8'hFE;

    // ========================================================================
    // Registers
    // ========================================================================
    logic [2:0] bias_sel_reg;
    logic       idle_mode_reg;
    logic [7:0] scan_config_reg;
    logic [15:0] timer_period_reg;
    logic [11:0] adc_data_reg;
    logic [31:0] version_reg;

    // ========================================================================
    // Control Register Bit Definitions
    // ========================================================================
    localparam CTRL_IDLE_EN = 0;

    // ========================================================================
    // Register Write Logic
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bias_sel_reg    <= 3'b000;
            idle_mode_reg   <= 1'b0;
            scan_config_reg <= 8'h00;
            timer_period_reg <= 16'd1000;
        end else if (reg_write) begin
            case (reg_addr)
                ADDR_CTRL: begin
                    idle_mode_reg <= reg_wdata[CTRL_IDLE_EN];
                end
                ADDR_BIAS_SEL: begin
                    bias_sel_reg <= reg_wdata[2:0];
                end
                ADDR_SCAN_CONFIG: begin
                    scan_config_reg <= reg_wdata[7:0];
                end
                ADDR_TIMER_L: begin
                    timer_period_reg[7:0] <= reg_wdata[7:0];
                end
                ADDR_TIMER_H: begin
                    timer_period_reg[15:8] <= reg_wdata[7:0];
                end
            endcase
        end
    end

    // ========================================================================
    // Register Read Logic
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_rdata <= 32'd0;
        else if (reg_read) begin
            case (reg_addr)
                ADDR_CTRL: begin
                    reg_rdata <= {31'd0, idle_mode_reg};
                end
                ADDR_STATUS: begin
                    reg_rdata <= {30'd0, idle_mode_reg, 1'b1}; // Bit 0: ready
                end
                ADDR_BIAS_SEL: begin
                    reg_rdata <= {29'd0, bias_sel_reg};
                end
                ADDR_SCAN_CONFIG: begin
                    reg_rdata <= {24'd0, scan_config_reg};
                end
                ADDR_TIMER_L: begin
                    reg_rdata <= {24'd0, timer_period_reg[7:0]};
                end
                ADDR_TIMER_H: begin
                    reg_rdata <= {24'd0, timer_period_reg[15:8]};
                end
                ADDR_ADC_DATA: begin
                    reg_rdata <= {20'd0, adc_data_reg};
                end
                ADDR_VERSION: begin
                    reg_rdata <= 32'h56313030; // "V10" version 1.0
                end
                default: begin
                    reg_rdata <= 32'd0;
                end
            endcase
        end
    end

    // ========================================================================
    // Output Assignments
    // ========================================================================
    assign bias_sel  = bias_sel_reg;
    assign idle_mode = idle_mode_reg;

    // ========================================================================
    // Version constant
    // ========================================================================
    assign version_reg = 32'h56313030;

endmodule
