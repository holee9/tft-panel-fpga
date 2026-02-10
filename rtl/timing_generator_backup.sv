// Timing Generator Module - SPEC-001 FR-1
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
    localparam CLK_FREQ_MHZ = 100;
    localparam MS_CYCLES = CLK_FREQ_MHZ * 1000;
    localparam RESET_CYCLES = CLK_FREQ_MHZ * 10;
    localparam ROW_CLK_DIV = 20;
    localparam COL_CLK_DIV = 10;
    
    typedef enum logic [2:0] { IDLE=0, RESET=1, INTEGRATE=2, READOUT=3, COMPLETE=4 } state_t;
    state_t current_state, next_state;
    
    logic [31:0] integrate_counter;
    logic [11:0] current_row, current_col;
    logic [5:0] row_clk_div_counter;
    logic [3:0] col_clk_div_counter;
    logic row_clk_tick, col_clk_tick;
    logic [15:0] reset_counter;
    
    assign row_clk_tick = (row_clk_div_counter == ROW_CLK_DIV - 1);
    assign col_clk_tick = (col_clk_div_counter == COL_CLK_DIV - 1);
    
    always_ff @(posedge clk) begin
        if (row_clk_div_counter >= ROW_CLK_DIV - 1)
            row_clk_div_counter <= 0;
        else if (current_state == READOUT)
            row_clk_div_counter <= row_clk_div_counter + 1;
        else
            row_clk_div_counter <= 0;
    end
    
    always_ff @(posedge clk) begin
        if (col_clk_div_counter >= COL_CLK_DIV - 1)
            col_clk_div_counter <= 0;
        else if (current_state == READOUT && row_clk_tick)
            col_clk_div_counter <= col_clk_div_counter + 1;
        else
            col_clk_div_counter <= 0;
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) integrate_counter <= 0;
        else if (current_state == INTEGRATE)
            if (integrate_counter >= integration_time * MS_CYCLES - 1)
                integrate_counter <= 0;
            else
                integrate_counter <= integrate_counter + 1;
        else
            integrate_counter <= 0;
    end
    
    always_ff @(posedge clk) if (!rst_n) current_state <= IDLE; else current_state <= next_state;
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (frame_start) next_state = RESET;
            RESET: if (reset_counter >= RESET_CYCLES - 1) next_state = INTEGRATE;
            INTEGRATE: if (integrate_counter >= integration_time * MS_CYCLES - 1) next_state = READOUT;
            READOUT: if (current_row >= row_end && current_col >= col_end && row_clk_tick) next_state = COMPLETE;
            COMPLETE: next_state = IDLE;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) reset_counter <= 0;
        else if (current_state == RESET) reset_counter <= reset_counter + 1; else reset_counter <= 0;
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) {current_row, current_col} <= 0;
        else case (current_state)
            IDLE, RESET, COMPLETE: {current_row, current_col} <= {row_start, col_start};
            READOUT: if (row_clk_tick)
                if (col_clk_tick) begin
                    if (current_col >= col_end) {current_row, current_col} <= {current_row + 1, col_start};
                    else current_col <= current_col + 1;
                end
        endcase
    end
    
    assign frame_busy = (current_state != IDLE) && (current_state != COMPLETE);
    assign frame_complete = (current_state == COMPLETE);
    assign row_addr = current_row;
    assign col_addr = current_col;
    assign row_clk_en = (current_state == READOUT) && row_clk_tick;
    assign col_clk_en = (current_state == READOUT) && col_clk_tick;
    assign gate_sel = (current_state == READOUT);
    assign reset_pulse = (current_state == RESET);
    assign adc_start_trigger = (current_state == READOUT) && row_clk_tick && col_clk_tick;
endmodule
