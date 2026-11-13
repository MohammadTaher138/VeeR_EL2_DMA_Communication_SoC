# I2C UVM Verification IP (VIP)

Modular, reusable UVM 1.2 Verification IP generated for the external **I2C** interface of the VeeR EL2 Communication SoC.

## External Interface Signals

| Signal Name | Direction | Bit Width |
| :--- | :---: | :---: |
| `clk` | `input` | 1 |
| `rst_n` | `input` | 1 |
| `i2c_scl` | `inout` | 1 |
| `i2c_sda` | `inout` | 1 |

## VIP Architecture

- **Interface (`i2c_if.sv`)**: Protocol signal declarations (with `wire` for inout lines).
- **Transaction Item (`i2c_item.sv`)**: Sequence item with randomized payload and `convert2string()`.
- **Sequencer (`i2c_sequencer.sv`)**: Transaction sequencer feeding the driver.
- **Sequences (`i2c_sequence.sv`)**: Base and randomized stimulus sequences mapped to test cases.
- **Driver (`i2c_driver.sv`)**: Drives stimulus items to the virtual interface on active clock edges.
- **Monitor (`i2c_monitor.sv`)**: Samples protocol lines and broadcasts transactions to the analysis port.
- **Agent (`i2c_agent.sv`)**: Encapsulates sequencer, driver, and monitor.
- **Scoreboard (`i2c_scoreboard.sv`)**: Checks transaction counts, protocol properties, and data integrity.
- **Environment (`i2c_env.sv`)**: Instantiates and connects agent and scoreboard.
- **Test (`i2c_test.sv`)**: UVM test raising objections and orchestrating stimulus.
- **Package (`i2c_pkg.sv`)**: Compiles all UVM components into the `i2c_pkg` namespace.
- **TB Top (`tb_top.sv`)**: Top-level harness generating clock/reset and invoking `run_test`.

## Documented Test Cases (21 Scenarios from CSV)

| Test Case ID | Test Scenario | Interface Type | Signals |
| :--- | :--- | :---: | :--- |
| `TC_I2C_VIP_RST_01` | Power-On Reset & Default Register States | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_RST_02` | Core Enable/Disable Control via CTR | Internal | `None (AHB/Wishbone Register Interface)` |
| `TC_I2C_VIP_FUNC_01` | Clock Prescaler Configuration & SCL Timing | External | `i2c_scl` |
| `TC_I2C_VIP_FUNC_02` | Bus START Condition Generation | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_03` | 7-Bit Slave Addressing & Write Transfer | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_04` | Master Single-Byte Data Write Transfer | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_05` | Master Single-Byte Data Read with Master NACK | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_06` | Repeated START Condition Generation | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_07` | Bus STOP Condition Generation | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_08` | Multi-Byte Sequential Write Transfer | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_09` | Multi-Byte Sequential Read Transfer with Master ACK/NACK | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_FUNC_10` | Standard Mode (100 kHz) vs Fast Mode (400 kHz) Operation | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_BND_01` | Maximum and Minimum Prescaler Values (PRER) | External | `i2c_scl` |
| `TC_I2C_VIP_BND_02` | Slave SCL Clock Stretching Handshake | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_BND_03` | Consecutive START and STOP Back-to-Back Sequences | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_ERR_01` | Slave Address NACK Detection & Bus Recovery | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_ERR_02` | Slave Data NACK Detection During Write Transfer | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_ERR_03` | Multi-Master Arbitration Lost (AL) Condition | External | `i2c_scl, i2c_sda` |
| `TC_I2C_VIP_INT_01` | Byte Transfer Complete (TIP Drop) Interrupt Assertion | Internal | `None (Internal Interrupt Signal: i2c_wb_inta_o to PIC extintsrc_req[5])` |
| `TC_I2C_VIP_INT_02` | Interrupt Acknowledge via IACK (CR[0]) | Internal | `None (AHB/Wishbone Register Interface)` |
| `TC_I2C_VIP_INT_03` | PIC External Interrupt Source 5 Integration & ISR Service | Internal | `None (Internal PIC Interconnect: extintsrc_req[5])` |

## How to Compile & Run

```bash
./compile_vcs.sh   # Compile with Synopsys VCS
./run_sim.sh       # Run UVM simulation
```
