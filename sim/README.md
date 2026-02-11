# TFT Panel FPGA Simulation Environment

## Directory Structure

```
sim/
|-- scripts/           # TCL and batch scripts for running simulations
|   |-- run_tb_enhanced.tcl
|   |-- run_tb_enhanced.bat
|   |-- run_all_tests.sh
|-- docs/              # Test documentation
|   |-- enhanced_testbench_documentation.md
|-- tb_*.sv            # Testbench files
|-- work/              # Compiled library (generated)
```

## Available Testbenches

| Testbench | DUT | Description |
|-----------|-----|-------------|
| `tb_bias_mux_controller.sv` | bias_mux_controller | Basic functionality test |
| `tb_bias_mux_controller_enhanced.sv` | bias_mux_controller | Comprehensive 15-test suite |

## Quick Start

### 1. Source Questa Sim Environment

```bash
# Windows (adjust path as needed)
call "C:\Mentor\QuestaSim\2023.4\vsim.bat"

# Linux
source /tools/mentor/questasim/2023.4/settings.sh
```

### 2. Run Enhanced Testbench

```bash
cd sim
vsim -c -do "do scripts/run_tb_enhanced.tcl"
```

### 3. View Results

The testbench outputs:
- Console output with pass/fail for each test
- Optional VCD waveform file (with +DUMP_WAVES)
- Summary report with statistics

## Running Individual Testbenches

### Bias MUX Controller (Basic)

```bash
cd sim
vlib work
vlog -sv ../rtl/bias_mux_controller.sv tb_bias_mux_controller.sv
vsim -c tb_bias_mux_controller -do "run -all; quit"
```

### Bias MUX Controller (Enhanced)

```bash
cd sim
vlib work
vlog -sv ../rtl/bias_mux_controller.sv tb_bias_mux_controller_enhanced.sv
vsim -c tb_bias_mux_controller_enhanced -do "run -all; quit"
```

## Common Issues and Solutions

### License Error

```
Cannot checkout an uncounted license within a Windows Terminal Services guest session
```

**Solution**: Launch Questa Sim GUI first, then run from the console.

### Compilation Errors

**Solution**: Ensure all RTL files are in the correct path:
```
../rtl/bias_mux_controller.sv
```

### Test Timeout

**Solution**: Check that:
1. Clock generation is working (100 MHz)
2. Reset is de-asserted
3. DUT has no syntax errors

## Test Coverage Summary

### Bias MUX Controller Enhanced Testbench

- **15 Test Cases**: Full functional coverage
- **Mode Transitions**: All 6 transitions tested
- **Timing**: < 10 us requirement verified
- **Edge Cases**: Reset handling, invalid modes, rapid switching
- **Glitch Detection**: Output stability verified

## Continuous Integration

For CI/CD integration, use the batch script:

```cmd
sim\scripts\run_tb_enhanced.bat
```

Exit codes:
- `0`: All tests passed
- `1`: Compilation or runtime error

## Documentation

See `sim/docs/enhanced_testbench_documentation.md` for detailed test descriptions.
