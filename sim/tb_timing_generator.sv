// Timing Generator Testbench - Debug version with 2x2 ROI
`timescale 1ns/1ps
module tb_timing_generator;
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

    // Monitor state transitions
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[%0t] State=%0d, current_row=%0d, current_col=%0d, pixel_done=%0d, row_clk_tick=%0d, col_clk_tick=%0d",
                $time, dut.state, dut.current_row, dut.current_col, dut.pixel_done, dut.row_clk_tick, dut.col_clk_tick);
        end
    end

    initial begin
        $display("=== Timing Generator Test Started ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 0;
        // Use 2x2 ROI for clearer testing (row 0-1, col 0-1)
        row_start = 0; row_end = 1; col_start = 0; col_end = 1;
        #100; rst_n = 1; #100;

        $display("[TEST 1] Basic frame capture with 0ms integration, 2x2 ROI");
        $display("[INFO] ROI: rows %0d-%0d, cols %0d-%0d", row_start, row_end, col_start, col_end);
        frame_start = 1;
        #20; frame_start = 0;

        wait(frame_busy);
        $display("[INFO] Frame busy detected at %0t ns", $time);

        fork
            begin
                wait(!frame_busy);
                $display("[INFO] Frame complete detected at %0t ns", $time);
                $display("[PASS] Basic frame capture test");
            end
            begin
                #5000000; // 5ms timeout
                $display("[ERROR] Frame not complete after 5ms");
                $display("  current_row=%0d (expected %0d)", dut.current_row, row_end);
                $display("  current_col=%0d (expected %0d)", dut.current_col, col_end);
                $display("  row_end=%0d, col_end=%0d", dut.row_end, dut.col_end);
                $display("  state=%0d", dut.state);
            end
        join_any

        #1000;
        $display("=== Test Completed ===");
        $finish;
    end

    initial begin #10000000 $display("ERROR: Test timeout!"); $finish; end
endmodule
