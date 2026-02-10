# SPEC-001: TFT Panel FPGA Controller Implementation

## Meta Information

| Field | Value |
|-------|-------|
| **Spec ID** | SPEC-001 |
| **Title** | TFT Panel FPGA Controller - Full Implementation |
| **Status** | Planning |
| **Priority** | High |
| **Created** | 2026-02-10 |
| **Author** | MoAI Team |

---

## 1. Executive Summary

Implement a complete FPGA controller for a-Si TFT Flat Panel Detector (R1717AS01.3) according to delivery package specifications.

**Target FPGA**: Xilinx Artix-7 35T (xc7a35tcpg236-1)
**Target Panel**: 2048 x 2048 a-Si TFT FPD

---

## 2. Requirements (EARS Format)

### FR-1: Timing Generation Module
**WHEN** the system is in active mode, **THE SYSTEM SHALL** generate sequential row/column timing signals.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-1.1 | Generate row addresses 0-2047 sequentially |
| FR-1.2 | Generate column addresses for each row |
| FR-1.3 | Provide row clock enable at 5 MHz +/- 1% |
| FR-1.4 | Provide column clock enable at 10 MHz +/- 1% |
| FR-1.5 | Support configurable integration time (1-65535 ms) |
| FR-1.6 | Complete full frame readout within 250 ms |

### FR-2: Bias Control Module
**WHEN** MCU requests bias mode change, **THE SYSTEM SHALL** switch within 10 us.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-2.1 | Support NORMAL_BIAS (V_PD=-1.5V, V_COL=-1.0V) |
| FR-2.2 | Support IDLE_LOW_BIAS (V_PD=-0.2V, V_COL=-0.2V) |
| FR-2.3 | Support SLEEP_BIAS (V_PD=0V, V_COL=0V) |
| FR-2.4 | Complete switching within 10 us |
| FR-2.5 | Glitch-free transitions |
| FR-2.6 | Report bias ready status |

### FR-3: Data Acquisition Module
**WHEN** reading panel data, **THE SYSTEM SHALL** buffer 14-bit ADC data.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-3.1 | Interface with 14-bit ADC |
| FR-3.2 | Provide ADC clock up to 20 MHz |
| FR-3.3 | Buffer in FIFO (2048 depth) |
| FR-3.4 | Report FIFO status |
| FR-3.5 | Support test pattern mode |

### FR-4: Dummy Scan Engine Module
**WHEN** in L2 idle mode, **THE SYSTEM SHALL** execute periodic dummy scan.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-4.1 | Configurable period (30-65535 sec) |
| FR-4.2 | Reset all 2048 rows sequentially |
| FR-4.3 | No ADC readout during dummy scan |
| FR-4.4 | Complete within 2 ms |
| FR-4.5 | Report dummy scan status |

### FR-5: SPI Slave Interface Module
**WHEN** MCU communicates via SPI, **THE SYSTEM SHALL** respond to commands.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-5.1 | Support SPI Mode 0 |
| FR-5.2 | Operate up to 10 MHz |
| FR-5.3 | Support 64 registers (0x00-0x3F) |
| FR-5.4 | Support burst read |
| FR-5.5 | 8-bit data width |

### FR-6: Status and Interrupt Module
**WHEN** events occur, **THE SYSTEM SHALL** report status and generate interrupts.

| Sub-Requirement | Description |
|----------------|-------------|
| FR-6.1 | Report frame busy status |
| FR-6.2 | Report FIFO status |
| FR-6.3 | Generate frame complete interrupt |
| FR-6.4 | Generate dummy scan complete interrupt |
| FR-6.5 | Generate error interrupt |

---

## 3. Gap Analysis

| Module | Current | Required | Gap |
|--------|---------|----------|-----|
| Top Module | 13 ports | 44 ports | Missing 31 ports |
| SPI Slave | Working | Working | OK |
| Register File | 8 regs | 64 regs | Missing 56 |
| Timing Generator | None | FSM + clocks | Missing |
| Bias Controller | Simple output | 3-mode FSM | Incomplete |
| Dummy Scan Engine | None | Timer + sequencer | Missing |
| ADC Controller | Placeholder | Full interface | Missing |
| Testbenches | Skeleton | 90% coverage | Incomplete |

