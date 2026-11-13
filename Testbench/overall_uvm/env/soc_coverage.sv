//==========================================================================
//  soc_coverage.sv – Enhanced Functional Coverage Collector for VeeR EL2 SoC
//==========================================================================

`ifndef SOC_COVERAGE_SV
`define SOC_COVERAGE_SV

`uvm_analysis_imp_decl(_cov_spi)
`uvm_analysis_imp_decl(_cov_i2c)
`uvm_analysis_imp_decl(_cov_uart)
`uvm_analysis_imp_decl(_cov_ahb)

class soc_coverage extends uvm_subscriber #(uvm_sequence_item);
  `uvm_component_utils(soc_coverage)

  // Subscribed analysis ports
  uvm_analysis_imp_cov_spi  #(spi_item,  soc_coverage) spi_cov_export;
  uvm_analysis_imp_cov_i2c  #(i2c_item,  soc_coverage) i2c_cov_export;
  uvm_analysis_imp_cov_uart #(uart_item, soc_coverage) uart_cov_export;
  uvm_analysis_imp_cov_ahb  #(ahb_item,  soc_coverage) ahb_cov_export;

  // Monitored items for sampling
  spi_item  curr_spi_item;
  i2c_item  curr_i2c_item;
  uart_item curr_uart_item;
  ahb_item  curr_ahb_item;

  soc_config cfg;

  // Active flags for cross-protocol & contention coverage
  bit spi_active       = 0;
  bit i2c_active       = 0;
  bit uart_active      = 0;
  bit dma_active       = 0;
  bit cpu_active       = 0;

  // Shadow DMA tracking variables for coverage
  logic [31:0] cov_dma_src;
  logic [31:0] cov_dma_dst;
  logic [31:0] cov_dma_bytes;
  logic [31:0] cov_dma_cfg;
  int          cov_dma_dir; // 0=M2M, 1=M2P, 2=P2M
  bit          cov_dma_abort;
  bit          cov_dma_done;

  // Shadow Protocol tracking variables
  bit [4:0]    cov_pic_irqs; // bits: [0]=DMA_done, [1]=DMA_err, [2]=SPI, [3]=UART, [4]=I2C
  bit          cov_i2c_is_read;
  bit          cov_i2c_nack_seen;
  bit          cov_spi_mode3;

  // ------------------------------------------------------------------------
  //  Covergroups
  // ------------------------------------------------------------------------

  // 1. SPI Protocol & Modes Coverage
  covergroup spi_cg;
    option.per_instance = 1;
    option.name = "spi_protocol_and_modes_coverage";

    cp_cs: coverpoint curr_spi_item.spi_cs_n_o {
      bins active   = {1'b0};
      bins inactive = {1'b1};
    }
    cp_sclk: coverpoint curr_spi_item.spi_clk_o {
      bins low  = {1'b0};
      bins high = {1'b1};
    }
    cp_mosi: coverpoint curr_spi_item.spi_mosi_o {
      bins zero = {1'b0};
      bins one  = {1'b1};
    }
    cp_miso: coverpoint curr_spi_item.spi_miso_i {
      bins zero = {1'b0};
      bins one  = {1'b1};
    }
    cp_mode: coverpoint cov_spi_mode3 {
      bins mode0_cpol0_cpha0 = {1'b0};
      bins mode3_cpol1_cpha1 = {1'b1};
    }
    cross cp_cs, cp_sclk;
    cross cp_mosi, cp_miso;
  endgroup

  // 2. I2C Protocol & Transactions Coverage
  covergroup i2c_cg;
    option.per_instance = 1;
    option.name = "i2c_protocol_and_transactions_coverage";

    cp_scl: coverpoint curr_i2c_item.i2c_scl {
      bins low  = {1'b0};
      bins high = {1'b1};
    }
    cp_sda: coverpoint curr_i2c_item.i2c_sda {
      bins low  = {1'b0};
      bins high = {1'b1};
    }
    cp_direction: coverpoint cov_i2c_is_read {
      bins write_transfer = {1'b0};
      bins read_transfer  = {1'b1};
    }
    cp_nack: coverpoint cov_i2c_nack_seen {
      bins ack_normal = {1'b0};
      bins nack_error = {1'b1};
    }
    cross cp_scl, cp_sda;
  endgroup

  // 3. UART Serial & Flow Control Coverage
  covergroup uart_cg;
    option.per_instance = 1;
    option.name = "uart_protocol_and_flow_control_coverage";

    cp_tx: coverpoint curr_uart_item.uart_tx_o {
      bins low  = {1'b0};
      bins high = {1'b1};
    }
    cp_rx: coverpoint curr_uart_item.uart_rx_i {
      bins low  = {1'b0};
      bins high = {1'b1};
    }
    cp_rts: coverpoint curr_uart_item.uart_rts_o {
      bins asserted   = {1'b0};
      bins deasserted = {1'b1};
    }
    cp_cts: coverpoint curr_uart_item.uart_cts_i {
      bins ready     = {1'b1};
      bins not_ready = {1'b0};
    }
    cross cp_tx, cp_rx;
  endgroup

  // 4. Concurrent Protocol Cross-Coverage
  covergroup concurrent_protocol_cg;
    option.per_instance = 1;
    option.name = "combined_concurrent_traffic_coverage";

    cp_spi_active: coverpoint spi_active {
      bins idle   = {1'b0};
      bins active = {1'b1};
    }
    cp_i2c_active: coverpoint i2c_active {
      bins idle   = {1'b0};
      bins active = {1'b1};
    }
    cp_uart_active: coverpoint uart_active {
      bins idle   = {1'b0};
      bins active = {1'b1};
    }
    cross cp_spi_active, cp_i2c_active, cp_uart_active;
  endgroup

  // 5. AHB-Lite Subsystem Bus Coverage
  covergroup ahb_bus_cg;
    option.per_instance = 1;
    option.name = "ahb_bus_monitoring_coverage";

    cp_write: coverpoint curr_ahb_item.hwrite {
      bins read  = {1'b0};
      bins write = {1'b1};
    }
    cp_size: coverpoint curr_ahb_item.hsize {
      bins byte_size     = {3'b000};
      bins halfword_size = {3'b001};
      bins word_size     = {3'b010};
      bins dword_size    = {3'b011};
    }
    cp_target: coverpoint curr_ahb_item.get_target_id() {
      bins spi  = {AHB_TARGET_SPI, AHB_TARGET_SPI_ALIAS};
      bins uart = {AHB_TARGET_UART, AHB_TARGET_UART_ALIAS};
      bins i2c  = {AHB_TARGET_I2C, AHB_TARGET_I2C_ALIAS};
      bins dma  = {AHB_TARGET_DMA_CSR};
      bins dccm = {AHB_TARGET_DCCM, AHB_TARGET_DCCM_ALIAS};
    }
    cross cp_write, cp_size;
    cross cp_target, cp_write;
  endgroup

  // 6. DMA Subsystem Operations & Register Access Coverage
  covergroup dma_cg;
    option.per_instance = 1;
    option.name = "dma_subsystem_coverage";

    cp_dma_trans: coverpoint curr_ahb_item.hwrite iff (curr_ahb_item.get_target_id() == AHB_TARGET_DMA_CSR) {
      bins csr_read  = {1'b0};
      bins csr_write = {1'b1};
    }
    cp_dma_reg: coverpoint curr_ahb_item.haddr[7:0] iff (curr_ahb_item.get_target_id() == AHB_TARGET_DMA_CSR) {
      bins ctrl     = {8'h00};
      bins status   = {8'h08};
      bins src_addr = {8'h20};
      bins dst_addr = {8'h30};
      bins bytes    = {8'h40};
      bins cfg      = {8'h50};
    }
  endgroup

  // 7. DMA Functional Transfers & Directions Coverage
  covergroup dma_transfer_cg;
    option.per_instance = 1;
    option.name = "dma_functional_transfers_coverage";

    cp_dir: coverpoint cov_dma_dir {
      bins m2m_dccm_to_dccm = {0};
      bins m2p_dccm_to_per  = {1};
      bins p2m_per_to_dccm  = {2};
    }
    cp_len: coverpoint cov_dma_bytes {
      bins single_byte = {1};
      bins burst_bytes = {8};
    }
    cp_cfg_mode: coverpoint cov_dma_cfg[2:0] {
      bins incr_incr = {3'b100};
      bins fixed_wr  = {3'b101};
      bins fixed_rd  = {3'b110};
    }
    cp_abort: coverpoint cov_dma_abort {
      bins abort_asserted = {1'b1};
    }
    cross cp_dir, cp_len;
  endgroup

  // 8. CPU-DMA Bus Contention Coverage
  covergroup cpu_dma_contention_cg;
    option.per_instance = 1;
    option.name = "cpu_dma_contention_coverage";

    cp_dma: coverpoint dma_active {
      bins idle = {1'b0};
      bins busy = {1'b1};
    }
    cp_cpu: coverpoint cpu_active {
      bins idle = {1'b0};
      bins busy = {1'b1};
    }
    cross cp_dma, cp_cpu;
  endgroup

  // 9. PIC Interrupt Routing Coverage
  covergroup pic_interrupt_cg;
    option.per_instance = 1;
    option.name = "pic_interrupt_routing_coverage";

    cp_irq_dma_done: coverpoint cov_pic_irqs[0] {
      bins asserted = {1'b1};
    }
    cp_irq_spi: coverpoint cov_pic_irqs[2] {
      bins asserted = {1'b1};
    }
    cp_irq_uart: coverpoint cov_pic_irqs[3] {
      bins asserted = {1'b1};
    }
    cp_irq_i2c: coverpoint cov_pic_irqs[4] {
      bins asserted = {1'b1};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    spi_cov_export  = new("spi_cov_export",  this);
    i2c_cov_export  = new("i2c_cov_export",  this);
    uart_cov_export = new("uart_cov_export", this);
    ahb_cov_export  = new("ahb_cov_export",  this);

    spi_cg                 = new();
    i2c_cg                 = new();
    uart_cg                = new();
    concurrent_protocol_cg = new();
    ahb_bus_cg             = new();
    dma_cg                 = new();
    dma_transfer_cg        = new();
    cpu_dma_contention_cg  = new();
    pic_interrupt_cg       = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "Coverage: soc_config not found via config_db; direct handle will be used", UVM_HIGH)
    end
  endfunction

  virtual function void write(uvm_sequence_item t);
  endfunction

  virtual function void write_cov_spi(spi_item item);
    if (cfg != null && !cfg.enable_coverage) return;
    curr_spi_item = item;
    spi_active = (!item.spi_cs_n_o);
    spi_cg.sample();
    concurrent_protocol_cg.sample();
  endfunction

  virtual function void write_cov_i2c(i2c_item item);
    if (cfg != null && !cfg.enable_coverage) return;
    curr_i2c_item = item;
    i2c_active = (item.i2c_scl == 1'b0 || item.i2c_sda == 1'b0);
    i2c_cg.sample();
    concurrent_protocol_cg.sample();
  endfunction

  virtual function void write_cov_uart(uart_item item);
    if (cfg != null && !cfg.enable_coverage) return;
    curr_uart_item = item;
    uart_active = (item.uart_tx_o == 1'b0 || item.uart_rx_i == 1'b0);
    uart_cg.sample();
    concurrent_protocol_cg.sample();
  endfunction

  virtual function void write_cov_ahb(ahb_item item);
    if (cfg != null && !cfg.enable_coverage) return;
    curr_ahb_item = item;
    ahb_bus_cg.sample();

    // Check CPU activity (CPU executes if haddr not in unmapped)
    cpu_active = (item.htrans[1] == 1'b1);

    // Track PIC interrupts from ahb_item
    cov_pic_irqs[0] = item.extintsrc_req[1]; // DMA Done
    cov_pic_irqs[1] = item.extintsrc_req[2]; // DMA Error
    cov_pic_irqs[2] = item.extintsrc_req[3]; // SPI
    cov_pic_irqs[3] = item.extintsrc_req[4]; // UART
    cov_pic_irqs[4] = item.extintsrc_req[5]; // I2C
    pic_interrupt_cg.sample();

    // Track SPI CPOL/CPHA writes
    if (item.hwrite && (item.haddr[15:0] == 16'h1060)) begin
      cov_spi_mode3 = (item.hwdata[4:3] == 2'b11);
    end

    // Track I2C command & NACK
    if (item.hwrite && (item.haddr[15:0] == 16'h3010)) begin
      cov_i2c_is_read = item.hwdata[5];
    end
    if (item.hwrite && (item.haddr[15:0] == 16'h300c) && (item.hwdata[7:0] == 8'hFE)) begin
      cov_i2c_nack_seen = 1'b1;
    end

    // Track DMA CSR accesses and transfer configurations
    if (curr_ahb_item.get_target_id() == AHB_TARGET_DMA_CSR) begin
      dma_cg.sample();
      if (item.hwrite) begin
        case (item.haddr[7:0])
          8'h00: begin
            if (item.hwdata[0]) begin // Go
              dma_active = 1'b1;
              cov_dma_abort = 1'b0;
              // Determine direction:
              // M2M: DCCM(0x0000xxxx) -> DCCM(0x0000xxxx)
              // M2P: DCCM -> SPI/I2C
              // P2M: SPI/I2C -> DCCM
              if ((cov_dma_src[31:28] == 4'h0 || cov_dma_src[31:16] == 16'hF004) &&
                  (cov_dma_dst[31:28] == 4'h0 || cov_dma_dst[31:16] == 16'hF004)) begin
                cov_dma_dir = 0; // M2M
              end else if (cov_dma_src[31:28] == 4'h0 || cov_dma_src[31:16] == 16'hF004) begin
                cov_dma_dir = 1; // M2P
              end else begin
                cov_dma_dir = 2; // P2M
              end
              dma_transfer_cg.sample();
            end else if (item.hwdata[1]) begin // Abort
              dma_active = 1'b0;
              cov_dma_abort = 1'b1;
              dma_transfer_cg.sample();
            end
          end
          8'h20: cov_dma_src   = item.hwdata[31:0];
          8'h30: cov_dma_dst   = item.hwdata[31:0];
          8'h40: cov_dma_bytes = item.hwdata[31:0];
          8'h50: cov_dma_cfg   = item.hwdata[31:0];
        endcase
      end
    end

    // Sample contention during DMA active
    if (dma_active) begin
      cpu_dma_contention_cg.sample();
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "              SOC FUNCTIONAL COVERAGE SUMMARY REPORT             ", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  SPI Protocol & Modes Coverage:      %0.2f %%", spi_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  I2C Protocol & Trans Coverage:      %0.2f %%", i2c_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  UART Protocol & Control Coverage:   %0.2f %%", uart_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  DMA Subsystem CSR Coverage:         %0.2f %%", dma_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  DMA Functional Transfers Coverage:  %0.2f %%", dma_transfer_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  CPU-DMA Bus Contention Coverage:    %0.2f %%", cpu_dma_contention_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  PIC Interrupt Routing Coverage:     %0.2f %%", pic_interrupt_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  Concurrent Protocol Cross-Coverage: %0.2f %%", concurrent_protocol_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("  AHB Subsystem Bus Coverage:         %0.2f %%", ahb_bus_cg.get_coverage()), UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
  endfunction
endclass

`endif
