#!/bin/bash
# =============================================================================
# Run all simulations in separate batch sessions
# =============================================================================

# Get absolute paths (handle both Git Bash and Windows)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Convert to relative paths for vsim compatibility
SIM_DIR=".."
RTL_PATH="../rtl"

echo "=========================================="
echo "Compiling RTL and Testbenches"
echo "=========================================="

# Create library and compile
vsim -c -do "vlib work; vlog -sv +acc ${RTL_PATH}/spi_slave_interface.sv ${RTL_PATH}/register_file.sv ${RTL_PATH}/timing_generator.sv ${RTL_PATH}/bias_mux_controller.sv ${RTL_PATH}/adc_controller.sv ${RTL_PATH}/dummy_scan_engine.sv ${RTL_PATH}/fpga_panel_controller.sv; vlog -sv +acc ./tb_*.sv; quit" 2>&1 | grep -E "(Compiling module|Errors|Warnings|^#)"

echo ""
echo "=========================================="
echo "Running Individual Module Tests"
echo "=========================================="

for testname in "tb_spi_slave_interface" "tb_register_file" "tb_timing_generator" "tb_bias_mux_controller" "tb_adc_controller" "tb_dummy_scan_engine" "tb_top"; do
    echo ""
    echo "--- Testing $testname ---"
    vsim -c -do "vsim -t ps work.${testname}; run -all; quit -f" 2>&1 | grep -E "(TEST|PASS|FAIL|Completed|Error|finish)" || echo "Test execution issue"
done

echo ""
echo "=========================================="
echo "All Tests Completed"
echo "=========================================="
