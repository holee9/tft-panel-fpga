@echo off
REM =============================================================================
REM Run Enhanced Bias MUX Controller Testbench
REM Usage: run_tb_enhanced.bat
REM =============================================================================

setlocal enabledelayedexpansion

REM Set paths
set SIM_DIR=%~dp0
set RTL_DIR=%SIM_DIR%..\rtl
set TB_DIR=%SIM_DIR%..

echo ==========================================
echo Enhanced Bias MUX Controller Testbench
echo ==========================================
echo.

REM Check if vsim is available
where vsim >nul 2>&1
if errorlevel 1 (
    echo ERROR: vsim not found in PATH
    echo Please source Questa Sim environment variables first
    exit /b 1
)

REM Change to simulation directory
cd /d "%TB_DIR%" || exit /b 1

echo Step 1: Cleaning previous compilation...
if exist work (
    rmdir /s /q work
)

echo Step 2: Compiling RTL and testbench...
vsim -c -do "vlib work; vlog -sv +acc %RTL_DIR%/bias_mux_controller.sv tb_bias_mux_controller_enhanced.sv; quit" 2>&1 | findstr /C:"Compiling" /C:"Error" /C:"Warning"

if errorlevel 1 (
    echo ERROR: Compilation failed
    exit /b 1
)

echo.
echo Step 3: Running simulation...
vsim -c tb_bias_mux_controller_enhanced -do "run -all; quit" 2>&1 | findstr /C:"TEST" /C:"PASS" /C:"FAIL" /C:"===" /C:"Summary"

echo.
echo ==========================================
echo Test run completed
echo ==========================================

REM Check VCD file was created
if exist tb_bias_mux_controller_enhanced.vcd (
    echo Waveform file: tb_bias_mux_controller_enhanced.vcd
)

exit /b 0
