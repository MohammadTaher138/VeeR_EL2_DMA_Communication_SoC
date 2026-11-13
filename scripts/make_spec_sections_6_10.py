import docx
from docx.shared import Inches, Pt, RGBColor
from make_spec_common import (
    add_heading_1, add_heading_2, add_heading_3,
    add_body_p, add_bullet_p, add_callout, add_figure,
    create_styled_table, RGB_NAVY, RGB_SLATE, RGB_RUST, RGB_TEXT, RGB_MUTED
)

def build_section_6(doc):
    add_heading_1(doc, "6. Register Specification")
    add_body_p(doc, "This section documents the exact register bit-fields, offsets, access permissions, reset values, and behavioral descriptions extracted directly from the verified RTL sources and firmware driver headers.")

    add_heading_2(doc, "6.1 DMA Controller Registers (Base: 0x4000_0C00)")
    add_body_p(doc, "The DMA subsystem control and status registers occupy a 1 KB window at base address 0x4000_0C00, implemented in csr_dma.v.")

    # Table 6.1 DMA Register Map
    dma_map_headers = ["Offset", "Register Name", "Width", "Access", "Reset Value", "Functional Description"]
    dma_map_data = [
        ["0x00", "DMA_CTRL", "32-bit", "R / W", "0x0000_0000", "Master DMA Channel Control (Start, Abort, Mode, Interrupt Enable)"],
        ["0x08", "DMA_STATUS", "32-bit", "RO / W1C", "0x0000_0000", "Channel Status (Busy, Done, Error, FSM State, Remaining Bytes)"],
        ["0x10", "DMA_ERROR_ADDR", "32-bit", "RO", "0x0000_0000", "Bus Error Address Latch (Captures faulting address on AXI/AHB error)"],
        ["0x18", "DMA_ERROR_STATS", "32-bit", "RO / W1C", "0x0000_0000", "Detailed Error Flags (Bus Error, Address Misalignment, Size Violation)"],
        ["0x20", "DMA_DESC0_SRC", "32-bit", "R / W", "0x0000_0000", "Channel 0 Source Address Pointer (DCCM or Peripheral FIFO address)"],
        ["0x30", "DMA_DESC0_DST", "32-bit", "R / W", "0x0000_0000", "Channel 0 Destination Address Pointer (DCCM or Peripheral FIFO address)"],
        ["0x40", "DMA_DESC0_BYTES", "32-bit", "R / W", "0x0000_0000", "Transfer Length in Bytes (1 to 65,536 bytes; 0 = Inactive)"],
        ["0x50", "DMA_DESC0_CFG", "32-bit", "R / W", "0x0000_0000", "Transfer Configuration (Burst length, source/dest increment, widths)"]
    ]
    create_styled_table(doc, dma_map_headers, dma_map_data, [Inches(0.8), Inches(1.8), Inches(0.7), Inches(0.8), Inches(1.1), Inches(2.2)])

    # Bitfields for DMA_CTRL
    add_heading_3(doc, "DMA_CTRL Register (Offset: 0x00)")
    dma_ctrl_headers = ["Bits", "Field Name", "Access", "Reset", "Description & Operational Behavior"]
    dma_ctrl_data = [
        ["0", "START", "WO", "0", "Channel Start: Write 1 to launch programmed transfer. Self-clearing."],
        ["1", "ABORT", "WO", "0", "Transfer Abort: Write 1 to force immediate FSM transition to IDLE."],
        ["2", "IE", "RW", "0", "Interrupt Enable: 1 = Assert dma_done / dma_error IRQ to PIC."],
        ["4:3", "MODE[1:0]", "RW", "00", "Transfer Mode: 2'b00 = M2M, 2'b01 = M2P (TX), 2'b10 = P2M (RX)."],
        ["7:5", "BURST_SZ[2:0]", "RW", "000", "Max Burst Beat Size: 000=Single beat, 001=4 beats, 010=8 beats, 011=16 beats."],
        ["8", "CH_EN", "RW", "0", "Channel Enable: 1 = Channel active, 0 = Disabled."],
        ["31:9", "RESERVED", "RO", "0", "Reserved bits. Always write 0."]
    ]
    create_styled_table(doc, dma_ctrl_headers, dma_ctrl_data, [Inches(0.8), Inches(1.4), Inches(0.8), Inches(0.7), Inches(3.2)])

    # Bitfields for DMA_STATUS
    add_heading_3(doc, "DMA_STATUS Register (Offset: 0x08)")
    dma_stat_headers = ["Bits", "Field Name", "Access", "Reset", "Description & Operational Behavior"]
    dma_stat_data = [
        ["0", "BUSY", "RO", "0", "DMA Busy Flag: 1 = Engine is actively executing transfers."],
        ["1", "DONE", "W1C", "0", "Transfer Done Flag: Set high on completion. Write 1 to clear."],
        ["2", "ERROR", "W1C", "0", "Error Flag: Set high on bus error or alignment violation. Write 1 to clear."],
        ["6:3", "FSM_STATE[3:0]", "RO", "0000", "Current FSM State: 0=IDLE, 1=FETCH, 2=READ, 3=WRITE, 4=DONE, 5=ERR."],
        ["31:16", "BYTES_LEFT[15:0]", "RO", "0x0000", "Remaining Transfer Bytes: Real-time decrementing byte counter."]
    ]
    create_styled_table(doc, dma_stat_headers, dma_stat_data, [Inches(0.8), Inches(1.4), Inches(0.8), Inches(0.7), Inches(3.2)])

    add_heading_2(doc, "6.2 SPI Controller Registers (Base: 0x4000_6000)")
    add_body_p(doc, "The SPI subsystem registers implement the Xilinx-compatible AXI Quad SPI architecture. Base address is 0x4000_6000 (alias 0x4000_1000).")

    spi_map_headers = ["Offset", "Register Name", "Width", "Access", "Reset Value", "Functional Description"]
    spi_map_data = [
        ["0x1C", "GIER", "32-bit", "R / W", "0x0000_0000", "Global Interrupt Enable: Bit 31 enables IP interrupt assertion."],
        ["0x20", "ISR", "32-bit", "RO / W1C", "0x0000_0000", "Interrupt Status Register: Displays pending SPI events."],
        ["0x28", "IER", "32-bit", "R / W", "0x0000_0000", "Interrupt Enable Register: Enables specific event flags to generate IRQ."],
        ["0x40", "SRR", "32-bit", "WO", "0x0000_0000", "Software Reset Register: Write 0x0000_000A to soft-reset SPI core."],
        ["0x60", "CR", "32-bit", "R / W", "0x0000_0180", "SPI Control Register: Master enable, CPOL/CPHA, FIFO resets, manual SS."],
        ["0x64", "SR", "32-bit", "RO", "0x0000_0005", "SPI Status Register: FIFO empty/full flags, transfer progress."],
        ["0x68", "DTR", "32-bit", "WO", "0x0000_0000", "Data Transmit Register: Top of 16-deep 32-bit Transmit FIFO."],
        ["0x6C", "DRR", "32-bit", "RO", "0x0000_0000", "Data Receive Register: Top of 16-deep 32-bit Receive FIFO."],
        ["0x70", "SSR", "32-bit", "R / W", "0xFFFF_FFFF", "Slave Select Register: Active-low bitmask (Bit 0 asserts spi_ss_o[0])."]
    ]
    create_styled_table(doc, spi_map_headers, spi_map_data, [Inches(0.8), Inches(1.4), Inches(0.7), Inches(0.8), Inches(1.1), Inches(2.5)])

    # Bitfields for SPI CR
    add_heading_3(doc, "SPI Control Register (CR, Offset: 0x60)")
    spi_cr_headers = ["Bits", "Field Name", "Access", "Reset", "Description & Operational Behavior"]
    spi_cr_data = [
        ["0", "LOOP", "RW", "0", "Loopback Mode: 1 = Internal loopback enabled, 0 = Normal pin operation."],
        ["1", "SPE", "RW", "0", "SPI System Enable: 1 = Core operational, 0 = Core disabled."],
        ["2", "MASTER", "RW", "0", "Master Mode Select: 1 = Master mode (always 1 for this SoC)."],
        ["3", "CPOL", "RW", "0", "Clock Polarity: 0 = SCK low when idle, 1 = SCK high when idle."],
        ["4", "CPHA", "RW", "0", "Clock Phase: 0 = Data captured on first edge, 1 = Second edge."],
        ["5", "TX_RST", "WO", "0", "TX FIFO Reset: Write 1 to flush Transmit FIFO."],
        ["6", "RX_RST", "WO", "0", "RX FIFO Reset: Write 1 to flush Receive FIFO."],
        ["7", "MANUAL_SS", "RW", "1", "Manual Slave Select Assertion: 1 = Driven by SSR, 0 = Automatic."]
    ]
    create_styled_table(doc, spi_cr_headers, spi_cr_data, [Inches(0.8), Inches(1.4), Inches(0.8), Inches(0.7), Inches(3.2)])

    add_heading_2(doc, "6.3 I2C Master Controller Registers (Base: 0x4000_8000)")
    add_body_p(doc, "The I2C master controller registers implement the OpenCores Wishbone architecture at base address 0x4000_8000 (alias 0x4000_3000).")

    i2c_map_headers = ["Offset", "Register Name", "Width", "Access", "Reset Value", "Functional Description"]
    i2c_map_data = [
        ["0x00", "PRER_LO", "8-bit", "R / W", "0xFF", "Clock Prescaler Low Byte: SCL frequency divider low byte."],
        ["0x04", "PRER_HI", "8-bit", "R / W", "0xFF", "Clock Prescaler High Byte: SCL frequency divider high byte."],
        ["0x08", "CTR", "8-bit", "R / W", "0x00", "Control Register: Bit 7=EN (Core Enable), Bit 6=IEN (Interrupt Enable)."],
        ["0x0C", "TXR / RXR", "8-bit", "WO / RO", "0x00", "Transmit Register (Write) / Receive Register (Read)."],
        ["0x10", "CR / SR", "8-bit", "WO / RO", "0x00", "Command Register (Write) / Status Register (Read)."]
    ]
    create_styled_table(doc, i2c_map_headers, i2c_map_data, [Inches(0.8), Inches(1.4), Inches(0.7), Inches(0.8), Inches(1.1), Inches(2.5)])

    # Bitfields for I2C CR and SR
    add_heading_3(doc, "I2C Command & Status Registers (Offset: 0x10)")
    i2c_cr_headers = ["Bits", "Field Name", "Access", "Description & Operational Behavior"]
    i2c_cr_data = [
        ["CR[7]", "STA", "WO", "Generate repeated START condition on bus."],
        ["CR[6]", "STO", "WO", "Generate STOP condition on bus."],
        ["CR[5]", "RD", "WO", "Read byte from I2C bus slave."],
        ["CR[4]", "WR", "WO", "Write byte in TXR to I2C bus slave."],
        ["CR[3]", "ACK", "WO", "Acknowledge value to drive during read cycle: 0=ACK, 1=NACK."],
        ["CR[0]", "IACK", "WO", "Interrupt Acknowledge: Write 1 to clear pending interrupt flag."],
        ["SR[7]", "RXACK", "RO", "Received Acknowledge from slave: 0 = ACK received, 1 = NACK received."],
        ["SR[6]", "BUSY", "RO", "Bus Busy: 1 = I2C bus is actively held; set by START, cleared by STOP."],
        ["SR[5]", "AL", "RO", "Arbitration Lost: 1 = Core lost multi-master bus arbitration."],
        ["SR[1]", "TIP", "RO", "Transfer In Progress: 1 = Byte transmission or reception active."],
        ["SR[0]", "IF", "RO", "Interrupt Flag: 1 = Byte transferred or arbitration lost."]
    ]
    create_styled_table(doc, i2c_cr_headers, i2c_cr_data, [Inches(1.0), Inches(1.4), Inches(0.8), Inches(3.7)])

    add_heading_2(doc, "6.4 UART Controller Registers (Base: 0x4000_0000)")
    add_body_p(doc, "The UART controller implements standard 16550 registers at base address 0x4000_0000 (alias 0x4000_2000).")

    uart_map_headers = ["Offset", "Register Name", "Width", "Access", "Reset Value", "Functional Description"]
    uart_map_data = [
        ["0x00", "RBR / THR", "8-bit", "RO / WO", "0x00", "Receive Buffer Register (RO) / Transmitter Holding Register (WO)."],
        ["0x04", "IER", "8-bit", "R / W", "0x00", "Interrupt Enable Register: Bit 0=ERBFI (RX ready), Bit 1=ETBEI (TX empty)."],
        ["0x08", "BAUD_DIVISOR", "16-bit", "R / W", "0x01B2", "Baud Rate Divisor Latch: Divisor = 50,000,000 / (16 * Baud Rate)."],
        ["0x0C", "LCR", "8-bit", "R / W", "0x03", "Line Control Register: 8 data bits, 1 stop bit, no parity (8N1)."],
        ["0x14", "LSR", "8-bit", "RO", "0x60", "Line Status Register: Bit 0=DR (Data Ready), Bit 5=THRE, Bit 6=TEMT."]
    ]
    create_styled_table(doc, uart_map_headers, uart_map_data, [Inches(0.8), Inches(1.6), Inches(0.7), Inches(0.8), Inches(1.1), Inches(2.3)])

    add_heading_2(doc, "6.5 VeeR EL2 PIC & RISC-V Core CSRs")
    add_body_p(doc, "The VeeR EL2 Programmable Interrupt Controller registers are memory-mapped to 0xF00C_0000. Core-internal CSRs are accessed via standard RISC-V csrr/csrw instructions.")

    pic_map_headers = ["Address / CSR", "Register Name", "Access", "Description & Interrupt Control Function"]
    pic_map_data = [
        ["0xF00C_0004", "meipl[1]", "R / W", "Source 1 Priority Level: DMA Done interrupt priority (0 to 15)."],
        ["0xF00C_0008", "meipl[2]", "R / W", "Source 2 Priority Level: DMA Bus Error interrupt priority (0 to 15)."],
        ["0xF00C_000C", "meipl[3]", "R / W", "Source 3 Priority Level: SPI peripheral interrupt priority (0 to 15)."],
        ["0xF00C_0010", "meipl[4]", "R / W", "Source 4 Priority Level: UART peripheral interrupt priority (0 to 15)."],
        ["0xF00C_0014", "meipl[5]", "R / W", "Source 5 Priority Level: I2C peripheral interrupt priority (0 to 15)."],
        ["0xF00C_1004..14", "meip[1..5]", "RO / W1C", "Gateway Interrupt Pending Registers: Displays active pending peripheral requests."],
        ["0xF00C_3000", "meicpct", "RO", "Claim Pending Context: Returns ID and priority of highest pending interrupt."],
        ["0xF00C_3004", "meipt", "R / W", "Claim Priority Threshold: Interrupts with priority <= threshold are masked."],
        ["CSR 0xBC8", "meivt", "R / W", "Machine External Interrupt Vector Table Base Address."],
        ["CSR 0x300", "mstatus", "R / W", "Machine Status: Bit 3 (MIE) provides global interrupt enable."],
        ["CSR 0x304", "mie", "R / W", "Machine Interrupt Enable: Bit 11 (MEIE) enables external PIC interrupts."],
        ["CSR 0x344", "mip", "RO", "Machine Interrupt Pending: Bit 11 (MEIP) reflects PIC trigger to core."]
    ]
    create_styled_table(doc, pic_map_headers, pic_map_data, [Inches(1.4), Inches(1.3), Inches(0.8), Inches(3.4)])

