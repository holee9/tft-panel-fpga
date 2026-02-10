// SPI Slave Interface Module
module spi_slave_interface (
    input  logic clk,
    input  logic rst_n,
    input  logic spi_sclk,
    input  logic spi_mosi,
    output logic spi_miso,
    input  logic spi_cs_n,
    output logic [7:0]  reg_addr,
    output logic [31:0] reg_wdata,
    input  logic [31:0] reg_rdata,
    output logic        reg_write,
    output logic        reg_read
);
    logic [31:0] shift_reg_tx, shift_reg_rx;
    logic [5:0] bit_cnt;
    logic [1:0] state;
    logic sclk_prev, sclk_rising;
    
    always_ff @(posedge clk) sclk_prev <= spi_sclk;
    assign sclk_rising = spi_sclk && !sclk_prev;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            bit_cnt <= 0;
            shift_reg_rx <= 0;
            reg_addr <= 0;
            reg_wdata <= 0;
            reg_write <= 0;
            reg_read <= 0;
        end else if (spi_cs_n) begin
            state <= 0;
            bit_cnt <= 0;
        end else if (sclk_rising) begin
            shift_reg_rx <= {shift_reg_rx[30:0], spi_mosi};
            if (bit_cnt < 31) begin
                bit_cnt <= bit_cnt + 1;
            end else begin
                bit_cnt <= 0;
                if (state == 0) reg_addr <= shift_reg_rx[7:0];
                else if (state == 1) reg_wdata <= shift_reg_rx;
                if (state == 1) reg_write <= 1;
                else if (state == 2) reg_read <= 1;
                state <= state + 1;
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_tx <= 0;
        end else if (spi_cs_n) begin
            shift_reg_tx <= 0;
        end else if (state == 2 && bit_cnt == 0) begin
            shift_reg_tx <= reg_rdata;
        end else if (state == 3 && !sclk_rising && bit_cnt > 0) begin
            shift_reg_tx <= {shift_reg_tx[30:0], 1'b0};
        end
    end
    
    assign spi_miso = (state == 3 && !spi_cs_n) ? shift_reg_tx[31] : 1'b0;
endmodule
