# UART UVM Verification IP (VIP)

Modular, reusable UVM 1.2 Verification IP generated for the external **UART** interface of the VeeR EL2 Communication SoC.

## External Interface Signals

| Signal Name | Direction | Bit Width |
| :--- | :---: | :---: |
| `clk` | `input` | 1 |
| `rst_n` | `input` | 1 |
| `uart_tx_o` | `output` | 1 |
| `uart_rx_i` | `input` | 1 |
| `uart_rts_o` | `output` | 1 |
| `uart_cts_i` | `input` | 1 |

## VIP Architecture

- **Interface (`uart_if.sv`)**: Protocol signal declarations (with `wire` for inout lines).
- **Transaction Item (`uart_item.sv`)**: Sequence item with randomized payload and `convert2string()`.
- **Sequencer (`uart_sequencer.sv`)**: Transaction sequencer feeding the driver.
- **Sequences (`uart_sequence.sv`)**: Base and randomized stimulus sequences mapped to test cases.
- **Driver (`uart_driver.sv`)**: Drives stimulus items to the virtual interface on active clock edges.
- **Monitor (`uart_monitor.sv`)**: Samples protocol lines and broadcasts transactions to the analysis port.
- **Agent (`uart_agent.sv`)**: Encapsulates sequencer, driver, and monitor.
- **Scoreboard (`uart_scoreboard.sv`)**: Checks transaction counts, protocol properties, and data integrity.
- **Environment (`uart_env.sv`)**: Instantiates and connects agent and scoreboard.
- **Test (`uart_test.sv`)**: UVM test raising objections and orchestrating stimulus.
- **Package (`uart_pkg.sv`)**: Compiles all UVM components into the `uart_pkg` namespace.
- **TB Top (`tb_top.sv`)**: Top-level harness generating clock/reset and invoking `run_test`.

## Documented Test Cases (21 Scenarios from CSV)

| Test Case ID | Test Scenario | Interface Type | Signals |
| :--- | :--- | :---: | :--- |
| `TC_UART_VIP_RST_01` | Power-On Reset State of Line Status & Control Registers | External | `uart_tx_o, uart_rx_i` |
| `TC_UART_VIP_RST_02` | Software Reset & FIFO Initialization | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_UART_VIP_FUNC_01` | Programmable Baud Rate Generator (115200 Baud Divisor) | External | `uart_tx_o` |
| `TC_UART_VIP_FUNC_02` | Single Character Transmission (8-N-1 Format) | External | `uart_tx_o` |
| `TC_UART_VIP_FUNC_03` | Multi-Character String Stream Transmission | External | `uart_tx_o` |
| `TC_UART_VIP_FUNC_04` | Single Character Reception (8-N-1 Format) | External | `uart_rx_i` |
| `TC_UART_VIP_FUNC_05` | Multi-Character Burst Reception into RX FIFO | External | `uart_rx_i` |
| `TC_UART_VIP_FUNC_06` | Transmitter Holding Register Empty (THRE) Flag Operation | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_UART_VIP_FUNC_07` | Transmitter Empty (TEMT) Shift Completion Flag Operation | External | `uart_tx_o` |
| `TC_UART_VIP_FUNC_08` | Line Control Register (UART_LCR) Stop Bits Configuration | External | `uart_tx_o` |
| `TC_UART_VIP_FUNC_09` | Hardware Flow Control Handshake (CTS/RTS) | External | `uart_tx_o, uart_cts_i, uart_rts_o` |
| `TC_UART_VIP_BND_01` | RX FIFO Full Depth Capacity Verification | External | `uart_rx_i` |
| `TC_UART_VIP_BND_02` | Zero Inter-Frame Delay Streaming Transmission | External | `uart_rx_i` |
| `TC_UART_VIP_BND_03` | Standard Baud Rates Accuracy (9600, 57600, 115200 Baud) | External | `uart_tx_o` |
| `TC_UART_VIP_ERR_01` | Stop Bit Framing Error Detection & Recovery | External | `uart_rx_i` |
| `TC_UART_VIP_ERR_02` | RX FIFO Overrun Error Condition | External | `uart_rx_i` |
| `TC_UART_VIP_ERR_03` | False Start Bit Glitch Suppression | External | `uart_rx_i` |
| `TC_UART_VIP_ERR_04` | Non-Decoded Read Address Bus Protection | Internal | `None (AHB/AXI-Lite Register Interface)` |
| `TC_UART_VIP_INT_01` | RX Data Ready Interrupt Assertion (read_interrupt_o) | External | `uart_rx_i` |
| `TC_UART_VIP_INT_02` | RX Interrupt Deassertion via UART_RBR Read | Internal | `None (Internal Interrupt Signal: uart_irq to PIC extintsrc_req[4])` |
| `TC_UART_VIP_INT_03` | PIC External Interrupt Source 4 Integration & ISR Service | External | `uart_rx_i` |

## How to Compile & Run

```bash
./compile_vcs.sh   # Compile with Synopsys VCS
./run_sim.sh       # Run UVM simulation
```
