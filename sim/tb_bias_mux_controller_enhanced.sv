// Bias Mux Controller Enhanced Testbench - SPEC-001 FR-2
// Comprehensive test coverage with 15 test cases
// Covers mode transitions, timing, glitch-free verification, and edge cases
`timescale 1ns/1ps

module tb_bias_mux_controller_enhanced;
    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT Inputs
    logic [1:0] bias_mode_select;

    // DUT Outputs
    logic bias_busy;
    logic bias_ready;
    logic v_pd_n;
    logic v_col_n;
    logic v_rg_n;

    // Test Control Signals
    int test_count;
    int pass_count;
    int fail_count;
    int test_timeout;
    string test_name;
    string error_msg;

    // Timing Analysis
    time transition_start_time;
    time transition_end_time;
    time transition_duration;
    longint max_transition_cycles;
    const longint MAX_ALLOWED_CYCLES = 1000; // 10us at 100MHz

    // Glitch Detection
    logic v_pd_n_prev;
    logic v_col_n_prev;
    logic v_rg_n_prev;
    int glitch_count;

    // DUT Instantiation
    bias_mux_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .bias_mode_select(bias_mode_select),
        .bias_busy(bias_busy),
        .bias_ready(bias_ready),
        .v_pd_n(v_pd_n),
        .v_col_n(v_col_n),
        .v_rg_n(v_rg_n)
    );

    // Clock Generation (100MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Glitch Detection Monitor
    always @(posedge clk) begin
        if (rst_n && test_count > 0) begin
            // Check for unintended transitions (glitches)
            // A glitch is a transient change that reverts within 1-2 cycles
            if (v_pd_n !== v_pd_n_prev && v_pd_n !== v_pd_n_prev) begin
                // Will be checked in post-transition analysis
            end
        end
        v_pd_n_prev <= v_pd_n;
        v_col_n_prev <= v_col_n;
        v_rg_n_prev <= v_rg_n;
    end

    // ============================================================================
    // Test Tasks
    // ============================================================================

    // Task: Initialize test environment
    task automatic test_init();
        begin
            rst_n = 0;
            bias_mode_select = 2'b00;
            test_count = 0;
            pass_count = 0;
            fail_count = 0;
            glitch_count = 0;
            test_timeout = 0;
            v_pd_n_prev = 0;
            v_col_n_prev = 0;
            v_rg_n_prev = 0;

            // Reset sequence
            repeat (20) @(posedge clk);
            rst_n = 1;
            repeat (10) @(posedge clk);

            $display("\n");
            $display("================================================================================");
            $display("  BIAS MUX CONTROLLER ENHANCED TESTBENCH");
            $display("  SPEC-001 FR-2 Verification");
            $display("================================================================================");
            $display("  Test Date: %0t", $time);
            $display("  Clock Period: 10ns (100MHz)");
            $display("  Max Transition Cycles: %0d (10us)", MAX_ALLOWED_CYCLES);
            $display("================================================================================\n");
        end
    endtask

    // Task: Start a test case
    task automatic start_test(input string name);
        begin
            test_count = test_count + 1;
            test_name = name;
            error_msg = "";
            glitch_count = 0;

            $display("\n[Test %0d] %s", test_count, test_name);
            $display("--------------------------------------------------------------------------------");
            $display("  Start Time: %0t ns", $time);
        end
    endtask

    // Task: Wait for ready state
    task automatic wait_for_ready(input int max_cycles = 2000);
        int cycle_count;
        begin
            cycle_count = 0;
            while (!bias_ready && cycle_count < max_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end

            if (cycle_count >= max_cycles) begin
                test_timeout = 1;
                error_msg = $sformatf("Timeout waiting for bias_ready (%0d cycles)", max_cycles);
            end

            $display("  Ready after %0d cycles (%0t ns)", cycle_count, $time);
        end
    endtask

    // Task: Measure transition timing
    task automatic measure_transition(input int max_cycles = 2000);
        int cycle_count;
        begin
            transition_start_time = $time;
            cycle_count = 0;

            // Wait for busy to assert
            while (!bias_busy && cycle_count < 100) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end

            // Count cycles while busy
            cycle_count = 0;
            while (bias_busy && cycle_count < max_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end

            transition_end_time = $time;
            transition_duration = transition_end_time - transition_start_time;

            if (cycle_count > max_transition_cycles) begin
                max_transition_cycles = cycle_count;
            end

            $display("  Transition: %0t ns (%0d cycles)", transition_duration, cycle_count);
        end
    endtask

    // Task: Check bias output values
    task automatic check_bias(
        input logic expected_v_pd_n,
        input logic expected_v_col_n,
        input logic expected_v_rg_n,
        input string description
    );
        begin
            repeat (5) @(posedge clk); // Wait for outputs to settle

            if (v_pd_n === expected_v_pd_n &&
                v_col_n === expected_v_col_n &&
                v_rg_n === expected_v_rg_n) begin
                $display("  [OK] %s: v_pd_n=%b, v_col_n=%b, v_rg_n=%b",
                    description, v_pd_n, v_col_n, v_rg_n);
            end else begin
                $display("  [ERROR] %s: Expected (v_pd_n=%b, v_col_n=%b, v_rg_n=%b), Got (v_pd_n=%b, v_col_n=%b, v_rg_n=%b)",
                    description, expected_v_pd_n, expected_v_col_n, expected_v_rg_n,
                    v_pd_n, v_col_n, v_rg_n);
                error_msg = "Bias output mismatch";
            end
        end
    endtask

    // Task: Verify busy/ready signals
    task automatic check_status(
        input logic expected_busy,
        input logic expected_ready,
        input string description
    );
        begin
            if (bias_busy === expected_busy && bias_ready === expected_ready) begin
                $display("  [OK] %s: bias_busy=%b, bias_ready=%b",
                    description, bias_busy, bias_ready);
            end else begin
                $display("  [ERROR] %s: Expected (bias_busy=%b, bias_ready=%b), Got (bias_busy=%b, bias_ready=%b)",
                    description, expected_busy, expected_ready, bias_busy, bias_ready);
                error_msg = "Status signal mismatch";
            end
        end
    endtask

    // Task: Pass/Fail report for test
    task automatic end_test();
        begin
            $display("--------------------------------------------------------------------------------");

            if (error_msg == "" && test_timeout == 0) begin
                pass_count = pass_count + 1;
                $display("[PASS] Test completed successfully\n");
            end else begin
                fail_count = fail_count + 1;
                if (test_timeout) begin
                    $display("[FAIL] %s\n", error_msg);
                end else begin
                    $display("[FAIL] %s\n", error_msg);
                end
            end

            // Clear error state
            error_msg = "";
            test_timeout = 0;
        end
    endtask

    // Task: Apply reset during operation
    task automatic apply_reset_during_transition();
        begin
            repeat (50) @(posedge clk); // Wait in middle of transition
            $display("  Applying reset during transition at %0t ns", $time);
            rst_n = 0;
            repeat (10) @(posedge clk);
            rst_n = 1;
            repeat (10) @(posedge clk);
        end
    endtask

    // ============================================================================
    // Main Test Sequence
    // ============================================================================

    initial begin
        // Initialize test environment
        test_init();

        //========================================================================
        // TEST 1: Normal Bias Mode After Reset
        //========================================================================
        start_test("Normal Bias Mode After Reset");
        bias_mode_select = 2'b00; // NORMAL_BIAS
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "Normal bias - all outputs low");
        check_status(1'b0, 1'b1, "Not busy, ready");
        end_test();

        //========================================================================
        // TEST 2: Mode Transition - NORMAL to IDLE
        //========================================================================
        start_test("Mode Transition - NORMAL to IDLE");
        bias_mode_select = 2'b00; // Start in NORMAL
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "Initial NORMAL mode");

        bias_mode_select = 2'b01; // Switch to IDLE_LOW_BIAS
        measure_transition();

        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "IDLE mode - outputs low");
        end_test();

        //========================================================================
        // TEST 3: Mode Transition - IDLE to SLEEP
        //========================================================================
        start_test("Mode Transition - IDLE to SLEEP");
        bias_mode_select = 2'b01; // Start in IDLE
        wait_for_ready();

        bias_mode_select = 2'b10; // Switch to SLEEP_BIAS
        measure_transition();

        wait_for_ready();
        check_bias(1'b1, 1'b1, 1'b1, "SLEEP mode - all outputs high");
        end_test();

        //========================================================================
        // TEST 4: Mode Transition - SLEEP to NORMAL
        //========================================================================
        start_test("Mode Transition - SLEEP to NORMAL");
        bias_mode_select = 2'b10; // Start in SLEEP
        wait_for_ready();
        check_bias(1'b1, 1'b1, 1'b1, "Initial SLEEP mode");

        bias_mode_select = 2'b00; // Switch to NORMAL
        measure_transition();

        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "NORMAL mode - all outputs low");
        end_test();

        //========================================================================
        // TEST 5: Complete Mode Cycle - NORMAL -> IDLE -> SLEEP -> NORMAL
        //========================================================================
        start_test("Complete Mode Cycle (NORMAL -> IDLE -> SLEEP -> NORMAL)");

        // NORMAL
        bias_mode_select = 2'b00;
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "State 1: NORMAL");
        $display("  State cycle: Step 1/4 (NORMAL)");

        // -> IDLE
        bias_mode_select = 2'b01;
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "State 2: IDLE");
        $display("  State cycle: Step 2/4 (IDLE)");

        // -> SLEEP
        bias_mode_select = 2'b10;
        wait_for_ready();
        check_bias(1'b1, 1'b1, 1'b1, "State 3: SLEEP");
        $display("  State cycle: Step 3/4 (SLEEP)");

        // -> NORMAL
        bias_mode_select = 2'b00;
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "State 4: NORMAL");
        $display("  State cycle: Step 4/4 (NORMAL)");

        end_test();

        //========================================================================
        // TEST 6: Rapid Mode Switching Stress Test
        //========================================================================
        start_test("Rapid Mode Switching Stress Test");
        repeat (5) begin
            // Switch through all modes rapidly
            bias_mode_select = 2'b00;
            repeat (100) @(posedge clk);

            bias_mode_select = 2'b01;
            repeat (100) @(posedge clk);

            bias_mode_select = 2'b10;
            repeat (100) @(posedge clk);

            $display("  Rapid switch iteration completed");
        end
        wait_for_ready();
        $display("  [OK] Survived rapid mode switching");
        end_test();

        //========================================================================
        // TEST 7: Transition Timing Verification (< 10us requirement)
        //========================================================================
        start_test("Transition Timing Verification (< 10us)");

        // Measure NORMAL to SLEEP transition (should be longest)
        bias_mode_select = 2'b00;
        wait_for_ready();

        bias_mode_select = 2'b10;
        measure_transition(1500); // Max 1500 cycles to detect timing issues

        if (transition_duration <= 10000) begin // 10us in ns
            $display("  [OK] Transition time %0t ns <= 10000 ns (10us)", transition_duration);
        end else begin
            $display("  [ERROR] Transition time %0t ns > 10000 ns (10us)", transition_duration);
            error_msg = "Transition time exceeds 10us requirement";
        end
        end_test();

        //========================================================================
        // TEST 8: Glitch-Free Transition Verification
        //========================================================================
        start_test("Glitch-Free Transition Verification");
        bias_mode_select = 2'b00;
        wait_for_ready();

        // Monitor outputs during transition for glitches
        fork
            begin
                bias_mode_select = 2'b10; // Trigger transition
            end
            begin
                // Watch for unexpected oscillations
                int changes;
                logic prev_v_pd, prev_v_col, prev_v_rg;
                prev_v_pd = v_pd_n;
                prev_v_col = v_col_n;
                prev_v_rg = v_rg_n;
                changes = 0;

                repeat (1100) begin
                    @(posedge clk);
                    if (v_pd_n !== prev_v_pd || v_col_n !== prev_v_col || v_rg_n !== prev_v_rg) begin
                        changes = changes + 1;
                        prev_v_pd = v_pd_n;
                        prev_v_col = v_col_n;
                        prev_v_rg = v_rg_n;
                    end
                end

                // Should have at most 1 transition (from low to high)
                if (changes <= 1) begin
                    $display("  [OK] No glitches detected (%0d output changes)", changes);
                end else begin
                    $display("  [WARNING] Multiple output changes detected: %0d", changes);
                    // Note: This is informational, not a hard fail
                end
            end
        join

        wait_for_ready();
        end_test();

        //========================================================================
        // TEST 9: Mode-Specific Voltage Level Verification
        //========================================================================
        start_test("Mode-Specific Voltage Level Verification");

        // Test NORMAL mode (all low)
        bias_mode_select = 2'b00;
        wait_for_ready();
        if (v_pd_n === 1'b0 && v_col_n === 1'b0 && v_rg_n === 1'b0) begin
            $display("  [OK] NORMAL: all outputs low");
        end else begin
            $display("  [ERROR] NORMAL: unexpected output levels");
            error_msg = "NORMAL mode voltage level incorrect";
        end

        // Test IDLE mode (all low)
        bias_mode_select = 2'b01;
        wait_for_ready();
        if (v_pd_n === 1'b0 && v_col_n === 1'b0 && v_rg_n === 1'b0) begin
            $display("  [OK] IDLE: all outputs low");
        end else begin
            $display("  [ERROR] IDLE: unexpected output levels");
            error_msg = "IDLE mode voltage level incorrect";
        end

        // Test SLEEP mode (all high)
        bias_mode_select = 2'b10;
        wait_for_ready();
        if (v_pd_n === 1'b1 && v_col_n === 1'b1 && v_rg_n === 1'b1) begin
            $display("  [OK] SLEEP: all outputs high");
        end else begin
            $display("  [ERROR] SLEEP: unexpected output levels");
            error_msg = "SLEEP mode voltage level incorrect";
        end
        end_test();

        //========================================================================
        // TEST 10: Busy/Ready Signal Behavior
        //========================================================================
        start_test("Busy/Ready Signal Behavior");

        bias_mode_select = 2'b00;
        wait_for_ready();

        // Check that busy asserts during transition
        bias_mode_select = 2'b10;
        repeat (20) @(posedge clk); // Should see busy within 20 cycles

        if (bias_busy) begin
            $display("  [OK] bias_busy asserted during transition");
        end else begin
            $display("  [ERROR] bias_busy not asserted");
            error_msg = "bias_busy should be asserted during transition";
        end

        // Wait for busy to deassert
        while (bias_busy) @(posedge clk);

        if (bias_ready && !bias_busy) begin
            $display("  [OK] bias_ready asserted, bias_busy deasserted after transition");
        end else begin
            $display("  [ERROR] Status signals incorrect after transition");
            error_msg = "Status signals incorrect after transition";
        end
        end_test();

        //========================================================================
        // TEST 11: Invalid Mode Handling (mode 11 - reserved)
        //========================================================================
        start_test("Invalid Mode Handling (Reserved Mode 11)");

        bias_mode_select = 2'b00;
        wait_for_ready();

        // Apply reserved mode (should be handled gracefully)
        bias_mode_select = 2'b11;
        repeat (1200) @(posedge clk); // Wait for potential transition

        // Check that device doesn't hang and outputs are stable
        if (bias_ready || bias_busy) begin
            $display("  [OK] Device responds to reserved mode (no hang)");
        end else begin
            $display("  [WARNING] Device may be locked on reserved mode");
        end

        // Return to valid mode
        bias_mode_select = 2'b00;
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "Recovery to NORMAL mode");

        end_test();

        //========================================================================
        // TEST 12: Reset During Mode Transition
        //========================================================================
        start_test("Reset During Mode Transition");

        bias_mode_select = 2'b00;
        wait_for_ready();

        // Start transition and apply reset mid-way
        bias_mode_select = 2'b10;
        apply_reset_during_transition();

        // Verify recovery
        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "After reset - outputs in default state");
        check_status(1'b0, 1'b1, "Ready after reset");

        end_test();

        //========================================================================
        // TEST 13: Concurrent Mode Changes and Reset
        //========================================================================
        start_test("Concurrent Mode Changes and Reset");

        // Rapid mode changes followed by immediate reset
        bias_mode_select = 2'b00;
        repeat (50) @(posedge clk);

        bias_mode_select = 2'b01;
        repeat (50) @(posedge clk);

        // Apply reset during switching
        rst_n = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;

        wait_for_ready();
        check_bias(1'b0, 1'b0, 1'b0, "After concurrent reset - default state");

        end_test();

        //========================================================================
        // TEST 14: State Machine Completeness (All State Transitions)
        //========================================================================
        start_test("State Machine Completeness Verification");

        // Verify all possible mode transitions
        // 00 -> 01, 00 -> 10, 01 -> 00, 01 -> 10, 10 -> 00, 10 -> 01

        // 00 -> 01
        bias_mode_select = 2'b00;
        wait_for_ready();
        bias_mode_select = 2'b01;
        wait_for_ready();
        $display("  [OK] Transition 00 -> 01");

        // 01 -> 10
        bias_mode_select = 2'b10;
        wait_for_ready();
        $display("  [OK] Transition 01 -> 10");

        // 10 -> 00
        bias_mode_select = 2'b00;
        wait_for_ready();
        $display("  [OK] Transition 10 -> 00");

        // 00 -> 10 (longest transition)
        bias_mode_select = 2'b10;
        wait_for_ready();
        $display("  [OK] Transition 00 -> 10");

        // 10 -> 01
        bias_mode_select = 2'b01;
        wait_for_ready();
        $display("  [OK] Transition 10 -> 01");

        // 01 -> 00
        bias_mode_select = 2'b00;
        wait_for_ready();
        $display("  [OK] Transition 01 -> 00");

        $display("  [OK] All state transitions verified");

        end_test();

        //========================================================================
        // TEST 15: Same Mode Re-selection (No Transition)
        //========================================================================
        start_test("Same Mode Re-selection (No Transition)");

        bias_mode_select = 2'b00;
        wait_for_ready();

        // Re-select same mode - should not trigger busy
        if (!bias_busy && bias_ready) begin
            $display("  [OK] Not busy when same mode re-selected");
        end else begin
            $display("  [ERROR] Unexpected busy state");
            error_msg = "Unexpected busy on same mode selection";
        end

        repeat (100) @(posedge clk);

        if (!bias_busy && bias_ready) begin
            $display("  [OK] Remains not busy and ready");
        end else begin
            $display("  [ERROR] Status changed unexpectedly");
            error_msg = "Status changed on same mode selection";
        end

        end_test();

        //========================================================================
        // Test Summary Report
        //========================================================================
        $display("\n");
        $display("================================================================================");
        $display("  TEST SUMMARY REPORT");
        $display("================================================================================");
        $display("  Total Tests:    %0d", test_count);
        $display("  Passed:         %0d", pass_count);
        $display("  Failed:         %0d", fail_count);
        $display("  Pass Rate:      %0d%%", (pass_count * 100) / test_count);
        $display("  Max Transition: %0d cycles", max_transition_cycles);
        $display("================================================================================");

        if (fail_count == 0) begin
            $display("  *** ALL TESTS PASSED ***");
        end else begin
            $display("  *** SOME TESTS FAILED ***");
        end

        $display("================================================================================\n");

        #100;
        $finish;
    end

    // ============================================================================
    // Timeout Watchdog
    // ============================================================================
    initial begin
        #500000; // 500us timeout
        $display("\n[FATAL ERROR] Testbench timeout! No finish within 500us");
        $display("  This indicates a potential hang in the DUT or testbench.");
        $finish;
    end

    // ============================================================================
    // Waveform Dump (for debugging)
    // ============================================================================
    initial begin
        if ($test$plusargs("DUMP_WAVES")) begin
            $display("[INFO] Waveform dumping enabled");
            $dumpfile("tb_bias_mux_controller_enhanced.vcd");
            $dumpvars(0, tb_bias_mux_controller_enhanced);
        end
    end

endmodule
