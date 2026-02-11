`timescale 1ns/1ps
module tb_1x1;
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
        $display("=== 1x1 Test ===");
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 0;
        row_start = 0; row_end = 0; col_start = 0; col_end = 0; // Single pixel
        #100; rst_n = 1; #100;

        $display("Starting frame capture at time %0t", $time);
        frame_start = 1;
        #20;
        frame_start = 0;

        $display("Waiting for state changes...");
        @(posedge clk) begin
            if (dut.reset_counter >= 990) begin
                $display("Reset counter is %0d at time %0t", dut.reset_counter, $time);
                if (dut.state != 1) begin
                    $display("State changed from RESET to %0d at time %0t", dut.state, $time);
                    $display("Reset counter: %0d", dut.reset_counter);
                    $finish;
                end
            end
        end
    end

    initial begin
        #1000000;
        $finish;
    end
endmodule