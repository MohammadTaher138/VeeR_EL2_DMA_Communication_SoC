import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from make_spec_common import (
    add_heading_1, add_heading_2, add_heading_3,
    add_body_p, add_bullet_p, add_callout, add_figure,
    create_styled_table, RGB_NAVY, RGB_SLATE, RGB_RUST, RGB_TEXT, RGB_MUTED
)

def build_cover_and_control(doc):
    # Title Page
    p_pre = doc.add_paragraph()
    p_pre.paragraph_format.space_before = Pt(36)
    p_pre.paragraph_format.space_after = Pt(12)
    run_pre = p_pre.add_run("ADVANCED RISC-V SYSTEM-ON-CHIP SPECIFICATION")
    run_pre.font.name = "Arial"
    run_pre.font.size = Pt(11)
    run_pre.font.bold = True
    run_pre.font.color.rgb = RGB_SLATE

    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(6)
    p_title.paragraph_format.space_after = Pt(12)
    p_title.paragraph_format.line_spacing = 1.1
    run_title = p_title.add_run("Design and Verification of a VeeR EL2-Based Communication SoC with DMA-Accelerated SPI and I²C")
    run_title.font.name = "Arial"
    run_title.font.size = Pt(22)
    run_title.font.bold = True
    run_title.font.color.rgb = RGB_NAVY

    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_before = Pt(4)
    p_sub.paragraph_format.space_after = Pt(28)
    run_sub = p_sub.add_run("System Architecture, Memory Map, Register Interface, Hardware Control/Data Paths, and Verification Specification")
    run_sub.font.name = "Arial"
    run_sub.font.size = Pt(12)
    run_sub.font.color.rgb = RGB_SLATE

    # Metadata Table
    meta_headers = ["Attribute", "Specification Value"]
    meta_data = [
        ["Document Identifier", "SOC-SPEC-2026-REV1.0"],
        ["Document Version", "Revision 1.0 (Final Approved Specification)"],
        ["Publication Date", "November 7, 2026"],
        ["Document Status", "APPROVED / PRODUCTION READY (100% Verification Closure)"],
        ["Target Architecture", "Western Digital VeeR EL2 RISC-V Core Complex (RV32IMC)"],
        ["System Bus Standard", "64-bit AMBA AHB-Lite Interconnect with Cycle-by-Cycle Arbitration"],
        ["Direct Memory Access", "AXI4 64-bit Master with Dedicated 64-bit Core DMA Slave Port"],
        ["Communication IPs", "AXI Quad SPI (16-Deep FIFOs), Wishbone I2C Master, 16550 UART"],
        ["Interrupt Controller", "Core-Integrated Programmable Interrupt Controller (PIC) with 15 Priorities"],
        ["Primary Authors", "SoC Architecture & Design Verification Engineering Group"],
        ["Security Classification", "STRICTLY CONFIDENTIAL — PROPRIETARY SYSTEM SPECIFICATION"]
    ]
    create_styled_table(doc, meta_headers, meta_data, [Inches(2.3), Inches(4.6)])

    add_callout(doc, 
        "SCOPE LOCK MANDATE: This specification strictly documents the implemented hardware modules comprising the Western Digital VeeR EL2 RISC-V core complex, the 64-bit AHB-Lite interconnect, the multi-channel DMA controller, the dedicated 64-bit DMA slave port interface, the 64 KB DCCM tightly-coupled SRAM, the 8 KB instruction boot ROM, the Xilinx-compatible AXI Quad SPI controller, the OpenCores Wishbone I2C master controller, the 16550-compatible UART, the core-internal Programmable Interrupt Controller (PIC), and the associated UVM 1.2 verification testbench. All other peripheral functions (including General Purpose I/O, General-Purpose Timers, Pulse Width Modulators, and external PLIC devices) are out of scope and intentionally excluded from the architecture.",
        title="ARCHITECTURAL SCOPE LOCK", alert_type="IMPORTANT")

    doc.add_page_break()

    # Document History
    add_heading_1(doc, "Document History & Revision Control")
    add_body_p(doc, "This document undergoes formal engineering review under strict change management protocols. Every revision corresponds to verified functional RTL states, gate-level checks, and comprehensive UVM regression runs.")

    hist_headers = ["Rev", "Date", "Description / Major Architectural Updates", "Author / Role", "Approval"]
    hist_data = [
        ["0.1", "2026-08-25", "Initial SoC architectural concept, VeeR EL2 selection, and bus topology definition.", "Architecture Team", "Lead Architect"],
        ["0.5", "2026-09-30", "Integration of 64-bit AHB-Lite interconnect, address decoder, and peripheral bridges.", "RTL Design Team", "SoC Lead"],
        ["0.8", "2026-10-15", "Addition of DMA subsystem, CSR definitions, and initial UVM environment bring-up.", "DV Engineering", "DV Lead"],
        ["0.9", "2026-10-31", "Architectural audit, integration of dedicated 64-bit core DMA slave port, and DCCM route verification.", "SoC Systems Team", "Chief Architect"],
        ["1.0", "2026-11-07", "Final comprehensive SoC hardware specification with 100% regression and functional coverage closure.", "Architecture & DV", "Project Director"]
    ]
    create_styled_table(doc, hist_headers, hist_data, [Inches(0.6), Inches(1.1), Inches(2.9), Inches(1.3), Inches(1.0)])

    # Table of Contents
    add_heading_1(doc, "Table of Contents")
    toc_items = [
        ("1. Introduction", "Project Overview, Purpose, Scope, Objectives, and System Features"),
        ("2. System Architecture", "Overall Architecture, Block Diagram, Subsystems, Data/Control Paths"),
        ("3. Block Inventory", "Inventory Table, RTL Module Names, Interfaces, and Peer Connectivity"),
        ("4. Address Map", "Master Memory Map, Peripheral Registers, DCCM Aliasing, and Address Decoding"),
        ("5. Interface and Signal Specification", "AHB-Lite, DMA Master/Slave AXI4, DCCM, SPI, I2C, UART, PIC, Clocks/Reset"),
        ("6. Register Specification", "DMA CSRs, SPI CSRs, I2C Registers, UART Registers, and VeeR PIC CSRs"),
        ("7. Detailed Control Path", "CPU Initialization, DMA Configuration, SPI/I2C Setup, and ISR Servicing"),
        ("8. Detailed Data Path", "Bus Widths, Lane Steering, DCCM-to-SPI/I2C Transfers, and Latencies"),
        ("9. DMA Architecture and Operation", "FSM, Descriptors, Dedicated Slave Port, 32/64-bit Sizing, CPU Arbitration"),
        ("10. Peripheral Specifications", "In-depth Specifications for SPI (AXI Quad SPI), I2C, and UART Controllers"),
        ("11. Interrupt Specification", "PIC Source Mapping, Priority Gateways, Glue Synchronization, Core Servicing"),
        ("12. Clock and Reset Specification", "Single 50 MHz Synchronous Domain, Reset Tree, Power-On Boot Vector"),
        ("13. Verification Architecture", "UVM Testbench Architecture, VIPs, 9 Covergroups, Milestones, 10 Regression Tests"),
        ("14. Design Constraints and Limitations", "Bandwidth, Alignment Boundaries, FIFO Depths, Single Outstanding Request"),
        ("15. Conclusion", "Summary of Architectural Achievements, Silicon Readiness, and Verification Closure")
    ]
    toc_headers = ["Section", "Section Title & Core Technical Content"]
    create_styled_table(doc, toc_headers, toc_items, [Inches(2.5), Inches(4.4)])

    doc.add_page_break()

