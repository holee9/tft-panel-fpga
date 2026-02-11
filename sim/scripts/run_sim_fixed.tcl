# =============================================================================
# Questa Simulation Script - Fixed
# =============================================================================
# Purpose: Run simulation with Questa Sim 2025
# Usage: vsim -c -do "source scripts/run_sim_fixed.tcl"
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

puts "\n=========================================="
puts "Running Individual Module Tests"
puts "==========================================\n"

# Test individual modules
puts "\n--- Testing SPI Slave Interface ---"
vsim -t ps -c work.tb_spi_slave_interface -do "run -all"
puts "SPI Slave Interface test completed"

puts "\n--- Testing Register File ---"
vsim -t ps -c work.tb_register_file -do "run -all"
puts "Register File test completed"

puts "\n--- Testing Timing Generator ---"
vsim -t ps -c work.tb_timing_generator -do "run -all"
puts "Timing Generator test completed"

puts "\n--- Testing Bias Mux Controller ---"
vsim -t ps -c work.tb_bias_mux_controller -do "run -all"
puts "Bias Mux Controller test completed"

puts "\n--- Testing ADC Controller ---"
vsim -t ps -c work.tb_adc_controller -do "run -all"
puts "ADC Controller test completed"

puts "\n--- Testing Dummy Scan Engine ---"
vsim -t ps -c work.tb_dummy_scan_engine -do "run -all"
puts "Dummy Scan Engine test completed"

puts "\n=========================================="
puts "Running Top-Level System Test"
puts "==========================================\n"

vsim -t ps -c work.tb_top -do "run -all"
puts "Top-Level System test completed"

puts "\n=========================================="
puts "All Tests Completed"
puts "==========================================\n"
