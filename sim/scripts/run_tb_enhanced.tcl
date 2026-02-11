# Run Enhanced Bias MUX Controller Testbench
# Usage: vsim -c -do "do scripts/run_tb_enhanced.tcl"

# Clean up any previous compilation
file delete -force work

# Create library and compile source files
vlib work
vlog -sv ../rtl/bias_mux_controller.sv
vlog -sv tb_bias_mux_controller_enhanced.sv

# Run simulation with waveform dumping
vsim -c tb_bias_mux_controller_enhanced -G"DUMP_WAVES=1" +DUMP_WAVES

# Add wave signals for viewing (if GUI)
# log -r *

# Run until completion
run -all

# Exit
quit -f
