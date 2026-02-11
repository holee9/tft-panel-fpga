# *****************************************************************************
# Test Runner Script for Dummy Scan Engine Enhanced Testbench
# *****************************************************************************
# Usage: In Questa Sim, source this script or run:
#        vsim -c -do "source scripts/run_dummy_scan_tests.tcl" -do "quit -f"
# *****************************************************************************

# Set library and file paths
set RTL_PATH "../rtl"
set SIM_PATH "."
set LIB_NAME "tft_panel_lib"

# Create library
if {[file exists $LIB_NAME]} {
    vdel -lib $LIB_NAME -all
}
vlib $LIB_NAME

# Map library
vmap $LIB_NAME $LIB_NAME

echo "=========================================================================="
echo "Compiling RTL and Testbench"
echo "=========================================================================="

# Compile RTL
vlog -sv -work $LIB_NAME \
    +define+SIMULATION \
    "$RTL_PATH/dummy_scan_engine.sv"

# Compile testbench
vlog -sv -work $LIB_NAME \
    -suppress 2583 \
    "$SIM_PATH/tb_dummy_scan_engine_enhanced.sv"

echo "=========================================================================="
echo "Running Simulation"
echo "=========================================================================="

# Simulate
vsim -voptargs=+acc -t 1ps -c -lib $LIB_NAME tb_dummy_scan_engine_enhanced

# Run
run -all

# Exit
quit -f
