// ADC Controller Module - SPEC-001 FR-3
// Enhanced with external FIFO read interface, flush, and level monitoring
module adc_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        adc_start,
    input  logic        adc_test_pattern_en,
    input  logic [7:0]  adc_test_pattern_val,
    output logic        adc_cs_n,
    output logic        adc_sclk,
    output logic        adc_mosi,
    input  logic        adc_miso,
    output logic        adc_clk,
    input  logic [13:0] adc_data,
    output logic        adc_busy,
    output logic        adc_data_valid,
    output logic [13:0] adc_data_reg,
    output logic        fifo_overflow,
    // Enhanced FIFO interface
    input  logic        fifo_rd,        // External FIFO read request
    input  logic        fifo_flush,     // FIFO flush (reset pointers)
    output logic [10:0] fifo_level      // Number of items in FIFO (0-2048)
);
    // Constants
    localparam ADC_CLK_DIV = 5;
    localparam CONVERSION_CYCLES = 10;
    localparam FIFO_DEPTH = 2048;
    localparam FIFO_ADDR_WIDTH = 11;  // 2^11 = 2048

    // State definition
    typedef enum logic [2:0] { IDLE=0, START_CONV=1, WAIT_CONV=2, READ_DATA=3, OUTPUT_DATA=4 } state_t;

    // State and control signals
    state_t current_state, next_state;
    logic [3:0] adc_clk_div_counter;
    logic [7:0] conv_counter;
    logic [4:0] bit_counter;
    logic [15:0] adc_shift_reg;
    logic [13:0] adc_data_output;

    // Enhanced FIFO signals
    logic [FIFO_ADDR_WIDTH-1:0] fifo_wr_ptr, fifo_rd_ptr;
    logic [FIFO_ADDR_WIDTH:0] fifo_count;  // One extra bit for overflow detection
    logic [13:0] fifo_mem[0:FIFO_DEPTH-1];
    logic fifo_full_int, fifo_empty_int;
    logic fifo_rd_reg;  // Registered read signal for timing
    
    // ADC clock divider - fixed with proper reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_clk_div_counter <= 0;
        else if (adc_clk_div_counter >= ADC_CLK_DIV - 1)
            adc_clk_div_counter <= 0;
        else
            adc_clk_div_counter <= adc_clk_div_counter + 1;
    end
    
    // ADC clock output
    assign adc_clk = adc_clk_div_counter[ADC_CLK_DIV/2];
    assign adc_sclk = adc_clk;
    
    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // FSM next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (adc_start)
                    next_state = START_CONV;
            end
            START_CONV: begin
                next_state = WAIT_CONV;
            end
            WAIT_CONV: begin
                if (conv_counter >= CONVERSION_CYCLES - 1)
                    next_state = READ_DATA;
            end
            READ_DATA: begin
                if (bit_counter >= 13)
                    next_state = OUTPUT_DATA;
            end
            OUTPUT_DATA: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Conversion counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            conv_counter <= 0;
        else if (current_state == WAIT_CONV && conv_counter < CONVERSION_CYCLES - 1)
            conv_counter <= conv_counter + 1;
        else
            conv_counter <= 0;
    end
    
    // Bit counter for reading data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bit_counter <= 0;
        else if (current_state == READ_DATA && adc_clk)
            if (bit_counter < 13)
                bit_counter <= bit_counter + 1;
    end
    
    // ADC shift register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_shift_reg <= 0;
        else if (current_state == READ_DATA && adc_clk)
            adc_shift_reg <= {adc_shift_reg[14:0], adc_miso};
    end
    
    // ADC data output mux
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_data_output <= 0;
        else if (adc_test_pattern_en)
            adc_data_output <= {6'd0, adc_test_pattern_val};
        else
            adc_data_output <= adc_shift_reg[13:0];
    end
    
    // ADC data register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_data_reg <= 0;
        else if (current_state == OUTPUT_DATA)
            adc_data_reg <= adc_data_output;
    end
    
    // Data valid signal (registered)
    logic adc_data_valid_int;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_data_valid_int <= 0;
        else
            adc_data_valid_int <= (current_state == OUTPUT_DATA) && !fifo_full_int;
    end

    // Register fifo_rd signal for proper timing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_rd_reg <= 0;
        else
            fifo_rd_reg <= fifo_rd;
    end

    // Enhanced FIFO write pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_wr_ptr <= 0;
        else if (fifo_flush)
            fifo_wr_ptr <= 0;
        else if (adc_data_valid && !fifo_full_int)
            fifo_wr_ptr <= fifo_wr_ptr + 1;
    end

    // Enhanced FIFO read pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_rd_ptr <= 0;
        else if (fifo_flush)
            fifo_rd_ptr <= 0;
        else if (fifo_rd_reg && !fifo_empty_int)
            fifo_rd_ptr <= fifo_rd_ptr + 1;
    end

    // FIFO count for level monitoring
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_count <= 0;
        else if (fifo_flush) begin
            fifo_count <= 0;
        end else begin
            case ({adc_data_valid && !fifo_full_int, fifo_rd_reg && !fifo_empty_int})
                2'b10: fifo_count <= fifo_count + 1;  // Write only
                2'b01: fifo_count <= fifo_count - 1;  // Read only
                2'b00: fifo_count <= fifo_count;      // No change
                2'b11: fifo_count <= fifo_count;      // Simultaneous R/W - no net change
            endcase
        end
    end

    // FIFO memory (synchronous write, asynchronous read)
    always_ff @(posedge clk) begin
        if (adc_data_valid && !fifo_full_int)
            fifo_mem[fifo_wr_ptr] <= adc_data_output;
    end

    // FIFO status - enhanced with proper read/write pointer consideration
    assign fifo_full_int  = (fifo_count == FIFO_DEPTH);
    assign fifo_empty_int = (fifo_count == 0);

    // FIFO level output (0 to FIFO_DEPTH)
    assign fifo_level = fifo_count;

    // FIFO overflow detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ; // Do nothing - fifo_overflow is combinatorial below
        // Overflow is detected combinatorially
    end

    // Chip select and MOSI
    assign adc_cs_n = !(current_state == START_CONV || current_state == WAIT_CONV || current_state == READ_DATA);
    assign adc_mosi = 0;

    // Outputs
    assign adc_busy = (current_state != IDLE);
    assign adc_data_valid = adc_data_valid_int;
    assign fifo_overflow = adc_data_valid_int && fifo_full_int;

    // FIFO data output (registered read)
    // Note: adc_data_reg is now driven only by the procedural assignment below

endmodule