---

## 4. Implementation Phases

### Phase 1: Foundation (Week 1)
- 1.1 Expand register_file to 64 registers
- 1.2 Update fpga_panel_controller to 44 ports
- 1.3 Expand tb_top testbench

### Phase 2: Timing Generation (Week 2)
- 2.1 Implement timing_generator FSM
- 2.2 Add clock dividers
- 2.3 Create tb_timing_generator

### Phase 3: Bias Control (Week 2)
- 3.1 Implement bias_mux_controller FSM
- 3.2 Add glitch-free output
- 3.3 Create tb_bias_mux

### Phase 4: Dummy Scan (Week 3)
- 4.1 Implement dummy_scan_engine timer
- 4.2 Add row reset sequencer
- 4.3 Create tb_dummy_scan

### Phase 5: Data Acquisition (Week 3-4)
- 5.1 Implement adc_controller FSM
- 5.2 Add FIFO (2048 depth)
- 5.3 Create tb_adc_controller

### Phase 6: Integration (Week 4)
- 6.1 Full system test
- 6.2 Synthesis
- 6.3 Timing analysis
- 6.4 Coverage report

---

## 5. Module Specifications

### 5.1 Timing Generator

```systemverilog
module timing_generator (
    input  logic clk_100mhz, rst_n,
    input  logic frame_start, frame_reset,
    input  logic [15:0] integration_time,
    output logic frame_busy,
    output logic [11:0] row_addr, col_addr,
    output logic row_clk_en, col_clk_en,
    output logic gate_sel, reset_pulse,
    output logic adc_start_trigger
);
```

**States**: IDLE -> RESET (10us) -> INTEGRATE (100ms) -> READOUT (102.4ms) -> IDLE

### 5.2 Register Map (Full)

| Addr | Name | Access | Reset | Description |
|------|------|--------|-------|-------------|
| 0x00 | CTRL_REG | RW | 0x00 | Control bits |
| 0x01 | STATUS_REG | RO | 0x01 | Status flags |
| 0x02 | BIAS_SELECT | RW | 0x00 | 00=NORMAL, 01=IDLE, 10=SLEEP |
| 0x03-04 | DUMMY_PERIOD | RW | 0x003C | Period in seconds |
| 0x05 | DUMMY_CONTROL | RW | 0x00 | Auto mode, trigger |
| 0x06-09 | ROW_START/END | RW | 0/2047 | ROI rows |
| 0x0A-0D | COL_START/END | RW | 0/2047 | ROI cols |
| 0x0E-0F | INTEGRATION_TIME | RW | 0x0064 | Integration (ms) |
| 0x10-13 | TIMING_CONFIG | RW | - | Clock dividers, mode |
| 0x14-15 | INTERRUPT | RW/W1C | 0x00 | Mask/Status |
| 0x16 | ERROR_CODE | RO | 0x00 | Error status |
| 0x17 | FIRMWARE_VERSION | RO | 0x10 | Version 1.0 |
| 0x20-3F | TEST_PATTERN | RW | 0x00 | 256 bytes |

---

## 6. Acceptance Criteria

### Functional Tests
- FT-001: SPI register read/write (64 registers)
- FT-002: Frame capture < 250 ms
- FT-003: Bias switching < 10 us
- FT-004: Dummy scan 30-65535 sec
- FT-005: FIFO no overflow/underflow
- FT-006: All interrupts work

### Performance
- PT-001: Row clock 5 MHz +/- 1%
- PT-002: Column clock 10 MHz +/- 1%
- PT-003: Bias switch < 10 us
- PT-004: SPI access < 2 us

### Resource Budget
| Resource | Target |
|----------|--------|
| Slice LUTs | < 15,000 (72%) |
| Slice Registers | < 20,000 (48%) |
| BRAMs | < 25 (25%) |
| MMCM/PLL | <= 2 |

---

## 7. References

- docs/delivery/00_project_overview.md
- docs/delivery/01_requirements.md
- docs/delivery/02_interfaces.md
- docs/delivery/03_timing_specifications.md
- docs/delivery/04_register_map.md
- docs/delivery/05_acceptance_criteria.md

---

**End of SPEC-001**
