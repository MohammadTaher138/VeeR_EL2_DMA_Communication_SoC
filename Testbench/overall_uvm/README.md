# VeeR EL2 RISC-V Communication SoC Overall UVM Testbench Environment

A complete, standard UVM 1.2 verification environment integrating external peripheral Verification IPs (VIPs) for **SPI**, **I²C**, and **UART**, coupled with an internal **passive AHB-Lite bus monitor**, central transaction-level scoreboard, functional coverage collector, and virtual sequencer/sequences connected directly to the actual SoC top RTL module (`RTL/top_veer_soc.sv`).

---

## 1. Directory Structure

```text
Testbench/
|-- SPI/                      # Existing SPI VIP (interface, agent, driver, monitor, sequences)
|-- I2C/                      # Existing I2C VIP (interface, agent, driver, monitor, sequences)
|-- UART/                     # Existing UART VIP (interface, agent, driver, monitor, sequences)
|-- DMA/                      # DMA verification testbench (tb_axi_dma.sv)
|
`-- overall_uvm/              # Complete Overall SoC UVM Environment
    |-- interfaces/
    |   `-- ahb_lite_mon_if.sv     # Passive AHB-Lite bus monitoring interface
    |
    |-- packages/
    |   `-- soc_uvm_pkg.sv         # Top-level SoC UVM package (includes env, agents, sequences, tests)
    |
    |-- agents/
    |   |-- ahb_monitor/           # Passive AHB bus monitoring agent
    |   |   |-- ahb_item.sv        # AHB sequence item with address decoder/target ID
    |   |   |-- ahb_monitor.sv     # Pipelined AHB address/data phase passive monitor
    |   |   `-- ahb_agent.sv       # Passive-only agent (no master/driver)
    |   |-- spi_agent -> ../../SPI # Symbolic link to peripheral SPI VIP
    |   |-- i2c_agent -> ../../I2C # Symbolic link to peripheral I2C VIP
    |   `-- uart_agent -> ../../UART # Symbolic link to peripheral UART VIP
    |
    |-- drivers/                   # Peripheral driver references
    |   |-- spi_driver.sv -> ../../SPI/spi_driver.sv
    |   |-- i2c_driver.sv -> ../../I2C/i2c_driver.sv
    |   `-- uart_driver.sv -> ../../UART/uart_driver.sv
    |
    |-- sequences/
    |   |-- soc_base_sequence.sv   # Base virtual sequence with p_sequencer declaration
    |   `-- soc_virtual_sequence.sv# Multi-VIP virtual sequences (independent & concurrent traffic)
    |
    |-- env/
    |   |-- soc_config.sv          # Environment configuration object (active/passive, clock, reset)
    |   |-- soc_virtual_sequencer.sv # Coordinates SPI, I2C, and UART sequencers
    |   |-- soc_scoreboard.sv      # Central scoreboard with protocol, data integrity & AHB checks
    |   |-- soc_coverage.sv        # Functional coverage collector for all protocols + cross-coverage
    |   `-- soc_env.sv             # Root UVM environment connecting agents, scoreboard & coverage
    |
    |-- tests/
    |   `-- soc_overall_test.sv    # Top-level UVM test running full integration sequence
    |
    |-- top/
    |   `-- tb_top_veer_soc.sv     # Top-level harness instantiating actual SoC DUT (top_veer_soc)
    |
    |-- scripts/
    |   |-- compile.sh             # Compiles overall environment with Synopsys VCS
    |   |-- run.sh                 # Executes simulation with simv
    |   `-- clean.sh               # Removes simulation and compilation artifacts
    |
    |-- firmware.hex               # Preloaded boot ROM hex binary for VeeR EL2 CPU
    |-- run_uvm.f                  # VCS filelist including RTL, VIPs, and overall testbench
    `-- README.md                  # Verification environment documentation
```

---

## 2. Overall UVM Architecture

