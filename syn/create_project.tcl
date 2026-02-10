# =============================================================================
# Vivado Project Creation Script
# =============================================================================
# Purpose: Create Vivado project for synthesis
# Tool: Vivado 2025.2
# Usage: vivado -mode batch -source syn/create_project.tcl
# =============================================================================

# Set parameters
set PROJECT_NAME fpga_panel
set PROJECT_DIR ./syn
set RTL_DIR ./rtl
set TOP_MODULE fpga_panel_controller

# Create project
create_project ${PROJECT_NAME} ${PROJECT_DIR}/${PROJECT_NAME} -part xc7a35tcpg236-1

# Add source files
add_files -norecurse {
    ${RTL_DIR}/fpga_panel_controller.sv
    ${RTL_DIR}/spi_slave_interface.sv
    ${RTL_DIR}/register_file.sv
}

# Add constraints file (create if not exists)
if {[file exists ${PROJECT_DIR}/constraints/fpga_panel.xdc]} {
    add_files -fileset constrs_1 -norecurse ${PROJECT_DIR}/constraints/fpga_panel.xdc
}

# Set top module
set_property top ${TOP_MODULE} [current_fileset]

# Update to set top as top module
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Save project
save_project_as ${PROJECT_NAME} -force

puts "Project created successfully: ${PROJECT_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.xpr"
