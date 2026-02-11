# =============================================================================
# Questa Simulation Script
# =============================================================================
# Purpose: Run simulation with Questa Sim 2025
# Usage: vsim -c -do "source scripts/run_sim.tcl"
# Note: Uses onfinish finish to prevent batch session exit
# =============================================================================

# Set project variables
set RTL_PATH ../rtl
set SIM_PATH .

# Create library
vlib work

# Compile all RTL files
vlog -sv +acc \
    ${RTL_PATH}/spi_slave_interface.sv \
    ${RTL_PATH}/register_file.sv \
    ${RTL_PATH}/timing_generator.sv \
    ${RTL_PATH}/bias_mux_controller.sv \
    ${RTL_PATH}/adc_controller.sv \
    ${RTL_PATH}/dummy_scan_engine.sv \
    ${RTL_PATH}/fpga_panel_controller.sv

# Compile testbenches
vlog -sv +acc \
    ${SIM_PATH}/tb_spi_slave_interface.sv \
    ${SIM_PATH}/tb_register_file.sv \
    ${SIM_PATH}/tb_timing_generator.sv \
    ${SIM_PATH}/tb_bias_mux_controller.sv \
    ${SIM_PATH}/tb_adc_controller.sv \
    ${SIM_PATH}/tb_dummy_scan_engine.sv \
    ${SIM_PATH}/tb_top.sv

# Configure onfinish to prevent session exit
onfinish finish

puts "\n=========================================="
puts "Running Individual Module Tests"
puts "==========================================\n"

# Test individual modules
puts "\n--- Testing SPI Slave Interface ---"
vsim -t ps -c work.tb_spi_slave_interface
run -all
# vsim exits on $finish from testbench, continue with next test

puts "\n--- Testing Register File ---"
vsim -t ps -c work.tb_register_file
run -all

puts "\n--- Testing Timing Generator ---"
vsim -t ps -c work.tb_timing_generator
run -all

puts "\n--- Testing Bias Mux Controller ---"
vsim -t ps -c work.tb_bias_mux_controller
run -all

puts "\n--- Testing ADC Controller ---"
vsim -t ps -c work.tb_adc_controller
run -all

puts "\n--- Testing Dummy Scan Engine ---"
vsim -t ps -c work.tb_dummy_scan_engine
run -all

puts "\n=========================================="
puts "Running Top-Level System Test"
puts "==========================================\n"

vsim -t ps -c work.tb_top
run -all

puts "\n=========================================="
puts "All Tests Completed"
puts "==========================================\n"

quit
