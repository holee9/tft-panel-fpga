# Dummy Scan Engine Enhanced Testbench

## Overview

Comprehensive testbench for the `dummy_scan_engine` module with 15 test cases covering all functional requirements.

## Test Coverage

| Test Case | Description | Coverage |
|-----------|-------------|----------|
| 01 | Reset Functionality | Verifies all outputs reset correctly |
| 02 | Manual Trigger - Basic | Single trigger operation |
| 03 | Minimum Period (30s) | Boundary value at minimum period |
| 04 | Maximum Period (65535s) | Boundary value at maximum period |
| 05 | Below Minimum Period (<30s) | Invalid period handling |
| 06 | Row Address Coverage | Row address output verification |
| 07 | Enable/Disable Transitions | Mode switching during operation |
| 08 | Manual Trigger Timing | Trigger response latency |
| 09 | Completion Timing | < 2ms requirement verification |
| 10 | Auto vs Manual Mode | Mode comparison |
| 11 | Reset Pulse Timing | Pulse width verification |
| 12 | Settle Timing | Settle state duration |
| 13 | Reset During Scan | Asynchronous reset handling |
| 14 | Period Boundaries | Register boundary values |
| 15 | Consecutive Triggers | Multiple trigger sequences |

## Running the Tests

### Method 1: Windows Batch Script
```batch
cd E:\github_work\tft-panel-fpga\sim\scripts
run_dummy_scan_tests.bat
```

### Method 2: Git Bash Shell Script
```bash
cd /e/github_work/tft-panel-fpga/sim/scripts
chmod +x run_dummy_scan_tests.sh
./run_dummy_scan_tests.sh
```

### Method 3: Questa Sim GUI
```tcl
# In Questa Sim Tcl console
cd E:/github_work/tft-panel-fpga/sim
source scripts/run_dummy_scan_tests.tcl
```

### Method 4: Command Line
```batch
vsim -c -do "source scripts/run_dummy_scan_tests.tcl" -do "quit -f"
```

## Test Results Interpretation

### Pass Criteria
- All 15 tests pass
- All individual checks pass within each test
- No simulation errors or warnings

### Expected Output
```
////////////////////////////////////////////////////////////////////////////////////
//  TEST SUMMARY
////////////////////////////////////////////////////////////////////////////////////
  Total Tests:  15
  Tests Passed: 15
  Tests Failed: 0
  Total Checks:  45+
  Checks Passed: 45+
  Checks Failed: 0
  *** ALL TESTS PASSED ***
////////////////////////////////////////////////////////////////////////////////////
```

## Timing Requirements

| Parameter | Value | Notes |
|-----------|-------|-------|
| Clock Frequency | 100 MHz | 10ns period |
| Reset Pulse Width | ~1us | 100 cycles |
| Settle Time | ~10us | 1000 cycles |
| Completion Time | < 2ms | Per requirement |

## Known Limitations

1. **Scaled Timing**: Real 30-second period tests use scaled timing for simulation
2. **Assertions Disabled**: Self-checking assertions commented out for compatibility
3. **Timeout**: 100ms simulation watchdog prevents infinite runs

## Debugging

### Generate Waveforms
The testbench automatically generates VCD output:
```
tb_dummy_scan_engine_enhanced.vcd
```

### View in GTKWave
```bash
gtkwave tb_dummy_scan_engine_enhanced.vcd
```

### Common Issues

**Issue**: `vsim not found`
**Solution**: Run from Questa Sim command prompt or source environment script

**Issue**: Compilation errors
**Solution**: Ensure `dummy_scan_engine.sv` exists in `../rtl/` directory

**Issue**: Timeout errors
**Solution**: Increase timeout in testbench or check for hanging conditions

## Test Files

- `tb_dummy_scan_engine_enhanced.sv` - Main testbench
- `scripts/run_dummy_scan_tests.tcl` - Tcl runner script
- `scripts/run_dummy_scan_tests.bat` - Windows batch script
- `scripts/run_dummy_scan_tests.sh` - Shell script
