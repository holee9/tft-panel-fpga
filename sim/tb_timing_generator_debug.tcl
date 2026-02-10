# Debug script for timing_generator
vlib work
vlog -sv +acc ../rtl/timing_generator.sv ./tb_timing_generator.sv

vsim -t ps work.tb_timing_generator

add wave -position insertpoint sim:/tb_timing_generator/clk
add wave -position insertpoint sim:/tb_timing_generator/rst_n
add wave -position insertpoint sim:/tb_timing_generator/frame_start
add wave -position insertpoint sim:/tb_timing_generator/frame_busy
add wave -position insertpoint sim:/tb_timing_generator/frame_complete
add wave -position insertpoint sim:/tb_timing_generator/dut/current_state
add wave -position insertpoint sim:/tb_timing_generator/dut/next_state
add wave -position insertpoint sim:/tb_timing_generator/dut/integrate_counter
add wave -position insertpoint sim:/tb_timing_generator/dut/integrate_done
add wave -position insertpoint sim:/tb_timing_generator/dut/reset_counter

run 2ms
quit -f
