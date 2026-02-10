# =============================================================================
# Vivado Synthesis Script
# =============================================================================
# Purpose: Run synthesis and generate bitstream
# Tool: Vivado 2025.2
# Usage: vivado -mode batch -source syn/run_synth.tcl
# =============================================================================

# Set parameters
set PROJECT_NAME fpga_panel
set PROJECT_DIR ./syn

# Open project
open_project ${PROJECT_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.xpr

# Run synthesis
synth_design -top fpga_panel_controller -part xc7a35tcpg236-1

# Save checkpoint
write_checkpoint -force ${PROJECT_DIR}/${PROJECT_NAME}/post_synth

# Generate reports
report_timing_summary -file ${PROJECT_DIR}/${PROJECT_NAME}/timing_report.txt
report_utilization -file ${PROJECT_DIR}/${PROJECT_NAME}/utilization_report.txt

# Run implementation
opt_design
place_design
route_design

# Save checkpoint
write_checkpoint -force ${PROJECT_DIR}/${PROJECT_NAME}/post_route

# Generate bitstream
write_bitstream -force ${PROJECT_DIR}/${PROJECT_NAME}/fpga_panel.bit

puts "Bitstream generated: ${PROJECT_DIR}/${PROJECT_NAME}/fpga_panel.bit"

# Close project
close_project
