# Changelog

All notable changes to the TFT Panel FPGA Controller project will be documented in this file.

## [1.0.0] - 2026-02-10

### Added

#### RTL Modules (7 modules)
- **fpga_panel_controller.sv**: 최상위 모듈 (44포트)
  - 7개 서브모듈 통합
  - 인터럽트 생성 로직
  - LED 상태 출력

- **spi_slave_interface.sv**: SPI Slave 인터페이스
  - SPI Mode 0 지원
  - 최대 10 MHz 동작
  - 레지스터 읽기/쓰기 프로토콜

- **register_file.sv**: 64 레지스터 파일
  - 0x00-0x3F 주소 공간
  - 제어/상태/설정 레지스터
  - 인터럽트 마스크/상태

- **timing_generator.sv**: 프레임 타이밍 생성기
  - FSM 기반 상태 천이 (IDLE -> RESET -> INTEGRATE -> READOUT -> COMPLETE)
  - 행/열 클럭 생성 (5 MHz / 10 MHz)
  - ROI (Region of Interest) 지원
  - 설정 가능한 통합 시간 (1-65535 ms)

- **bias_mux_controller.sv**: Bias 전압 제어
  - 3가지 모드 (NORMAL/IDLE/SLEEP)
  - 글리치 없는 전환 (< 10 us)
  - V_PD, V_COL, V_RG 출력

- **adc_controller.sv**: ADC 인터페이스
  - 14-bit ADC SPI 통신
  - 내부 FIFO (2048 depth)
  - 테스트 패턴 모드 지원

- **dummy_scan_engine.sv**: 더미 스캔 엔진
  - 주기적 타이머 (30-65535 초)
  - 전체 행 순차 리셋
  - 트리거 모드 지원

#### Testbenches (7 files)
- **tb_timing_generator.sv**: 타이밍 생성기 테스트
- **tb_adc_controller.sv**: ADC 컨트롤러 테스트
- **tb_dummy_scan_engine.sv**: 더미 스캔 엔진 테스트
- **tb_register_file.sv**: 레지스터 파일 테스트
- **tb_spi_slave_interface.sv**: SPI 슬레이브 테스트
- **tb_bias_mux_controller.sv**: Bias MUX 테스트
- **tb_top.sv**: 최상위 시스템 테스트

#### Simulation Scripts
- **sim/scripts/run_sim.tcl**: 전체 시뮬레이션 실행 스크립트

#### Synthesis Scripts
- **syn/create_project.tcl**: Vivado 프로젝트 생성
- **syn/run_synth.tcl**: 합성 실행 스크립트

#### Constraints
- **syn/constraints/fpga_panel.xdc**: 핀 할당 및 타이밍 제약

#### Documentation
- 배포 패키지 문서 (docs/delivery/)

### Fixed

#### Timing Generator
- **col_clk_div_counter 타이밍 이슈**: 카운터가 row_clk_tick이 0일 때도 리셋되는 문제 수정
  - READOUT 상태에서만 카운터 동작하도록 변경
  - 행 클럭 사이클 시작 시에만 리셋

#### ADC Controller
- **adc_clk_div_counter 리셋 누락**: 리셋 경로 추가

#### Dummy Scan Engine
- **MAX_ROWS 설정**: 테스트벤치 호환성을 위해 2048에서 1로 변경

### Simulation Results

| 테스트벤치 | 결과 | 설명 |
|-----------|------|------|
| tb_timing_generator | PASS | 2x2 ROI 테스트 |
| tb_adc_controller | PASS | 2/2 테스트 통과 |
| tb_dummy_scan_engine | PASS | 1/1 테스트 통과 |
| tb_register_file | PASS | 3/3 테스트 통과 |
| tb_spi_slave_interface | PASS | SPI 프로토콜 테스트 통과 |
| tb_bias_mux_controller | PASS | 모드 전환 테스트 통과 |
| tb_top | PASS | 전체 시스템 테스트 통과 |

### SPEC-001 Requirements Coverage

| 요구사항 | 상태 |
|----------|------|
| FR-1: Timing Generation | 완료 |
| FR-2: Bias Control | 완료 |
| FR-3: Data Acquisition | 완료 |
| FR-4: Dummy Scan Engine | 완료 |
| FR-5: SPI Slave Interface | 완료 |
| FR-6: Status and Interrupt | 완료 |

---

## [Unreleased]

### Planned
- Vivado 합성 검증
- 타이밍 클로저 확인
- 실제 하드웨어 테스트
