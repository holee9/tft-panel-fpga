# TFT Panel FPGA Controller - 코드베이스 구조

## 프로젝트 디렉터리 구조

```
tft-panel-fpga/
├── rtl/                          # RTL 소스 코드
│   ├── fpga_panel_controller.sv  # 최상위 모듈
│   ├── timing_generator.sv       # 타이밍 생성기
│   ├── register_file.sv          # 레지스터 파일 (64 레지스터)
│   ├── spi_slave_interface.sv    # SPI 슬레이브 인터페이스
│   ├── bias_mux_controller.sv    # 바이어스 MUX 컨트롤러
│   ├── dummy_scan_engine.sv      # 더미 스캔 엔진
│   └── adc_controller.sv         # ADC 컨트롤러
├── sim/                          # 시뮬레이션 환경
│   ├── tb/                       # 테스트벤치 (tb_*.sv)
│   │   ├── tb_timing_generator.sv
│   │   ├── tb_register_file.sv
│   │   ├── tb_spi_slave_interface.sv
│   │   ├── tb_bias_mux_controller.sv
│   │   ├── tb_dummy_scan_engine.sv
│   │   ├── tb_adc_controller.sv
│   │   └── tb_top.sv             # 통합 테스트벤치
│   ├── scripts/                  # 테스트 실행 스크립트
│   │   ├── run_all_tests.sh      # 전체 테스트 자동 실행
│   │   ├── run_sim_fixed.tcl     # Questa 시뮬레이션 스크립트
│   │   └── compile_rtl.tcl       # RTL 컴파일 스크립트
│   └── spi_slave_interface.sv    # 시뮬레이션용 SPI 모델
├── syn/                          # 합성 스크립트
│   └── constraints/
│       └── fpga_panel.xdc        # Xilinx 제약 조건 파일
├── docs/                         # 문서
│   └── delivery/                 # 납품 문서
├── .moai/                        # MoAI 프로젝트 설정
│   ├── specs/
│   │   └── SPEC-001/
│   │       └── spec.md           # 제품 사양서
│   ├── project/
│   │   ├── product.md            # 제품 개요
│   │   ├── structure.md          # 코드베이스 구조
│   │   └── tech.md               # 기술 사양
│   └── config/                   # 프로젝트 설정
└── CLAUDE.md                     # MoAI 실행 지시문
```

## 모듈 계층 구조

```
fpga_panel_controller (최상위)
│
├── spi_slave_interface       # MCU와 SPI 통신
│   └── register_file          # 64개 레지스터 관리
│
├── timing_generator           # 타이밍 신호 생성
│   ├── Row Address (0-2047)
│   ├── Column Address (0-2047)
│   ├── Row Clock Enable (5MHz)
│   └── Column Clock Enable (10MHz)
│
├── bias_mux_controller        # 바이어스 모드 제어
│   ├── NORMAL_BIAS (V_PD=-1.5V, V_COL=-1.0V)
│   ├── IDLE_LOW_BIAS (V_PD=-0.2V, V_COL=-0.2V)
│   └── SLEEP_BIAS (V_PD=0V, V_COL=0V)
│
├── dummy_scan_engine          # 다크 전류 감소용 더미 스캔
│   └── Period 30-65535 sec
│
└── adc_controller             # ADC 인터페이스 및 FIFO
    ├── ADC Interface (14-bit)
    └── FIFO Buffer (2048 depth)
```

## 최상위 모듈 포트 (44개)

### 시스템 포트 (2개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| clk | input | 100 MHz 시스템 클럭 |
| rst_n | input | 활성화 낮은 리셋 |

### SPI 인터페이스 (4개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| spi_sclk | input | SPI 클럭 |
| spi_mosi | input | MCU -> FPGA 데이터 |
| spi_miso | output | FPGA -> MCU 데이터 |
| spi_cs_n | input | SPI 칩 선택 |

