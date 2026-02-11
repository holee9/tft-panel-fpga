@echo off
REM *****************************************************************************
REM Batch Script to Run Dummy Scan Engine Enhanced Tests
REM *****************************************************************************
REM Usage: run_dummy_scan_tests.bat
REM *****************************************************************************

setlocal enabledelayedexpansion

REM Set paths
set SIM_DIR=E:\github_work\tft-panel-fpga\sim
set SCRIPT_DIR=%SIM_DIR%\scripts
set RTL_DIR=E:\github_work\tft-panel-fpga\rtl

echo ============================================================================
echo Dummy Scan Engine Enhanced Test Runner
echo ============================================================================

REM Change to simulation directory
cd /d "%SIM_DIR%"

REM Check if vsim exists
where vsim >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: vsim not found in PATH
    echo Please run from Questa Sim command prompt or add to PATH
    pause
    exit /b 1
)

echo.
echo Creating library...
vlib tft_panel_lib 2>nul
if exist work (
    vdel -lib tft_panel_lib -all
)

echo.
echo Compiling RTL...
vlog -sv -work tft_panel_lib +define+SIMULATION "%RTL_DIR%/dummy_scan_engine.sv"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: RTL compilation failed
    pause
    exit /b 1
)

echo.
echo Compiling testbench...
vlog -sv -work tft_panel_lib -suppress 2583 "tb_dummy_scan_engine_enhanced.sv"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Testbench compilation failed
    pause
    exit /b 1
)

echo.
echo Running simulation...
vsim -voptargs=+acc -t 1ps -c -lib tft_panel_lib tb_dummy_scan_engine_enhanced -do "run -all" -do "quit -f"

echo.
echo ============================================================================
echo Simulation Complete
echo ============================================================================
echo.
echo Check transcript or log file for results
echo.

pause
