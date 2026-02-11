@echo off
REM =============================================================================
REM Run all FPGA simulations in batch mode
REM Usage: run_all.bat
REM =============================================================================

setlocal enabledelayedexpansion

set SIM_DIR=%~dp0
set RTL_PATH=..\rtl
set LIBRARY=%SIM_DIR%work

echo ==========================================
echo Compiling RTL and Testbenches
echo ==========================================

cd /d "%SIM_DIR%"

vsim -c -do "vlib work; vlog -sv +acc %RTL_PATH%\spi_slave_interface.sv %RTL_PATH%\register_file.sv %RTL_PATH%\timing_generator.sv %RTL_PATH%\bias_mux_controller.sv %RTL_PATH%\adc_controller.sv %RTL_PATH%\dummy_scan_engine.sv %RTL_PATH%\fpga_panel_controller.sv; vlog -sv +acc tb_spi_slave_interface.sv tb_register_file.sv tb_timing_generator.sv tb_bias_mux_controller.sv tb_adc_controller.sv tb_dummy_scan_engine.sv tb_top.sv; quit" 2>&1 | findstr /I "Compiling Errors Warning"

if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo.
echo ==========================================
echo Running Tests
echo ==========================================

set TESTS=tb_spi_slave_interface tb_register_file tb_timing_generator tb_bias_mux_controller tb_adc_controller tb_dummy_scan_engine tb_top
set PASS=0
set FAIL=0

for %%T in (%TESTS%) do (
    echo.
    echo --- Testing %%T ---
    vsim -c -do "vsim -t ps work.%%T; run -all; quit -f" 2>&1 > result_%%T.txt
    findstr /C:"PASS" result_%%T.txt >nul
    if errorlevel 1 (
        findstr /C:"Completed Successfully" result_%%T.txt >nul
        if errorlevel 1 (
            echo [FAIL] %%T
            set /a FAIL+=1
        ) else (
            echo [PASS] %%T
            set /a PASS+=1
        )
    ) else (
        echo [PASS] %%T
        set /a PASS+=1
    )
    del result_%%T.txt 2>nul
)

echo.
echo ==========================================
echo Test Summary
echo ==========================================
echo Passed: %PASS%
echo Failed: %FAIL%
echo Total: 7
echo.

if %FAIL%==0 (
    echo All tests PASSED!
    exit /b 0
) else (
    echo Some tests FAILED!
    exit /b 1
)
