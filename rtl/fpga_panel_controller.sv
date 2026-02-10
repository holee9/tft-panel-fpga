// TFT Panel FPGA Controller - Top Module (44 ports)
module fpga_panel_controller (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        spi_sclk,
    input  logic        spi_mosi,
    output logic        spi_miso,
    input  logic        spi_cs_n,
    output logic [11:0] row_addr,
    output logic [11:0] col_addr,
    output logic        row_clk_en,
    output logic        col_clk_en,
    output logic        gate_sel,
    output logic        gate_pulse,
    output logic        reset_pulse,
    output logic        frame_busy,
    output logic        frame_complete,
    output logic [1:0]  bias_mode_select,
    output logic        v_pd_n,
    output logic        v_col_n,
    output logic        v_rg_n,
    output logic        bias_ready,
    output logic        bias_busy,
    output logic        dummy_scan_active,
    output logic        dummy_scan_busy,
    output logic [11:0] dummy_row_addr,
    output logic        dummy_reset_pulse,
    output logic        adc_cs_n,
    output logic        adc_sclk,
    output logic        adc_mosi,
    input  logic        adc_miso,
    output logic        adc_clk,
    output logic        adc_start,
    input  logic [13:0] adc_data,
    output logic        fifo_wr_en,
    output logic [13:0] fifo_wr_data,
    input  logic        fifo_full,
    input  logic        fifo_empty,
    output logic        int_frame_complete,
    output logic        int_dummy_complete,
    output logic        int_fifo_overflow,
    output logic        int_error,
    output logic        int_active,
    output logic        led_idle,
    output logic        led_active,
    output logic        led_error
);
    logic [7:0] reg_addr;
    logic [31:0] reg_wdata, reg_rdata;
    logic reg_write, reg_read;
    logic [15:0] integration_time;
    logic frame_start, frame_reset;
    logic [1:0] bias_mode_select_reg;
    logic [15:0] dummy_period;
    logic dummy_enable, dummy_trigger;
    logic adc_test_pattern_en;
    logic [7:0] adc_test_pattern_val;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic [7:0] row_clk_div, col_clk_div;
    logic [31:0] interrupt_mask, interrupt_status_raw;
    logic frame_busy_reg, fifo_overflow_reg, dummy_busy_reg, bias_ready_reg;
    logic [2:0] bias_sel;
    logic idle_mode;
    logic tg_frame_busy, tg_frame_complete;
    logic [11:0] tg_row_addr, tg_col_addr;
    logic tg_row_clk_en, tg_col_clk_en, tg_gate_sel, tg_reset_pulse, tg_adc_start_trigger;
    logic bc_bias_busy, bc_bias_ready, bc_v_pd_n, bc_v_col_n, bc_v_rg_n;
    logic dse_dummy_active, dse_dummy_complete;
    logic [11:0] dse_row_addr;
    logic dse_reset_pulse, dse_dummy_scan_mode;
    logic adc_busy, adc_data_valid;
    logic [13:0] adc_data_reg;
    logic adc_fifo_overflow;
    
    spi_slave_interface u_spi_slave (
        .clk, .rst_n, .spi_sclk, .spi_mosi, .spi_miso, .spi_cs_n,
        .reg_addr, .reg_wdata, .reg_rdata, .reg_write, .reg_read
    );
    
    register_file u_reg_file (
        .clk, .rst_n, .reg_addr, .reg_wdata, .reg_rdata, .reg_write, .reg_read,
        .integration_time, .frame_start, .frame_reset, .bias_mode_select(bias_mode_select_reg),
        .dummy_period, .dummy_enable, .dummy_trigger, .adc_test_pattern_en,
        .adc_test_pattern_val, .row_start, .row_end, .col_start, .col_end,
        .row_clk_div, .col_clk_div, .interrupt_mask, .interrupt_clear(),
        .frame_busy(tg_frame_busy), .fifo_empty, .fifo_full, .fifo_overflow(adc_fifo_overflow),
        .dummy_busy(dse_dummy_active), .bias_ready(bc_bias_ready),
        .interrupt_status_raw, .test_pattern_addr(), .test_pattern_data(),
        .test_pattern_we(), .bias_sel, .idle_mode
    );
    
    timing_generator u_timing_gen (
        .clk, .rst_n, .frame_start, .frame_reset, .integration_time,
        .row_start, .row_end, .col_start, .col_end, .frame_busy(tg_frame_busy),
        .frame_complete(tg_frame_complete), .row_addr(tg_row_addr), .col_addr(tg_col_addr),
        .row_clk_en(tg_row_clk_en), .col_clk_en(tg_col_clk_en), .gate_sel(tg_gate_sel),
        .reset_pulse(tg_reset_pulse), .adc_start_trigger(tg_adc_start_trigger)
    );
    
    bias_mux_controller u_bias_ctrl (
        .clk, .rst_n, .bias_mode_select(bias_mode_select_reg), .bias_busy(bc_bias_busy),
        .bias_ready(bc_bias_ready), .v_pd_n(bc_v_pd_n), .v_col_n(bc_v_col_n), .v_rg_n(bc_v_rg_n)
    );
    
    dummy_scan_engine u_dummy_scan (
        .clk, .rst_n, .dummy_period, .dummy_enable, .dummy_trigger,
        .dummy_active(dse_dummy_active), .dummy_complete(dse_dummy_complete),
        .row_addr(dse_row_addr), .reset_pulse(dse_reset_pulse), .dummy_scan_mode(dse_dummy_scan_mode)
    );
    
    adc_controller u_adc_ctrl (
        .clk, .rst_n, .adc_start(tg_adc_start_trigger), .adc_test_pattern_en,
        .adc_test_pattern_val, .adc_cs_n, .adc_sclk, .adc_mosi, .adc_miso,
        .adc_clk, .adc_data, .adc_busy, .adc_data_valid, .adc_data_reg,
        .fifo_overflow(adc_fifo_overflow)
    );
    
    assign row_addr = tg_row_addr;
    assign col_addr = tg_col_addr;
    assign row_clk_en = tg_row_clk_en;
    assign col_clk_en = tg_col_clk_en;
    assign gate_sel = tg_gate_sel;
    assign gate_pulse = tg_gate_sel && tg_row_clk_en;
    assign reset_pulse = tg_reset_pulse;
    assign frame_busy = tg_frame_busy;
    assign frame_complete = tg_frame_complete;
    assign bias_mode_select = bias_mode_select_reg;
    assign v_pd_n = bc_v_pd_n;
    assign v_col_n = bc_v_col_n;
    assign v_rg_n = bc_v_rg_n;
    assign bias_ready = bc_bias_ready;
    assign bias_busy = bc_bias_busy;
    assign dummy_scan_active = dse_dummy_active;
    assign dummy_scan_busy = dse_dummy_active;
    assign dummy_row_addr = dse_row_addr;
    assign dummy_reset_pulse = dse_reset_pulse;
    assign fifo_wr_en = adc_data_valid;
    assign fifo_wr_data = adc_data_reg;
    
    localparam INT_FRAME_COMPLETE = 0, INT_DUMMY_COMPLETE = 1, INT_FIFO_OVERFLOW = 2, INT_ERROR = 3;
    logic [31:0] interrupt_status;
    always_comb begin
        interrupt_status = 0;
        interrupt_status[INT_FRAME_COMPLETE] = tg_frame_complete;
        interrupt_status[INT_DUMMY_COMPLETE] = dse_dummy_complete;
        interrupt_status[INT_FIFO_OVERFLOW] = adc_fifo_overflow;
        interrupt_status[INT_ERROR] = |{adc_fifo_overflow, bc_bias_busy && !bc_bias_ready};
    end
    assign interrupt_status_raw = interrupt_status & interrupt_mask;
    assign int_frame_complete = interrupt_status_raw[INT_FRAME_COMPLETE];
    assign int_dummy_complete = interrupt_status_raw[INT_DUMMY_COMPLETE];
    assign int_fifo_overflow = interrupt_status_raw[INT_FIFO_OVERFLOW];
    assign int_error = interrupt_status_raw[INT_ERROR];
    assign int_active = |interrupt_status_raw;
    
    assign led_idle = idle_mode;
    assign led_active = !idle_mode && !tg_frame_busy;
    assign led_error = |{adc_fifo_overflow, !bc_bias_ready && bc_bias_busy};
endmodule
