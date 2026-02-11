@echo off
REM =============================================================================
REM Enhanced ADC Controller Testbench - Windows Batch Script
REM Usage: run_adc_enhanced.bat
REM =============================================================================

cd /d E:\github_work\tft-panel-fpga\sim

echo ========================================
echo Enhanced ADC Controller Testbench
echo ========================================
echo.

REM Compile and run with Questa Sim
vsim -c -do "source scripts/run_adc_enhanced.tcl"

echo.
echo ========================================
echo Simulation Complete
echo ========================================

pause
