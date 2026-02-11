// Register File Module - 64 registers
// Enhanced with individual interrupt enable, status, and clear registers
module register_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [7:0]  reg_addr,
    input  logic [31:0] reg_wdata,
    output logic [31:0] reg_rdata,
    input  logic        reg_write,
    input  logic        reg_read,
    output logic [15:0] integration_time,
    output logic        frame_start,
    output logic        frame_reset,
    output logic [1:0]  bias_mode_select,
    output logic [15:0] dummy_period,
    output logic        dummy_enable,
    input  logic        dummy_trigger,
    output logic        adc_test_pattern_en,
    output logic [7:0]  adc_test_pattern_val,
    output logic [11:0] row_start,
    output logic [11:0] row_end,
    output logic [11:0] col_start,
    output logic [11:0] col_end,
    output logic [7:0]  row_clk_div,
    output logic [7:0]  col_clk_div,
    output logic [31:0] interrupt_mask,
    output logic        interrupt_clear,
    input  logic        frame_busy,
    input  logic        fifo_empty,
    input  logic        fifo_full,
    input  logic        fifo_overflow,
    input  logic        dummy_busy,
    input  logic        bias_ready,
    input  logic [31:0] interrupt_status_raw,
    output logic [7:0]  test_pattern_addr,
    output logic [7:0]  test_pattern_data,
    output logic        test_pattern_we,
    output logic [2:0]  bias_sel,
    output logic        idle_mode,
    // Enhanced interrupt outputs
    output logic [31:0] interrupt_status     // Interrupt status register (read-only)
);
    // Address definitions
    localparam ADDR_CTRL = 0, ADDR_STATUS = 1, ADDR_BIAS_SEL = 2;
    localparam ADDR_DUMMY_PERIOD_L = 3, ADDR_DUMMY_PERIOD_H = 4, ADDR_DUMMY_CONTROL = 5;
    localparam ADDR_ROW_START_L = 6, ADDR_ROW_START_H = 7;
    localparam ADDR_ROW_END_L = 8, ADDR_ROW_END_H = 9;
    localparam ADDR_COL_START_L = 10, ADDR_COL_START_H = 11;
    localparam ADDR_COL_END_L = 12, ADDR_COL_END_H = 13;
    localparam ADDR_INTEGRATION_L = 14, ADDR_INTEGRATION_H = 15;
    localparam ADDR_FIRMWARE_VER = 23;
    // Enhanced interrupt register addresses
    localparam ADDR_INT_EN = 24;           // Interrupt Enable register (RW)
    localparam ADDR_INT_STATUS = 25;       // Interrupt Status register (RO)
    localparam ADDR_INT_CLEAR = 26;        // Interrupt Clear register (W1C)

    // Interrupt bit definitions
    localparam INT_FRAME_COMPLETE     = 5'd0;  // Frame capture complete interrupt
    localparam INT_FIFO_OVERFLOW      = 5'd1;  // FIFO overflow interrupt
    localparam INT_DUMMY_SCAN_COMPLETE = 5'd2; // Dummy scan complete interrupt
    localparam INT_BIAS_READY         = 5'd3;  // Bias ready interrupt
    localparam INT_ADC_DATA_READY     = 5'd4;  // ADC data ready interrupt
    
    // Internal registers
    logic [2:0] bias_sel_reg;
    logic idle_mode_reg;
    logic [15:0] dummy_period_reg;
    logic dummy_enable_reg;
    logic [11:0] row_start_reg, row_end_reg, col_start_reg, col_end_reg;
    logic [15:0] integration_time_reg;
    logic [31:0] interrupt_mask_reg;      // Legacy: Single mask for all interrupts
    logic [31:0] interrupt_status_reg;    // Current interrupt status
    logic [31:0] int_enable_reg;          // Individual interrupt enable bits
    logic [31:0] int_status_reg;          // Raw interrupt status (latched)
    logic [31:0] int_clear_reg;           // Interrupt clear register (write-only)
    logic frame_start_reg, frame_reset_reg;
    logic adc_test_pattern_en_reg;
    logic [7:0] adc_test_pattern_val_reg;

    // Interrupt raw signals extracted from interrupt_status_raw
    logic frame_complete_int;
    logic fifo_overflow_int;
    logic dummy_scan_complete_int;
    logic bias_ready_int;
    logic adc_data_ready_int;

    // Assign individual interrupt signals from raw input
    assign frame_complete_int      = interrupt_status_raw[INT_FRAME_COMPLETE];
    assign fifo_overflow_int       = interrupt_status_raw[INT_FIFO_OVERFLOW];
    assign dummy_scan_complete_int = interrupt_status_raw[INT_DUMMY_SCAN_COMPLETE];
    assign bias_ready_int          = interrupt_status_raw[INT_BIAS_READY];
    assign adc_data_ready_int      = interrupt_status_raw[INT_ADC_DATA_READY];
    
    // Enhanced interrupt status logic
    // Interrupts are latched when raw signal goes high
    // They can be individually enabled/disabled via int_enable_reg
    // They can be cleared via write to INT_CLEAR register
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            bias_sel_reg <= 0;
            idle_mode_reg <= 0;
            dummy_period_reg <= 60;
            dummy_enable_reg <= 0;
            row_start_reg <= 0;
            row_end_reg <= 2047;
            col_start_reg <= 0;
            col_end_reg <= 2047;
            integration_time_reg <= 100;
            interrupt_mask_reg <= 0;
            interrupt_status_reg <= 0;
            int_enable_reg <= 0;           // All interrupts disabled by default
            int_status_reg <= 0;           // No pending interrupts
            int_clear_reg <= 0;
            frame_start_reg <= 0;
            frame_reset_reg <= 0;
            adc_test_pattern_en_reg <= 0;
            adc_test_pattern_val_reg <= 0;
        end else begin
            frame_start_reg <= 0;
            frame_reset_reg <= 0;
            int_clear_reg <= 0;            // Clear is pulse-based

            if (reg_write) begin
                case (reg_addr)
                    ADDR_CTRL: begin
                        idle_mode_reg <= reg_wdata[0];
                        frame_start_reg <= reg_wdata[1];
                        frame_reset_reg <= reg_wdata[2];
                        adc_test_pattern_en_reg <= reg_wdata[3];
                    end
                    ADDR_BIAS_SEL: bias_sel_reg <= reg_wdata[2:0];
                    ADDR_DUMMY_PERIOD_L: dummy_period_reg[7:0] <= reg_wdata[7:0];
                    ADDR_DUMMY_PERIOD_H: dummy_period_reg[15:8] <= reg_wdata[7:0];
                    ADDR_DUMMY_CONTROL: dummy_enable_reg <= reg_wdata[0];
                    ADDR_ROW_START_L: row_start_reg[7:0] <= reg_wdata[7:0];
                    ADDR_ROW_START_H: row_start_reg[11:8] <= reg_wdata[3:0];
                    ADDR_ROW_END_L: row_end_reg[7:0] <= reg_wdata[7:0];
                    ADDR_ROW_END_H: row_end_reg[11:8] <= reg_wdata[3:0];
                    ADDR_COL_START_L: col_start_reg[7:0] <= reg_wdata[7:0];
                    ADDR_COL_START_H: col_start_reg[11:8] <= reg_wdata[3:0];
                    ADDR_COL_END_L: col_end_reg[7:0] <= reg_wdata[7:0];
                    ADDR_COL_END_H: col_end_reg[11:8] <= reg_wdata[3:0];
                    ADDR_INTEGRATION_L: integration_time_reg[7:0] <= reg_wdata[7:0];
                    ADDR_INTEGRATION_H: integration_time_reg[15:8] <= reg_wdata[7:0];
                    // Enhanced interrupt registers
                    ADDR_INT_EN: int_enable_reg <= reg_wdata;  // Individual interrupt enable
                    ADDR_INT_CLEAR: int_clear_reg <= reg_wdata; // Write to clear specific interrupts
                endcase
            end

            // Legacy interrupt status calculation (for backward compatibility)
            interrupt_status_reg <= (interrupt_status_reg & ~interrupt_status_raw) |
                                    (interrupt_status_raw & interrupt_mask_reg);

            // Enhanced interrupt latching logic
            // Set interrupt bit when raw signal is high and corresponding enable is set
            // Interrupts remain latched until explicitly cleared
            if (frame_complete_int)      int_status_reg[INT_FRAME_COMPLETE]      <= 1'b1;
            if (fifo_overflow_int)       int_status_reg[INT_FIFO_OVERFLOW]       <= 1'b1;
            if (dummy_scan_complete_int) int_status_reg[INT_DUMMY_SCAN_COMPLETE] <= 1'b1;
            if (bias_ready_int)          int_status_reg[INT_BIAS_READY]          <= 1'b1;
            if (adc_data_ready_int)      int_status_reg[INT_ADC_DATA_READY]      <= 1'b1;

            // Clear interrupts when INT_CLEAR register is written (write-1-to-clear)
            if (int_clear_reg[INT_FRAME_COMPLETE])      int_status_reg[INT_FRAME_COMPLETE]      <= 1'b0;
            if (int_clear_reg[INT_FIFO_OVERFLOW])       int_status_reg[INT_FIFO_OVERFLOW]       <= 1'b0;
            if (int_clear_reg[INT_DUMMY_SCAN_COMPLETE]) int_status_reg[INT_DUMMY_SCAN_COMPLETE] <= 1'b0;
            if (int_clear_reg[INT_BIAS_READY])          int_status_reg[INT_BIAS_READY]          <= 1'b0;
            if (int_clear_reg[INT_ADC_DATA_READY])      int_status_reg[INT_ADC_DATA_READY]      <= 1'b0;
        end
    end
    
    // Register read logic
    always_ff @(posedge clk) begin
        if (!rst_n) reg_rdata <= 0;
        else if (reg_read) begin
            case (reg_addr)
                ADDR_CTRL: reg_rdata <= {29'd0, adc_test_pattern_en_reg, frame_reset_reg, frame_start_reg, idle_mode_reg};
                ADDR_STATUS: reg_rdata <= {24'd0, 8'd0, bias_ready, dummy_busy, fifo_full, fifo_empty, frame_busy, idle_mode_reg, 1'b1};
                ADDR_BIAS_SEL: reg_rdata <= {29'd0, bias_sel_reg};
                ADDR_FIRMWARE_VER: reg_rdata <= 32'h56313030;
                // Enhanced interrupt registers
                ADDR_INT_EN: reg_rdata <= int_enable_reg;  // Read interrupt enable register
                ADDR_INT_STATUS: reg_rdata <= int_status_reg;  // Read interrupt status (latched)
                // ADDR_INT_CLEAR is write-only, returns 0 on read
                default: reg_rdata <= 32'd0;
            endcase
        end
    end
    
    // Output assignments
    assign bias_sel = bias_sel_reg;
    assign idle_mode = idle_mode_reg;
    assign integration_time = integration_time_reg;
    assign frame_start = frame_start_reg;
    assign frame_reset = frame_reset_reg;
    assign bias_mode_select = bias_sel_reg[1:0];
    assign dummy_period = dummy_period_reg;
    assign dummy_enable = dummy_enable_reg;
    assign adc_test_pattern_en = adc_test_pattern_en_reg;
    assign adc_test_pattern_val = adc_test_pattern_val_reg;
    assign row_start = row_start_reg;
    assign row_end = row_end_reg;
    assign col_start = col_start_reg;
    assign col_end = col_end_reg;
    assign row_clk_div = 8'd20;
    assign col_clk_div = 8'd10;
    assign interrupt_mask = int_enable_reg;  // Enhanced: Use individual enables
    assign interrupt_clear = reg_write && (reg_addr == ADDR_CTRL);
    assign interrupt_status = int_status_reg & int_enable_reg;  // Output masked status
    assign test_pattern_addr = 8'd0;
    assign test_pattern_data = 8'd0;
    assign test_pattern_we = 1'b0;
endmodule
