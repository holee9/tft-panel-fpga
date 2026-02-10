// =============================================================================
// SPI Slave Interface Module
// =============================================================================
// Purpose: SPI Slave protocol handler for register access
// Author: TFT Leakage Reduction Project
// Date: 2026-02-10
// =============================================================================

module spi_slave_interface (
    input  logic clk,
    input  logic rst_n,

    // SPI Physical Interface
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,

    // Register Interface
    output logic [7:0]  reg_addr,
    output logic [31:0] reg_wdata,
    input  logic [31:0] reg_rdata,
    output logic        reg_write,
    output logic        reg_read
);

    // ========================================================================
    // Parameters
    // ========================================================================
    localparam IDLE       = 2'b00;
    localparam RX_ADDR    = 2'b01;
    localparam RX_DATA    = 2'b10;
    localparam TX_DATA    = 2'b11;

    // ========================================================================
    // Internal Signals
    // ========================================================================
    logic [2:0] bit_cnt;
    logic [7:0] shift_addr;
    logic [31:0] shift_wdata;
    logic [31:0] shift_rdata;
    logic [1:0] state, next_state;
    logic sclk_prev;
    logic sclk_rising;
    logic sclk_falling;

    // ========================================================================
    // Edge Detection
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_prev <= 1'b0;
        else
            sclk_prev <= spi_sclk;
    end

    assign sclk_rising  = spi_sclk && !sclk_prev;
    assign sclk_falling = !spi_sclk && sclk_prev;

    // ========================================================================
    // State Machine
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (spi_cs_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!spi_cs_n)
                    next_state = RX_ADDR;
            end
            RX_ADDR: begin
                if (bit_cnt == 3'd7)
                    next_state = RX_DATA;
            end
            RX_DATA: begin
                if (bit_cnt == 3'd31)
                    next_state = TX_DATA;
            end
            TX_DATA: begin
                if (bit_cnt == 3'd31)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // ========================================================================
    // Shift Register Logic
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt     <= 3'd0;
            shift_addr  <= 8'd0;
            shift_wdata <= 32'd0;
            shift_rdata <= 32'd0;
            reg_addr    <= 8'd0;
            reg_wdata   <= 32'd0;
            reg_write   <= 1'b0;
            reg_read    <= 1'b0;
        end else begin
            reg_write <= 1'b0;
            reg_read  <= 1'b0;

            if (spi_cs_n) begin
                bit_cnt     <= 3'd0;
                shift_addr  <= 8'd0;
            end else if (sclk_rising) begin
                case (state)
                    RX_ADDR: begin
                        shift_addr <= {shift_addr[6:0], spi_mosi};
                        if (bit_cnt < 3'd7)
                            bit_cnt <= bit_cnt + 1;
                        else begin
                            reg_addr <= {shift_addr[6:0], spi_mosi};
                            bit_cnt  <= 3'd0;
                        end
                    end
                    RX_DATA: begin
                        shift_wdata <= {shift_wdata[30:0], spi_mosi};
                        if (bit_cnt < 3'd31)
                            bit_cnt <= bit_cnt + 1;
                        else begin
                            reg_wdata <= {shift_wdata[30:0], spi_mosi};
                            reg_write <= 1'b1;
                            bit_cnt   <= 3'd0;
                        end
                    end
                    TX_DATA: begin
                        if (bit_cnt == 3'd0)
                            shift_rdata <= reg_rdata;
                        if (bit_cnt < 3'd31)
                            bit_cnt <= bit_cnt + 1;
                        else
                            bit_cnt <= 3'd0;
                    end
                endcase
            end
        end
    end

    // ========================================================================
    // MISO Output
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            spi_miso <= 1'b0;
        else if (spi_cs_n)
            spi_miso <= 1'b0;
        else if (sclk_falling && state == TX_DATA)
            spi_miso <= shift_rdata[31];
        else
            spi_miso <= 1'b0;
    end

    // ========================================================================
    // Output shift on falling edge
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ; // Do nothing
        else if (sclk_falling && state == TX_DATA)
            shift_rdata <= {shift_rdata[30:0], 1'b0};
    end

endmodule