def build_section_7(doc):
    add_heading_1(doc, "7. Detailed Control Path")
    
    add_heading_2(doc, "7.1 CPU Control Path Architecture")
    add_body_p(doc, "The CPU control path encompasses all instructions executed by the VeeR EL2 core to program peripheral configurations, initiate DMA channels, manage hardware FIFOs, and service interrupts. Figure 7.1 details the bus pathways and address translation mechanics utilized by the CPU.")

    add_figure(doc, "/tmp/soc_spec_diagrams/cpu_control_path.png", "Figure 7.1", 
               "CPU Control Path Diagram showing VeeR EL2 LSU instruction execution, AXI-to-AHB bridge, Address Decoder, and Peripheral CSR Mapping.", width=Inches(6.4))

    add_heading_2(doc, "7.2 Step-by-Step Firmware Programming Sequences")
    
    add_heading_3(doc, "7.2.1 CPU Initialization Sequence")
    add_bullet_p(doc, "Set exception vector base, initialize stack pointer (sp = 0x0000_2000), and configure Machine Trap Vector (mtvec).", bold_prefix="1. Core Setup: ")
    add_bullet_p(doc, "Write meipt = 0 (allow all priorities > 0), set meipl[1..5] to assigned levels (1..15), and set meivt to the vector table base.", bold_prefix="2. PIC Setup: ")
    add_bullet_p(doc, "Write mstatus.MIE = 1 and mie.MEIE = 1 to unmask external interrupts in the RISC-V core pipeline.", bold_prefix="3. CSR Unmask: ")

    add_heading_3(doc, "7.2.2 DMA Transfer Configuration & Descriptor Setup")
    add_bullet_p(doc, "Firmware writes DMA_DESC0_SRC = 0xF004_1000 (Source DCCM buffer pointer).", bold_prefix="Step 1: ")
    add_bullet_p(doc, "Firmware writes DMA_DESC0_DST = 0x4000_6068 (Destination SPI DTR FIFO address).", bold_prefix="Step 2: ")
    add_bullet_p(doc, "Firmware writes DMA_DESC0_BYTES = 64 (Payload length: 64 bytes).", bold_prefix="Step 3: ")
    add_bullet_p(doc, "Firmware writes DMA_DESC0_CFG = 0x0000_0121 (SRC_INC=1, DST_INC=0, BURST=4 beats).", bold_prefix="Step 4: ")
    add_bullet_p(doc, "Firmware writes DMA_CTRL = 0x0000_0105 (CH_EN=1, IE=1, MODE=M2P, START=1).", bold_prefix="Step 5: ")

    add_heading_3(doc, "7.2.3 SPI Peripheral Setup & Activation")
    add_bullet_p(doc, "Write SPI SRR (0x40) = 0x0A (Software reset; flushes FIFOs and resets shift registers).", bold_prefix="1. Soft Reset: ")
    add_bullet_p(doc, "Write SPI CR (0x60) = 0x0186 (SPE=1, Master=1, Manual SS=1, CPOL=0, CPHA=0).", bold_prefix="2. Mode Config: ")
    add_bullet_p(doc, "Write SPI SSR (0x70) = 0xFFFFFFFE (Asserts chip select 0 low to target slave).", bold_prefix="3. Slave Select: ")

    add_heading_3(doc, "7.2.4 I2C Peripheral Setup & Command Execution")
    add_bullet_p(doc, "Write PRER_LO = 0x63, PRER_HI = 0x00 (Prescaler = 99 for 100 kHz SCL from 50 MHz clock).", bold_prefix="1. Clock Prescale: ")
    add_bullet_p(doc, "Write CTR = 0x80 (Core Enable bit EN = 1).", bold_prefix="2. Core Enable: ")
    add_bullet_p(doc, "Write TXR = {Slave_Addr, 1'b0} (Slave write address), then write CR = 0x90 (STA + WR).", bold_prefix="3. START & Addr: ")
    add_bullet_p(doc, "Poll SR[1] (TIP) until transmission finishes, verify SR[7] (RXACK == 0).", bold_prefix="4. Handshake: ")

    add_heading_2(doc, "7.3 Interrupt Servicing & Completion Sequence")
    add_body_p(doc, "When a transfer concludes, hardware and software interact via a deterministic handshake:")
    add_bullet_p(doc, "DMA asserts dma_done; pic_interrupt_glue pulses extintsrc_req[1].", bold_prefix="1. Hardware Trigger: ")
    add_bullet_p(doc, "VeeR PIC latches meip[1], evaluates priority > meipt, and drives core interrupt line.", bold_prefix="2. PIC Arbitration: ")
    add_bullet_p(doc, "Core completes current instruction, pushes PC to mepc, sets mcause = 0x8000000B, and vectors to ISR.", bold_prefix="3. Pipeline Trap: ")
    add_bullet_p(doc, "ISR reads meicpct to identify Source 1 (DMA Done).", bold_prefix="4. Claim: ")
    add_bullet_p(doc, "ISR writes 1 to DMA_STATUS.DONE (clearing flag) and writes 1 to meip[1] (clearing PIC gateway).", bold_prefix="5. Acknowledge: ")
    add_bullet_p(doc, "ISR executes mret instruction; core resumes baseline execution.", bold_prefix="6. Return: ")

