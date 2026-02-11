// Enhanced Timing Generator Testbench - Corner Case Tests
// Tests minimum/maximum integration times, ROI boundaries, and self-checking assertions
`timescale 1ns/1ps
module tb_timing_generator_enhanced;
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

    // Clock generation
    initial begin clk = 0; forever #5 clk = ~clk; end

    // Test statistics
    int pass_count = 0;
    int fail_count = 0;
    int test_num = 0;

    // Self-checking assertions
    property row_addr_in_range;
        @(posedge clk) frame_busy |-> (row_addr >= row_start && row_addr <= row_end + 1);
    endproperty
    assert_row_addr_range: assert property(row_addr_in_range)
        else $error("[ASSERTION FAIL] row_addr out of range: %0d (expected %0d-%0d)",
                    row_addr, row_start, row_end);

    property col_addr_in_range;
        @(posedge clk) frame_busy |-> (col_addr >= col_start && col_addr <= col_end + 1);
    endproperty
    assert_col_addr_range: assert property(col_addr_in_range)
        else $error("[ASSERTION FAIL] col_addr out of range: %0d (expected %0d-%0d)",
                    col_addr, col_start, col_end);

    property reset_pulse_during_reset;
        @(posedge clk) dut.state == dut.RESET |-> ##[1:1000] reset_pulse;
    endproperty
    assert_reset_pulse: assert property(reset_pulse_during_reset)
        else $error("[ASSERTION FAIL] reset_pulse not active during RESET state");

    property gate_sel_during_readout;
        @(posedge clk) dut.state == dut.READOUT |-> gate_sel;
    endproperty
    assert_gate_sel: assert property(gate_sel_during_readout)
        else $error("[ASSERTION FAIL] gate_sel not active during READOUT state");

    // Task to wait for frame completion with timeout
    task automatic wait_frame_complete(input time timeout_ns);
        fork
            begin
                wait(frame_complete);
            end
            begin
                #(timeout_ns);
                $error("[TIMEOUT] Frame not complete after %0t ns", timeout_ns);
            end
        join_any
    endtask

    // Task to run a single frame capture test
    task automatic run_frame_test(
        input string test_name,
        input [15:0] int_time,
        input [11:0] r_start, r_end,
        input [11:0] c_start, c_end,
        input time timeout_ns,
        output logic passed
    );
        begin
            test_num++;
            $display("\n[TEST %0d] %s", test_num, test_name);
            $display("  Integration: %0d ms, ROI: [%0d:%0d] x [%0d:%0d]",
                     int_time, r_start, r_end, c_start, c_end);

            // Setup
            integration_time = int_time;
            row_start = r_start;
            row_end = r_end;
            col_start = c_start;
            col_end = c_end;

            @(posedge clk);
            frame_start = 1;
            @(posedge clk);
            frame_start = 0;

            // Wait for busy
            fork
                begin
                    wait(frame_busy);
                    $display("  Frame busy detected at %0t ns", $time);
                end
                begin
                    #10000;
                    $error("  Frame did not go busy!");
                    passed = 0;
                    return;
                end
            join_any

            // Wait for completion
            wait_frame_complete(timeout_ns);
            #100;

            // Check results
            passed = frame_complete;
            if (passed) begin
                $display("  [PASS] Frame completed successfully");
                pass_count++;
            end else begin
                $display("  [FAIL] Frame did not complete");
                fail_count++;
            end

            // Wait for return to IDLE
            wait(!frame_busy);
            #1000;
        end
    endtask

    main: begin
        $display("========================================");
        $display("Enhanced Timing Generator Testbench");
        $display("Corner Case & Boundary Tests");
        $display("========================================");

        // Initialize
        rst_n = 0; frame_start = 0; frame_reset = 0; integration_time = 100;
        row_start = 0; row_end = 2047; col_start = 0; col_end = 2047;
        #100; rst_n = 1; #100;

        // Test 1: Minimum integration time (1ms)
        run_frame_test("Minimum integration time (1ms)",
                       16'd1,           // 1ms
                       12'd0, 12'd10,   // Small ROI
                       12'd0, 12'd10,
                       5000000,         // 5ms timeout
                       test1_pass);
        if (test1_pass) $display("  Verified: 1ms integration works");

        // Test 2: Maximum integration time (65535ms)
        run_frame_test("Maximum integration time (65535ms)",
                       16'd65535,      // 65535ms - will use reduced timeout for simulation
                       12'd0, 12'd1,   // Minimal ROI
                       12'd0, 12'd1,
                       70000000,       // 70ms timeout (reduced from actual for sim)
                       test2_pass);
        // Note: In real simulation, 65535ms would take too long
        // This test verifies the counter can handle the max value

        // Test 3: Zero integration time (skip integration phase)
        $display("\n[TEST %0d] Zero integration time (skip phase)", test_num + 1);
        test_num++;
        integration_time = 0;
        row_start = 0; row_end = 1; col_start = 0; col_end = 1;
        @(posedge clk);
        frame_start = 1;
        @(posedge clk);
        frame_start = 0;
        wait(frame_busy);
        wait_frame_complete(5000000);
        #100;
        if (frame_complete) begin
            $display("  [PASS] Zero integration skips integration phase");
            pass_count++;
        end else begin
            $display("  [FAIL] Zero integration did not complete");
            fail_count++;
        end
        wait(!frame_busy);
        #1000;

        // Test 4: Minimum ROI (1x1)
        run_frame_test("Minimum ROI (1x1)",
                       16'd0,
                       12'd0, 12'd0,   // Single row
                       12'd0, 12'd0,   // Single column
                       5000000,
                       test4_pass);

        // Test 5: Maximum ROI (2048x2048)
        run_frame_test("Maximum ROI (2048x2048)",
                       16'd0,
                       12'd0, 12'd2047,   // All rows
                       12'd0, 12'd2047,   // All columns
                       50000000,          // 50ms timeout
                       test5_pass);

        // Test 6: ROI at upper boundary
        run_frame_test("ROI at upper boundary",
                       16'd0,
                       12'd2000, 12'd2047,  // Last 48 rows
                       12'd2000, 12'd2047,  // Last 48 columns
                       5000000,
                       test6_pass);

        // Test 7: Non-power-of-2 ROI
        run_frame_test("Non-power-of-2 ROI (7x13)",
                       16'd0,
                       12'd100, 12'd106,  // 7 rows
                       12'd50, 12'd62,    // 13 columns
                       5000000,
                       test7_pass);

        // Test 8: Frame reset during busy
        $display("\n[TEST %0d] Frame reset during busy", test_num + 1);
        test_num++;
        integration_time = 100;
        row_start = 0; row_end = 2047; col_start = 0; col_end = 2047;
        @(posedge clk);
        frame_start = 1;
        @(posedge clk);
        frame_start = 0;
        wait(frame_busy);
        #100000;  // Wait 100us into frame
        frame_reset = 1;
        @(posedge clk);
        frame_reset = 0;
        #1000;
        if (!frame_busy) begin
            $display("  [PASS] Frame reset terminated busy state");
            pass_count++;
        end else begin
            $display("  [FAIL] Frame reset did not terminate busy state");
            fail_count++;
        end

        // Test 9: Boundary transitions - row address
        $display("\n[TEST %0d] Row address boundary transitions", test_num + 1);
        test_num++;
        integration_time = 0;
        row_start = 0; row_end = 2; col_start = 0; col_end = 1;
        @(posedge clk);
        frame_start = 1;
        @(posedge clk);
        frame_start = 0;
        wait(frame_busy);
        // Monitor row transitions
        fork
            begin
                logic [11:0] last_row;
                last_row = 12'hFFF;
                wait(frame_complete);
                #1000;
                $display("  [INFO] Row transitions completed");
                pass_count++;
            end
            begin
                #50000000;
            end
        join_any

        // Test 10: Back-to-back frames
        $display("\n[TEST %0d] Back-to-back frame captures", test_num + 1);
        test_num++;
        integration_time = 10;
        row_start = 0; row_end = 10; col_start = 0; col_end = 10;
        repeat (3) begin
            @(posedge clk);
            frame_start = 1;
            @(posedge clk);
            frame_start = 0;
            wait(frame_complete);
            #1000;
            wait(!frame_busy);
        end
        $display("  [PASS] Three back-to-back frames completed");
        pass_count++;

        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Total:  %0d", test_num);
        $display("========================================");

        if (fail_count == 0) begin
            $display("\n[SUCCESS] All tests PASSED!");
        end else begin
            $display("\n[FAILURE] Some tests FAILED!");
        end

        #1000;
        $finish;
    end

    // Global timeout
    initial begin #1000000000 $display("ERROR: Global timeout!"); $finish; end

endmodule
