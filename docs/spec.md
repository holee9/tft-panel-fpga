# TFT Panel FPGA Controller Specification

## Summary

이 문서는 aSi TFT 패널의 누설 전류를 감소시키기 위한 FPGA 제어 로직의 사양서입니다.

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [요구사항](#2-요구사항)
3. [인터페이스](#3-인터페이스)
4. [타이밍 사양](#4-타이밍-사양)
5. [레지스터 맵](#5-레지스터-맵)
6. [인수 기준](#6-인수-기준)

---

## 1. 프로젝트 개요

### 목표

- 2D Idle 상태 구현을 통한 누설 전류 최소화
- Bias MUX 제어로 패널 전압 최적화
- Dummy Scan 기능으로 화소 안정성 확보
- i.MX8MP와의 SPI 통신 인터페이스

### 하드웨어 사양

| 항목 | 사양 |
|------|------|
| FPGA | Xilinx Artix-7 (기반) |
| 툴 버전 | Vivado 2025.2, Questa Sim 2025 |
| 클럭 | 100MHz 시스템 클럭 |
| SPI | Slave 모드, 최대 25MHz |

---

## 2. 요구사항

### 기능 요구사항

- [REQ-FPGA-001] FPGA는 SPI Slave 모드로 i.MX8MP와 통신해야 한다
- [REQ-FPGA-002] FPGA는 3가지 Bias 전압을 선택할 수 있어야 한다
- [REQ-FPGA-003] FPGA는 2D Idle 상태 진입 시 Dummy Scan을 수행해야 한다
- [REQ-FPGA-004] FPGA는 Gate/Data 신호를 제어할 수 있어야 한다
- [REQ-FPGA-005] FPGA는 패널 온도 모니터링을 위한 ADC 인터페이스를 제공해야 한다

### 성능 요구사항

- [PERF-FPGA-001] SPI 통신 속도: 최대 25MHz
- [PERF-FPGA-002] Bias 전환 시간: 100us 이내
- [PERF-FPGA-003] Dummy Scan 주기: 100ms ~ 10s 가변

---

## 3. 인터페이스

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
| BIAS_SEL[2:0] | Output | Bias 전압 선택 (000: V1, 001: V2, 010: V3, 111: OFF) |
| GATE_EN | Output | Gate 신호 활성화 (Active High) |
| DATA_EN | Output | 데이터 신호 활성화 (Active High) |
| SCAN_START | Output | Dummy Scan 시작 (Level Trigger) |

---

## 4. 타이밍 사양

### SPI 타이밍

```
CS_N      ______/              \______
              __    __    __    __
SCLK      __/  \__/  \__/  \__/  \__
          <-------> <-------------->
           Address     Data (32bit)
           (8bit)
```

| 파라미터 | 최소 | 최대 | 단위 |
|----------|------|------|------|
| t_SCLK | 40 | - | ns (25MHz) |
| t_SU | 10 | - | ns |
| t_H | 10 | - | ns |

### Bias 전환 타이밍

| 파라미터 | 최소 | 최대 | 단위 |
|----------|------|------|------|
| t_BIAS_SWITCH | - | 100 | us |

---

## 5. 레지스터 맵

| 주소 | 레지스터 | 접근 | 리셋 값 | 설명 |
|------|----------|------|---------|------|
| 0x00 | CTRL | RW | 0x00 | 제어 레지스터 |
| 0x01 | STATUS | R | 0x01 | 상태 레지스터 |
| 0x02 | BIAS_SEL | RW | 0x00 | Bias 선택 레지스터 |
| 0x03 | SCAN_CONFIG | RW | 0x00 | Scan 설정 레지스터 |
| 0x04 | TIMER_PERIOD | RW | 0x03E8 | 타이머 주기 (ms) |
| 0x10 | TIMER_L | RW | 0xE8 | 타이머 주기 하위 바이트 |
| 0x11 | TIMER_H | RW | 0x03 | 타이머 주기 상위 바이트 |
| 0x20 | ADC_DATA | R | 0x000 | ADC 데이터 |
| 0xFE | VERSION | R | 0x56313030 | 펌웨어 버전 ("V10") |

### CTRL 레지스터 (0x00)

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 0 | IDLE_EN | RW | Idle 모드 활성화 (1: Idle, 0: Active) |
| 31:1 | Reserved | - | 예약됨 |

### STATUS 레지스터 (0x01)

| 비트 | 이름 | 접근 | 설명 |
|------|------|------|------|
| 0 | READY | R | 준비 상태 (1: Ready) |
| 1 | IDLE | R | Idle 모드 상태 |
| 31:2 | Reserved | - | 예약됨 |

### BIAS_SEL 레지스터 (0x02)

| 값 | Bias 전압 |
|------|----------|
| 000 | V1 (일반 모드) |
| 001 | V2 (중간 모드) |
| 010 | V3 (Idle 모드) |
| 111 | OFF |

---

## 6. 인수 기준

### 기능 테스트

- [TEST-FPGA-001] SPI 쓰기/읽기 동작 검증
- [TEST-FPGA-002] Bias 전환 동작 검증
- [TEST-FPGA-003] Idle 모드 진입/퇴출 검증
- [TEST-FPGA-004] Dummy Scan 트리거 검증

### 성능 테스트

- [TEST-FPGA-101] SPI 최대 클럭 (25MHz) 동작 검증
- [TEST-FPGA-102] Bias 전환 시간 100us 이내 검증
- [TEST-FPGA-103] 타이머 정확도 ±1% 검증

### 합성 테스트

- [TEST-FPGA-201] Vivado 합성 성공
- [TEST-FPGA-202] 타이밍 제약조건 만족 (설정 클럭)
- [TEST-FPGA-203] 리소스 사용량 < 80% (타겟 디바이스)

---

## 참고 문서

- [docs/delivery/to-fpga-team/](https://github.com/holee9/TFT-Leak-plan/tree/main/docs/delivery/to-fpga-team) - 상세 사양서