def build_section_8(doc):
    add_heading_1(doc, "8. Detailed Data Path")
    
    add_heading_2(doc, "8.1 DMA Data Path Architecture")
    add_body_p(doc, "The SoC data path has been architected to achieve maximum transfer throughput between memory and peripherals while eliminating bus bottlenecks. Figure 8.1 depicts the DMA data routing mechanism, showing the separation between dedicated DCCM accesses and peripheral AHB-Lite transfers.")

    add_figure(doc, "/tmp/soc_spec_diagrams/dma_data_path.png", "Figure 8.1", 
               "DMA Data Path Diagram showing DMA Engine, Address Router, Dedicated 64-bit Core DMA Slave Port, DCCM SRAM, and AHB-Lite Interconnect.", width=Inches(6.4))

    add_heading_2(doc, "8.2 Transmit Data Path: DCCM to SPI/I2C")
    add_body_p(doc, "During memory-to-peripheral (TX) acceleration, data flows along the following stages:")
    add_bullet_p(doc, "The DMA master drives m_axi_araddr = 0xF004_1000. The router forwards this to the dedicated slave port (dma_axi_araddr). The core DCCM arbiter grants access, and DCCM returns 64 bits of data in 1 clock cycle.", bold_prefix="Phase 1 (DCCM Read): ")
    add_bullet_p(doc, "The 64-bit data word is latched into the DMA internal holding register. The byte-packing engine splits the double-word into 32-bit or 8-bit slices depending on target peripheral width.", bold_prefix="Phase 2 (Internal Slicing): ")
    add_bullet_p(doc, "The DMA router directs m_axi_awaddr = 0x4000_6068 (SPI DTR) to dma_axi4_to_ahb_adapter. The adapter initiates an AHB write (HADDR=0x4000_6068, HWDATA=data_word).", bold_prefix="Phase 3 (AHB Write): ")
    add_bullet_p(doc, "The ahb2axi_spi bridge converts AHB to AXI-Lite and pushes the word into the 16-deep SPI Transmit FIFO.", bold_prefix="Phase 4 (FIFO Push): ")
    add_bullet_p(doc, "The SPI shift register pops the FIFO and shifts bits serially out of spi_mosi_o on consecutive SCK clock edges.", bold_prefix="Phase 5 (Serialization): ")

    add_heading_2(doc, "8.3 Receive Data Path: SPI/I2C to DCCM")
    add_body_p(doc, "During peripheral-to-memory (RX) acceleration, the process operates in reverse:")
    add_bullet_p(doc, "Serial bits arriving on spi_miso_i or sda_pad_i are deserialized into internal byte/word registers. For SPI, words accumulate in the 16-deep DRR FIFO.", bold_prefix="Phase 1 (Deserialization): ")
    add_bullet_p(doc, "The DMA adapter acquires the AHB bus and executes an AHB read to SPI DRR (0x4000_606C) or I2C RXR (0x4000_800C).", bold_prefix="Phase 2 (Peripheral Read): ")
    add_bullet_p(doc, "The incoming bytes are assembled into a 64-bit quad-word in the DMA engine holding register.", bold_prefix="Phase 3 (Packing): ")
    add_bullet_p(doc, "The DMA router steers m_axi_awaddr = 0xF004_2000 into the dedicated core DMA slave port. The write completes into DCCM SRAM in a single clock cycle.", bold_prefix="Phase 4 (DCCM Single-Cycle Write): ")

    add_heading_2(doc, "8.4 Bus Widths, Lane Steering & Transfer Latencies")
    add_body_p(doc, "Table 8.1 details the bus parameters, lane steering mechanics, and cycle latencies across each stage of the data path.")

    path_param_headers = ["Data Path Segment", "Bus Protocol", "Native Data Width", "Transfer Sizing", "Typical Latency (Cycles)"]
    path_param_data = [
        ["Core LSU to DCCM", "Direct Core Bus", "64-bit", "8-bit, 16-bit, 32-bit, 64-bit", "1 cycle (Zero wait states)"],
        ["DMA to Dedicated Slave Port", "AMBA AXI4", "64-bit", "32-bit word, 64-bit double", "1 cycle address + 1 cycle data"],
        ["DMA to AHB System Interconnect", "AMBA AHB-Lite", "64-bit", "32-bit word, 64-bit burst", "2 cycles per single beat"],
        ["AHB to SPI Controller", "AXI-Lite Bridge", "32-bit", "32-bit word (Lane [31:0])", "3 cycles (Bridge + FIFO push)"],
        ["AHB to I2C Master", "Wishbone Bridge", "8-bit", "8-bit byte (Lane [7:0])", "4 cycles (Bridge + WB handshake)"],
        ["AHB to UART Controller", "AXI-Lite Bridge", "8/32-bit", "8-bit byte (Lane [7:0])", "3 cycles (Bridge + Reg write)"]
    ]
    create_styled_table(doc, path_param_headers, path_param_data, [Inches(1.8), Inches(1.2), Inches(1.0), Inches(1.6), Inches(1.3)])