def build_section_1(doc):
    add_heading_1(doc, "1. Introduction")
    
    add_heading_2(doc, "1.1 Project Overview")
    add_body_p(doc, "The Design and Verification of a VeeR EL2-Based Communication SoC with DMA-Accelerated SPI and I²C addresses the critical performance bottleneck associated with peripheral data transfers in embedded systems. In standard microcontroller architectures, the central processing unit (CPU) must actively orchestrate every byte transferred between system memory and low-speed communication peripherals via programmed input/output (PIO) loops or high-latency interrupt service routines (ISRs). This PIO paradigm severely throttles compute efficiency, wasting CPU instruction execution cycles on trivial memory loads, peripheral status checks, and data writes.")
    add_body_p(doc, "To overcome these performance penalties, this SoC integrates an ultra-low-power, high-performance Western Digital VeeR EL2 32-bit RISC-V processor core (RV32IMC) with an advanced multi-channel Direct Memory Access (DMA) controller. The DMA engine features dual master routing capability: high-bandwidth local memory accesses bypass the system interconnect and communicate directly with the processor's Data Closely Coupled Memory (DCCM) via a dedicated 64-bit AXI4 core DMA slave port, while peripheral transactions traverse a 64-bit AMBA AHB-Lite system interconnect.")
    add_body_p(doc, "The SoC incorporates three industry-standard serial communication peripherals: an AXI Quad Serial Peripheral Interface (SPI) controller with 16-deep FIFOs, an OpenCores Wishbone Inter-Integrated Circuit (I²C) master controller supporting standard (100 kbps) and fast (400 kbps) modes, and an industry-standard 16550 Universal Asynchronous Receiver Transmitter (UART) core. Interrupt management is handled by an on-chip, core-internal Programmable Interrupt Controller (PIC) providing 15 prioritized levels, fast vectored dispatch, and zero-overhead interrupt claim cycles.")

    add_heading_2(doc, "1.2 Purpose of the Specification")
    add_body_p(doc, "This System Specification document serves as the formal architectural reference and design verification contract for the VeeR EL2 Communication SoC. It defines:")
    add_bullet_p(doc, "The complete structural hierarchy, RTL module partitioning, and top-level interconnect.", bold_prefix="System Architecture: ")
    add_bullet_p(doc, "The exhaustive physical memory map, peripheral register ranges, and aliased address regions.", bold_prefix="Memory Organization: ")
    add_bullet_p(doc, "Cycle-accurate signal definitions, bus widths, protocol handshakes, and pin-level multiplexing.", bold_prefix="Interface Specifications: ")
    add_bullet_p(doc, "Bit-level definitions, field descriptions, access privileges, and reset states for all control registers.", bold_prefix="Register Definitions: ")
    add_bullet_p(doc, "Step-by-step firmware programming flows, hardware transfer state machines, and arbitration protocols.", bold_prefix="Control & Data Paths: ")
    add_bullet_p(doc, "The comprehensive Universal Verification Methodology (UVM 1.2) testbench architecture, functional covergroups, and regression results.", bold_prefix="Verification Framework: ")

    add_heading_2(doc, "1.3 Scope of the Project")
    add_body_p(doc, "The scope of this project encompasses the complete register-transfer level (RTL) design, integration, firmware validation, and functional verification of the SoC. Specifically, the documented scope includes:")
    add_bullet_p(doc, "Western Digital VeeR EL2 RISC-V Core Complex (RV32IMC, 4-stage in-order pipeline, machine-mode only).")
    add_bullet_p(doc, "64-bit AMBA AHB-Lite System Interconnect with cycle-by-cycle multi-master arbitration.")
    add_bullet_p(doc, "Multi-Channel DMA Engine with dual AXI4 master routing (Dedicated Core Slave Port vs. AHB Adapter).")
    add_bullet_p(doc, "Dedicated 64-bit AXI4 VeeR EL2 DMA Slave Interface connecting directly to local DCCM memory.")
    add_bullet_p(doc, "64 KB Single-Cycle Data Closely Coupled Memory (DCCM) supporting 32-bit and 64-bit accesses.")
    add_bullet_p(doc, "8 KB Instruction Boot ROM loaded from initialization hex image (firmware.hex).")
    add_bullet_p(doc, "Xilinx-compatible AXI Quad SPI IP core with dual 16x32-bit hardware FIFOs.")
    add_bullet_p(doc, "OpenCores Wishbone I²C Master IP core with programmable baud rate prescaler and byte controller.")
    add_bullet_p(doc, "16550-compatible UART IP core for serial diagnostics, console logging, and status reporting.")
    add_bullet_p(doc, "Core-internal Programmable Interrupt Controller (PIC) supporting 15 priority levels and 5 peripheral IRQ lines.")
    add_bullet_p(doc, "Single 50 MHz synchronous system clock tree and active-low synchronous reset network.")
    add_bullet_p(doc, "Comprehensive UVM 1.2 testbench environment with automated scoreboards, VIPs, and 9 functional covergroups.")

    add_heading_2(doc, "1.4 Design Objectives")
    add_body_p(doc, "The SoC architecture has been engineered to fulfill five primary technical objectives:")
    add_bullet_p(doc, "Eliminate CPU polling during bulk serial transfers by offloading memory-to-peripheral (M2P) and peripheral-to-memory (P2M) operations to the DMA engine.", bold_prefix="CPU Offload & Throughput: ")
    add_bullet_p(doc, "Provide single-cycle, contention-free memory access to the processor's DCCM via a dedicated 64-bit AXI4 slave port, bypassing system bus arbitration.", bold_prefix="Low-Latency Memory Access: ")
    add_bullet_p(doc, "Implement standardized AMBA AHB-Lite and AXI4 bus protocols, ensuring modularity, reusable bridge logic, and predictable cycle timing.", bold_prefix="Standardized Protocol Interconnect: ")
    add_bullet_p(doc, "Incorporate hardware FIFOs, configurable clock dividers, and flexible SPI/I²C transfer modes to interface with a wide range of external devices.", bold_prefix="Robust Peripheral Control: ")
    add_bullet_p(doc, "Attain 100% functional test closure, zero UVM error reports, and verified hardware/firmware co-simulation across 30 milestone test cases.", bold_prefix="Verification Rigor: ")

    add_heading_2(doc, "1.5 System Features & Key Parameters")
    add_body_p(doc, "Table 1.1 summarizes the foundational engineering specifications, clock frequencies, bus widths, and operational parameters of the SoC.")

    params_headers = ["Subsystem Parameter", "Specification Value", "Architectural Description"]
    params_data = [
        ["Processor Core", "Western Digital VeeR EL2", "RV32IMC ISA, 4-stage scalar in-order pipeline, Machine mode only"],
        ["System Clock Frequency", "50.0 MHz (20.0 ns cycle)", "Single synchronous clock domain distributed to all cores and peripherals"],
        ["Primary System Bus", "64-bit AMBA AHB-Lite", "Connects CPU LSU master and DMA adapter master to slave peripherals"],
        ["Dedicated DMA Slave Bus", "64-bit AMBA AXI4", "Direct low-latency coupling between DMA master and VeeR EL2 DCCM"],
        ["Data Closely Coupled Memory", "64 KB Single-Cycle SRAM", "Base 0xF004_0000; aliased to 0x0000_0000; 64-bit data path with ECC logic"],
        ["Instruction Memory / ROM", "8 KB Boot ROM / 64 KB ICCM", "Boot ROM base at 0x4000_0000; ICCM at 0xEE00_0000; 64-bit fetch bus"],
        ["DMA Controller", "Custom AXI4 Master Core", "Supports M2M, M2P, P2M modes; 1B to 64KB bursts; 32/64-bit lane alignment"],
        ["SPI Controller", "AXI Quad SPI (Xilinx-compat)", "16x32-bit TX/RX FIFOs; Master mode; CPOL=0/1, CPHA=0/1; up to 25 MHz SCK"],
        ["I²C Master Controller", "Wishbone I²C (OpenCores)", "Standard (100 kbps) and Fast (400 kbps) speeds; programmable 16-bit prescaler"],
        ["UART Controller", "16550 Compatible Core", "Programmable baud generator; 8N1 frame format; TX/RX holding registers"],
        ["Interrupt Controller", "VeeR EL2 Internal PIC", "15 priority levels; 5 peripheral external interrupt sources; fast vectoring"],
        ["Silicon Process Target", "CMOS Synthesizable RTL", "Full synchronous design; no internal derived clocks; single active-low reset"]
    ]
    create_styled_table(doc, params_headers, params_data, [Inches(1.8), Inches(2.2), Inches(2.9)])