```
                                  +---------------------------------------+
                                  |            soc_overall_test           |
                                  +---------------------------------------+
                                                      |
                                          +-----------------------+
                                          |        soc_env        |
                                          +-----------------------+
                                                      |
    +-------------------------------------------------+---------------------------------------------+
    |                         |                       |                      |                      |
+-------+                 +-------+               +-------+              +-------+             +----------+
|  SPI  |                 |  I2C  |               | UART  |              |  AHB  |             | Virtual  |
| Agent |                 | Agent |               | Agent |              | Agent |             |Sequencer |
+-------+                 +-------+               +-------+              +-------+             +----------+
    |                         |                       |                      |                      |
 (Driver,                  (Driver,                (Driver,              (Passive               (Coordinates
 Sequencer,                Sequencer,              Sequencer,             Monitor                SPI, I2C &
  Monitor)                  Monitor)                Monitor)               Only)                 UART seqr)
    |                         |                       |                      |                      |
    +-------------------------+-----------------------+----------------------+                      |
                              |                                              |                      |
                              v                                              v                      v
                 +--------------------------+                   +-----------------------+   +-------------------+
                 |      soc_scoreboard      |                   |      soc_coverage     |   | Virtual Sequences |
                 |--------------------------|                   |-----------------------|   |-------------------|
                 | - SPI MISO/MOSI check    |                   | - SPI Covergroup      |   | - Sequential Indep|
                 | - I2C START/STOP/level   |                   | - I2C Covergroup      |   | - Simultaneous    |
                 | - UART frame & flow ctrl |                   | - UART Covergroup     |   |   Concurrent      |
                 | - AHB Subsystem mapping  |                   | - AHB Bus Covergroup  |   | - Full Integrated |
                 | - 0 Data Mismatches      |                   | - Cross-Protocol Cov  |   +-------------------+
                 +--------------------------+                   +-----------------------+
                              ^                                              ^
                              |                                              |
    ==========================+==============================================+========================
    Hardware Pin & Probe Layer:
       spi_if (vif)           | spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i
       i2c_if (vif)           | i2c_scl, i2c_sda (bidirectional open-drain with pullups)
       uart_if (vif)          | uart_tx_o, uart_rx_i, uart_rts_o, uart_cts_i
       ahb_lite_mon_if (vif)  | sys_haddr, sys_htrans, sys_hwrite, sys_hsize, sys_hwdata, sys_hrdata, sys_hready
    ==================================================================================================
                              |
                     +-----------------+
                     |  top_veer_soc   | (Actual VeeR EL2 SoC RTL DUT)
                     +-----------------+
```

---

## 3. Peripheral VIP Integration & Driver Support

All three peripheral VIPs are fully connected to their respective DUT pins:

1. **SPI VIP (`Testbench/SPI`)**:
   - Master/Slave support via `spi_if`
   - Active driver (`spi_driver.sv`) sending transactions to `spi_vif`
   - Monitor (`spi_monitor.sv`) sampling clock, chip select, MOSI, and MISO
   - Scoreboard verification validates MISO/MOSI loopback integrity when `spi_cs_n_o == 0`.

2. **I²C VIP (`Testbench/I2C`)**:
   - Master/Slave support via `i2c_if`
   - Active driver (`i2c_driver.sv`)
   - Monitor (`i2c_monitor.sv`) sampling bidirectional open-drain `i2c_scl` and `i2c_sda`
   - Scoreboard checks valid logic levels (detects illegal 'X' states) and START/STOP conditions.

3. **UART VIP (`Testbench/UART`)**:
   - TX/RX serial interface via `uart_if`
   - Active driver (`uart_driver.sv`)
   - Monitor (`uart_monitor.sv`) sampling `uart_tx_o`, `uart_rx_i`, `uart_rts_o`, `uart_cts_i`
   - Scoreboard validates non-X levels and hardware flow-control handshake.