def build_section_9(doc):
    add_heading_1(doc, "9. DMA Architecture and Operation")
    
    add_heading_2(doc, "9.1 DMA Engine Architecture & FSM Pipeline")
    add_body_p(doc, "The DMA subsystem core (dma_axi_wrapper) is a high-performance transfer engine governed by a robust finite state machine. The FSM states include:")
    add_bullet_p(doc, "Channel idle; waiting for DMA_CTRL.START assertion.", bold_prefix="IDLE (4'b0000): ")
    add_bullet_p(doc, "Latches programmed descriptors (SRC, DST, BYTES, CFG) and calculates burst boundaries.", bold_prefix="FETCH_DESC (4'b0001): ")
    add_bullet_p(doc, "Drives AXI read address channel (AR) and collects read beats on R data channel.", bold_prefix="READ_SRC (4'b0010): ")
    add_bullet_p(doc, "Drives AXI write address channel (AW) and streams beats on W data channel.", bold_prefix="WRITE_DST (4'b0011): ")
    add_bullet_p(doc, "Decrements remaining byte counter. Loops back to READ_SRC if BYTES > 0.", bold_prefix="BURST_UPDATE (4'b0100): ")
    add_bullet_p(doc, "Asserts dma_done interrupt line, updates DMA_STATUS.DONE, and returns to IDLE.", bold_prefix="DONE (4'b0101): ")
    add_bullet_p(doc, "Latches fault address into DMA_ERROR_ADDR, asserts dma_error IRQ, and halts.", bold_prefix="ERROR (4'b0110): ")

    add_heading_2(doc, "9.2 Transfer Modes & Descriptor Engine")
    add_body_p(doc, "The DMA controller supports three primary operational modes:")
    add_bullet_p(doc, "Moves data blocks between two DCCM regions. Both source and destination accesses use the dedicated 64-bit core DMA slave port, achieving maximum data throughput (up to 400 MB/s at 50 MHz).", bold_prefix="Memory-to-Memory (M2M): ")
    add_bullet_p(doc, "Reads source data from DCCM via the dedicated slave port and writes into peripheral FIFOs (SPI DTR / UART THR / I2C TXR) across the AHB interconnect.", bold_prefix="Memory-to-Peripheral (M2P): ")
    add_bullet_p(doc, "Reads incoming peripheral data across AHB and deposits payloads into DCCM via the dedicated slave port.", bold_prefix="Peripheral-to-Memory (P2M): ")

    add_heading_2(doc, "9.3 Dedicated VeeR EL2 DMA Slave Interface Integration")
    add_body_p(doc, "In strict adherence to the Western Digital VeeR EL2 Programmer's Reference Manual, the core provides an external 64-bit AXI4 slave port dedicated exclusively to DCCM access. Integrating this port directly with the DMA router yields three critical advantages:")
    add_bullet_p(doc, "Eliminates AHB bus contention between DMA DCCM accesses and CPU peripheral accesses.")
    add_bullet_p(doc, "Guarantees deterministic, single-cycle SRAM access timing.")
    add_bullet_p(doc, "Preserves full 64-bit data path bandwidth directly into the memory core.")

    add_heading_2(doc, "9.4 32-bit and 64-bit Alignment Rules & Access Sizing")
    add_body_p(doc, "The VeeR EL2 DCCM memory array is organized as 64-bit words with byte-write enables. To prevent memory corruption and ECC faults, the DMA enforces strict alignment rules:")
    add_bullet_p(doc, "64-bit transfers must be 8-byte aligned (addr[2:0] == 3'b000). Strobes wstrb[7:0] are asserted simultaneously.", bold_prefix="Double-Word (64-bit): ")
    add_bullet_p(doc, "32-bit transfers must be 4-byte aligned (addr[1:0] == 2'b00). For lower-word access (addr[2]==0), wstrb[3:0] is asserted; for upper-word (addr[2]==1), wstrb[7:4] is asserted.", bold_prefix="Word (32-bit): ")
    add_bullet_p(doc, "If an unaligned address is programmed, the DMA halts immediately and raises the ADDR_UNALIGNED error flag in DMA_ERROR_STATS.", bold_prefix="Error Handling: ")

    add_heading_2(doc, "9.5 CPU vs DMA DCCM Arbitration & mfdc.dqc Handshake")
    add_body_p(doc, "When the CPU LSU and the dedicated DMA slave port simultaneously request DCCM access, the VeeR EL2 core internal arbiter resolves contention:")
    add_bullet_p(doc, "By default, the CPU LSU is granted priority to prevent pipeline stalls during time-critical loops.", bold_prefix="Default Arbitration: ")
    add_bullet_p(doc, "The RISC-V Machine Feature Disable Control CSR (mfdc.dqc, bit 18) controls DMA queue throttling, ensuring that burst DMA accesses do not starve the processor.", bold_prefix="DMA Queue Control (DQC): ")
    add_bullet_p(doc, "The memory controller asserts dccm_ready to throttle the DMA when the CPU claims a back-to-back memory cycle.", bold_prefix="Throttle Handshake: ")

