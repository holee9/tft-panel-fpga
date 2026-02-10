// Bias MUX Controller Module - SPEC-001 FR-2
module bias_mux_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  bias_mode_select,
    output logic        bias_busy,
    output logic        bias_ready,
    output logic        v_pd_n,
    output logic        v_col_n,
    output logic        v_rg_n
);
    localparam SWITCH_CYCLES = 1000; // 10us at 100MHz
    typedef enum logic [1:0] { IDLE=0, SWITCHING=1, READY=2 } state_t;
    
    state_t current_state, next_state;
    logic [1:0] target_bias, current_bias;
    logic [15:0] switch_counter;
    logic [2:0] bias_select_reg;
    
    always_ff @(posedge clk) if (!rst_n) current_state <= IDLE; else current_state <= next_state;
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: if (target_bias != current_bias) next_state = SWITCHING; else next_state = READY;
            SWITCHING: if (switch_counter >= SWITCH_CYCLES - 1) next_state = READY;
            READY: if (target_bias != current_bias) next_state = SWITCHING;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) {switch_counter, target_bias} <= 0;
        else case (current_state)
            IDLE: switch_counter <= 0;
            SWITCHING: if (switch_counter < SWITCH_CYCLES - 1) switch_counter <= switch_counter + 1;
            READY: if (target_bias != current_bias) switch_counter <= 0;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (!rst_n) {bias_select_reg, current_bias} <= 0;
        else case (current_state)
            IDLE: if (target_bias == current_bias) bias_select_reg <= {target_bias, 1'b0};
            SWITCHING: if (switch_counter == SWITCH_CYCLES/2) {bias_select_reg, current_bias} <= {target_bias, 1'b0, target_bias};
        endcase
    end
    
    assign bias_busy = (current_state == SWITCHING);
    assign bias_ready = (current_state == READY) || (current_state == IDLE && target_bias == current_bias);
    assign v_pd_n = bias_select_reg[0];
    assign v_col_n = bias_select_reg[1];
    assign v_rg_n = bias_select_reg[2];
endmodule
