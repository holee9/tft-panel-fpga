# TFT Panel FPGA Controller

a-Si TFT (Amorphous Silicon Thin Film Transistor) Flat Panel Detector의 dark current drift를 최소화하기 위한 FPGA 제어 로직 구현입니다.

## 목표

- **2D Idle 상태 구현**: Idle 상태에서 누설 전류 최소화
- **Bias MUX 제어**: Normal/Idle/Sleep 모드 간 전압 전환
- **Dummy Scan 기능**: 주기적 더미 스캔으로 화소 안정성 유지
- **SPI 통신 인터페이스**: i.MX8MP와의 레지스터 액세스

## 하드웨어 사양

| 항목 | 사양 |
|------|------|
| **Target FPGA** | Xilinx Artix-7 35T (xc7a35tcpg236-1) |
| **Target Panel** | R1717AS01.3 (2048 x 2048 a-Si TFT FPD) |
| **시스템 클럭** | 100 MHz |
| **SPI 인터페이스** | Slave Mode 0, 최대 10 MHz |
| **ADC 인터페이스** | 14-bit, 최대 20 MHz |

## 프로젝트 구조

```
tft-panel-fpga/
|-- rtl/                      # SystemVerilog RTL 소스
|   |-- fpga_panel_controller.sv     # 최상위 모듈 (44포트)
|   |-- spi_slave_interface.sv       # SPI Slave 인터페이스
|   |-- register_file.sv             # 64개 레지스터 파일
|   |-- timing_generator.sv          # 프레임 타이밍 생성기
|   |-- bias_mux_controller.sv       # Bias 전압 제어
|   |-- adc_controller.sv            # ADC 인터페이스
|   +-- dummy_scan_engine.sv         # 더미 스캔 엔진
|
|-- sim/                      # Questa 시뮬레이션
|   |-- scripts/run_sim.tcl          # 전체 시뮬레이션 스크립트
|   |-- tb_*.sv                       # 각 모듈 테스트벤치
|   +-- tb_top.sv                     # 최상위 시스템 테스트
|
|-- syn/                      # Vivado 합성
|   |-- create_project.tcl            # 프로젝트 생성 스크립트
|   |-- run_synth.tcl                 # 합성 실행 스크립트
|   +-- constraints/fpga_panel.xdc    # 핀 할당 및 타이밍 제약
|
|-- docs/                     # 문서
|   |-- delivery/                     # 배포 패키지 문서
|   +-- spec.md                       # 사양 요약
|
+-- .moai/                    # MoAI 설정 및 SPEC
```

## 빌드 방법

### 시뮬레이션 (Questa Sim 2025)

```tcl
cd sim
vsim -c -do "source scripts/run_sim.tcl"
```

또는 개별 모듈 테스트:

```tcl
# 타이밍 생성기 테스트
vsim -c work.tb_timing_generator -do "run -all; quit -f"

# 전체 시스템 테스트
vsim -c work.tb_top -do "run -all; quit -f"
```

### 합성 (Vivado 2025.2)

```tcl
# 프로젝트 생성
vivado -mode batch -source syn/create_project.tcl

# 합성 및 비트스트림 생성
vivado -mode batch -source syn/run_synth.tcl
```

생성된 비트스트림: `syn/fpga_panel/fpga_panel.bit`

## 주요 기능

### 1. 타이밍 생성 (Timing Generator)

프레임 캡처를 위한 행/열 타이밍 신호 생성

| 파라미터 | 값 |
|----------|-----|
| 행 클럭 | 5 MHz (+/- 1%) |
| 열 클럭 | 10 MHz (+/- 1%) |
| 리셋 펄스 | 10 us |
| 통합 시간 | 1-65535 ms (설정 가능) |
| ROI 지원 | 0-2047 행/열 |

### 2. Bias 제어 (Bias MUX Controller)

세 가지 바이어스 모드 간 글리치 없는 전환

