# =============================================================================
# TFT Panel FPGA Constraints File
# =============================================================================
# Purpose: Pin assignments and timing constraints
# Target: Xilinx Artix-7 (adjust for actual device)
# =============================================================================

# ========================================================================
# Clock Constraint
# ========================================================================
# 100MHz system clock
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

# ========================================================================
# SPI Slave Interface
# ========================================================================
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports spi_sclk]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports spi_cs_n]

# ========================================================================
# Panel Control Outputs
# ========================================================================
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS33} [get_ports {bias_sel[0]}]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports {bias_sel[1]}]
set_property -dict {PACKAGE_PIN C3 IOSTANDARD LVCMOS33} [get_ports {bias_sel[2]}]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports gate_en]
set_property -dict {PACKAGE_PIN E4 IOSTANDARD LVCMOS33} [get_ports data_en]
set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS33} [get_ports scan_start]

# ========================================================================
# ADC Interface
# ========================================================================
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports adc_cs_n]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports adc_sclk]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports adc_mosi]
set_property -dict {PACKAGE_PIN K5 IOSTANDARD LVCMOS33} [get_ports adc_miso]

# ========================================================================
# Status LEDs
# ========================================================================
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS33} [get_ports led_idle]
set_property -dict {PACKAGE_PIN M5 IOSTANDARD LVCMOS33} [get_ports led_active]

# ========================================================================
# Reset
# ========================================================================
set_property -dict {PACKAGE_PIN N5 IOSTANDARD LVCMOS33} [get_ports rst_n]

# ========================================================================
# Timing Constraints
# ========================================================================
# SPI timing (max 25MHz SPI clock)
set_input_delay -clock clk -max 20.0 [get_ports {spi_cs_n spi_mosi spi_sclk}]
set_output_delay -clock clk -max 20.0 [get_ports spi_miso]