def build_section_2(doc):
    add_heading_1(doc, "2. System Architecture")
    
    add_heading_2(doc, "2.1 Complete SoC Architecture Overview")
    add_body_p(doc, "The VeeR EL2 Communication SoC utilizes a hybrid dual-bus topology optimized for high-bandwidth communication and minimal CPU latency. The system centers around the Western Digital VeeR EL2 processor core, which executes RISC-V 32-bit instructions from an 8 KB Boot ROM or 64 KB ICCM, and manipulates application data residing in a 64 KB tightly-coupled DCCM SRAM.")
    add_body_p(doc, "A critical architectural innovation is the separation of control and data traffic. Control traffic—such as peripheral configuration, status polling, and interrupt acknowledgement—is driven by the CPU's Load-Store Unit (LSU) over an LSU AXI-to-AHB bridge into a 64-bit AHB-Lite interconnect. High-volume data transfers—such as moving communication payloads between DCCM buffers and peripheral FIFOs—are managed autonomously by the DMA controller.")
    add_body_p(doc, "The DMA master is coupled to an intelligent address router (dma_axi_master_router). When the DMA initiates a transfer targeting DCCM memory addresses (0x0000_xxxx or 0xF004_xxxx), the router steers the request directly into the VeeR EL2 core's dedicated 64-bit AXI4 DMA slave port. This dedicated path bypasses the AHB-Lite system bus entirely, enabling single-cycle, zero-wait-state memory reads and writes without arbitrating against CPU peripheral accesses.")

    add_heading_2(doc, "2.2 Detailed System Block Diagram")
    add_body_p(doc, "Figure 2.1 illustrates the complete block-level architectural schematic of the SoC, displaying the processor complex, tightly-coupled memories, bus bridges, DMA engine, router, peripherals, and interrupt network.")

    add_figure(doc, "/tmp/soc_spec_diagrams/soc_overall_block_diagram.png", "Figure 2.1", 
               "Complete Block Diagram of the VeeR EL2 Communication SoC showing Core, Dedicated DMA Slave Port, DCCM, AHB-Lite Interconnect, Peripherals, and PIC Interrupts.", width=Inches(6.4))

    add_heading_2(doc, "2.3 Subsystem Detailed Architectural Breakdown")
    
    add_heading_3(doc, "2.3.1 VeeR EL2 RV32IMC Processor Core Subsystem")
    add_body_p(doc, "The Western Digital VeeR EL2 is a 4-stage, scalar, in-order execution processor core implementing the RISC-V RV32IMC instruction set architecture. It incorporates a sophisticated branch predictor with a Branch Target Buffer (BTB) and Direction Predictor, an efficient integer multiply/divide execution unit, and dual 64-bit memory interfaces: an Instruction Fetch Unit (IFU) AXI4 master interface for fetching code, and a Load-Store Unit (LSU) AXI4 master interface for data operations.")
    add_body_p(doc, "In addition to standard interfaces, the VeeR EL2 core integrates a dedicated 64-bit AXI4 DMA slave port (u_veer.dma_axi_*). This port grants external bus masters direct access to the core's internal DCCM SRAM. Internal core arbitration guarantees deterministic access between CPU pipeline stalls and external DMA requests, governed by the Machine Feature Disable Control (MFDC.DQC) register.")

    add_heading_3(doc, "2.3.2 64-bit AHB-Lite System Interconnect & Multi-Master Bus Arbiter")
    add_body_p(doc, "The system interconnect implements the AMBA AHB-Lite 64-bit protocol standard. It acts as the primary communication backbone for all peripheral transactions. Two bus masters compete for interconnect ownership:")
    add_bullet_p(doc, "The primary master for peripheral initialization, register configuration, and status polling.", bold_prefix="Master 0: CPU LSU Master (via u_lsu_axi2ahb): ")
    add_bullet_p(doc, "The secondary master used when the DMA moves data to/from peripheral FIFOs.", bold_prefix="Master 1: DMA Master (via dma_axi4_to_ahb_adapter): ")
    add_body_p(doc, "A cycle-by-cycle bus arbiter arbitrates access between Master 0 and Master 1. By default, the CPU LSU is assigned higher priority to ensure immediate response to critical control operations. However, during active DMA peripheral bursts, the DMA adapter holds bus ownership across burst beats using HMASTLOCK assertions to preserve burst integrity.")

    add_heading_3(doc, "2.3.3 Address Decoder (address_decoder) & Memory Mapping Logic")
    add_body_p(doc, "The address decoder monitors the 32-bit AHB address bus (HADDR) during the address phase and asserts one-hot slave select lines (HSEL_*). The decoding rules partition the address space into dedicated 4 KB / 1 KB peripheral windows and memory ranges. Slaves return transfer response signals (HREADY, HRESP) back through a multiplexer to the active bus master.")

    add_heading_3(doc, "2.3.4 DMA Controller Subsystem (dma_axi_wrapper)")
    add_body_p(doc, "The DMA subsystem is an autonomous, descriptor-driven, multi-mode data transfer engine. It comprises a set of AHB-accessible control/status registers (csr_dma.v), an internal transfer finite state machine (FSM), address calculation logic, and an AXI4 64-bit master interface. The engine supports Memory-to-Memory (M2M), Memory-to-Peripheral (M2P), and Peripheral-to-Memory (P2M) modes. Transfer sizes from 1 byte up to 64 KB are handled seamlessly, with automatic byte packing/unpacking across 32-bit and 64-bit bus boundaries.")

    add_heading_3(doc, "2.3.5 DMA Address Router (dma_axi_master_router) & Dedicated Slave Port")
    add_body_p(doc, "The dma_axi_master_router module sits between the DMA master port and the system fabric. It inspects the upper address bits of every read and write transaction initiated by the DMA:")
    add_bullet_p(doc, "The router forwards the transaction directly to the VeeR EL2 dedicated 64-bit AXI4 DMA slave port. Address normalization logic maps low-memory aliased addresses (0x0000_xxxx) to the physical DCCM range {16'hF004, addr[15:0]}.", bold_prefix="DCCM Access (0x0000_xxxx or 0xF004_xxxx): ")
    add_bullet_p(doc, "The router forwards the transaction to the dma_axi4_to_ahb_adapter, driving the AHB-Lite interconnect to access SPI, I2C, or UART registers.", bold_prefix="Peripheral Access (0x4000_xxxx): ")

    add_heading_3(doc, "2.3.6 DCCM RAM Subsystem (soc_dccm_ram)")
    add_body_p(doc, "The Data Closely Coupled Memory provides 64 KB of high-speed SRAM storage directly coupled to the processor. It operates at the full 50 MHz core frequency with zero wait states. It features dual access paths: one internal path to the VeeR EL2 execution pipeline and one external path via the core's dedicated DMA slave interface.")

    add_heading_3(doc, "2.3.7 Instruction Boot ROM Subsystem (soc_ifu_boot_rom)")
    add_body_p(doc, "The Instruction Boot ROM provides 8 KB of non-volatile read-only storage mapped to base address 0x4000_0000. It is pre-loaded at simulation and synthesis time with the system firmware binary (firmware.hex). Upon power-on reset deassertion, the VeeR EL2 Instruction Fetch Unit fetches its first instruction from address 0x4000_0000.")

    add_heading_3(doc, "2.3.8 SPI Master Subsystem (axi_spi_top)")
    add_body_p(doc, "The SPI controller is a Xilinx-compatible AXI Quad SPI core mapped to base address 0x4000_6000 (with an alias at 0x4000_1000). It features independent 16-entry by 32-bit Transmit (DTR) and Receive (DRR) hardware FIFOs, programmable clock polarity and phase (CPOL, CPHA), and hardware slave select generation (SSR). It connects to the AHB bus via an ahb2axi_lite_bridge.")

    add_heading_3(doc, "2.3.9 I2C Master Subsystem (i2c_master_top)")
    add_body_p(doc, "The I2C master is an OpenCores-compatible Wishbone core mapped to base address 0x4000_8000 (with an alias at 0x4000_3000). It supports standard (100 kbps) and fast (400 kbps) serial speeds. It features an internal 16-bit prescaler, a byte-level transfer state machine, automatic ACK/NACK generation, and bus arbitration detection. It connects to AHB via an ahb2wishbone_bridge.")

    add_heading_3(doc, "2.3.10 UART Subsystem (axi_uart_top)")
    add_body_p(doc, "The UART controller is a standard 16550-compatible serial communication core mapped to base address 0x4000_0000 (with an alias at 0x4000_2000). It includes a programmable baud rate generator, 8N1 framing, transmit holding register (THR), receive buffer register (RBR), and line status monitoring (LSR). It connects to AHB via an ahb2axi_lite_bridge.")

    add_heading_3(doc, "2.3.11 Programmable Interrupt Controller (PIC) & Glue (pic_interrupt_glue)")
    add_body_p(doc, "Interrupt management is performed by the VeeR EL2 core-internal PIC (el2_pic_ctrl.sv). The PIC is mapped to address space 0xF00C_0000 and is accessed with zero wait states by the CPU LSU via an internal dedicated PICM bus. External peripheral interrupts (DMA Done, DMA Error, SPI IRQ, UART IRQ, I2C IRQ) are conditioned and synchronized by pic_interrupt_glue before driving PIC source inputs extintsrc_req[5:1].")

    add_heading_2(doc, "2.4 CPU-to-Peripheral Communication Path")
    add_body_p(doc, "When firmware running on the VeeR EL2 CPU configures or queries a peripheral, the access follows a deterministic path:")
    add_bullet_p(doc, "The CPU executes a 32-bit load or store instruction (e.g., lw, sw) targeting address range 0x4000_xxxx.", bold_prefix="1. Pipeline Execution: ")
    add_bullet_p(doc, "The LSU issues a 64-bit AXI4 transaction to the u_lsu_axi2ahb bridge.", bold_prefix="2. Core LSU Interface: ")
    add_bullet_p(doc, "The bridge converts the AXI transaction into an AHB-Lite transfer (HADDR, HWDATA, HWRITE).", bold_prefix="3. AHB Conversion: ")
    add_bullet_p(doc, "The address decoder evaluates HADDR and asserts the appropriate peripheral select line (HSEL_SPI, HSEL_I2C, HSEL_UART, or HSEL_DMA).", bold_prefix="4. Address Decoding: ")
    add_bullet_p(doc, "The target protocol bridge (AHB-to-AXI-Lite or AHB-to-Wishbone) translates AHB signaling into peripheral-native bus cycles.", bold_prefix="5. Protocol Adaptation: ")
    add_bullet_p(doc, "The peripheral register updates or returns data, asserting HREADY to release the CPU pipeline.", bold_prefix="6. Completion: ")

    add_heading_2(doc, "2.5 DMA-to-DCCM Communication Path (Dedicated Port Architecture)")
    add_body_p(doc, "When the DMA controller accesses DCCM SRAM, data travels over an isolated, high-performance path completely detached from the AHB-Lite bus:")
    add_bullet_p(doc, "The DMA master drives an AXI4 read or write request targeting DCCM memory (0x0000_xxxx or 0xF004_xxxx).", bold_prefix="1. DMA Request: ")
    add_bullet_p(doc, "The dma_axi_master_router intercepts the request, detects the DCCM address range, and normalizes the upper 16 bits to 16'hF004.", bold_prefix="2. Router Interception: ")
    add_bullet_p(doc, "The request is driven onto the VeeR EL2 dedicated 64-bit AXI4 slave port (u_veer.dma_axi_*).", bold_prefix="3. Dedicated Slave Port: ")
    add_bullet_p(doc, "The core internal DCCM arbiter grants access to the dedicated port, asserting dma_axi_arready / awready.", bold_prefix="4. Core Memory Arbitration: ")
    add_bullet_p(doc, "64 bits of data are read from or written to DCCM SRAM in a single clock cycle, achieving maximum theoretical bandwidth.", bold_prefix="5. Single-Cycle Memory Cycle: ")

    add_heading_2(doc, "2.6 DMA-to-SPI and DMA-to-I2C Communication Paths")
    add_body_p(doc, "To move data between DCCM and peripheral FIFOs, the DMA controller executes coordinated two-phase transactions:")
    add_bullet_p(doc, "The DMA reads a 32-bit or 64-bit payload from DCCM via the dedicated DMA slave port. Next, the DMA router directs the write to dma_axi4_to_ahb_adapter, which acquires the AHB bus and writes the data into the SPI DTR FIFO (0x4000_6068).", bold_prefix="Transmit Acceleration (TX Path): ")
    add_bullet_p(doc, "The DMA adapter acquires the AHB bus to read the SPI DRR FIFO (0x4000_606C) or I2C RXR register (0x4000_800C). The received byte/word is latched into the DMA engine and written directly into DCCM via the dedicated slave port.", bold_prefix="Receive Acceleration (RX Path): ")

    add_heading_2(doc, "2.7 Interrupt Architecture Overview")
    add_body_p(doc, "The interrupt architecture utilizes an integrated, low-latency topology. Five primary hardware interrupt lines are generated across the SoC and routed into pic_interrupt_glue:")
    add_bullet_p(doc, "Asserted when a programmed DMA block transfer finishes successfully.", bold_prefix="Source 1 (dma_done): ")
    add_bullet_p(doc, "Asserted upon bus error, unaligned address access, or slave decode fault.", bold_prefix="Source 2 (dma_error): ")
    add_bullet_p(doc, "Asserted on TX FIFO empty, RX FIFO full, or transfer overrun conditions.", bold_prefix="Source 3 (spi_irq): ")
    add_bullet_p(doc, "Asserted on RX data available (RDA) or transmitter holding register empty (THRE).", bold_prefix="Source 4 (uart_irq): ")
    add_bullet_p(doc, "Asserted on byte transfer complete, arbitration loss, or slave acknowledge received.", bold_prefix="Source 5 (i2c_wb_inta_o): ")
    add_body_p(doc, "These synchronized signals enter the VeeR EL2 PIC as extintsrc_req[5:1]. The PIC prioritizes the highest pending request against the programmed threshold register (meicpct) and presents the claim to the core execution engine.")

