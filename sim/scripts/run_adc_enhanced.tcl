# =============================================================================
# Questa Simulation Script - Enhanced ADC Controller Testbench
# =============================================================================
# Purpose: Run enhanced ADC controller testbench with Questa Sim 2025
# Usage: vsim -c -do "source scripts/run_adc_enhanced.tcl" (from sim/ directory)
#        or: cd sim && vsim -c -do "source scripts/run_adc_enhanced.tcl"
# =============================================================================

# Set project variables
set RTL_PATH ../rtl
set SIM_PATH .

# Create library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compile ADC Controller RTL
puts "\n=========================================="
puts "Compiling ADC Controller RTL"
puts "==========================================\n"

vlog -sv +acc ${RTL_PATH}/adc_controller.sv

if {[file exists work/adc_controller]} {
    puts "ADC Controller compiled successfully\n"
} else {
    puts "ERROR: Failed to compile ADC Controller\n"
    exit
}

# Compile Enhanced Testbench
puts "\n=========================================="
puts "Compiling Enhanced Testbench"
puts "==========================================\n"

vlog -sv +acc ${SIM_PATH}/tb_adc_controller_enhanced.sv

if {[file exists work/tb_adc_controller_enhanced]} {
    puts "Enhanced testbench compiled successfully\n"
} else {
    puts "ERROR: Failed to compile enhanced testbench\n"
    exit
}

# Run Simulation
puts "\n=========================================="
puts "Running Enhanced ADC Controller Testbench"
puts "==========================================\n"

vsim -t ps -c work.tb_adc_controller_enhanced -do "run -all"

puts "\n=========================================="
puts "Simulation Completed"
puts "==========================================\n"
