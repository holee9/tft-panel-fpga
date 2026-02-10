# TFT Panel FPGA Controller - Technical Manual

| Document Information | |
|---------------------|------------------|
| SPEC ID | SPEC-001 |
| Version | 1.0.0 |
| Date | 2026-02-10 |
| Target FPGA | Xilinx Artix-7 35T (xc7a35tcpg236-1) |
| Target Panel | 2048x2048 a-Si TFT Flat Panel Detector |

---

## 1. 레지스터 맵 (Register Map)

### 1.1 레지스터 요약표

| Address | Name | Access | Default | Description |
|---------|------|--------|---------|-------------|
| 0x00 | CTRL | RW | 0x00 | Control Register |
| 0x01 | STATUS | R | 0x81 | Status Register |
| 0x02 | BIAS_SEL | RW | 0x00 | Bias Mode Select |
| 0x03 | DUMMY_PERIOD_L | RW | 0x3C | Dummy Period (LSB) |
| 0x04 | DUMMY_PERIOD_H | RW | 0x00 | Dummy Period (MSB) |
| 0x05 | DUMMY_CTRL | RW | 0x00 | Dummy Scan Control |
| 0x06 | ROW_START_L | RW | 0x00 | ROI Row Start (LSB) |
| 0x07 | ROW_START_H | RW | 0x00 | ROI Row Start (MSB) |
| 0x08 | ROW_END_L | RW | 0xFF | ROI Row End (LSB) |
| 0x09 | ROW_END_H | RW | 0x07 | ROI Row End (MSB) |
| 0x0A | COL_START_L | RW | 0x00 | ROI Col Start (LSB) |
| 0x0B | COL_START_H | RW | 0x00 | ROI Col Start (MSB) |
| 0x0C | COL_END_L | RW | 0xFF | ROI Col End (LSB) |
| 0x0D | COL_END_H | RW | 0x07 | ROI Col End (MSB) |
| 0x0E | INTEGRATION_L | RW | 0x64 | Integration Time (LSB) |
| 0x0F | INTEGRATION_H | RW | 0x00 | Integration Time (MSB) |
| 0x10-0x16 | RESERVED | - | - | Reserved |
| 0x17 | INT_MASK | RW | 0x00 | Interrupt Mask |
| 0x18-0x22 | RESERVED | - | - | Reserved |
| 0x23 | FIRMWARE_VER | R | 0x56313030 | Firmware Version |

### 1.2 CONTROL 레지스터 (0x00)

| Bit | Name | R/W | Description |
|-----|------|-----|-------------|
| 0 | IDLE_MODE | RW | 1: Idle mode, 0: Active mode |
| 1 | FRAME_START | WO | Write 1 to start frame capture |
| 2 | FRAME_RESET | WO | Write 1 to reset frame capture |
| 3 | ADC_TEST_EN | RW | ADC test pattern enable |
| 31:4 | RESERVED | - | Reserved, write 0 |

### 1.3 STATUS 레지스터 (0x01)

| Bit | Name | R/W | Description |
|-----|------|-----|-------------|
| 0 | PRESENT | RO | Always 1 (device present) |
| 1 | IDLE_STATUS | RO | 1: Idle mode active |
| 2 | FIFO_EMPTY | RO | FIFO is empty |
| 3 | FIFO_FULL | RO | FIFO is full |
| 4 | DUMMY_BUSY | RO | Dummy scan in progress |
| 5 | BIAS_READY | RO | Bias voltage ready |
| 6 | FRAME_BUSY | RO | Frame capture in progress |
| 31:7 | RESERVED | - | Reserved |

---

## 2. SPI 통신 프로토콜 (SPI Protocol)

### 2.1 SPI 사양

| Parameter | Value |
|-----------|-------|
| SPI Mode | Mode 0 (CPOL=0, CPHA=0) |
| Maximum Clock | 10 MHz |
| Data Order | MSB first |
| Chip Select | Active low |

### 2.2 쓰기 트랜잭션 (Write)

```
CMD (1 byte) | ADDR (1 byte) | DATA (4 bytes)
   0x01       |  Register     |  Write Value
```

### 2.3 읽기 트랜잭션 (Read)

```
CMD (1 byte) | ADDR (1 byte) | DUMMY (4 bytes) | DATA (4 bytes)
   0x03       |  Register     |     0x00        |  Read Value
```

---

## 3. 타이밍 다이어그램 (Timing Diagrams)

### 3.1 상태 전환

```
IDLE → RESET (10us) → INTEGRATE (0-65535ms) → READOUT → COMPLETE → IDLE
```

### 3.2 타이밍 파라미터

| Parameter | Value | Description |
|-----------|-------|-------------|
| CLK_FREQ | 100 MHz | System clock |
| RESET_TIME | 10 us | 1000 cycles |
| ROW_CLK_DIV | 20 | Row clock divider |
| COL_CLK_DIV | 10 | Column clock divider |

### 3.3 ROI READOUT 시간 계산

```
Readout_Time = (ROW_END - ROW_START + 1) × (COL_END - COL_START + 1) × 200ns
```

---

## 4. 모듈 인터페이스

### 4.1 시스템 신호

| Port | Direction | Description |
|------|-----------|-------------|
| clk | Input | 100 MHz system clock |
| rst_n | Input | Active low reset |

### 4.2 SPI 인터페이스

| Port | Direction | Description |
|------|-----------|-------------|
| spi_sclk | Input | SPI clock (max 10 MHz) |
| spi_mosi | Input | SPI MOSI |
| spi_miso | Output | SPI MISO |
| spi_cs_n | Input | SPI chip select |

### 4.3 패널 타이밍

| Port | Direction | Description |
|------|-----------|-------------|
| row_addr[11:0] | Output | Row address |
| col_addr[11:0] | Output | Column address |
| row_clk_en | Output | Row clock enable |
| col_clk_en | Output | Column clock enable |
| gate_sel | Output | Gate select |
| gate_pulse | Output | Gate pulse |
| reset_pulse | Output | Reset pulse |
| frame_busy | Output | Frame busy flag |
| frame_complete | Output | Frame complete flag |

---

*EOFMANUAL