def build_section_3(doc):
    add_heading_1(doc, "3. Block Inventory")
    add_body_p(doc, "Table 3.1 details the verified hardware modules instantiated in the VeeR EL2 Communication SoC, specifying their RTL entity names, file system locations, architectural functions, and interface connectivity.")

    inv_headers = ["Block Name", "RTL Module Name", "Source Path in Repository", "Primary Architectural Function", "Interface Standards", "Connected Blocks"]
    inv_data = [
        ["SoC Top Level", "top_veer_soc", "RTL/top_veer_soc.sv", "SoC top-level integration, pin muxing, bus routing, and reset/clock wiring", "External Pins & Internal Buses", "All Subsystems"],
        ["VeeR EL2 Core", "el2_veer_wrapper", "RTL/Cores-VeeR-EL2-main/design/...", "RV32IMC 4-stage processor core, branch predictor, IFU/LSU pipelines", "AXI4 Master (64b), AXI4 Slave (64b), PICM", "Interconnect, DCCM, Boot ROM, PIC"],
        ["DMA Master Router", "dma_axi_master_router", "RTL/DMA/dma_axi_master_router.sv", "Dynamic route steering: DCCM space to dedicated slave; peripheral to AHB adapter", "AXI4 64-bit Master & Slave Interfaces", "DMA Master, VeeR Core, AHB Adapter"],
        ["DMA AHB Adapter", "dma_axi4_to_ahb_adapter", "RTL/DMA/dma_axi4_to_ahb_adapter.sv", "Bridges 64-bit AXI4 DMA transactions to 64-bit AHB-Lite bus master transfers", "AXI4 64b Slave, AHB-Lite 64b Master", "DMA Router, AHB Interconnect"],
        ["DMA Controller", "dma_axi_wrapper / csr_dma", "RTL/DMA/dma_axi_wrapper.v, csr_dma.v", "Multi-mode descriptor-based DMA engine with byte counters and FSM logic", "AXI4 64b Master, AHB 32b Slave (CSR)", "AHB Interconnect, Router, PIC Glue"],
        ["Address Decoder", "address_decoder", "RTL/Interconnect/address_decoder.sv", "AHB address phase decoding, generating 1-hot slave selects (HSEL_*)", "AHB-Lite Control Signals", "AHB Bus, All AHB Slaves"],
        ["LSU AXI-AHB Bridge", "u_lsu_axi2ahb", "RTL/Interconnect/axi2ahb.sv", "Translates CPU LSU AXI4 transactions into 64-bit AHB-Lite master cycles", "AXI4 64b Slave, AHB-Lite 64b Master", "VeeR LSU, AHB Interconnect"],
        ["DCCM SRAM Array", "soc_dccm_ram", "RTL/Memory/soc_dccm_ram.sv", "64 KB tightly-coupled data memory array with single-cycle read/write access", "Dedicated Core Memory Interface (64b)", "VeeR EL2 Core Complex"],
        ["Instruction Boot ROM", "soc_ifu_boot_rom", "RTL/Memory/soc_ifu_boot_rom.sv", "8 KB instruction ROM initialized from firmware.hex containing boot code", "AXI4 64b Slave / Core IFU Bus", "VeeR EL2 IFU Fetch Unit"],
        ["SPI Controller", "axi_spi_top", "RTL/SPI/axi_spi_top.v", "Xilinx-compatible AXI Quad SPI master with dual 16x32 FIFOs and clock gen", "AXI-Lite 32b Slave, SPI 4-Wire Pins", "AHB2AXI Bridge, External SPI Pins, PIC"],
        ["AHB-to-AXI-Lite SPI", "ahb2axi_spi", "RTL/Interconnect/ahb2axi_lite.sv", "Protocol bridge adapting 64-bit AHB-Lite transfers to 32-bit AXI-Lite SPI port", "AHB 64b Slave, AXI-Lite 32b Master", "AHB Bus, SPI Controller"],
        ["I2C Master Core", "i2c_master_top", "RTL/I2C/i2c_master_top.v", "OpenCores I2C master with 16b prescaler, byte controller, and ACK detect", "Wishbone 8/32b Slave, I2C 2-Wire Pins", "AHB2WB Bridge, External I2C Pins, PIC"],
        ["AHB-to-Wishbone I2C", "ahb2wb_i2c", "RTL/Interconnect/ahb2wishbone.sv", "Protocol bridge adapting 64-bit AHB-Lite transfers to Wishbone I2C port", "AHB 64b Slave, Wishbone Master", "AHB Bus, I2C Master"],
        ["UART Controller", "axi_uart_top", "RTL/UART/axi_uart_top.v", "16550-compatible UART core with baud divisor, line framing, and status flags", "AXI-Lite 32b Slave, UART TX/RX Pins", "AHB2AXI Bridge, External UART Pins, PIC"],
        ["AHB-to-AXI-Lite UART", "ahb2axi_uart", "RTL/Interconnect/ahb2axi_lite.sv", "Protocol bridge adapting 64-bit AHB-Lite transfers to 32-bit AXI-Lite UART port", "AHB 64b Slave, AXI-Lite 32b Master", "AHB Bus, UART Controller"],
        ["Programmable IRQ Ctrl", "el2_pic_ctrl", "RTL/Cores-VeeR-EL2-main/design/...", "Core-internal PIC managing 15 priorities, gateway latches, and vector base", "Internal PICM Bus (Zero-Wait LSU)", "VeeR LSU, Execution Core, PIC Glue"],
        ["PIC Interrupt Glue", "pic_interrupt_glue", "RTL/Interrupt/pic_interrupt_glue.sv", "Synchronizes, conditions, and aggregates peripheral IRQs into extintsrc_req", "5x Discrete IRQ Lines, 5b Level Bus", "DMA, SPI, I2C, UART, Core PIC"]
    ]
    create_styled_table(doc, inv_headers, inv_data, [Inches(1.2), Inches(1.3), Inches(1.5), Inches(1.5), Inches(1.1), Inches(1.0)])