def build_section_10(doc):
    add_heading_1(doc, "10. Peripheral Specifications")
    
    add_heading_2(doc, "10.1 Serial Peripheral Interface (SPI)")
    add_body_p(doc, "Figure 10.1 illustrates the complete hardware data path for DMA-accelerated SPI transfers.")

    add_figure(doc, "/tmp/soc_spec_diagrams/spi_dma_transfer.png", "Figure 10.1", 
               "DMA-Accelerated SPI Transfer Architecture showing DCCM Buffer, DMA Engine, AHB Interconnect, AXI-Lite Bridge, Dual 16-deep FIFOs, and Physical SPI Pins.", width=Inches(6.4))

    add_heading_3(doc, "10.1.1 Overview & Functional Features")
    add_body_p(doc, "The SPI controller (axi_spi_top) is an AMBA AXI Quad SPI master IP core fully compatible with industry-standard serial flash, sensor, and display devices. Features include:")
    add_bullet_p(doc, "Dual 16-entry deep by 32-bit wide Transmit (DTR) and Receive (DRR) FIFOs.")
    add_bullet_p(doc, "Full duplex master operation with programmable baud rate up to clk/2 (25 MHz).")
    add_bullet_p(doc, "Configurable clock polarity (CPOL) and phase (CPHA) supporting Modes 0, 1, 2, and 3.")
    add_bullet_p(doc, "Manual and automatic chip select assertion (spi_ss_o[0]).")
    add_bullet_p(doc, "Independent interrupt generation for TX FIFO empty, RX FIFO full, and overrun events.")

    add_heading_3(doc, "10.1.2 Clocking and Protocol Modes")
    add_body_p(doc, "Table 10.1 outlines the four SPI operational modes supported by the core.")
    spi_modes_headers = ["Mode", "CPOL", "CPHA", "SCK Idle State", "Data Capture Edge", "Data Shift Edge"]
    spi_modes_data = [
        ["Mode 0", "0", "0", "Low (0)", "Rising Edge (First)", "Falling Edge (Second)"],
        ["Mode 1", "0", "1", "Low (0)", "Falling Edge (Second)", "Rising Edge (First)"],
        ["Mode 2", "1", "0", "High (1)", "Falling Edge (First)", "Rising Edge (Second)"],
        ["Mode 3", "1", "1", "High (1)", "Rising Edge (Second)", "Falling Edge (First)"]
    ]
    create_styled_table(doc, spi_modes_headers, spi_modes_data, [Inches(1.0), Inches(0.8), Inches(0.8), Inches(1.4), Inches(1.5), Inches(1.4)])

    add_heading_2(doc, "10.2 Inter-Integrated Circuit (I²C) Master Interface")
    add_body_p(doc, "Figure 10.2 depicts the DMA-accelerated I2C transmission and reception architecture.")

    add_figure(doc, "/tmp/soc_spec_diagrams/i2c_dma_transfer.png", "Figure 10.2", 
               "DMA-Accelerated I2C Transfer Architecture showing DCCM Buffer, DMA Engine, AHB Interconnect, Wishbone Bridge, I2C Master Core, and Physical Open-Drain Bus Pins.", width=Inches(6.4))

    add_heading_3(doc, "10.2.1 Overview & Functional Features")
    add_body_p(doc, "The I2C master controller (i2c_master_top) provides an OpenCores-compatible two-wire serial interface supporting multi-byte master transfers. Features include:")
    add_bullet_p(doc, "Support for Standard mode (100 kbps) and Fast mode (400 kbps) operation.")
    add_bullet_p(doc, "Programmable 16-bit clock prescaler derived from the 50 MHz system clock.")
    add_bullet_p(doc, "Automated generation of START, Repeated START, and STOP conditions.")
    add_bullet_p(doc, "Hardware acknowledge detection (ACK/NACK) and multi-master arbitration loss detection.")
    add_bullet_p(doc, "DMA handshake integration enabling continuous burst streaming.")

    add_heading_3(doc, "10.2.2 Clock Prescaler Calculation")
    add_body_p(doc, "The I2C serial clock (SCL) frequency is configured via prescale registers PRER_LO and PRER_HI according to the formula:")
    add_callout(doc,
        "I2C PRESCALER FORMULA:\n"
        "PRER = (System_Clock / (5 * SCL_Frequency)) - 1\n\n"
        "Example for 100 kHz Standard Mode (System Clock = 50 MHz):\n"
        "PRER = (50,000,000 / (5 * 100,000)) - 1 = 100 - 1 = 99 (0x0063)\n"
        "Result: Write PRER_LO = 0x63, PRER_HI = 0x00.\n\n"
        "Example for 400 kHz Fast Mode (System Clock = 50 MHz):\n"
        "PRER = (50,000,000 / (5 * 400,000)) - 1 = 25 - 1 = 24 (0x0018)\n"
        "Result: Write PRER_LO = 0x18, PRER_HI = 0x00.",
        title="I2C SCL PRESCALER CALCULATION", alert_type="NOTE")

    add_heading_2(doc, "10.3 Universal Asynchronous Receiver Transmitter (UART)")
    add_heading_3(doc, "10.3.1 Overview & Functional Features")
    add_body_p(doc, "The UART controller (axi_uart_top) implements an industry-standard 16550 architecture. Features include:")
    add_bullet_p(doc, "Standard 8N1 serial frame format (8 data bits, no parity, 1 stop bit).")
    add_bullet_p(doc, "Programmable 16-bit baud rate divisor matching standard rates (115200, 57600, 38400, 9600 bps).")
    add_bullet_p(doc, "Holding registers for transmit (THR) and receive (RBR) with line status flags (LSR.THRE, LSR.DR).")
    add_bullet_p(doc, "Dedicated interrupt output (uart_irq) routed directly to PIC Source 4.")

    add_heading_3(doc, "10.3.2 Baud Rate Generator Formula")
    add_body_p(doc, "The UART baud rate is calculated using the 16-bit BAUD_DIVISOR register:")
    add_callout(doc,
        "UART BAUD DIVISOR FORMULA:\n"
        "BAUD_DIVISOR = System_Clock / (16 * Baud_Rate)\n\n"
        "Example for 115,200 bps (System Clock = 50 MHz):\n"
        "BAUD_DIVISOR = 50,000,000 / (16 * 115,200) = 50,000,000 / 1,843,200 ≈ 27.126 -> Divisor = 27 (0x001B)\n"
        "Actual Baud: 115,740 bps (0.47% error, well within standard 2% UART tolerance).\n\n"
        "Example for 9,600 bps (System Clock = 50 MHz):\n"
        "BAUD_DIVISOR = 50,000,000 / (16 * 9,600) = 50,000,000 / 153,600 ≈ 325.52 -> Divisor = 326 (0x0146).",
        title="UART BAUD RATE CALCULATION", alert_type="NOTE")
