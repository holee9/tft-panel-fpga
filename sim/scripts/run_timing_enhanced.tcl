# Run Timing Generator Enhanced Testbench
vlib work
vlog -sv +acc ../rtl/timing_generator.sv ./tb_timing_generator_enhanced.sv
vsim -t ps work.tb_timing_generator_enhanced
run -all
quit -f
