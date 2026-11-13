# SPI UVM Verification IP (VIP)

Modular, reusable UVM 1.2 Verification IP generated for the external **SPI** interface of the VeeR EL2 Communication SoC.

## External Interface Signals

| Signal Name | Direction | Bit Width |
| :--- | :---: | :---: |
| `clk` | `input` | 1 |
| `rst_n` | `input` | 1 |
| `spi_clk_o` | `output` | 1 |
| `spi_cs_n_o` | `output` | 1 |
| `spi_mosi_o` | `output` | 1 |
| `spi_miso_i` | `input` | 1 |

## VIP Architecture

- **Interface (`spi_if.sv`)**: Protocol signal declarations (with `wire` for inout lines).
- **Transaction Item (`spi_item.sv`)**: Sequence item with randomized payload and `convert2string()`.
- **Sequencer (`spi_sequencer.sv`)**: Transaction sequencer feeding the driver.
- **Sequences (`spi_sequence.sv`)**: Base and randomized stimulus sequences mapped to test cases.
- **Driver (`spi_driver.sv`)**: Drives stimulus items to the virtual interface on active clock edges.
- **Monitor (`spi_monitor.sv`)**: Samples protocol lines and broadcasts transactions to the analysis port.
- **Agent (`spi_agent.sv`)**: Encapsulates sequencer, driver, and monitor.
- **Scoreboard (`spi_scoreboard.sv`)**: Checks transaction counts, protocol properties, and data integrity.
- **Environment (`spi_env.sv`)**: Instantiates and connects agent and scoreboard.
- **Test (`spi_test.sv`)**: UVM test raising objections and orchestrating stimulus.
- **Package (`spi_pkg.sv`)**: Compiles all UVM components into the `spi_pkg` namespace.
- **TB Top (`tb_top.sv`)**: Top-level harness generating clock/reset and invoking `run_test`.

## Documented Test Cases (22 Scenarios from CSV)

| Test Case ID | Test Scenario | Interface Type | Signals |
| :--- | :--- | :---: | :--- |
| `TC_SPI_VIP_RST_01` | Hardware Power-On Reset State | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_RST_02` | Software Reset Register Verification (SPI_SRR) | Internal | `None (Internal AHB/AXI-Lite Register Interface; SPI pins held inactive)` |
| `TC_SPI_VIP_FUNC_01` | Register Read/Write Access & Bit Masking | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_SPI_VIP_FUNC_02` | Single-Byte Master Transmit in SPI Mode 0 | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o` |
| `TC_SPI_VIP_FUNC_03` | Single-Byte Master Receive in SPI Mode 0 | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_FUNC_04` | Master Transmit/Receive in SPI Mode 1 (CPOL=0, CPHA=1) | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_FUNC_05` | Master Transmit/Receive in SPI Mode 2 (CPOL=1, CPHA=0) | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_FUNC_06` | Master Transmit/Receive in SPI Mode 3 (CPOL=1, CPHA=1) | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_FUNC_07` | Programmable Clock Divider Timing (SPI_RCLK) | External | `spi_clk_o, spi_cs_n_o` |
| `TC_SPI_VIP_FUNC_08` | Manual vs Automatic Slave Select Control | External | `spi_cs_n_o, spi_clk_o` |
| `TC_SPI_VIP_FUNC_09` | Multi-Byte Continuous Stream Burst Transfer | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_FUNC_10` | SPI Loopback Mode Transfer Verification | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i` |
| `TC_SPI_VIP_BND_01` | TX FIFO Full Condition & Overflow Protection | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_SPI_VIP_BND_02` | RX FIFO Full Condition & Status Indication | External | `spi_clk_o, spi_cs_n_o, spi_miso_i` |
| `TC_SPI_VIP_BND_03` | TX & RX FIFO Empty Status Flags Validation | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_SPI_VIP_BND_04` | Clock Divider Minimum and Maximum Frequency Limits | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o` |
| `TC_SPI_VIP_ERR_01` | Mode Fault (MODF) Detection & Recovery | External | `spi_cs_n_o, spi_clk_o, spi_mosi_o` |
| `TC_SPI_VIP_ERR_02` | TX FIFO Write Attempt When Core Disabled | External | `spi_clk_o, spi_cs_n_o, spi_mosi_o` |
| `TC_SPI_VIP_ERR_03` | Read Attempt from Empty RX Data Register (SPIDRR) | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_SPI_VIP_INT_01` | TX FIFO Empty Interrupt Assertion & Clearance | Internal | `None (Internal Interrupt Signal: spi_irq to PIC extintsrc_req[3])` |
| `TC_SPI_VIP_INT_02` | RX FIFO Not-Empty Interrupt Assertion & Clearance | External | `spi_clk_o, spi_cs_n_o, spi_miso_i` |
| `TC_SPI_VIP_INT_03` | PIC External Interrupt Source 3 Integration & ISR Service | Internal | `None (Internal PIC Interconnect: extintsrc_req[3])` |

## How to Compile & Run

```bash
./compile_vcs.sh   # Compile with Synopsys VCS
./run_sim.sh       # Run UVM simulation
```