### 패널 제어 출력 (17개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| row_addr[11:0] | output | 행 주소 (0-2047) |
| col_addr[11:0] | output | 열 주소 (0-2047) |
| row_clk_en | output | 행 클럭 인에이블 (5MHz) |
| col_clk_en | output | 열 클럭 인에이블 (10MHz) |
| gate_sel | output | 게이트 선택 |
| gate_pulse | output | 게이트 펄스 |
| reset_pulse | output | 패널 리셋 펄스 |
| frame_busy | output | 프레임 처리 중 |
| frame_complete | output | 프레임 완료 |
| bias_mode_select[1:0] | output | 바이어스 모드 선택 |
| v_pd_n | output | 포토다이오드 바이어스 |
| v_col_n | output | 컬럼 바이어스 |
| v_rg_n | output | 리셋 게이트 바이어스 |
| bias_ready | output | 바이어스 준비 완료 |
| bias_busy | output | 바이어스 전환 중 |

### 더미 스캔 (5개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| dummy_scan_active | output | 더미 스캔 활성 |
| dummy_scan_busy | output | 더미 스캔 처리 중 |
| dummy_row_addr[11:0] | output | 더미 스캔 행 주소 |
| dummy_reset_pulse | output | 더미 리셋 펄스 |

### ADC 인터페이스 (8개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| adc_cs_n | output | ADC 칩 선택 |
| adc_sclk | output | ADC SPI 클럭 |
| adc_mosi | output | ADC MOSI |
| adc_miso | input | ADC MISO |
| adc_clk | output | ADC 클럭 |
| adc_start | output | ADC 변환 시작 |
| adc_data[13:0] | input | 14비트 ADC 데이터 |
| fifo_wr_en | output | FIFO 쓰기 인에이블 |
| fifo_wr_data[13:0] | output | FIFO 쓰기 데이터 |
| fifo_full | input | FIFO 풀 플래그 |
| fifo_empty | input | FIFO 엠프티 플래그 |

### 인터럽트 (5개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| int_frame_complete | output | 프레임 완료 인터럽트 |
| int_dummy_complete | output | 더미 스캔 완료 인터럽트 |
| int_fifo_overflow | output | FIFO 오버플로우 인터럽트 |
| int_error | output | 에러 인터럽트 |
| int_active | output | 인터럽트 활성 |

### LED 상태 표시 (3개)
| 포트명 | 방향 | 설명 |
|--------|------|------|
| led_idle | output | 유휴 상태 LED |
| led_active | output | 활성 상태 LED |
| led_error | output | 에러 상태 LED |

## 모듈별 설명

### 1. fpga_panel_controller.sv (최상위 모듈)
- 모든 서브모듈을 인스턴스화하고 연결
- 44개의 입출력 포트 정의
- 인터럽트 상태 로직 처리
- LED 상태 표시 로직

### 2. timing_generator.sv
- FSM 기반 타이밍 제어
- 5가지 상태: IDLE -> RESET -> INTEGRATE -> READOUT -> COMPLETE
- 행/열 클럭 디바이더
- ROI(관심 영역) 지원

### 3. register_file.sv
- 64개 레지스터 (0x00-0x3F)
- RW/RO 접근 제어
- MCU 설정값 저장

### 4. spi_slave_interface.sv
- SPI Mode 0 지원
- 8비트 주소 + 32비트 데이터 프로토콜
- 최대 10 MHz 동작

### 5. bias_mux_controller.sv
- 3가지 바이어스 모드
- 10us 이내 전환
- 글리치 프리 출력

### 6. dummy_scan_engine.sv
- 주기적 더미 스캔 실행
- 30-65535초 주기 설정
- 2ms 이내 완료

### 7. adc_controller.sv
- 14비트 ADC 인터페이스
- 2048 깊이 내부 FIFO
- 테스트 패턴 모드

## 테스트벤치 구조

| 파일명 | 대상 모듈 | 커버리지 |
|--------|----------|----------|
| tb_timing_generator.sv | timing_generator | FSM, 클럭 생성 |
| tb_register_file.sv | register_file | 64 레지스터 RW |
| tb_spi_slave_interface.sv | spi_slave_interface | SPI 프로토콜 |
| tb_bias_mux_controller.sv | bias_mux_controller | 바이어스 전환 |
| tb_dummy_scan_engine.sv | dummy_scan_engine | 더미 스캔 FSM |
| tb_adc_controller.sv | adc_controller | ADC 인터페이스 |
| tb_top.sv | 전체 시스템 | 통합 테스트 |

---

문서 버전: 1.0
최종 업데이트: 2026-02-11
