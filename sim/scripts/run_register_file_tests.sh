#!/bin/bash
# *****************************************************************************
# Shell Script to Run Register File Enhanced Tests
# *****************************************************************************
# Usage: ./run_register_file_tests.sh
# *****************************************************************************

set -e

# Set paths (convert Windows path to Git Bash format if needed)
SIM_DIR="/e/github_work/tft-panel-fpga/sim"
RTL_DIR="/e/github_work/tft-panel-fpga/rtl"
SCRIPT_DIR="$SIM_DIR/scripts"

echo "=========================================================================================="
echo "Register File Enhanced Test Runner"
echo "=========================================================================================="

# Change to simulation directory
cd "$SIM_DIR"

# Check if vsim exists
if ! command -v vsim &> /dev/null; then
    echo "ERROR: vsim not found in PATH"
    echo "Please source Questa Sim environment script first"
    exit 1
fi

echo ""
echo "Creating library..."
rm -rf tft_panel_lib
vlib tft_panel_lib

echo ""
echo "Compiling RTL..."
vlog -sv -work tft_panel_lib +define+SIMULATION "$RTL_DIR/register_file.sv"

echo ""
echo "Compiling testbench..."
vlog -sv -work tft_panel_lib -suppress 2583 "tb_register_file_enhanced.sv"

echo ""
echo "Running simulation..."
vsim -voptargs=+acc -t 1ps -c -lib tft_panel_lib tb_register_file_enhanced -do "run -all" -do "quit -f"

echo ""
echo "=========================================================================================="
echo "Simulation Complete"
echo "=========================================================================================="
echo ""
echo "Check transcript for results"
echo ""
