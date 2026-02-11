# Bias MUX Controller Enhanced Testbench Documentation

## Overview

The enhanced testbench (`tb_bias_mux_controller_enhanced.sv`) provides comprehensive verification of the Bias MUX Controller module (SPEC-001 FR-2). It includes 15 test cases covering all operational modes, timing requirements, and edge cases.

## Test Environment

- **DUT**: `bias_mux_controller.sv`
- **Clock**: 100 MHz (10 ns period)
- **Max Transition Time**: 10 us (1000 cycles)
- **Timescale**: 1 ns / 1 ps

## Test Cases Summary

| Test # | Name | Description |
|--------|------|-------------|
| 1 | Normal Bias Mode After Reset | Verify default state after reset |
| 2 | NORMAL to IDLE Transition | Mode transition from NORMAL to IDLE_LOW_BIAS |
| 3 | IDLE to SLEEP Transition | Mode transition from IDLE_LOW_BIAS to SLEEP_BIAS |
| 4 | SLEEP to NORMAL Transition | Mode transition from SLEEP_BIAS back to NORMAL |
| 5 | Complete Mode Cycle | Full cycle through all three modes |
| 6 | Rapid Mode Switching | Stress test with rapid mode changes |
| 7 | Transition Timing Verification | Verify < 10 us transition requirement |
| 8 | Glitch-Free Transition | Detect output glitches during transitions |
| 9 | Mode-Specific Voltage Levels | Verify output levels for each mode |
| 10 | Busy/Ready Signal Behavior | Verify status signal correctness |
| 11 | Invalid Mode Handling | Test reserved mode (11) handling |
| 12 | Reset During Transition | Verify reset recovery mid-transition |
| 13 | Concurrent Mode Change and Reset | Test simultaneous mode change and reset |
| 14 | State Machine Completeness | Verify all possible state transitions |
| 15 | Same Mode Re-selection | Verify no transition on same mode |

## Mode Definitions

| Mode Code | Mode Name | v_pd_n | v_col_n | v_rg_n |
|-----------|-----------|--------|---------|--------|
| 2'b00 | NORMAL_BIAS | 0 | 0 | 0 |
| 2'b01 | IDLE_LOW_BIAS | 0 | 0 | 0 |
| 2'b10 | SLEEP_BIAS | 1 | 1 | 1 |
| 2'b11 | Reserved | - | - | - |

## Running the Testbench

### Method 1: Using TCL Script (Recommended)

```bash
cd sim
vsim -c -do "do scripts/run_tb_enhanced.tcl"
```

### Method 2: Using Batch Script (Windows)

```cmd
cd sim\scripts
run_tb_enhanced.bat
```

### Method 3: Manual Compilation and Simulation

```bash
cd sim
vlib work
vlog -sv ../rtl/bias_mux_controller.sv
vlog -sv tb_bias_mux_controller_enhanced.sv
vsim -c tb_bias_mux_controller_enhanced
run -all
```

### Method 4: With Waveform Dumping

```bash
vsim -c tb_bias_mux_controller_enhanced +DUMP_WAVES
run -all
# View waves with: gtkwave tb_bias_mux_controller_enhanced.vcd
```

## Expected Output

### Successful Test Run

```
================================================================================
  BIAS MUX CONTROLLER ENHANCED TESTBENCH
  SPEC-001 FR-2 Verification
================================================================================
  Test Date: X ns
  Clock Period: 10ns (100MHz)
  Max Transition Cycles: 1000 (10us)
================================================================================

[Test 1] Normal Bias Mode After Reset
--------------------------------------------------------------------------------
...
[PASS] Test completed successfully

...

================================================================================
  TEST SUMMARY REPORT
================================================================================
  Total Tests:    15
  Passed:         15
  Failed:         0
  Pass Rate:      100%
  Max Transition: 1000 cycles
================================================================================
  *** ALL TESTS PASSED ***
================================================================================
```

## Test Coverage Analysis

### Functional Coverage
- **Mode Transitions**: All 6 possible transitions covered
- **Reset Behavior**: Reset at idle, during transition, and concurrent with mode change
- **Error Handling**: Invalid/reserved mode handling
- **Status Signals**: Busy and ready signal behavior verified

### Timing Coverage
- **Transition Time**: Measured and verified against 10 us requirement
- **Glitch Detection**: Monitored during all transitions

### State Machine Coverage
- All states: IDLE, SWITCHING, READY
- All state transitions verified

## Troubleshooting

### Test Fails with "Timeout"
- Check if clock is running correctly
- Verify DUT compilation succeeded
- Check reset assertion timing

### Transition Time Exceeds 10 us
- Verify clock frequency is 100 MHz
- Check SWITCH_CYCLES parameter in DUT
- Review state machine logic

### Waveform Dump Not Created
- Add `+DUMP_WAVES` argument when running simulation
- Check write permissions in simulation directory

### Compilation Errors
- Verify SystemVerilog file paths are correct
- Check for syntax errors in source files
- Ensure Questa Sim version supports used SV features

## Testbench Architecture

### Tasks
- `test_init()`: Initialize test environment and counters
- `start_test(name)`: Begin a new test case
- `wait_for_ready()`: Wait for DUT to reach ready state
- `measure_transition()`: Measure transition timing
- `check_bias()`: Verify bias output values
- `check_status()`: Verify busy/ready status signals
- `end_test()`: Report test pass/fail and update counters

### Assertions
Note: Self-checking assertions are disabled for Questa Sim timing compatibility.
Instead, manual checks are performed using the `check_*` tasks.

### Timeout Protection
- Global watchdog: 500 us maximum simulation time
- Per-test timeout: 2000 cycles for wait_for_ready()
- Prevents testbench hangs from DUT issues

## Coverage Goals

- **Functional**: 100% of mode transitions
- **Code**: Aim for >90% line coverage
- **State**: All states and transitions covered
- **Timing**: All timing requirements verified

## Future Enhancements

Potential additions for even more comprehensive testing:
- Coverage-driven verification with covergroups
- Constrained random testing
- X-propagation checking
- Power-aware simulation (UPF)
- Formal verification integration
