# =============================================================================
# Questa Simulation Script
# =============================================================================
# Purpose: Run simulation with Questa Sim 2025
# Usage: vsim -c -do "source scripts/run_sim.tcl"
# =============================================================================

# Set project variables
set TOP_MODULE tb_top
set RTL_PATH ../rtl
set SIM_PATH .

# Create library
vlib work

# Compile RTL files
vlog -sv +acc \
    ${RTL_PATH}/fpga_panel_controller.sv \
    ${RTL_PATH}/spi_slave_interface.sv \
    ${RTL_PATH}/register_file.sv

# Compile testbench
vlog -sv +acc ${SIM_PATH}/tb_top.sv

# Elaborate
vsim -t ps -c work.${TOP_MODULE}

# Add waves
add wave -position insertpoint  \
    sim:/tb_top/clk \
    sim:/tb_top/rst_n \
    sim:/tb_top/spi_cs_n \
    sim:/tb_top/spi_sclk \
    sim:/tb_top/spi_mosi \
    sim:/tb_top/spi_miso

add wave -position insertpoint  \
    sim:/tb_top/bias_sel \
    sim:/tb_top/gate_en \
    sim:/tb_top/data_en \
    sim:/tb_top/scan_start

add wave -position insertpoint  \
    sim:/tb_top/led_idle \
    sim:/tb_top/led_active

# Run simulation
run -all

# Exit
quit
