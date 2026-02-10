// ADC Controller Module - SPEC-001 FR-3
// Fixed reset and timing issues
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
    output logic        fifo_overflow
);
    localparam ADC_CLK_DIV = 5;
    localparam CONVERSION_CYCLES = 10;
    localparam FIFO_DEPTH = 2048;
    localparam FIFO_ADDR_WIDTH = 12;
    
    typedef enum logic [2:0] { IDLE=0, START_CONV=1, WAIT_CONV=2, READ_DATA=3, OUTPUT_DATA=4 } state_t;
    
    state_t current_state, next_state;
    logic [3:0] adc_clk_div_counter;
    logic [7:0] conv_counter;
    logic [4:0] bit_counter;
    logic [15:0] adc_shift_reg;
    logic [13:0] adc_data_output;
    logic [FIFO_ADDR_WIDTH-1:0] fifo_wr_ptr, fifo_rd_ptr;
    logic [13:0] fifo_mem[0:FIFO_DEPTH-1];
    logic fifo_full_int, fifo_empty_int;
    
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
    
    // FIFO write pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fifo_wr_ptr <= 0;
        else if (adc_data_valid && !fifo_full_int)
            fifo_wr_ptr <= fifo_wr_ptr + 1;
    end
    
    // FIFO read pointer (simplified - assumes external read)
    assign fifo_rd_ptr = 0;  // No external read in this implementation
    
    // FIFO status
    assign fifo_full_int = (fifo_wr_ptr == FIFO_DEPTH - 1);
    assign fifo_empty_int = (fifo_wr_ptr == fifo_rd_ptr);
    
    // Chip select
    assign adc_cs_n = !(current_state == START_CONV || current_state == WAIT_CONV || current_state == READ_DATA);
    assign adc_mosi = 0;
    
    // Outputs
    assign adc_busy = (current_state != IDLE);
    assign adc_data_valid = adc_data_valid_int;
    assign fifo_overflow = adc_data_valid_int && fifo_full_int;

endmodule
