// SPI Slave Interface Module - SPI Mode 0 (CPOL=0, CPHA=0)
// Protocol: 8-bit address + 32-bit data (LSB first)
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

    typedef enum logic [1:0] {
        IDLE, ADDR_PHASE, DATA_PHASE
    } state_t;

    state_t state;
    logic [5:0] bit_counter;
    logic [31:0] shift_reg_rx;
    logic [31:0] shift_reg_tx;

    always_ff @(posedge spi_sclk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_counter <= 6'd0;
            shift_reg_rx <= 32'd0;
            reg_addr <= 8'd0;
            reg_wdata <= 32'd0;
            reg_write <= 1'b0;
            reg_read <= 1'b0;
            shift_reg_tx <= 32'd0;
        end else begin
            reg_write <= 1'b0;
            reg_read <= 1'b0;

            if (spi_cs_n) begin
                state <= IDLE;
                bit_counter <= 6'd0;
                shift_reg_rx <= 32'd0;
            end else begin
                case (state)
                    IDLE: begin
                        shift_reg_rx <= {shift_reg_rx[30:0], spi_mosi};
                        bit_counter   <= 6'd1;
                        state         <= ADDR_PHASE;
                    end

                    ADDR_PHASE: begin
                        // Use blocking assignment for immediate update
                        shift_reg_rx = {shift_reg_rx[30:0], spi_mosi};

                        if (bit_counter == 6'd7) begin
                            // All 8 address bits received
                            reg_addr <= {
                                shift_reg_rx[0], shift_reg_rx[1], shift_reg_rx[2], shift_reg_rx[3],
                                shift_reg_rx[4], shift_reg_rx[5], shift_reg_rx[6], shift_reg_rx[7]
                            };
                            state <= DATA_PHASE;
                            bit_counter <= 6'd0;
                            shift_reg_tx <= reg_rdata;
                        end else begin
                            bit_counter <= bit_counter + 6'd1;
                        end
                    end

                    DATA_PHASE: begin
                        // Use blocking assignment for immediate update
                        shift_reg_rx = {shift_reg_rx[30:0], spi_mosi};

                        if (bit_counter == 6'd31) begin
                            // All 32 data bits received
                            reg_wdata <= {
                                shift_reg_rx[0], shift_reg_rx[1], shift_reg_rx[2], shift_reg_rx[3],
                                shift_reg_rx[4], shift_reg_rx[5], shift_reg_rx[6], shift_reg_rx[7],
                                shift_reg_rx[8], shift_reg_rx[9], shift_reg_rx[10], shift_reg_rx[11],
                                shift_reg_rx[12], shift_reg_rx[13], shift_reg_rx[14], shift_reg_rx[15],
                                shift_reg_rx[16], shift_reg_rx[17], shift_reg_rx[18], shift_reg_rx[19],
                                shift_reg_rx[20], shift_reg_rx[21], shift_reg_rx[22], shift_reg_rx[23],
                                shift_reg_rx[24], shift_reg_rx[25], shift_reg_rx[26], shift_reg_rx[27],
                                shift_reg_rx[28], shift_reg_rx[29], shift_reg_rx[30], shift_reg_rx[31]
                            };
                            reg_write <= 1'b1;
                            state <= IDLE;
                            bit_counter <= 6'd0;
                        end else begin
                            bit_counter <= bit_counter + 6'd1;
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end

    assign spi_miso = (state == DATA_PHASE && !spi_cs_n) ? shift_reg_tx[31] : 1'b0;

endmodule
