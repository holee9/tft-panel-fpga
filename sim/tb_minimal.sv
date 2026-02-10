`timescale 1ns/1ps
module tb_minimal;
    logic clk, rst_n;
    logic frame_start;
    logic [15:0] integration_time;
    logic [11:0] row_start, row_end, col_start, col_end;
    logic frame_busy, frame_complete;

    timing_generator dut (
        .clk, .rst_n, .frame_start, .frame_reset(0), .integration_time,
        .row_start, .row_end, .col_start, .col_end,
        .frame_busy, .frame_complete
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("=== Minimal Test Started ===");
        rst_n = 0; 
        frame_start = 0; 
        integration_time = 1; // 1ms
        row_start = 0; row_end = 0; col_start = 0; col_end = 0; // Single pixel
        #100; 
        rst_n = 1; 
        #100;

        $display("Starting frame capture");
        frame_start = 1;
        #20; 
        frame_start = 0;

        #1000000; // Wait 1ms
        if (frame_busy) begin
            $display("Frame busy detected");
            #1000000; // Wait another 1ms
            if (!frame_busy) begin
                $display("Frame completed successfully!");
            end else begin
                $display("ERROR: Frame still busy after 2ms");
            end
        end else begin
            $display("ERROR: Frame never went busy");
        end
        
        $finish;
    end

    initial begin #5000000 $display("Global timeout!"); $finish; end
endmodule