| 모드 | V_PD | V_COL | 설명 |
|------|------|-------|------|
| NORMAL | -1.5V | -1.0V | 정상 이미지 캡처 |
| IDLE | -0.2V | -0.2V | Low power 대기 |
| SLEEP | 0V | 0V | 최소 전력 소비 |

전환 시간: < 10 us

### 3. 더미 스캔 (Dummy Scan Engine)

L2 Idle 모드에서 주기적 화소 리셋

- 주기 설정: 30-65535 초
- 전체 행 순차 리셋
- ADC readout 없음
- 완료 시간: < 2 ms

### 4. ADC FIFO 제어

ADC 데이터 버퍼링 및 외부 읽기 인터페이스

| 기능 | 설명 |
|------|------|
| FIFO 깊이 | 2048 샘플 |
| fifo_rd | 외부 읽기 요청 신호 |
| fifo_flush | FIFO 포인터 리셋 |
| fifo_level[10:0] | FIFO 내 아이템 수 (0-2048) |

### 5. SPI 레지스터 인터페이스

MCU를 통한 FPGA 설정 및 상태 모니터링

| 주소 | 레지스터 | 접근 | 설명 |
|------|----------|------|------|
| 0x00 | CTRL | RW | 제어 레지스터 |
| 0x01 | STATUS | RO | 상태 플래그 |
| 0x02 | BIAS_SELECT | RW | Bias 모드 선택 |
| 0x03-04 | DUMMY_PERIOD | RW | 더미 스캔 주기 (초) |
| 0x05 | DUMMY_CONTROL | RW | 더미 스캔 제어 |
| 0x06-09 | ROW_START/END | RW | ROI 행 범위 |
| 0x0A-0D | COL_START/END | RW | ROI 열 범위 |
| 0x0E-0F | INTEGRATION_TIME | RW | 통합 시간 (ms) |
| 0x18 | INT_EN | RW | 인터럽트 활성화 (개별 비트) |
| 0x19 | INT_STATUS | RO | 인터럽트 상태 (Latch) |
| 0x1A | INT_CLEAR | WO | 인터럽트 클리어 (Write-1-to-Clear) |
| 0x17 | FIRMWARE_VERSION | RO | 펌웨어 버전 (0x10) |

## 시뮬레이션 결과

| 테스트벤치 | 결과 | 설명 |
|-----------|------|------|
| tb_timing_generator | PASS | 2x2 ROI 테스트 |
| tb_timing_generator_enhanced | PASS | 경계값/코너 케이스 테스트 (10케이스) |
| tb_adc_controller | PASS | 2/2 테스트 통과 |
| tb_dummy_scan_engine | PASS | 1/1 테스트 통과 |
| tb_register_file | PASS | 3/3 테스트 통과 |
| tb_spi_slave_interface | PASS | SPI 프로토콜 테스트 |
| tb_spi_slave_interface_enhanced | PASS | 경계값/인터럽트 레지스터 테스트 (15케이스) |
| tb_top | PASS | 전체 시스템 테스트 |

## 인터페이스 신호

### SPI Slave Interface

| 신호 | 방향 | 설명 |
|------|------|------|
| SPI_SCLK | Input | SPI 클럭 |
| SPI_MOSI | Input | Master Out Slave In |
| SPI_MISO | Output | Slave Out Master In |
| SPI_CS_N | Input | Chip Select (Active Low) |

### Panel Control Outputs

| 신호 | 방향 | 폭 | 설명 |
|------|------|-----|------|
| row_addr[11:0] | Output | 12 | 행 주소 (0-2047) |
| col_addr[11:0] | Output | 12 | 열 주소 (0-2047) |
| row_clk_en | Output | 1 | 행 클럭 인에이블 |
| col_clk_en | Output | 1 | 열 클럭 인에이블 |
| gate_sel | Output | 1 | 게이트 선택 |
| reset_pulse | Output | 1 | 리셋 펄스 |
| bias_mode_select[1:0] | Output | 2 | 바이어스 모드 선택 |
| v_pd_n | Output | 1 | 포토다이오드 바이어스 |
| v_col_n | Output | 1 | 열 바이어스 |
| v_rg_n | Output | 1 | 리셋 게이트 바이어스 |

