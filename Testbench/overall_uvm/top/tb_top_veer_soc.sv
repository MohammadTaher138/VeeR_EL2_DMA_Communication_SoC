//==========================================================================
//  tb_top_veer_soc.sv – Top-Level UVM Testbench Harness for VeeR EL2 SoC
//==========================================================================
//  Instantiates actual SoC RTL (top_veer_soc), binds external VIP interfaces
//  (SPI, I2C, UART), attaches the passive AHB-Lite bus monitor, preloads
//  firmware into the boot ROM, and launches the UVM environment.
//==========================================================================

`timescale 1ns/1ps
`default_nettype none

module tb_top_veer_soc;
  import uvm_pkg::*;
  import spi_pkg::*;
  import i2c_pkg::*;
  import uart_pkg::*;
  import soc_uvm_pkg::*;

  // --------------------------------------------------------------------
  //  1. Clock & Reset Generation
  // --------------------------------------------------------------------
  logic clk_i;
  logic rst_n_i;

  initial clk_i = 1'b0;
  always #5 clk_i = ~clk_i; // 100 MHz clock (10 ns period)

  initial begin
    rst_n_i = 1'b0;
    #40 rst_n_i = 1'b1;
    $display("[%0t] INFO – Hardware Reset deasserted", $time);
  end

  // --------------------------------------------------------------------
  //  2. VIP Protocol Interface Instances
  // --------------------------------------------------------------------
  spi_if          spi_vif();
  i2c_if          i2c_vif();
  uart_if         uart_vif();
  ahb_lite_mon_if ahb_vif(clk_i, rst_n_i);

  // Clock & Reset connections to VIP interfaces
  assign spi_vif.clk   = clk_i;
  assign spi_vif.rst_n = rst_n_i;

  assign i2c_vif.clk   = clk_i;
  assign i2c_vif.rst_n = rst_n_i;

  assign uart_vif.clk   = clk_i;
  assign uart_vif.rst_n = rst_n_i;

  // I2C Open-Drain Pullup Resistors
  pullup p_scl (i2c_vif.i2c_scl);
  pullup p_sda (i2c_vif.i2c_sda);

  // Note: External inputs (spi_miso_i, uart_rx_i, uart_cts_i, i2c_sda) are actively
  // driven and verified by the functional UVM VIP drivers (spi_driver, uart_driver, i2c_driver)

  // --------------------------------------------------------------------
  //  3. Actual VeeR EL2 Communication SoC DUT Instantiation
  // --------------------------------------------------------------------
  top_veer_soc u_dut (
    .clk_i      (clk_i),
    .rst_n_i    (rst_n_i),

    // SPI external pins
    .spi_clk_o  (spi_vif.spi_clk_o),
    .spi_cs_n_o (spi_vif.spi_cs_n_o),
    .spi_mosi_o (spi_vif.spi_mosi_o),
    .spi_miso_i (spi_vif.spi_miso_i),

    // UART external pins
    .uart_tx_o  (uart_vif.uart_tx_o),
    .uart_rx_i  (uart_vif.uart_rx_i),
    .uart_rts_o (uart_vif.uart_rts_o),
    .uart_cts_i (uart_vif.uart_cts_i),

    // I2C external pins (bidirectional open-drain)
    .i2c_scl    (i2c_vif.i2c_scl),
    .i2c_sda    (i2c_vif.i2c_sda)
  );

  // Connect I2C transfer direction indication to VIP interface
  assign i2c_vif.is_read = u_dut.u_i2c.cr[5];

  // --------------------------------------------------------------------
  //  4. Passive Internal AHB-Lite Bus Monitoring Probe
  // --------------------------------------------------------------------
  assign ahb_vif.haddr     = u_dut.sys_haddr;
  assign ahb_vif.htrans    = u_dut.sys_htrans;
  assign ahb_vif.hwrite    = u_dut.sys_hwrite;
  assign ahb_vif.hsize     = u_dut.sys_hsize;
  assign ahb_vif.hburst    = u_dut.sys_hburst;
  assign ahb_vif.hprot     = u_dut.sys_hprot;
  assign ahb_vif.hmastlock = u_dut.sys_hmastlock;
  assign ahb_vif.hready    = u_dut.sys_hready;
  assign ahb_vif.hresp     = u_dut.sys_hresp;
  assign ahb_vif.hwdata    = u_dut.sys_hwdata;
  assign ahb_vif.hrdata    = u_dut.sys_hrdata;

  // Interrupt monitoring connections
  assign ahb_vif.extintsrc_req = u_dut.extintsrc_req;
  assign ahb_vif.dma_done      = u_dut.dma_done;
  assign ahb_vif.dma_error     = u_dut.dma_error;

  // VeeR EL2 Dedicated DMA Slave Port monitoring connections
  assign ahb_vif.veer_dma_awvalid = u_dut.veer_dma_awvalid;
  assign ahb_vif.veer_dma_awready = u_dut.veer_dma_awready;
  assign ahb_vif.veer_dma_awaddr  = u_dut.veer_dma_awaddr;
  assign ahb_vif.veer_dma_awsize  = u_dut.veer_dma_awsize;
  assign ahb_vif.veer_dma_wvalid  = u_dut.veer_dma_wvalid;
  assign ahb_vif.veer_dma_wready  = u_dut.veer_dma_wready;
  assign ahb_vif.veer_dma_wdata   = u_dut.veer_dma_wdata;
  assign ahb_vif.veer_dma_wstrb   = u_dut.veer_dma_wstrb;
  assign ahb_vif.veer_dma_bvalid  = u_dut.veer_dma_bvalid;
  assign ahb_vif.veer_dma_bready  = u_dut.veer_dma_bready;
  assign ahb_vif.veer_dma_bresp   = u_dut.veer_dma_bresp;
  assign ahb_vif.veer_dma_arvalid = u_dut.veer_dma_arvalid;
  assign ahb_vif.veer_dma_arready = u_dut.veer_dma_arready;
  assign ahb_vif.veer_dma_araddr  = u_dut.veer_dma_araddr;
  assign ahb_vif.veer_dma_arsize  = u_dut.veer_dma_arsize;
  assign ahb_vif.veer_dma_rvalid  = u_dut.veer_dma_rvalid;
  assign ahb_vif.veer_dma_rready  = u_dut.veer_dma_rready;
  assign ahb_vif.veer_dma_rdata   = u_dut.veer_dma_rdata;
  assign ahb_vif.veer_dma_rresp   = u_dut.veer_dma_rresp;
  assign ahb_vif.veer_dma_rlast   = u_dut.veer_dma_rlast;

  // --------------------------------------------------------------------
  //  5. Firmware Boot ROM Preload
  // --------------------------------------------------------------------
  string hex_file_path = "firmware.hex";
  int hex_fd;
  initial begin : load_firmware_hex
    #1ps;
    if ($value$plusargs("hex=%s", hex_file_path) || $value$plusargs("firmware=%s", hex_file_path)) begin
      $display("[%0t] INFO – Firmware hex specified via plusarg: %s", $time, hex_file_path);
    end else begin
      hex_fd = $fopen("firmware.hex", "r");
      if (hex_fd != 0) begin
        $fclose(hex_fd);
        hex_file_path = "firmware.hex";
      end else begin
        hex_fd = $fopen("../Run/firmware.hex", "r");
        if (hex_fd != 0) begin
          $fclose(hex_fd);
          hex_file_path = "../Run/firmware.hex";
        end else begin
          hex_fd = $fopen("../../Run/firmware.hex", "r");
          if (hex_fd != 0) begin
            $fclose(hex_fd);
            hex_file_path = "../../Run/firmware.hex";
          end else begin
            hex_fd = $fopen("../../Firmware/firmware.hex", "r");
            if (hex_fd != 0) begin
              $fclose(hex_fd);
              hex_file_path = "../../Firmware/firmware.hex";
            end
          end
        end
      end
    end
    if (hex_fd != 0 || hex_file_path != "") begin
      $display("[%0t] INFO – Loading firmware into IFU boot ROM: %s", $time, hex_file_path);
      $readmemh(hex_file_path, u_dut.u_ifu_rom.rom_mem);
    end
  end

  // --------------------------------------------------------------------
  //  6. UVM Configuration DB Registration & Simulation Launch
  // --------------------------------------------------------------------
  soc_config top_cfg;

  always @(u_dut.u_dccm_ram.mem[16'h0100] or u_dut.u_dccm_ram.mem[16'h0108] or u_dut.u_dccm_ram.mem[16'h0104]) begin
    if (top_cfg != null) begin
      top_cfg.current_milestone = u_dut.u_dccm_ram.mem[16'h0100];
      top_cfg.fail_code         = u_dut.u_dccm_ram.mem[16'h0108];
      top_cfg.isr_count         = u_dut.u_dccm_ram.mem[16'h0104];
      if (top_cfg.current_milestone == 8'hAA) begin
        top_cfg.all_tests_passed = 1'b1;
      end
      -> top_cfg.milestone_ev;
    end
  end

  initial begin
    // Register VIP virtual interfaces with uvm_config_db
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", spi_vif);
    uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", i2c_vif);
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_vif);
    uvm_config_db#(virtual ahb_lite_mon_if)::set(null, "*", "vif", ahb_vif);

    // Register top-level configuration object with virtual interface handles
    top_cfg = soc_config::type_id::create("top_cfg");
    top_cfg.spi_vif  = spi_vif;
    top_cfg.i2c_vif  = i2c_vif;
    top_cfg.uart_vif = uart_vif;
    top_cfg.ahb_vif  = ahb_vif;
    uvm_config_db#(soc_config)::set(null, "*", "cfg", top_cfg);

    // Launch top UVM test
    run_test("soc_overall_test");
  end
endmodule
`default_nettype wire
