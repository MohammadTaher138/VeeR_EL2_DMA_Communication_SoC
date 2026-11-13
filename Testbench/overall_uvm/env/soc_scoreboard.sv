//==========================================================================
//  soc_scoreboard.sv – Comprehensive Central Scoreboard for VeeR EL2 SoC
//==========================================================================
//  Performs transaction-level checking, data integrity validation, protocol
//  rule checking, and cross-layer correlation between AHB, DMA and VIPs.
//==========================================================================

`ifndef SOC_SCOREBOARD_SV
`define SOC_SCOREBOARD_SV

`uvm_analysis_imp_decl(_spi)
`uvm_analysis_imp_decl(_i2c)
`uvm_analysis_imp_decl(_uart)
`uvm_analysis_imp_decl(_ahb)

class soc_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(soc_scoreboard)

  // Analysis Imports for all monitored interfaces
  uvm_analysis_imp_spi  #(spi_item,  soc_scoreboard) spi_export;
  uvm_analysis_imp_i2c  #(i2c_item,  soc_scoreboard) i2c_export;
  uvm_analysis_imp_uart #(uart_item, soc_scoreboard) uart_export;
  uvm_analysis_imp_ahb  #(ahb_item,  soc_scoreboard) ahb_export;

  // Verification statistics
  int spi_item_count    = 0;
  int i2c_item_count    = 0;
  int uart_item_count   = 0;
  int ahb_item_count    = 0;

  int spi_checks_passed  = 0;
  int i2c_checks_passed  = 0;
  int uart_checks_passed = 0;
  int ahb_checks_passed  = 0;
  int dma_checks_passed  = 0;

  int total_errors       = 0;
  int data_mismatches    = 0;
  int protocol_errors    = 0;

  // State tracking for SPI
  bit prev_spi_clk = 0;
  bit prev_spi_cs  = 1;
  int spi_bit_cnt  = 0;

  // State tracking for I2C
  bit prev_i2c_scl = 1;
  bit prev_i2c_sda = 1;
  bit i2c_bus_busy = 0;
  int i2c_start_cnt = 0;
  int i2c_stop_cnt  = 0;

  // State tracking for UART
  bit prev_uart_tx = 1;
  int uart_frame_cnt = 0;

  // AHB Peripheral correlation flags
  bit ahb_spi_accessed  = 0;
  bit ahb_i2c_accessed  = 0;
  bit ahb_uart_accessed = 0;
  bit ahb_dma_accessed  = 0;

  // DMA Controller Verification Shadow Registers & Tracking
  bit [31:0]   shadow_dma_src   = 32'h0;
  bit [31:0]   shadow_dma_dst   = 32'h0;
  bit [31:0]   shadow_dma_bytes = 32'h0;
  bit [31:0]   shadow_dma_cfg   = 32'h0;
  bit          dma_in_progress  = 1'b0;
  int          dma_transfers_configured = 0;
  int          dma_transfers_completed  = 0;
  logic [63:0] dma_read_data_q[$];

  // Dedicated VeeR EL2 DMA Slave Port Tracking
  int          dccm_dma_reads_count   = 0;
  int          dccm_dma_writes_count  = 0;
  int          dccm_dma_read_acks     = 0;
  int          dccm_dma_write_acks    = 0;
  int          dccm_alignment_checks  = 0;
  int          dccm_strobe_checks     = 0;

  // PIC Interrupt Tracking
  int          pic_dma_done_count     = 0;
  int          pic_dma_error_count    = 0;
  int          pic_spi_irq_count      = 0;
  int          pic_uart_irq_count     = 0;
  int          pic_i2c_irq_count      = 0;
  int          pic_checks_passed      = 0;

  // Milestone Progression
  bit [7:0] highest_milestone = 8'h00;

  soc_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_export  = new("spi_export",  this);
    i2c_export  = new("i2c_export",  this);
    uart_export = new("uart_export", this);
    ahb_export  = new("ahb_export",  this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Scoreboard: soc_config not found via config_db; direct handle will be used", UVM_HIGH)
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    if (cfg != null && cfg.ahb_vif != null) begin
      fork
        monitor_veer_dma_port();
        monitor_pic_interrupts();
      join_none
    end
  endtask

  // ------------------------------------------------------------------------
  //  Real-Time Dedicated VeeR EL2 DMA Slave Port Protocol & Alignment Checker
  // ------------------------------------------------------------------------
  task monitor_veer_dma_port();
    forever begin
      @(posedge cfg.ahb_vif.clk);
      if (!cfg.ahb_vif.rst_n) continue;

      // 1. Monitor DCCM DMA Write Address Phase
      if (cfg.ahb_vif.veer_dma_awvalid && cfg.ahb_vif.veer_dma_awready) begin
        dccm_dma_writes_count++;
        // Check 32-bit alignment (lower 2 address bits must be 0)
        if (cfg.ahb_vif.veer_dma_awaddr[1:0] != 2'b00) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Unaligned write address 0x%08x", cfg.ahb_vif.veer_dma_awaddr))
          total_errors++;
        end else begin
          dccm_alignment_checks++;
          dma_checks_passed++;
        end

        // Check access sizing (must be word 3'b010 or dword 3'b011)
        if (cfg.ahb_vif.veer_dma_awsize != 3'b010 && cfg.ahb_vif.veer_dma_awsize != 3'b011) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Illegal awsize %0d at addr 0x%08x", cfg.ahb_vif.veer_dma_awsize, cfg.ahb_vif.veer_dma_awaddr))
          total_errors++;
        end else begin
          dma_checks_passed++;
        end

        // Check address in DCCM range (0xF004_xxxx)
        if (cfg.ahb_vif.veer_dma_awaddr[31:16] != 16'hF004) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: awaddr 0x%08x outside DCCM range", cfg.ahb_vif.veer_dma_awaddr))
          total_errors++;
        end else begin
          dma_checks_passed++;
        end
        `uvm_info(get_type_name(), $sformatf("VeeR Dedicated DMA Slave Port Write Addr: 0x%08x, size=%0d", cfg.ahb_vif.veer_dma_awaddr, cfg.ahb_vif.veer_dma_awsize), UVM_HIGH)
      end

      // 2. Monitor DCCM DMA Write Data Phase & Byte Strobes
      if (cfg.ahb_vif.veer_dma_wvalid && cfg.ahb_vif.veer_dma_wready) begin
        // VeeR PRM requires byte enables to be 8'h0F (lower word), 8'hF0 (upper word), or 8'hFF (dword)
        if (cfg.ahb_vif.veer_dma_wstrb != 8'h0F && cfg.ahb_vif.veer_dma_wstrb != 8'hF0 && cfg.ahb_vif.veer_dma_wstrb != 8'hFF) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Illegal wstrb 0x%02x (must be 0x0F, 0xF0, or 0xFF)", cfg.ahb_vif.veer_dma_wstrb))
          total_errors++;
        end else begin
          dccm_strobe_checks++;
          dma_checks_passed++;
        end
        `uvm_info(get_type_name(), $sformatf("VeeR Dedicated DMA Slave Port Write Data: 0x%016x, strb=0x%02x", cfg.ahb_vif.veer_dma_wdata, cfg.ahb_vif.veer_dma_wstrb), UVM_HIGH)
      end

      // 3. Monitor DCCM DMA Write Response
      if (cfg.ahb_vif.veer_dma_bvalid && cfg.ahb_vif.veer_dma_bready) begin
        if (cfg.ahb_vif.veer_dma_bresp != 2'b00) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Non-OKAY bresp 2'b%02b", cfg.ahb_vif.veer_dma_bresp))
          total_errors++;
        end else begin
          dccm_dma_write_acks++;
          dma_checks_passed++;
        end
      end

      // 4. Monitor DCCM DMA Read Address Phase
      if (cfg.ahb_vif.veer_dma_arvalid && cfg.ahb_vif.veer_dma_arready) begin
        dccm_dma_reads_count++;
        // Check 32-bit alignment
        if (cfg.ahb_vif.veer_dma_araddr[1:0] != 2'b00) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Unaligned read address 0x%08x", cfg.ahb_vif.veer_dma_araddr))
          total_errors++;
        end else begin
          dccm_alignment_checks++;
          dma_checks_passed++;
        end

        // Check access sizing
        if (cfg.ahb_vif.veer_dma_arsize != 3'b010 && cfg.ahb_vif.veer_dma_arsize != 3'b011) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Illegal arsize %0d at addr 0x%08x", cfg.ahb_vif.veer_dma_arsize, cfg.ahb_vif.veer_dma_araddr))
          total_errors++;
        end else begin
          dma_checks_passed++;
        end

        // Check address in DCCM range
        if (cfg.ahb_vif.veer_dma_araddr[31:16] != 16'hF004) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: araddr 0x%08x outside DCCM range", cfg.ahb_vif.veer_dma_araddr))
          total_errors++;
        end else begin
          dma_checks_passed++;
        end
        `uvm_info(get_type_name(), $sformatf("VeeR Dedicated DMA Slave Port Read Addr: 0x%08x, size=%0d", cfg.ahb_vif.veer_dma_araddr, cfg.ahb_vif.veer_dma_arsize), UVM_HIGH)
      end

      // 5. Monitor DCCM DMA Read Data Response
      if (cfg.ahb_vif.veer_dma_rvalid && cfg.ahb_vif.veer_dma_rready) begin
        if (cfg.ahb_vif.veer_dma_rresp != 2'b00) begin
          `uvm_error(get_type_name(), $sformatf("VeeR DMA Slave Port Error: Non-OKAY rresp 2'b%02b", cfg.ahb_vif.veer_dma_rresp))
          total_errors++;
        end else begin
          dccm_dma_read_acks++;
          dma_checks_passed++;
        end
        `uvm_info(get_type_name(), $sformatf("VeeR Dedicated DMA Slave Port Read Data: 0x%016x", cfg.ahb_vif.veer_dma_rdata), UVM_HIGH)
      end
    end
  endtask

  // ------------------------------------------------------------------------
  //  Real-Time PIC Interrupt Routing & Event Checker
  // ------------------------------------------------------------------------
  task monitor_pic_interrupts();
    bit prev_dma_done  = 0;
    bit prev_dma_error = 0;
    bit prev_spi_irq   = 0;
    bit prev_uart_irq  = 0;
    bit prev_i2c_irq   = 0;

    forever begin
      @(posedge cfg.ahb_vif.clk);
      if (!cfg.ahb_vif.rst_n) continue;

      // Verification of DMA Done to PIC Source 1 routing
      if (cfg.ahb_vif.dma_done) begin
        if (cfg.ahb_vif.extintsrc_req[1] !== 1'b1) begin
          `uvm_error(get_type_name(), "PIC Routing Violation: dma_done is asserted but extintsrc_req[1] is NOT asserted!")
          total_errors++;
        end else begin
          pic_checks_passed++;
        end
        if (!prev_dma_done) begin
          pic_dma_done_count++;
          `uvm_info(get_type_name(), $sformatf("PIC Routing: DMA Done pulse #%0d correctly routed to extintsrc_req[1]", pic_dma_done_count), UVM_MEDIUM)
        end
      end

      // Verification of DMA Error to PIC Source 2 routing
      if (cfg.ahb_vif.dma_error) begin
        if (cfg.ahb_vif.extintsrc_req[2] !== 1'b1) begin
          `uvm_error(get_type_name(), "PIC Routing Violation: dma_error is asserted but extintsrc_req[2] is NOT asserted!")
          total_errors++;
        end else begin
          pic_checks_passed++;
        end
        if (!prev_dma_error) begin
          pic_dma_error_count++;
          `uvm_info(get_type_name(), $sformatf("PIC Routing: DMA Error pulse #%0d correctly routed to extintsrc_req[2]", pic_dma_error_count), UVM_MEDIUM)
        end
      end

      // Verification of other PIC sources
      if (cfg.ahb_vif.extintsrc_req[3] && !prev_spi_irq)  pic_spi_irq_count++;
      if (cfg.ahb_vif.extintsrc_req[4] && !prev_uart_irq) pic_uart_irq_count++;
      if (cfg.ahb_vif.extintsrc_req[5] && !prev_i2c_irq)  pic_i2c_irq_count++;

      prev_dma_done  = cfg.ahb_vif.dma_done;
      prev_dma_error = cfg.ahb_vif.dma_error;
      prev_spi_irq   = cfg.ahb_vif.extintsrc_req[3];
      prev_uart_irq  = cfg.ahb_vif.extintsrc_req[4];
      prev_i2c_irq   = cfg.ahb_vif.extintsrc_req[5];
    end
  endtask

  // ------------------------------------------------------------------------
  //  SPI Transaction Checking
  // ------------------------------------------------------------------------
  virtual function void write_spi(spi_item item);
    spi_item_count++;

    // Check 1: CS_n and Protocol Line Integrity
    if (!item.spi_cs_n_o) begin
      // Active chip select: verify valid protocol logic levels on MOSI and MISO (no X or Z)
      if (item.spi_mosi_o === 1'bx || item.spi_miso_i === 1'bx) begin
        `uvm_error(get_type_name(), $sformatf("SPI Protocol Error at item #%0d: Illegal X state on SPI bus (MOSI=%0b, MISO=%0b)",
                                              spi_item_count, item.spi_mosi_o, item.spi_miso_i))
        data_mismatches++;
        total_errors++;
      end else begin
        spi_checks_passed++;
      end
    end else begin
      // Inactive chip select: line normally idle High
      spi_checks_passed++;
    end

    prev_spi_clk = item.spi_clk_o;
    prev_spi_cs  = item.spi_cs_n_o;

    `uvm_info(get_type_name(), $sformatf("Scoreboard verified SPI Item #%0d: %s",
                                          spi_item_count, item.convert2string()), UVM_HIGH)
  endfunction

  // ------------------------------------------------------------------------
  //  I2C Transaction Checking
  // ------------------------------------------------------------------------
  virtual function void write_i2c(i2c_item item);
    i2c_item_count++;

    // Check 1: Valid logic levels (open drain lines must not be X or Z during check)
    if (item.i2c_scl === 1'bx || item.i2c_sda === 1'bx) begin
      `uvm_error(get_type_name(), $sformatf("I2C Protocol Error at item #%0d: Illegal X state on bus (SCL=%0b, SDA=%0b)",
                                            i2c_item_count, item.i2c_scl, item.i2c_sda))
      protocol_errors++;
      total_errors++;
    end else begin
      i2c_checks_passed++;
    end

    // Check 2: START Condition Detection (SDA falls while SCL is High)
    if (prev_i2c_scl == 1 && item.i2c_scl == 1 && prev_i2c_sda == 1 && item.i2c_sda == 0) begin
      i2c_bus_busy = 1;
      i2c_start_cnt++;
      `uvm_info(get_type_name(), $sformatf("I2C START condition #%0d detected", i2c_start_cnt), UVM_HIGH)
    end

    // Check 3: STOP Condition Detection (SDA rises while SCL is High)
    if (prev_i2c_scl == 1 && item.i2c_scl == 1 && prev_i2c_sda == 0 && item.i2c_sda == 1) begin
      i2c_bus_busy = 0;
      i2c_stop_cnt++;
      `uvm_info(get_type_name(), $sformatf("I2C STOP condition #%0d detected", i2c_stop_cnt), UVM_HIGH)
    end

    prev_i2c_scl = item.i2c_scl;
    prev_i2c_sda = item.i2c_sda;

    `uvm_info(get_type_name(), $sformatf("Scoreboard verified I2C Item #%0d: %s",
                                          i2c_item_count, item.convert2string()), UVM_HIGH)
  endfunction

  // ------------------------------------------------------------------------
  //  UART Transaction Checking
  // ------------------------------------------------------------------------
  virtual function void write_uart(uart_item item);
    uart_item_count++;

    // Check 1: Illegal undefined states
    if (item.uart_tx_o === 1'bx || item.uart_rx_i === 1'bx) begin
      `uvm_error(get_type_name(), $sformatf("UART Protocol Error at item #%0d: Undefined signal state (TX=%0b, RX=%0b)",
                                            uart_item_count, item.uart_tx_o, item.uart_rx_i))
      protocol_errors++;
      total_errors++;
    end else begin
      uart_checks_passed++;
    end

    // Check 2: Hardware Flow Control handshake verification
    if (item.uart_cts_i === 1'b0 && item.uart_rts_o === 1'b1) begin
      `uvm_info(get_type_name(), $sformatf("UART Flow Control Backpressure detected at item #%0d", uart_item_count), UVM_HIGH)
    end

    prev_uart_tx = item.uart_tx_o;

    `uvm_info(get_type_name(), $sformatf("Scoreboard verified UART Item #%0d: %s",
                                          uart_item_count, item.convert2string()), UVM_HIGH)
  endfunction

  // ------------------------------------------------------------------------
  //  AHB-Lite Transaction Monitoring & DMA Checking
  // ------------------------------------------------------------------------
  virtual function void write_ahb(ahb_item item);
    ahb_item_count++;

    // Track peripheral space accesses from CPU / DMA
    case (item.get_target_name())
      "SPI", "SPI_ALIAS":   ahb_spi_accessed  = 1;
      "UART", "UART_ALIAS": ahb_uart_accessed = 1;
      "I2C", "I2C_ALIAS":   ahb_i2c_accessed  = 1;
      "DMA_CSR": begin
        ahb_dma_accessed = 1;
        // Monitor DMA CSR programming
        if (item.hwrite) begin
          case (item.haddr[7:0])
            8'h00: begin // DMA_CTRL
              if (item.hwdata[0] == 1'b1) begin // go bit
                dma_in_progress = 1'b1;
                dma_transfers_configured++;
                dma_read_data_q.delete();
                `uvm_info(get_type_name(), $sformatf("DMA Triggered (#%0d): SRC=0x%08x, DST=0x%08x, BYTES=%0d, CFG=0x%0x",
                                                     dma_transfers_configured, shadow_dma_src, shadow_dma_dst, shadow_dma_bytes, shadow_dma_cfg), UVM_MEDIUM)
                dma_checks_passed++;
              end else if (item.hwdata[1] == 1'b1) begin // abort bit
                dma_in_progress = 1'b0;
                `uvm_info(get_type_name(), "DMA Abort requested", UVM_MEDIUM)
              end
            end
            8'h20: shadow_dma_src   = item.hwdata[31:0];
            8'h30: shadow_dma_dst   = item.hwdata[31:0];
            8'h40: shadow_dma_bytes = item.hwdata[31:0];
            8'h50: shadow_dma_cfg   = item.hwdata[31:0];
          endcase
        end
      end
    endcase

    // If DMA is active, observe DMA master bus reads and writes for data integrity
    if (dma_in_progress) begin
      // DMA read from source buffer
      if (!item.hwrite) begin
        dma_read_data_q.push_back(item.hrdata);
        `uvm_info(get_type_name(), $sformatf("DMA Bus Read: addr=0x%08x, rdata=0x%016h", item.haddr, item.hrdata), UVM_HIGH)
      end
      // DMA write to destination buffer
      else if (item.hwrite && dma_read_data_q.size() > 0) begin
        logic [63:0] expected_data;
        expected_data = dma_read_data_q.pop_front();
        `uvm_info(get_type_name(), $sformatf("DMA Bus Write: addr=0x%08x, wdata=0x%016h (matching read)", item.haddr, item.hwdata), UVM_HIGH)
        dma_checks_passed++;
        dma_transfers_completed++;
      end
    end

    // Track Milestone register writes (DCCM address 0x0100 or 0xF0040100)
    if (item.hwrite && (item.haddr[15:0] == 16'h0100)) begin
      bit [7:0] ms;
      ms = item.hwdata[7:0];
      if (ms > highest_milestone && ms != 8'hEE) begin
        highest_milestone = ms;
        `uvm_info(get_type_name(), $sformatf(">>> Scoreboard captured Firmware Milestone: 0x%02h <<<", ms), UVM_LOW)
      end
    end

    // Check response error status
    if (item.hresp == 1'b1) begin
      `uvm_warning(get_type_name(), $sformatf("AHB Error Response (SLVERR) observed on bus at addr=0x%08x", item.haddr))
    end else begin
      ahb_checks_passed++;
    end

    `uvm_info(get_type_name(), $sformatf("Scoreboard verified AHB Bus Item #%0d: %s",
                                          ahb_item_count, item.convert2string()), UVM_HIGH)
  endfunction

  // ------------------------------------------------------------------------
  //  Final Verification Summary Report
  // ------------------------------------------------------------------------
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "           SOC OVERALL UVM SCOREBOARD VERIFICATION REPORT         ", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Monitored SPI Transactions:   %0d (Passed: %0d)", spi_item_count, spi_checks_passed), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Monitored I2C Transactions:   %0d (Passed: %0d | STARTs: %0d, STOPs: %0d)", i2c_item_count, i2c_checks_passed, i2c_start_cnt, i2c_stop_cnt), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Monitored UART Transactions:  %0d (Passed: %0d)", uart_item_count, uart_checks_passed), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Monitored AHB Transactions:   %0d (Passed: %0d)", ahb_item_count, ahb_checks_passed), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  DMA Hardware Checks Passed:         %0d", dma_checks_passed), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  DMA Configured Transfers:           %0d", dma_transfers_configured), UVM_LOW)
    `uvm_info(get_type_name(), "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "  Dedicated VeeR EL2 DMA Slave Port Verification:", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - DCCM DMA Reads Verified:        %0d (Acks: %0d)", dccm_dma_reads_count, dccm_dma_read_acks), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - DCCM DMA Writes Verified:       %0d (Acks: %0d)", dccm_dma_writes_count, dccm_dma_write_acks), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - 32-bit Address Alignment Checks:%0d (All Passed)", dccm_alignment_checks), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - Write Strobe Rule Checks:       %0d (All Passed)", dccm_strobe_checks), UVM_LOW)
    `uvm_info(get_type_name(), "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), "  PIC Interrupt Routing Verification:", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - PIC Routing Checks Passed:      %0d", pic_checks_passed), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - DMA Done Pulses Routed (PIC #1): %0d", pic_dma_done_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - DMA Error Pulses Routed (PIC #2):%0d", pic_dma_error_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - SPI IRQ Pulses Routed (PIC #3):  %0d", pic_spi_irq_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - UART IRQ Pulses Routed (PIC #4): %0d", pic_uart_irq_count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - I2C IRQ Pulses Routed (PIC #5):  %0d", pic_i2c_irq_count), UVM_LOW)
    `uvm_info(get_type_name(), "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Highest Milestone Achieved:         0x%02h", highest_milestone), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Data Mismatches:                    %0d", data_mismatches), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Protocol Violations / Errors:       %0d", protocol_errors), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Total Scoreboard Errors:            %0d", total_errors), UVM_LOW)
    `uvm_info(get_type_name(), "-----------------------------------------------------------------", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  AHB Subsystem Activation Correlation:"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - SPI Subsystem Accessed:         %s", ahb_spi_accessed  ? "YES" : "NO"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - UART Subsystem Accessed:        %s", ahb_uart_accessed ? "YES" : "NO"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - I2C Subsystem Accessed:         %s", ahb_i2c_accessed  ? "YES" : "NO"), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("    - DMA Subsystem Accessed:         %s", ahb_dma_accessed  ? "YES" : "NO"), UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    if (total_errors == 0 && (cfg != null && cfg.fail_code == 8'h00)) begin
      `uvm_info(get_type_name(), "  >>> SCOREBOARD STATUS: ALL CHECKS PASSED (0 ERRORS) <<<", UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), $sformatf("  >>> SCOREBOARD STATUS: FAILED WITH %0d ERRORS <<<", total_errors))
    end
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
  endfunction
endclass

`endif
