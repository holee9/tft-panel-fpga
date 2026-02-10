vlib work
vlog -sv +acc ../rtl/timing_generator.sv ./tb_timing_generator.sv
vsim -t ps work.tb_timing_generator
add wave -position insertpoint sim:/tb_timing_generator/dut/state
add wave -position insertpoint sim:/tb_timing_generator/dut/integrate_done
add wave -position insertpoint sim:/tb_timing_generator/dut/integration_time
add wave -position insertpoint sim:/tb_timing_generator/frame_busy
run 5ms
quit -f