def build_section_4(doc):
    add_heading_1(doc, "4. Address Map")
    
    add_heading_2(doc, "4.1 Master System Memory Map")
    add_body_p(doc, "The VeeR EL2 Communication SoC organizes its 32-bit address space into distinct memory regions, peripheral register banks, and core-internal control spaces. Table 4.1 outlines the complete system address map extracted from the implemented RTL address decoders and verified firmware linkers.")

    map_headers = ["Memory Region", "Base Address", "End Address", "Size", "Bus / Port", "Access", "Functional Description & Decoding"]
    map_data = [
        ["Boot ROM / Reset", "0x4000_0000", "0x4000_1FFF", "8 KB", "Core IFU / AHB", "R / X", "Power-on reset vector base; executes firmware.hex initialization code"],
        ["UART Controller", "0x4000_0000", "0x4000_0BFF", "3 KB", "AHB-Lite Bridge", "R / W", "16550 UART registers (RBR/THR, IER, LCR, LSR, BAUD_DIV)"],
        ["UART Alias Window", "0x4000_2000", "0x4000_2FFF", "4 KB", "AHB-Lite Bridge", "R / W", "Secondary peripheral alias decode window for UART controller"],
        ["DMA CSR Registers", "0x4000_0C00", "0x4000_0FFF", "1 KB", "AHB-Lite Interconnect", "R / W", "DMA engine control, status, error registers, and descriptor 0"],
        ["SPI Controller", "0x4000_6000", "0x4000_6FFF", "4 KB", "AHB-Lite Bridge", "R / W", "AXI Quad SPI registers (CR, SR, DTR FIFO, DRR FIFO, SSR, IER)"],
        ["SPI Alias Window", "0x4000_1000", "0x4000_1FFF", "4 KB", "AHB-Lite Bridge", "R / W", "Secondary peripheral alias decode window for SPI controller"],
        ["I2C Master Core", "0x4000_8000", "0x4000_8FFF", "4 KB", "AHB-Lite Bridge", "R / W", "OpenCores Wishbone I2C registers (PRER, CTR, TXR/RXR, CR/SR)"],
        ["I2C Alias Window", "0x4000_3000", "0x4000_3FFF", "4 KB", "AHB-Lite Bridge", "R / W", "Secondary peripheral alias decode window for I2C controller"],
        ["ICCM SRAM Base", "0xEE00_0000", "0xEE00_FFFF", "64 KB", "Core Internal IFU", "R / W / X", "Instruction Closely Coupled Memory; high-speed code execution"],
        ["DCCM SRAM Base", "0xF004_0000", "0xF004_FFFF", "64 KB", "Dedicated DMA / LSU", "R / W", "Data Closely Coupled Memory physical base; single-cycle SRAM access"],
        ["DCCM Alias Window", "0x0000_0000", "0x0000_FFFF", "64 KB", "Dedicated DMA / LSU", "R / W", "Low-memory mirror of DCCM; normalized by router to 0xF004_xxxx"],
        ["Core PIC Registers", "0xF00C_0000", "0xF00C_7FFF", "32 KB", "Internal PICM Bus", "R / W", "VeeR EL2 Programmable Interrupt Controller priority, mask, gateway CSRs"]
    ]
    create_styled_table(doc, map_headers, map_data, [Inches(1.3), Inches(1.1), Inches(1.1), Inches(0.6), Inches(1.1), Inches(0.5), Inches(1.9)])

    add_heading_2(doc, "4.2 Peripheral Register Address Ranges")
    add_body_p(doc, "All peripheral registers reside within the 0x4000_xxxx address partition. The address decoder partitions this segment to allocate independent 4 KB or 1 KB address ranges to each IP core. Both primary and alias address windows are supported in RTL to maintain backwards compatibility across varied firmware drivers.")

    add_heading_2(doc, "4.3 DCCM Address Aliasing and Normalization Logic")
    add_body_p(doc, "The physical DCCM memory is located at 0xF004_0000. However, standard RISC-V embedded compilers often position stack and static global data within the lowest 64 KB of memory (0x0000_0000 to 0x0000_FFFF) to exploit efficient absolute addressing modes.")
    add_body_p(doc, "To support this transparently without complicating software drivers, the dma_axi_master_router implements hardware address normalization logic. When the DMA issues a read or write with address bits [31:16] == 16'h0000, the router replaces the upper 16 bits with 16'hF004 prior to driving the dedicated core DMA slave interface:")
    add_callout(doc, 
        "DCCM ROUTE NORMALIZATION EQUATION:\n"
        "if ((dma_addr[31:28] == 4'h0) || (dma_addr[31:16] == 16'hF004)) begin\n"
        "    target_port = DEDICATED_CORE_DMA_SLAVE;\n"
        "    normalized_addr = {16'hF004, dma_addr[15:0]};\n"
        "end else begin\n"
        "    target_port = AHB_LITE_SYSTEM_ADAPTER;\n"
        "    normalized_addr = dma_addr;\n"
        "end",
        title="HARDWARE ROUTING NORMALIZATION", alert_type="NOTE")

    add_heading_2(doc, "4.4 Address Decoder Implementation Details & Decoding Equations")
    add_body_p(doc, "The AHB-Lite address_decoder module decodes HADDR during the transfer address phase. The implemented combinational equations generating the slave select signals are as follows:")
    add_bullet_p(doc, "assign HSEL_UART = (HADDR[31:12] == 20'h40000) || (HADDR[31:12] == 20'h40002);", bold_prefix="UART Select: ")
    add_bullet_p(doc, "assign HSEL_DMA  = (HADDR[31:12] == 20'h40000) && (HADDR[11:10] == 2'b11); // Range: 0x4000_0C00 - 0x4000_0FFF", bold_prefix="DMA CSR Select: ")
    add_bullet_p(doc, "assign HSEL_SPI  = (HADDR[31:12] == 20'h40006) || (HADDR[31:12] == 20'h40001);", bold_prefix="SPI Select: ")
    add_bullet_p(doc, "assign HSEL_I2C  = (HADDR[31:12] == 20'h40008) || (HADDR[31:12] == 20'h40003);", bold_prefix="I2C Select: ")
    add_bullet_p(doc, "assign HSEL_DCCM = (HADDR[31:28] == 4'h0) || (HADDR[31:16] == 16'hF004);", bold_prefix="DCCM Select: ")
    add_bullet_p(doc, "assign HSEL_BOOT = (HADDR[31:16] == 16'h4000) && (HADDR[15:13] == 3'b000);", bold_prefix="Boot ROM Select: ")

