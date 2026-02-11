#!/bin/bash
# =============================================================================
# Run all FPGA simulations
# Usage: ./run_all.sh
# =============================================================================

SIM_DIR="$(cd "$(dirname "$0")" && pwd)"
RTL_PATH="$SIM_DIR/../rtl"

echo "=========================================="
echo "Compiling RTL and Testbenches"
echo "=========================================="

cd "$SIM_DIR" || exit 1

# Clean and create library
rm -rf work
vlib work

# Compile RTL
vlog -sv +acc \
    "$RTL_PATH/spi_slave_interface.sv" \
    "$RTL_PATH/register_file.sv" \
    "$RTL_PATH/timing_generator.sv" \
    "$RTL_PATH/bias_mux_controller.sv" \
    "$RTL_PATH/adc_controller.sv" \
    "$RTL_PATH/dummy_scan_engine.sv" \
    "$RTL_PATH/fpga_panel_controller.sv"

# Compile testbenches
vlog -sv +acc \
    tb_spi_slave_interface.sv \
    tb_register_file.sv \
    tb_timing_generator.sv \
    tb_bias_mux_controller.sv \
    tb_adc_controller.sv \
    tb_dummy_scan_engine.sv \
    tb_top.sv

echo ""
echo "=========================================="
echo "Running Tests"
echo "=========================================="

TESTS=("tb_spi_slave_interface" "tb_register_file" "tb_timing_generator" "tb_bias_mux_controller" "tb_adc_controller" "tb_dummy_scan_engine" "tb_top")
PASS=0
FAIL=0

for test in "${TESTS[@]}"; do
    echo ""
    echo "--- Testing $test ---"
    vsim -c -do "vsim -t ps work.$test; run -all; quit -f" 2>&1 | tee "result_$test.txt" | grep -E "PASS|FAIL|Test.*Completed" || true
    
    if grep -q "PASS" "result_$test.txt" || grep -q "Completed Successfully" "result_$test.txt"; then
        ((PASS++))
    else
        ((FAIL++))
    fi
    rm -f "result_$test.txt"
done

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total: 7"
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "All tests PASSED!"
    exit 0
else
    echo "Some tests FAILED!"
    exit 1
fi
