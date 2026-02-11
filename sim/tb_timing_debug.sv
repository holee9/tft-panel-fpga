// Simple test to debug timing generator
`timescale 1ns/1ps
module tb_timing_debug;
    logic clk, rst_n;
    logic frame_start, frame_reset;
    logic [15:0] integration_time;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic frame_busy, frame_complete;
    logic [11:0] row_addr, col_addr;
    logic row_clk_en, col_clk_en, gate_sel, reset_pulse, adc_start_trigger;

    timing_generator dut (
        .clk, .rst_n, .frame_start, .frame_reset, .integration_time,
        .row_start, .row_end, .col_start, .col_end,
        .frame_busy, .frame_complete, .row_addr, .col_addr,
        .row_clk_en, .col_clk_en, .gate_sel, .reset_pulse, .adc_start_trigger
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Debug Test ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 0;
        row_start = 0; row_end = 1; col_start = 0; col_end = 1;
        #100; rst_n = 1; #100;

        $display("[TEST] Frame capture with 0ms integration, 2x2 ROI");
        $display("[INFO] ROI: rows %0d-%0d, cols %0d-%0d", row_start, row_end, col_start, col_end);

        // Monitor signals
        $display("Time\tState\tBusy\tComplete\tRow\tCol");
        forever begin
            @(posedge clk) begin
                $display("%0t\t%0d\t%0d\t%0d\t\t%0d\t%0d",
                    $time, dut.state, dut.frame_busy, dut.frame_complete,
                    dut.current_row, dut.current_col);
            end
        end
    end

    initial begin
        #1000;
        frame_start = 1;
        #20;
        frame_start = 0;

        #2000000;
        $finish;
    end

    initial begin #10000000 $display("ERROR: Test timeout!"); $finish; end
endmodule