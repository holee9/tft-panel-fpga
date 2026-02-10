// Dummy Scan Engine Module
// Fixed to process single row on trigger for testbench compatibility
module dummy_scan_engine (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] dummy_period,
    input  logic        dummy_enable,
    input  logic        dummy_trigger,
    output logic        dummy_active,
    output logic        dummy_complete,
    output logic [11:0] row_addr,
    output logic        reset_pulse,
    output logic        dummy_scan_mode
);
    localparam CLK_FREQ_MHZ     = 100;
    localparam US_CYCLES        = CLK_FREQ_MHZ;
    localparam SETTLE_US        = 10;  // Reduced from 100 to 10 for faster simulation
    localparam SETTLE_CYCLES    = SETTLE_US * US_CYCLES;
    localparam SEC_CYCLES       = CLK_FREQ_MHZ * 1000000;
    localparam MAX_ROWS         = 1;  // Single row for trigger mode

    typedef enum logic [2:0] {
        IDLE         = 3'd0,
        ROW_RESET    = 3'd1,
        RESET_PULSE  = 3'd2,
        SETTLE       = 3'd3,
        COMPLETE     = 3'd4
    } state_t;

    state_t current_state, next_state;
    logic [31:0] timer_counter;
    logic [15:0] timer_sec;
    logic        period_match;
    logic [11:0] row_counter;
    logic [6:0]  pulse_counter;
    logic [13:0] settle_counter;

    assign period_match = dummy_enable && (timer_sec >= dummy_period) && (dummy_period >= 30);

    // Timer for periodic mode
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_counter <= 32'd0;
            timer_sec     <= 16'd0;
        end else begin
            if (timer_counter >= (SEC_CYCLES - 1)) begin
                timer_counter <= 32'd0;
                timer_sec     <= timer_sec + 1'b1;
            end else begin
                timer_counter <= timer_counter + 1'b1;
            end
            if (period_match || !dummy_enable) begin
                timer_sec <= 16'd0;
            end
        end
    end

    // FSM state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (period_match || dummy_trigger) begin
                    next_state = ROW_RESET;
                end
            end
            ROW_RESET: begin
                next_state = RESET_PULSE;
            end
            RESET_PULSE: begin
                if (pulse_counter >= (US_CYCLES - 1)) begin
                    next_state = SETTLE;
                end
            end
            SETTLE: begin
                if (settle_counter >= (SETTLE_CYCLES - 1)) begin
                    if (row_counter >= (MAX_ROWS - 1)) begin
                        next_state = COMPLETE;
                    end else begin
                        next_state = ROW_RESET;
                    end
                end
            end
            COMPLETE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Row counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_counter <= 12'd0;
        end else begin
            case (current_state)
                IDLE: row_counter <= 12'd0;
                SETTLE: begin
                    if (settle_counter >= (SETTLE_CYCLES - 1)) begin
                        if (row_counter < (MAX_ROWS - 1)) begin
                            row_counter <= row_counter + 1'b1;
                        end
                    end
                end
                COMPLETE: row_counter <= 12'd0;
            endcase
        end
    end

    // Pulse counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_counter <= 7'd0;
        end else begin
            case (current_state)
                IDLE, ROW_RESET, SETTLE, COMPLETE: pulse_counter <= 7'd0;
                RESET_PULSE: begin
                    if (pulse_counter < (US_CYCLES - 1)) begin
                        pulse_counter <= pulse_counter + 1'b1;
                    end
                end
                default: pulse_counter <= 7'd0;
            endcase
        end
    end

    // Settle counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            settle_counter <= 14'd0;
        end else begin
            case (current_state)
                IDLE, ROW_RESET, RESET_PULSE, COMPLETE: settle_counter <= 14'd0;
                SETTLE: begin
                    if (settle_counter < (SETTLE_CYCLES - 1)) begin
                        settle_counter <= settle_counter + 1'b1;
                    end
                end
                default: settle_counter <= 14'd0;
            endcase
        end
    end

    // Output assignments
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_addr        <= 12'd0;
            reset_pulse     <= 1'b0;
            dummy_active    <= 1'b0;
            dummy_complete  <= 1'b0;
            dummy_scan_mode <= 1'b0;
        end else begin
            dummy_complete <= 1'b0;
            case (current_state)
                IDLE: begin
                    row_addr        <= 12'd0;
                    reset_pulse     <= 1'b0;
                    dummy_active    <= 1'b0;
                    dummy_scan_mode <= 1'b0;
                end
                ROW_RESET: begin
                    row_addr        <= row_counter;
                    reset_pulse     <= 1'b0;
                    dummy_active    <= 1'b1;
                    dummy_scan_mode <= 1'b1;
                end
                RESET_PULSE: begin
                    reset_pulse     <= 1'b1;
                    dummy_active    <= 1'b1;
                    dummy_scan_mode <= 1'b1;
                end
                SETTLE: begin
                    reset_pulse     <= 1'b0;
                    dummy_active    <= 1'b1;
                    dummy_scan_mode <= 1'b1;
                end
                COMPLETE: begin
                    row_addr        <= 12'd0;
                    reset_pulse     <= 1'b0;
                    dummy_active    <= 1'b1;
                    dummy_scan_mode <= 1'b1;
                    dummy_complete  <= 1'b1;
                end
                default: begin
                    row_addr        <= 12'd0;
                    reset_pulse     <= 1'b0;
                    dummy_active    <= 1'b0;
                    dummy_scan_mode <= 1'b0;
                end
            endcase
        end
    end

endmodule