def build_section_5(doc):
    add_heading_1(doc, "5. Interface and Signal Specification")
    add_body_p(doc, "This section documents every critical bus and physical pin-level interface implemented in the VeeR EL2 Communication SoC, using the exact signal names, widths, and directions from top_veer_soc.sv and associated submodules.")

    add_heading_2(doc, "5.1 64-bit AMBA AHB-Lite System Interconnect Signals")
    add_body_p(doc, "Table 5.1 defines the signals comprising the primary 64-bit AHB-Lite system interconnect fabric connecting masters (CPU LSU and DMA Adapter) to slave peripherals.")

    ahb_headers = ["Signal Name", "Dir", "Width", "Description & Protocol Function", "Source Block", "Destination Block"]
    ahb_data = [
        ["hclk", "In", "1", "System bus clock (50.0 MHz synchronous timebase)", "Clock Generator", "All AHB Modules"],
        ["hreset_n", "In", "1", "System active-low synchronous reset", "Reset Controller", "All AHB Modules"],
        ["haddr", "Out", "32", "AHB byte address driven by the active bus master", "Active Bus Master", "Address Decoder, Slaves"],
        ["hwrite", "Out", "1", "Transfer direction: 1 = Write transfer, 0 = Read transfer", "Active Bus Master", "All AHB Slaves"],
        ["hsize", "Out", "3", "Transfer size: 3'b000=8b, 3'b001=16b, 3'b010=32b, 3'b011=64b", "Active Bus Master", "All AHB Slaves"],
        ["hburst", "Out", "3", "Burst type: Single (000), INCR (001), INCR4 (011), INCR8 (101)", "Active Bus Master", "All AHB Slaves"],
        ["hprot", "Out", "4", "Protection control: privileged, user, data, instruction access", "Active Bus Master", "Interconnect Arbiter"],
        ["htrans", "Out", "2", "Transfer type: IDLE (2'b00), BUSY (2'b01), NONSEQ (2'b10), SEQ (2'b11)", "Active Bus Master", "All AHB Slaves"],
        ["hmastlock", "Out", "1", "Locked master transfer sequence indicator (atomic bursts)", "Active Bus Master", "AHB Bus Arbiter"],
        ["hwdata", "Out", "64", "64-bit write data bus driven during write cycles", "Active Bus Master", "Selected AHB Slave"],
        ["hrdata", "In", "64", "64-bit read data bus driven by the addressed slave", "Addressed Slave", "Active Bus Master"],
        ["hready", "In/Out", "1", "Transfer complete handshake; high indicates slave is ready", "Addressed Slave", "Master & Interconnect"],
        ["hresp", "In", "1", "Transfer status: 1'b0 = OKAY response, 1'b1 = ERROR condition", "Addressed Slave", "Active Bus Master"],
        ["hsel_spi", "Out", "1", "Slave select for SPI controller (asserted for 0x4000_6xxx)", "Address Decoder", "ahb2axi_spi Bridge"],
        ["hsel_i2c", "Out", "1", "Slave select for I2C controller (asserted for 0x4000_8xxx)", "Address Decoder", "ahb2wb_i2c Bridge"],
        ["hsel_uart", "Out", "1", "Slave select for UART controller (asserted for 0x4000_0xxx)", "Address Decoder", "ahb2axi_uart Bridge"],
        ["hsel_dma", "Out", "1", "Slave select for DMA CSRs (asserted for 0x4000_0C00)", "Address Decoder", "DMA CSR Interface"]
    ]
    create_styled_table(doc, ahb_headers, ahb_data, [Inches(1.2), Inches(0.4), Inches(0.5), Inches(2.3), Inches(1.3), Inches(1.3)])

    add_heading_2(doc, "5.2 DMA AXI4 Master Interface Signals (m_axi_*)")
    add_body_p(doc, "Table 5.2 defines the 64-bit AXI4 master interface signals driven by the DMA core into the dma_axi_master_router.")

    axi_m_headers = ["Signal Name", "Dir", "Width", "Description & Protocol Function", "Source Block", "Destination Block"]
    axi_m_data = [
        ["m_axi_awid", "Out", "4", "Write address transaction ID tag", "DMA Master Core", "DMA Router"],
        ["m_axi_awaddr", "Out", "32", "Write address byte pointer", "DMA Master Core", "DMA Router"],
        ["m_axi_awlen", "Out", "8", "Write burst length (number of transfers minus 1: 0 to 255)", "DMA Master Core", "DMA Router"],
        ["m_axi_awsize", "Out", "3", "Write burst transfer size: 3'b010 = 32-bit, 3'b011 = 64-bit", "DMA Master Core", "DMA Router"],
        ["m_axi_awburst", "Out", "2", "Write burst type: 2'b00 = FIXED, 2'b01 = INCR", "DMA Master Core", "DMA Router"],
        ["m_axi_awvalid", "Out", "1", "Write address valid strobe", "DMA Master Core", "DMA Router"],
        ["m_axi_awready", "In", "1", "Write address acknowledge from slave/router", "DMA Router", "DMA Master Core"],
        ["m_axi_wdata", "Out", "64", "64-bit write payload data bus", "DMA Master Core", "DMA Router"],
        ["m_axi_wstrb", "Out", "8", "Write byte enables (1 bit per active byte lane)", "DMA Master Core", "DMA Router"],
        ["m_axi_wlast", "Out", "1", "Write last beat indicator for current burst", "DMA Master Core", "DMA Router"],
        ["m_axi_wvalid", "Out", "1", "Write data valid strobe", "DMA Master Core", "DMA Router"],
        ["m_axi_wready", "In", "1", "Write data acknowledge from slave/router", "DMA Router", "DMA Master Core"],
        ["m_axi_bresp", "In", "2", "Write response status: 2'b00=OKAY, 2'b10=SLVERR, 2'b11=DECERR", "DMA Router", "DMA Master Core"],
        ["m_axi_bvalid", "In", "1", "Write response valid strobe", "DMA Router", "DMA Master Core"],
        ["m_axi_bready", "Out", "1", "Write response ready acknowledgment", "DMA Master Core", "DMA Router"],
        ["m_axi_arid", "Out", "4", "Read address transaction ID tag", "DMA Master Core", "DMA Router"],
        ["m_axi_araddr", "Out", "32", "Read address byte pointer", "DMA Master Core", "DMA Router"],
        ["m_axi_arlen", "Out", "8", "Read burst length (number of transfers minus 1: 0 to 255)", "DMA Master Core", "DMA Router"],
        ["m_axi_arsize", "Out", "3", "Read burst transfer size: 3'b010 = 32-bit, 3'b011 = 64-bit", "DMA Master Core", "DMA Router"],
        ["m_axi_arburst", "Out", "2", "Read burst type: 2'b00 = FIXED, 2'b01 = INCR", "DMA Master Core", "DMA Router"],
        ["m_axi_arvalid", "Out", "1", "Read address valid strobe", "DMA Master Core", "DMA Router"],
        ["m_axi_arready", "In", "1", "Read address acknowledge from slave/router", "DMA Router", "DMA Master Core"],
        ["m_axi_rdata", "In", "64", "64-bit read payload data bus", "DMA Router", "DMA Master Core"],
        ["m_axi_rresp", "In", "2", "Read response status: 2'b00=OKAY, 2'b10=SLVERR, 2'b11=DECERR", "DMA Router", "DMA Master Core"],
        ["m_axi_rlast", "In", "1", "Read last beat indicator from slave", "DMA Router", "DMA Master Core"],
        ["m_axi_rvalid", "In", "1", "Read data valid strobe", "DMA Router", "DMA Master Core"],
        ["m_axi_rready", "Out", "1", "Read data ready acknowledgment", "DMA Master Core", "DMA Router"]
    ]
    create_styled_table(doc, axi_m_headers, axi_m_data, [Inches(1.3), Inches(0.4), Inches(0.5), Inches(2.3), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.3 Dedicated VeeR EL2 DMA Slave Interface Signals (dma_axi_*)")
    add_body_p(doc, "Table 5.3 defines the 64-bit AXI4 interface signals connecting the dma_axi_master_router directly into the core DMA slave port (u_veer.dma_axi_*).")

    axi_s_headers = ["Signal Name", "Dir", "Width", "Description & Protocol Function", "Source Block", "Destination Block"]
    axi_s_data = [
        ["dma_axi_awvalid", "Out", "1", "Write address valid targeting core DCCM", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_awready", "In", "1", "Core DCCM write address ready acknowledgment", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_awaddr", "Out", "32", "Normalized DCCM write address ({16'hF004, addr[15:0]})", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_awsize", "Out", "3", "Write transfer size: 3'b010=32-bit word, 3'b011=64-bit double", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_wvalid", "Out", "1", "Write data valid targeting core DCCM", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_wready", "In", "1", "Core DCCM write data ready acknowledgment", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_wdata", "Out", "64", "64-bit write payload data bus into DCCM", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_wstrb", "Out", "8", "Active byte write strobes for DCCM write lanes", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_bvalid", "In", "1", "Core DCCM write response valid", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_bready", "Out", "1", "Router write response ready acknowledge", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_bresp", "In", "2", "Write response code from core DCCM (OKAY / SLVERR)", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_arvalid", "Out", "1", "Read address valid targeting core DCCM", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_arready", "In", "1", "Core DCCM read address ready acknowledgment", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_araddr", "Out", "32", "Normalized DCCM read address ({16'hF004, addr[15:0]})", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_arsize", "Out", "3", "Read transfer size: 3'b010=32-bit word, 3'b011=64-bit double", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_rvalid", "In", "1", "Core DCCM read data valid strobe", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_rready", "Out", "1", "Router read data ready acknowledgment", "DMA Router", "VeeR EL2 Core"],
        ["dma_axi_rdata", "In", "64", "64-bit read payload returned directly from DCCM SRAM", "VeeR EL2 Core", "DMA Router"],
        ["dma_axi_rresp", "In", "2", "Read response code from core DCCM (OKAY / SLVERR)", "VeeR EL2 Core", "DMA Router"]
    ]
    create_styled_table(doc, axi_s_headers, axi_s_data, [Inches(1.4), Inches(0.4), Inches(0.5), Inches(2.2), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.4 DCCM RAM Interface Signals")
    add_body_p(doc, "Table 5.4 specifies the physical SRAM macro interface signals connecting soc_dccm_ram to the core LSU and dedicated slave arbiter.")

    dccm_sig_headers = ["Signal Name", "Dir", "Width", "Description & Function", "Source Block", "Destination Block"]
    dccm_sig_data = [
        ["dccm_clk", "In", "1", "Synchronous memory clock (50.0 MHz)", "Clock Network", "soc_dccm_ram"],
        ["dccm_rst_n", "In", "1", "Active-low synchronous memory reset", "Reset Network", "soc_dccm_ram"],
        ["dccm_cs", "In", "1", "SRAM chip select; activates memory bank access", "Core Memory Arbiter", "soc_dccm_ram"],
        ["dccm_we", "In", "8", "Byte-level write enables for 64-bit SRAM word", "Core Memory Arbiter", "soc_dccm_ram"],
        ["dccm_addr", "In", "16", "SRAM word address pointer (64 KB address span)", "Core Memory Arbiter", "soc_dccm_ram"],
        ["dccm_wdata", "In", "64", "64-bit write data bus into SRAM array", "Core Memory Arbiter", "soc_dccm_ram"],
        ["dccm_rdata", "Out", "64", "64-bit read data output from SRAM array (single-cycle)", "soc_dccm_ram", "Core Memory Arbiter"],
        ["dccm_ready", "Out", "1", "Memory ready flag; signals single-cycle cycle completion", "soc_dccm_ram", "VeeR Pipeline & DMA"]
    ]
    create_styled_table(doc, dccm_sig_headers, dccm_sig_data, [Inches(1.2), Inches(0.4), Inches(0.5), Inches(2.4), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.5 SPI Physical and Register Interface Signals")
    add_body_p(doc, "Table 5.5 lists the physical external pins and internal interconnect signals for axi_spi_top.")

    spi_sig_headers = ["Signal Name", "Dir", "Width", "Description & Function", "Source Block", "Destination Block"]
    spi_sig_data = [
        ["spi_sck_o", "Out", "1", "SPI serial shift clock (up to 25 MHz)", "axi_spi_top", "External SPI Bus Pin"],
        ["spi_mosi_o", "Out", "1", "Master-Out Slave-In serial data transmit line", "axi_spi_top", "External SPI Bus Pin"],
        ["spi_miso_i", "In", "1", "Master-In Slave-Out serial data receive line", "External SPI Bus Pin", "axi_spi_top"],
        ["spi_ss_o", "Out", "1", "Active-low slave chip select line 0", "axi_spi_top", "External SPI Bus Pin"],
        ["spi_irq", "Out", "1", "Interrupt request: TX FIFO empty, RX FIFO full, overrun", "axi_spi_top", "pic_interrupt_glue"],
        ["s_axi_awaddr", "In", "7", "AXI-Lite write address (7-bit byte offset)", "ahb2axi_spi", "axi_spi_top"],
        ["s_axi_wdata", "In", "32", "AXI-Lite 32-bit write data bus", "ahb2axi_spi", "axi_spi_top"],
        ["s_axi_rdata", "Out", "32", "AXI-Lite 32-bit read data bus (FIFO and status read)", "axi_spi_top", "ahb2axi_spi"]
    ]
    create_styled_table(doc, spi_sig_headers, spi_sig_data, [Inches(1.2), Inches(0.4), Inches(0.5), Inches(2.4), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.6 I2C Physical and Register Interface Signals")
    add_body_p(doc, "Table 5.6 details the physical open-drain pads and Wishbone interface signals for i2c_master_top.")

    i2c_sig_headers = ["Signal Name", "Dir", "Width", "Description & Function", "Source Block", "Destination Block"]
    i2c_sig_data = [
        ["scl_pad_i", "In", "1", "I2C clock input sense from external bus line", "External I2C Pin", "i2c_master_top"],
        ["scl_pad_o", "Out", "1", "I2C clock output driver (drives 0 to pull down SCL)", "i2c_master_top", "External I2C Pin Driver"],
        ["scl_padoen_o", "Out", "1", "I2C clock output enable (1 = High-Z / Float, 0 = Drive)", "i2c_master_top", "External I2C Pin Driver"],
        ["sda_pad_i", "In", "1", "I2C data input sense from external bus line", "External I2C Pin", "i2c_master_top"],
        ["sda_pad_o", "Out", "1", "I2C data output driver (drives 0 to pull down SDA)", "i2c_master_top", "External I2C Pin Driver"],
        ["sda_padoen_o", "Out", "1", "I2C data output enable (1 = High-Z / Float, 0 = Drive)", "i2c_master_top", "External I2C Pin Driver"],
        ["i2c_wb_inta_o", "Out", "1", "Interrupt request: Byte transferred, ACK received, AL", "i2c_master_top", "pic_interrupt_glue"],
        ["wb_adr_i", "In", "3", "Wishbone register byte offset (3-bit address)", "ahb2wb_i2c", "i2c_master_top"],
        ["wb_dat_i", "In", "8", "Wishbone 8-bit write data byte", "ahb2wb_i2c", "i2c_master_top"],
        ["wb_dat_o", "Out", "8", "Wishbone 8-bit read data byte", "i2c_master_top", "ahb2wb_i2c"]
    ]
    create_styled_table(doc, i2c_sig_headers, i2c_sig_data, [Inches(1.2), Inches(0.4), Inches(0.5), Inches(2.4), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.7 UART Physical and Register Interface Signals")
    add_body_p(doc, "Table 5.7 specifies the serial communication pins and register interface signals for axi_uart_top.")

    uart_sig_headers = ["Signal Name", "Dir", "Width", "Description & Function", "Source Block", "Destination Block"]
    uart_sig_data = [
        ["uart_txd_o", "Out", "1", "UART asynchronous serial transmit output", "axi_uart_top", "External UART Pin"],
        ["uart_rxd_i", "In", "1", "UART asynchronous serial receive input", "External UART Pin", "axi_uart_top"],
        ["uart_irq", "Out", "1", "Interrupt request: RX data ready (RDA), TX holding empty", "axi_uart_top", "pic_interrupt_glue"],
        ["s_axi_awaddr", "In", "5", "AXI-Lite write address (5-bit byte offset)", "ahb2axi_uart", "axi_uart_top"],
        ["s_axi_wdata", "In", "32", "AXI-Lite 32-bit write data bus (THR, IER, LCR)", "ahb2axi_uart", "axi_uart_top"],
        ["s_axi_rdata", "Out", "32", "AXI-Lite 32-bit read data bus (RBR, LSR, IIR)", "axi_uart_top", "ahb2axi_uart"]
    ]
    create_styled_table(doc, uart_sig_headers, uart_sig_data, [Inches(1.2), Inches(0.4), Inches(0.5), Inches(2.4), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.8 PIC Interrupt Interface Signals")
    add_body_p(doc, "Table 5.8 specifies the interrupt request inputs and synchronization signals connecting pic_interrupt_glue to el2_pic_ctrl.sv.")

    pic_sig_headers = ["Signal Name", "Dir", "Width", "Description & Mapping", "Source Block", "Destination Block"]
    pic_sig_data = [
        ["extintsrc_req[1]", "In", "1", "Source 1: DMA transfer complete interrupt (dma_done)", "pic_interrupt_glue", "VeeR EL2 PIC"],
        ["extintsrc_req[2]", "In", "1", "Source 2: DMA bus error / fault interrupt (dma_error)", "pic_interrupt_glue", "VeeR EL2 PIC"],
        ["extintsrc_req[3]", "In", "1", "Source 3: SPI peripheral interrupt (spi_irq)", "pic_interrupt_glue", "VeeR EL2 PIC"],
        ["extintsrc_req[4]", "In", "1", "Source 4: UART peripheral interrupt (uart_irq)", "pic_interrupt_glue", "VeeR EL2 PIC"],
        ["extintsrc_req[5]", "In", "1", "Source 5: I2C peripheral interrupt (i2c_wb_inta_o)", "pic_interrupt_glue", "VeeR EL2 PIC"],
        ["picm_maddr", "In", "32", "Core LSU direct PICM register address (0xF00C_xxxx)", "VeeR EL2 LSU", "VeeR EL2 PIC"],
        ["picm_wdata", "In", "32", "Core LSU direct PICM write data", "VeeR EL2 LSU", "VeeR EL2 PIC"],
        ["picm_rdata", "Out", "32", "Core LSU direct PICM read data (zero-wait)", "VeeR EL2 PIC", "VeeR EL2 LSU"]
    ]
    create_styled_table(doc, pic_sig_headers, pic_sig_data, [Inches(1.3), Inches(0.4), Inches(0.5), Inches(2.3), Inches(1.2), Inches(1.2)])

    add_heading_2(doc, "5.9 Clock and Reset Signals")
    add_body_p(doc, "Table 5.9 summarizes the global timing and reset control signals across the SoC hierarchy.")

    clk_sig_headers = ["Signal Name", "Dir", "Width", "Description & Timing Characteristic", "Source Block", "Destination Block"]
    clk_sig_data = [
        ["clk", "In", "1", "Primary system clock: 50.0 MHz, 50% duty cycle", "External Oscillator", "All Flip-Flops & Memories"],
        ["rst_n", "In", "1", "Global master asynchronous active-low reset", "External Reset Pad", "Reset Synchronizer Tree"],
        ["hreset_n", "Internal", "1", "Synchronous active-low system bus reset", "Reset Synchronizer", "AHB Interconnect & Bridges"],
        ["core_rst_n", "Internal", "1", "Synchronous active-low core pipeline reset", "Reset Synchronizer", "VeeR EL2 Core Complex"]
    ]
    create_styled_table(doc, clk_sig_headers, clk_sig_data, [Inches(1.2), Inches(0.6), Inches(0.5), Inches(2.3), Inches(1.2), Inches(1.1)])