### ADC Interface

| 신호 | 방향 | 폭 | 설명 |
|------|------|-----|------|
| adc_cs_n | Output | 1 | ADC Chip Select |
| adc_sclk | Output | 1 | ADC SPI 클럭 |
| adc_mosi | Output | 1 | ADC MOSI |
| adc_miso | Input | 1 | ADC MISO |
| adc_clk | Output | 1 | ADC 클럭 (최대 20 MHz) |
| adc_data[13:0] | Input | 14 | ADC 데이터 |
| fifo_rd | Input | 1 | FIFO 읽기 요청 |
| fifo_flush | Input | 1 | FIFO 플래시 |
| fifo_level[10:0] | Output | 11 | FIFO 레벨 (0-2048) |
| fifo_wr_en | Output | 1 | FIFO 쓰기 인에이블 |
| fifo_wr_data[13:0] | Output | 14 | FIFO 쓰기 데이터 |

### Interrupt Outputs

| 신호 | 방향 | 설명 |
|------|------|------|
| int_frame_complete | Output | 프레임 완료 인터럽트 |
| int_dummy_complete | Output | 더미 스캔 완료 인터럽트 |
| int_fifo_overflow | Output | FIFO 오버플로우 인터럽트 |
| int_error | Output | 에러 인터럽트 |
| int_active | Output | 인터럽트 활성 상태 |

#### 인터럽트 타입 (INT_EN/INT_STATUS/INT_CLEAR)

| 비트 | 인터럽트 | 설명 |
|-----|---------|------|
| 0 | FRAME_COMPLETE | 프레임 캡처 완료 |
| 1 | FIFO_OVERFLOW | ADC FIFO 오버플로우 |
| 2 | DUMMY_SCAN_COMPLETE | 더미 스캔 완료 |
| 3 | BIAS_READY | Bias 모드 전환 완료 |
| 4 | ADC_DATA_READY | ADC 데이터 변환 완료 |
| 5-31 | Reserved | 예약 |

## 리소스 사용량 (예상)

| 리소스 | 사용량 | 가용량 | Utilization |
|--------|---------|--------|-------------|
| Slice LUTs | ~15,000 | 20,800 | 72% |
| Slice Registers | ~10,000 | 41,600 | 24% |
| BRAMs | ~20 | 100 | 20% |
| DSP48E1 | ~5 | 80 | 6% |

## 문서

### 배포 패키지 문서

| 문서 | 설명 |
|------|------|
| [README.md](docs/delivery/README.md) | 배포 패키지 개요 |
| [00_project_overview.md](docs/delivery/00_project_overview.md) | 프로젝트 개요 및 시스템 아키텍처 |
| [01_requirements.md](docs/delivery/01_requirements.md) | 기능 및 성능 요구사항 |
| [02_interfaces.md](docs/delivery/02_interfaces.md) | SPI, LVDS, Bias Control, ADC 인터페이스 상세 |
| [03_timing_specifications.md](docs/delivery/03_timing_specifications.md) | 행/열 타이밍, 프레임 타이밍 상세 |
| [04_register_map.md](docs/delivery/04_register_map.md) | SPI 레지스터 주소 맵 상세 |
| [05_acceptance_criteria.md](docs/delivery/05_acceptance_criteria.md) | 검증 및 테스트 요구사항 |
| [reference/panel_physics_summary.md](docs/delivery/reference/panel_physics_summary.md) | 패널 물리 특성 참고 |

## 관련 프로젝트

- [meta-tft-leakage](https://github.com/holee9/meta-tft-leakage) - Yocto Layer for SW stack
- [TftLeakage.Hardware](https://github.com/holee9/TftLeakage.Hardware) - .NET 라이브러리

## 라이선스

MIT License - [LICENSE](LICENSE)

## 저작권

Copyright (c) 2026 TFT Panel FPGA Controller Project