4. **Passive AHB-Lite Bus Monitor (`Testbench/overall_uvm/agents/ahb_monitor`)**:
   - Strictly passive observation of internal SoC bus: `sys_haddr`, `sys_htrans`, `sys_hwrite`, `sys_hsize`, `sys_hwdata`, `sys_hrdata`, `sys_hready`, `sys_hresp`.
   - Captures pipelined address and data phases when `sys_hready` is asserted.
   - Maps memory spaces to peripheral subsystems (`SPI`, `UART`, `I2C`, `DMA_CSR`, `DCCM`).

---

## 4. Virtual Sequencer & Multi-VIP Sequences

- **`soc_virtual_sequencer`**: Contains handles `spi_seqr`, `i2c_seqr`, `uart_seqr` connected in `soc_env::connect_phase`.
- **`soc_base_sequence`**: Uses `uvm_declare_p_sequencer(soc_virtual_sequencer)`.
- **`soc_independent_traffic_seq`**: Coordinates sequential execution of `spi_random_seq`, `i2c_random_seq`, and `uart_random_seq`.
- **`soc_concurrent_traffic_seq`**: Forks simultaneous traffic across SPI, I2C, and UART.
- **`soc_full_integration_seq`**: Executes both independent and concurrent verification phases.

---

## 5. Central Scoreboard & Functional Coverage

### Scoreboard (`soc_scoreboard.sv`)
- **Protocol & Data Integrity Checks**: Checks SPI loopback integrity, I2C START/STOP condition sequencing, UART flow-control backpressure, and AHB response error codes (`hresp`).
- **AHB Subsystem Activation Tracking**: Correlates CPU MMIO register accesses to peripheral address spaces (SPI @ `0x40001000`, UART @ `0x40002000`, I2C @ `0x40003000`, DMA @ `0x40000C00`).
- **Zero-Tolerance Error Reporting**: Flags missing transactions, data mismatches, protocol errors, or unexpected states.

### Functional Coverage (`soc_coverage.sv`)
- `spi_cg`: SPI Chip-Select active/inactive, clock low/high, MOSI/MISO bits, CS × SCLK cross.
- `i2c_cg`: I2C SCL low/high, SDA low/high, SCL × SDA cross.
- `uart_cg`: UART TX low/high, RX low/high, RTS asserted/deasserted, CTS ready/not ready.
- `concurrent_protocol_cg`: 3-way cross-coverage of simultaneous SPI, I2C, and UART activity.
- `ahb_bus_cg`: Read/Write transfer directions, transfer sizes (byte, halfword, word, dword), target peripheral subsystems.

---

## 6. UVM Tests

1. **`soc_overall_test` (Default Full Integration Test)**:
   - Starts `soc_full_integration_seq`.
   - Executes sequential independent and concurrent simultaneous SPI, I2C, and UART sequences.
   - Monitors internal AHB-Lite bus while CPU boots firmware and exercises peripherals.
   - Verifies 100% of scoreboard checks and functional coverage.

2. **`soc_construction_test` (Construction-Only Test)**:
   - Verifies all 13 structural checks (DUT instantiation, environment, 3 protocol agents, passive AHB monitor, virtual sequencer, configuration distribution, virtual interfaces, scoreboard, and coverage collector).
   - Operates without launching any peripheral stimulus sequences.
   - Completes cleanly with 0 UVM fatal/error messages.

---

## 7. How to Compile & Run

### Using Scripts:
```bash
cd Testbench/overall_uvm

# 1. Compile with Synopsys VCS
./scripts/compile.sh

# 2. Run default full integration test
./scripts/run.sh

# 3. Run construction-only verification test
./scripts/run.sh +UVM_TESTNAME=soc_construction_test

# 4. Clean generated simulation artifacts
./scripts/clean.sh
```

### Using Root Testbench Makefile:
```bash
cd Testbench

# Compile and run the overall UVM testbench
make overall

# Clean all artifacts
make clean
```
