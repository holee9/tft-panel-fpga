# TFT Panel FPGA Controller

aSi TFT 패널 누설 전류 감소를 위한 FPGA 제어 로직입니다.

## 목표

- 2D Idle 상태 구현을 통한 누설 전류 최소화
- Bias MUX 제어로 패널 전압 최적화
- Dummy Scan 기능으로 화소 안정성 확보
- i.MX8MP와의 SPI 통신 인터페이스

## 하드웨어 사양

| 항목 | 사양 |
|------|------|
| FPGA | Xilinx Artix-7 (기반) |
| 툴 버전 | Vivado 2025.2, Questa Sim 2025 |
| 클럭 | 100MHz 시스템 클럭 |
| SPI | Slave 모드, 최대 25MHz |

## 프로젝트 구조

```
tft-panel-fpga/
├── rtl/                      # SystemVerilog 소스
├── sim/                      # Questa 시뮬레이션
├── syn/                      # Vivado 합성
└── docs/                     # 사양서
```

## 빌드 방법

### 시뮬레이션 (Questa Sim 2025)

```tcl
cd sim
source scripts/run_sim.tcl
```

### 합성 (Vivado 2025.2)

```tcl
cd syn
source create_project.tcl
source run_synth.tcl
```

## 인터페이스

### SPI Slave Interface

| 신호 | 방향 | 설명 |
|------|------|------|
| SPI_SCLK | Input | SPI 클럭 |
| SPI_MOSI | Input | Master Out Slave In |
| SPI_MISO | Output | Slave Out Master In |
| SPI_CS_N | Input | Chip Select (Active Low) |

### Panel Control Signals

| 신호 | 방향 | 설명 |
|------|------|------|
| BIAS_SEL[2:0] | Output | Bias 전압 선택 |
| GATE_EN | Output | Gate 신호 활성화 |
| DATA_EN | Output | 데이터 신호 활성화 |
| SCAN_START | Output | Dummy Scan 시작 |

## 레지스터 맵

| 주소 | 레지스터 | 접근 |
|------|----------|------|
| 0x00 | CTRL | RW |
| 0x01 | STATUS | R |
| 0x02 | BIAS_SEL | RW |
| 0x03 | SCAN_CONFIG | RW |
| 0x04 | TIMER_PERIOD | RW |

## 문서

### 배포 패키지

| 문서 | 설명 |
|------|------|
| [README.md](docs/delivery/README.md) | 배포 패키지 개요 |
| [00_project_overview.md](docs/delivery/00_project_overview.md) | 프로젝트 개요 및 시스템 역할 |
| [01_requirements.md](docs/delivery/01_requirements.md) | 기능 및 성능 요구사항 |
| [02_interfaces.md](docs/delivery/02_interfaces.md) | SPI, LVDS, Bias Control, ADC 인터페이스 |
| [03_timing_specifications.md](docs/delivery/03_timing_specifications.md) | 행/열 타이밍, 프레임 타이밍 |
| [04_register_map.md](docs/delivery/04_register_map.md) | SPI 레지스터 주소 맵 |
| [05_acceptance_criteria.md](docs/delivery/05_acceptance_criteria.md) | 검증 및 테스트 요구사항 |
| [reference/](docs/delivery/reference/) | 패널 물리 특성 참고 문서 |

### 요약 사양

- [docs/spec.md](docs/spec.md) - 간단 사양 요약

## 라이선스

MIT License - [LICENSE](LICENSE)

## 관련 프로젝트

- [meta-tft-leakage](https://github.com/holee9/meta-tft-leakage) - Yocto Layer
- [TftLeakage.Hardware](https://github.com/holee9/TftLeakage.Hardware) - .NET 라이브러리
