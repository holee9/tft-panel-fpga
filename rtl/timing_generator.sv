// Timing Generator Module - SPEC-001 FR-1
// Fixed col_clk_div_counter timing issue
module timing_generator (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        frame_start,
    input  logic        frame_reset,
    input  logic [15:0] integration_time,
    input  logic [11:0] row_start,
    input  logic [11:0] row_end,
    input  logic [11:0] col_start,
    input  logic [11:0] col_end,
    output logic        frame_busy,
    output logic        frame_complete,
    output logic [11:0] row_addr,
    output logic [11:0] col_addr,
    output logic        row_clk_en,
    output logic        col_clk_en,
    output logic        gate_sel,
    output logic        reset_pulse,
    output logic        adc_start_trigger
);
    // Constants
    localparam CLK_FREQ_MHZ = 100;
    localparam MS_CYCLES = CLK_FREQ_MHZ * 1000;  // 100,000 cycles per ms
    localparam RESET_CYCLES = CLK_FREQ_MHZ * 10; // 1,000 cycles
    localparam ROW_CLK_DIV = 20;
    localparam COL_CLK_DIV = 10;

    // State definition
    typedef enum logic [2:0] {
        IDLE      = 3'd0,
        RESET     = 3'd1,
        INTEGRATE = 3'd2,
        READOUT   = 3'd3,
        COMPLETE  = 3'd4
    } state_t;

    state_t state;

    // Internal signals
    logic [31:0] integrate_counter;
    logic [15:0] reset_counter;
    logic [11:0] current_row, current_col;
    logic [5:0] row_clk_div_counter;
    logic [3:0] col_clk_div_counter;
    logic row_clk_tick, col_clk_tick;
    logic integrate_done;
    logic pixel_done;  // Single pixel processing done
    logic row_clk_active;  // Track if we're in row clock cycle
    
    // Clock divider ticks
    assign row_clk_tick = (state == READOUT) && (row_clk_div_counter == ROW_CLK_DIV - 1);
    assign col_clk_tick = (state == READOUT) && (col_clk_div_counter == COL_CLK_DIV - 1);

    // Integration done calculation
    always_comb begin
        if (integration_time == 0)
            integrate_done = 1'b1;
        else
            integrate_done = (integrate_counter >= integration_time * MS_CYCLES - 1);
    end

    // Pixel processing done - registered version for timing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pixel_done <= 0;
        else if (col_clk_tick)
            pixel_done <= 1'b1;
        else
            pixel_done <= 0;
    end
    
    // Integrate counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            integrate_counter <= 0;
        else if (state == INTEGRATE && integration_time > 0)
            integrate_counter <= integrate_counter + 1;
        else
            integrate_counter <= 0;
    end

    // Row clock divider - runs continuously during READOUT
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            row_clk_div_counter <= 0;
        else if (state == READOUT) begin
            if (row_clk_div_counter >= ROW_CLK_DIV - 1)
                row_clk_div_counter <= 0;
            else
                row_clk_div_counter <= row_clk_div_counter + 1;
        end else begin
            row_clk_div_counter <= 0;
        end
    end

    // Col clock divider - runs continuously during READOUT
    // Don't reset when row_clk_tick is 0, only when not in READOUT
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            col_clk_div_counter <= 0;
        else if (state == READOUT) begin
            if (row_clk_tick) begin
                // Reset col counter at start of each row cycle
                col_clk_div_counter <= 0;
            end else begin
                // Increment col counter during row cycle
                if (col_clk_div_counter >= COL_CLK_DIV - 1)
                    col_clk_div_counter <= 0;
                else
                    col_clk_div_counter <= col_clk_div_counter + 1;
            end
        end else begin
            col_clk_div_counter <= 0;
        end
    end

    // Reset counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_counter <= 0;
        else if (state == RESET)
            reset_counter <= reset_counter + 1;
        else
            reset_counter <= 0;
    end

    // Row/Col address counters
    // Use pixel_done (delayed by 1 clock from col_clk_tick) to trigger increment
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_row <= 0;
            current_col <= 0;
        end else begin
            case (state)
                IDLE, COMPLETE: begin
                    current_row <= row_start;
                    current_col <= col_start;
                end
                RESET: begin
                    current_row <= row_start;
                    current_col <= col_start;
                end
                READOUT: begin
                    // Increment when pixel processing is done
                    if (pixel_done) begin
                        if (current_col == col_end) begin
                            current_row <= current_row + 1;
                            current_col <= col_start;
                        end else begin
                            current_col <= current_col + 1;
                        end
                    end
                end
                default: begin
                    // Keep current values
                end
            endcase
        end
    end

    // FSM State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else begin
            case (state)
                IDLE: begin
                    if (frame_start)
                        state <= RESET;
                end
                RESET: begin
                    if (reset_counter >= RESET_CYCLES - 1)
                        state <= INTEGRATE;
                end
                INTEGRATE: begin
                    if (integrate_done)
                        state <= READOUT;
                end
                READOUT: begin
                    // Check completion condition: at end position AND just finished processing
                    if (current_row == row_end && current_col == col_end && pixel_done)
                        state <= COMPLETE;
                end
                COMPLETE: begin
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Output assignments
    assign frame_busy       = (state != IDLE) && (state != COMPLETE);
    assign frame_complete   = (state == COMPLETE);
    assign row_addr         = current_row;
    assign col_addr         = current_col;
    assign row_clk_en       = row_clk_tick;
    assign col_clk_en       = col_clk_tick;
    assign gate_sel         = (state == READOUT);
    assign reset_pulse      = (state == RESET);
    assign adc_start_trigger = pixel_done;

endmodule
