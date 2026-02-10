// Monitor Internal State
`timescale 1ns/1ps
module tb_timing_generator_monitor;
    logic clk, rst_n;
    logic frame_start, frame_reset;
    logic [15:0] integration_time;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic frame_busy, frame_complete;

    // Monitor internal signals by adding probe to existing instance
    timing_generator dut (
        .clk, .rst_n, .frame_start, .frame_reset, .integration_time,
        .row_start, .row_end, .col_start, .col_end,
        .frame_busy, .frame_complete
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== State Monitor Test Started ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 1;
        row_start = 0; row_end = 1; col_start = 0; col_end = 1; // Smaller ROI
        #100; rst_n = 1; #100;

        $display("[TEST] Starting frame capture");
        frame_start = 1;
        #20; frame_start = 0;

        // Monitor every 100ns for 2ms
        $display("Monitoring state changes...");
        for (int i = 0; i < 20000; i = i + 1) begin
            #100;
            if (dut.current_state !== dut.current_state) begin
                $display("[TIME] %0t ns: State = %d, row = %d, col = %d, int_counter = %d",
                         $time, dut.current_state, dut.current_row, dut.current_col, dut.integrate_counter);
            end
        end
        
        $display("=== State Monitor Test Ended ===");
        $finish;
    end

    initial begin #3000000 $display("ERROR: Timeout!"); $finish; end
endmodule
