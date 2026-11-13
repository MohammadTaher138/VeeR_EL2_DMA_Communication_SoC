//==========================================================================
//  top_veer_soc.sv – Complete System‑on‑Chip for VeeR‑EL2 + Interconnect +
//                     DMA + SPI + I²C + UART
//==========================================================================

`default_nettype none

module top_veer_soc
import el2_pkg::*;
import amba_axi_pkg::*;
#(
`include "el2_param.vh"
)
(
  // Global clocks and reset
  input  logic        clk_i,        // system clock
  input  logic        rst_n_i,      // active‑low reset (global)

  // External pins for peripheral IPs
  // SPI pins
  output logic        spi_clk_o,
  output logic        spi_cs_n_o,
  output logic        spi_mosi_o,
  input  logic        spi_miso_i,

  // UART pins
  output logic        uart_tx_o,
  input  logic        uart_rx_i,
  output logic        uart_rts_o,
  input  logic        uart_cts_i,

  // I²C pins (Open‑Drain)
  inout  wire         i2c_scl,
  inout  wire         i2c_sda
);

  // Local reset (active‑high inside the design)
  logic  rst_l;
  assign rst_l = rst_n_i;

  // Interrupt and status wires
  logic        dma_done;
  logic        dma_error;
  logic        uart_irq;
  logic        spi_irq;

  // CPU Execution Trace Wires
  logic [31:0] cpu_trace_insn;
  logic [31:0] cpu_trace_addr;
  logic        cpu_trace_valid;
  logic        cpu_trace_interrupt;

  // Core DCCM SRAM interface wires
  logic                          dccm_core_wren;
  logic                          dccm_core_rden;
  logic [pt.DCCM_BITS-1:0]       dccm_core_wr_addr_lo;
  logic [pt.DCCM_BITS-1:0]       dccm_core_wr_addr_hi;
  logic [pt.DCCM_BITS-1:0]       dccm_core_rd_addr_lo;
  logic [pt.DCCM_FDATA_WIDTH-1:0] dccm_core_wr_data_lo;
  logic [pt.DCCM_FDATA_WIDTH-1:0] dccm_core_wr_data_hi;
  logic [pt.DCCM_FDATA_WIDTH-1:0] dccm_core_rd_data_lo;
  logic [pt.DCCM_FDATA_WIDTH-1:0] dccm_core_rd_data_hi;

  // IFU AXI instruction fetch interface wires
  logic                            ifu_axi_arvalid;
  logic                            ifu_axi_arready;
  logic [pt.IFU_BUS_TAG-1:0]       ifu_axi_arid;
  logic [31:0]                     ifu_axi_araddr;
  logic [7:0]                      ifu_axi_arlen;
  logic [2:0]                      ifu_axi_arsize;
  logic [1:0]                      ifu_axi_arburst;
  logic                            ifu_axi_rvalid;
  logic                            ifu_axi_rready;
  logic [pt.IFU_BUS_TAG-1:0]       ifu_axi_rid;
  logic [63:0]                     ifu_axi_rdata;
  logic [1:0]                      ifu_axi_rresp;
  logic                            ifu_axi_rlast;

  // VeeR EL2 DMA AXI slave port wires
  logic                            veer_dma_awvalid;
  logic                            veer_dma_awready;
  logic [pt.DMA_BUS_TAG-1:0]       veer_dma_awid;
  logic [31:0]                     veer_dma_awaddr;
  logic [2:0]                      veer_dma_awsize;
  logic [2:0]                      veer_dma_awprot;
  logic [7:0]                      veer_dma_awlen;
  logic [1:0]                      veer_dma_awburst;
  logic                            veer_dma_wvalid;
  logic                            veer_dma_wready;
  logic [63:0]                     veer_dma_wdata;
  logic [7:0]                      veer_dma_wstrb;
  logic                            veer_dma_wlast;
  logic                            veer_dma_bvalid;
  logic                            veer_dma_bready;
  logic [1:0]                      veer_dma_bresp;
  logic [pt.DMA_BUS_TAG-1:0]       veer_dma_bid;
  logic                            veer_dma_arvalid;
  logic                            veer_dma_arready;
  logic [pt.DMA_BUS_TAG-1:0]       veer_dma_arid;
  logic [31:0]                     veer_dma_araddr;
  logic [2:0]                      veer_dma_arsize;
  logic [2:0]                      veer_dma_arprot;
  logic [7:0]                      veer_dma_arlen;
  logic [1:0]                      veer_dma_arburst;
  logic                            veer_dma_rvalid;
  logic                            veer_dma_rready;
  logic [pt.DMA_BUS_TAG-1:0]       veer_dma_rid;
  logic [63:0]                     veer_dma_rdata;
  logic [1:0]                      veer_dma_rresp;
  logic                            veer_dma_rlast;

  // VeeR LSU AXI interface signals
  logic                            lsu_axi_awvalid;
  logic                            lsu_axi_awready;
  logic [pt.LSU_BUS_TAG-1:0]       lsu_axi_awid;
  logic [31:0]                     lsu_axi_awaddr;
  logic [2:0]                      lsu_axi_awsize;
  logic [2:0]                      lsu_axi_awprot;
  logic                            lsu_axi_wvalid;
  logic                            lsu_axi_wready;
  logic [63:0]                     lsu_axi_wdata;
  logic [7:0]                      lsu_axi_wstrb;
  logic                            lsu_axi_wlast;
  logic                            lsu_axi_bvalid;
  logic                            lsu_axi_bready;
  logic [1:0]                      lsu_axi_bresp;
  logic [pt.LSU_BUS_TAG-1:0]       lsu_axi_bid;
  logic                            lsu_axi_arvalid;
  logic                            lsu_axi_arready;
  logic [pt.LSU_BUS_TAG-1:0]       lsu_axi_arid;
  logic [31:0]                     lsu_axi_araddr;
  logic [2:0]                      lsu_axi_arsize;
  logic [2:0]                      lsu_axi_arprot;
  logic                            lsu_axi_rvalid;
  logic                            lsu_axi_rready;
  logic [pt.LSU_BUS_TAG-1:0]       lsu_axi_rid;
  logic [63:0]                     lsu_axi_rdata;
  logic [1:0]                      lsu_axi_rresp;
  logic                            lsu_axi_rlast;

  // --------------------------------------------------------------------
  //  1) VeeR‑EL2 CPU AHB‑Lite / DMA ports
  // --------------------------------------------------------------------
  logic [31:0]  cpu_haddr;
  logic [2:0]   cpu_hburst;
  logic         cpu_hmastlock;
  logic [3:0]   cpu_hprot;
  logic [2:0]   cpu_hsize;
  logic [1:0]   cpu_htrans;
  logic         cpu_hwrite;
  logic [63:0]  cpu_hwdata;
  logic [63:0]  cpu_hrdata;
  logic         cpu_hready;
  logic         cpu_hresp;

  // DMA AHB‑Lite master ports
  logic         dma_hsel;
  logic [31:0]  dma_haddr;
  logic [2:0]   dma_hburst;
  logic         dma_hmastlock;
  logic [3:0]   dma_hprot;
  logic [2:0]   dma_hsize;
  logic [1:0]   dma_htrans;
  logic         dma_hwrite;
  logic [63:0]  dma_hwdata;
  logic [63:0]  dma_hrdata;
  logic         dma_hreadyin;
  logic         dma_hreadyout;
  logic         dma_hresp;

  // Unified System AHB bus (arbitrated between CPU and DMA)
  logic [31:0]  sys_haddr;
  logic [2:0]   sys_hburst;
  logic         sys_hmastlock;
  logic [3:0]   sys_hprot;
  logic [2:0]   sys_hsize;
  logic [1:0]   sys_htrans;
  logic         sys_hwrite;
  logic [63:0]  sys_hwdata;
  logic [63:0]  sys_hrdata;
  logic         sys_hready;
  logic         sys_hresp;

  // Interrupt vector to the VeeR PIC
  logic [pt.PIC_TOTAL_INT_PLUS1-1:0] extintsrc_req;

  // VeeR-EL2 Core Instance
  el2_veer #(.pt(pt)) u_veer (
    .clk                 (clk_i),
    .rst_l               (rst_l),
    .dbg_rst_l           (rst_l),
    .rst_vec             (31'h4000_0000),
    .nmi_int             (1'b0),
    .nmi_vec             (31'h0),
    .core_rst_l          (),
    .active_l2clk        (),
    .free_l2clk          (),
    .trace_rv_i_insn_ip  (cpu_trace_insn),
    .trace_rv_i_address_ip(cpu_trace_addr),
    .trace_rv_i_valid_ip (cpu_trace_valid),
    .trace_rv_i_exception_ip(),
    .trace_rv_i_ecause_ip(),
    .trace_rv_i_interrupt_ip(cpu_trace_interrupt),
    .trace_rv_i_tval_ip  (),
    .dccm_clk_override   (),
    .icm_clk_override    (),
    .dec_tlu_core_ecc_disable(),
    .dec_tlu_dccm_wr_readback_disable(),
    .i_cpu_halt_req      (1'b0),
    .i_cpu_run_req       (1'b1),
    .o_cpu_halt_ack      (),
    .o_cpu_halt_status   (),
    .o_cpu_run_ack       (),
    .o_debug_mode_status (),
    .core_id             (28'h0),
    .mpc_debug_halt_req  (1'b0),
    .mpc_debug_run_req   (1'b1),
    .mpc_reset_run_req   (1'b1),
    .mpc_debug_halt_ack  (),
    .mpc_debug_run_ack   (),
    .debug_brkpt_status  (),
    .dec_tlu_perfcnt0    (),
    .dec_tlu_perfcnt1    (),
    .dec_tlu_perfcnt2    (),
    .dec_tlu_perfcnt3    (),
    .dccm_wren           (dccm_core_wren),
    .dccm_rden           (dccm_core_rden),
    .dccm_wr_addr_lo     (dccm_core_wr_addr_lo),
    .dccm_wr_addr_hi     (dccm_core_wr_addr_hi),
    .dccm_rd_addr_lo     (dccm_core_rd_addr_lo),
    .dccm_rd_addr_hi     (),
    .dccm_wr_data_lo     (dccm_core_wr_data_lo),
    .dccm_wr_data_hi     (dccm_core_wr_data_hi),
    .dccm_rd_data_lo     (dccm_core_rd_data_lo),
    .dccm_rd_data_hi     (dccm_core_rd_data_hi),
    .iccm_rw_addr        (),
    .iccm_wren           (),
    .iccm_rden           (),
    .iccm_wr_size        (),
    .iccm_wr_data        (),
    .iccm_buf_correct_ecc(),
    .iccm_correction_state(),
    .iccm_rd_data_ecc    (78'h0),
    .ic_rw_addr          (),
    .ic_tag_valid        (),
    .ic_wr_en            (),
    .ic_rd_en            (),
    .ic_wr_data          (),
    .ic_rd_data          (142'h0),
    .ic_rd_addr_lo       (2'b0),
    .ic_rd_bank_check_en (2'b0),
    .ic_debug_rd_data    (71'h0),
    .ictag_debug_rd_data (26'h0),
    .ic_debug_wr_data    (),
    .ic_debug_addr       (),
    .ic_debug_rd_en      (),
    .ic_debug_wr_en      (),
    .ic_debug_tag_array  (),
    .ic_debug_way        (),
    .ic_rd_hit           (2'b0),
    .ic_tag_perr         (1'b0),

    // AXI Bus interfaces
    .lsu_axi_awvalid     (lsu_axi_awvalid),
    .lsu_axi_awready     (lsu_axi_awready),
    .lsu_axi_awid        (lsu_axi_awid),
    .lsu_axi_awaddr      (lsu_axi_awaddr),
    .lsu_axi_awregion    (),
    .lsu_axi_awlen       (),
    .lsu_axi_awsize      (lsu_axi_awsize),
    .lsu_axi_awburst     (),
    .lsu_axi_awlock      (),
    .lsu_axi_awcache     (),
    .lsu_axi_awprot      (lsu_axi_awprot),
    .lsu_axi_awqos       (),
    .lsu_axi_wvalid      (lsu_axi_wvalid),
    .lsu_axi_wready      (lsu_axi_wready),
    .lsu_axi_wdata       (lsu_axi_wdata),
    .lsu_axi_wstrb       (lsu_axi_wstrb),
    .lsu_axi_wlast       (lsu_axi_wlast),
    .lsu_axi_bvalid      (lsu_axi_bvalid),
    .lsu_axi_bready      (lsu_axi_bready),
    .lsu_axi_bresp       (lsu_axi_bresp),
    .lsu_axi_bid         (lsu_axi_bid),
    .lsu_axi_arvalid     (lsu_axi_arvalid),
    .lsu_axi_arready     (lsu_axi_arready),
    .lsu_axi_arid        (lsu_axi_arid),
    .lsu_axi_araddr      (lsu_axi_araddr),
    .lsu_axi_arregion    (),
    .lsu_axi_arlen       (),
    .lsu_axi_arsize      (lsu_axi_arsize),
    .lsu_axi_arburst     (),
    .lsu_axi_arlock      (),
    .lsu_axi_arcache     (),
    .lsu_axi_arprot      (lsu_axi_arprot),
    .lsu_axi_arqos       (),
    .lsu_axi_rvalid      (lsu_axi_rvalid),
    .lsu_axi_rready      (lsu_axi_rready),
    .lsu_axi_rid         (lsu_axi_rid),
    .lsu_axi_rdata       (lsu_axi_rdata),
    .lsu_axi_rresp       (lsu_axi_rresp),
    .lsu_axi_rlast       (lsu_axi_rlast),

    .ifu_axi_awvalid     (),
    .ifu_axi_awready     (1'b0),
    .ifu_axi_awid        (),
    .ifu_axi_awaddr      (),
    .ifu_axi_awregion    (),
    .ifu_axi_awlen       (),
    .ifu_axi_awsize      (),
    .ifu_axi_awburst     (),
    .ifu_axi_awlock      (),
    .ifu_axi_awcache     (),
    .ifu_axi_awprot      (),
    .ifu_axi_awqos       (),
    .ifu_axi_wvalid      (),
    .ifu_axi_wready      (1'b0),
    .ifu_axi_wdata       (),
    .ifu_axi_wstrb       (),
    .ifu_axi_wlast       (),
    .ifu_axi_bvalid      (1'b0),
    .ifu_axi_bready      (),
    .ifu_axi_bresp       (2'b0),
    .ifu_axi_bid         (3'b0),
    .ifu_axi_arvalid     (ifu_axi_arvalid),
    .ifu_axi_arready     (ifu_axi_arready),
    .ifu_axi_arid        (ifu_axi_arid),
    .ifu_axi_araddr      (ifu_axi_araddr),
    .ifu_axi_arregion    (),
    .ifu_axi_arlen       (ifu_axi_arlen),
    .ifu_axi_arsize      (ifu_axi_arsize),
    .ifu_axi_arburst     (ifu_axi_arburst),
    .ifu_axi_arlock      (),
    .ifu_axi_arcache     (),
    .ifu_axi_arprot      (),
    .ifu_axi_arqos       (),
    .ifu_axi_rvalid      (ifu_axi_rvalid),
    .ifu_axi_rready      (ifu_axi_rready),
    .ifu_axi_rid         (ifu_axi_rid),
    .ifu_axi_rdata       (ifu_axi_rdata),
    .ifu_axi_rresp       (ifu_axi_rresp),
    .ifu_axi_rlast       (ifu_axi_rlast),

    .sb_axi_awvalid      (),
    .sb_axi_awready      (1'b0),
    .sb_axi_awid         (),
    .sb_axi_awaddr       (),
    .sb_axi_awregion     (),
    .sb_axi_awlen        (),
    .sb_axi_awsize       (),
    .sb_axi_awburst      (),
    .sb_axi_awlock       (),
    .sb_axi_awcache      (),
    .sb_axi_awprot       (),
    .sb_axi_awqos        (),
    .sb_axi_wvalid       (),
    .sb_axi_wready       (1'b0),
    .sb_axi_wdata        (),
    .sb_axi_wstrb        (),
    .sb_axi_wlast        (),
    .sb_axi_bvalid       (1'b0),
    .sb_axi_bready       (),
    .sb_axi_bresp        (2'b0),
    .sb_axi_bid          (1'b0),
    .sb_axi_arvalid      (),
    .sb_axi_arready      (1'b0),
    .sb_axi_arid         (),
    .sb_axi_araddr       (),
    .sb_axi_arregion     (),
    .sb_axi_arlen        (),
    .sb_axi_arsize       (),
    .sb_axi_arburst      (),
    .sb_axi_arlock       (),
    .sb_axi_arcache      (),
    .sb_axi_arprot       (),
    .sb_axi_arqos        (),
    .sb_axi_rvalid       (1'b0),
    .sb_axi_rready       (),
    .sb_axi_rid          (1'b0),
    .sb_axi_rdata        (64'h0),
    .sb_axi_rresp        (2'b0),
    .sb_axi_rlast        (1'b0),

    .dma_axi_awvalid     (veer_dma_awvalid),
    .dma_axi_awready     (veer_dma_awready),
    .dma_axi_awid        (veer_dma_awid),
    .dma_axi_awaddr      (veer_dma_awaddr),
    .dma_axi_awsize      (veer_dma_awsize),
    .dma_axi_awprot      (veer_dma_awprot),
    .dma_axi_awlen       (veer_dma_awlen),
    .dma_axi_awburst     (veer_dma_awburst),
    .dma_axi_wvalid      (veer_dma_wvalid),
    .dma_axi_wready      (veer_dma_wready),
    .dma_axi_wdata       (veer_dma_wdata),
    .dma_axi_wstrb       (veer_dma_wstrb),
    .dma_axi_wlast       (veer_dma_wlast),
    .dma_axi_bvalid      (veer_dma_bvalid),
    .dma_axi_bready      (veer_dma_bready),
    .dma_axi_bresp       (veer_dma_bresp),
    .dma_axi_bid         (veer_dma_bid),
    .dma_axi_arvalid     (veer_dma_arvalid),
    .dma_axi_arready     (veer_dma_arready),
    .dma_axi_arid        (veer_dma_arid),
    .dma_axi_araddr      (veer_dma_araddr),
    .dma_axi_arsize      (veer_dma_arsize),
    .dma_axi_arprot      (veer_dma_arprot),
    .dma_axi_arlen       (veer_dma_arlen),
    .dma_axi_arburst     (veer_dma_arburst),
    .dma_axi_rvalid      (veer_dma_rvalid),
    .dma_axi_rready      (veer_dma_rready),
    .dma_axi_rid         (veer_dma_rid),
    .dma_axi_rdata       (veer_dma_rdata),
    .dma_axi_rresp       (veer_dma_rresp),
    .dma_axi_rlast       (veer_dma_rlast),

    // External interrupts
    .extintsrc_req       (extintsrc_req[pt.PIC_TOTAL_INT:1]),
    .timer_int           (1'b0),
    .soft_int            (1'b0),

    // Bus Clock Enables & DMI
    .lsu_bus_clk_en      (1'b1),
    .ifu_bus_clk_en      (1'b1),
    .dbg_bus_clk_en      (1'b1),
    .dma_bus_clk_en      (1'b1),
    .dmi_reg_en          (1'b0),
    .dmi_reg_addr        (7'h0),
    .dmi_reg_wr_en       (1'b0),
    .dmi_reg_wdata       (32'h0),
    .dmi_reg_rdata       (),
    .scan_mode           (1'b0)
  );

  // AXI4-to-AHB bridge for VeeR-EL2 LSU master
  axi4_to_ahb #(
    .pt  (pt),
    .TAG (pt.LSU_BUS_TAG)
  ) u_lsu_axi2ahb (
    .clk                 (clk_i),
    .free_clk            (clk_i),
    .rst_l               (rst_l),
    .scan_mode           (1'b0),
    .bus_clk_en          (1'b1),
    .clk_override        (1'b0),
    .dec_tlu_force_halt  (1'b0),

    .axi_awvalid         (lsu_axi_awvalid),
    .axi_awready         (lsu_axi_awready),
    .axi_awid            (lsu_axi_awid),
    .axi_awaddr          (lsu_axi_awaddr),
    .axi_awsize          (lsu_axi_awsize),
    .axi_awprot          (lsu_axi_awprot),

    .axi_wvalid          (lsu_axi_wvalid),
    .axi_wready          (lsu_axi_wready),
    .axi_wdata           (lsu_axi_wdata),
    .axi_wstrb           (lsu_axi_wstrb),
    .axi_wlast           (lsu_axi_wlast),

    .axi_bvalid          (lsu_axi_bvalid),
    .axi_bready          (lsu_axi_bready),
    .axi_bresp           (lsu_axi_bresp),
    .axi_bid             (lsu_axi_bid),

    .axi_arvalid         (lsu_axi_arvalid),
    .axi_arready         (lsu_axi_arready),
    .axi_arid            (lsu_axi_arid),
    .axi_araddr          (lsu_axi_araddr),
    .axi_arsize          (lsu_axi_arsize),
    .axi_arprot          (lsu_axi_arprot),

    .axi_rvalid          (lsu_axi_rvalid),
    .axi_rready          (lsu_axi_rready),
    .axi_rid             (lsu_axi_rid),
    .axi_rdata           (lsu_axi_rdata),
    .axi_rresp           (lsu_axi_rresp),
    .axi_rlast           (lsu_axi_rlast),

    .ahb_haddr           (cpu_haddr),
    .ahb_hburst          (cpu_hburst),
    .ahb_hmastlock       (cpu_hmastlock),
    .ahb_hprot           (cpu_hprot),
    .ahb_hsize           (cpu_hsize),
    .ahb_htrans          (cpu_htrans),
    .ahb_hwrite          (cpu_hwrite),
    .ahb_hwdata          (cpu_hwdata),

    .ahb_hrdata          (cpu_hrdata),
    .ahb_hready          (cpu_hready),
    .ahb_hresp           (cpu_hresp)
  );

  // --------------------------------------------------------------------
  //  2) Address decoder and AHB slave response multiplexer
  // --------------------------------------------------------------------
  logic hsel_dccm, hsel_spi, hsel_uart, hsel_i2c, hsel_dma_csr;
  logic [63:0] dccm_hrdata;
  logic        dccm_hready, dccm_hresp;

  // AHB Bus Arbiter between CPU and DMA
  logic dma_busy;
  logic dma_bus_active;
  assign dma_bus_active = dma_busy;

  always_comb begin
    if (dma_bus_active) begin
      sys_haddr     = dma_haddr;
      sys_hburst    = dma_hburst;
      sys_hmastlock = dma_hmastlock;
      sys_hprot     = dma_hprot;
      sys_hsize     = dma_hsize;
      sys_htrans    = dma_htrans;
      sys_hwrite    = dma_hwrite;
      sys_hwdata    = dma_hwdata;

      dma_hrdata    = sys_hrdata;
      dma_hreadyout = sys_hready;
      dma_hresp     = sys_hresp;

      cpu_hrdata    = '0;
      cpu_hready    = 1'b0;
      cpu_hresp     = 1'b0;
    end else begin
      sys_haddr     = cpu_haddr;
      sys_hburst    = cpu_hburst;
      sys_hmastlock = cpu_hmastlock;
      sys_hprot     = cpu_hprot;
      sys_hsize     = cpu_hsize;
      sys_htrans    = cpu_htrans;
      sys_hwrite    = cpu_hwrite;
      sys_hwdata    = cpu_hwdata;

      cpu_hrdata    = sys_hrdata;
      cpu_hready    = sys_hready;
      cpu_hresp     = sys_hresp;

      dma_hrdata    = '0;
      dma_hreadyout = 1'b1;
      dma_hresp     = 1'b0;
    end
  end

  address_decoder u_addrdec (
    .haddr        (sys_haddr),
    .hsel_dccm    (hsel_dccm),
    .hsel_spi     (hsel_spi),
    .hsel_uart    (hsel_uart),
    .hsel_i2c     (hsel_i2c),
    .hsel_dma_csr (hsel_dma_csr)
  );

  soc_dccm_ram #(
    .ADDR_WIDTH(16),
    .DATA_WIDTH(64)
  ) u_dccm_ram (
    .clk              (clk_i),
    .rst_l            (rst_l),
    .hsel             (hsel_dccm),
    .haddr            (sys_haddr),
    .htrans           (sys_htrans),
    .hwrite           (sys_hwrite),
    .hsize            (sys_hsize),
    .hwdata           (sys_hwdata),
    .hrdata           (dccm_hrdata),
    .hready           (dccm_hready),
    .hresp            (dccm_hresp),
    .core_wren        (dccm_core_wren),
    .core_rden        (dccm_core_rden),
    .core_wr_addr_lo  (dccm_core_wr_addr_lo[15:0]),
    .core_wr_addr_hi  (dccm_core_wr_addr_hi[15:0]),
    .core_rd_addr_lo  (dccm_core_rd_addr_lo[15:0]),
    .core_wr_data_lo  (dccm_core_wr_data_lo),
    .core_wr_data_hi  (dccm_core_wr_data_hi),
    .core_rd_data_lo  (dccm_core_rd_data_lo),
    .core_rd_data_hi  (dccm_core_rd_data_hi)
  );

  soc_ifu_boot_rom #(
    .TAG_WIDTH(pt.IFU_BUS_TAG)
  ) u_ifu_rom (
    .clk              (clk_i),
    .rst_l            (rst_l),
    .arvalid          (ifu_axi_arvalid),
    .arready          (ifu_axi_arready),
    .araddr           (ifu_axi_araddr),
    .arid             (ifu_axi_arid),
    .rvalid           (ifu_axi_rvalid),
    .rready           (ifu_axi_rready),
    .rid              (ifu_axi_rid),
    .rdata            (ifu_axi_rdata),
    .rresp            (ifu_axi_rresp),
    .rlast            (ifu_axi_rlast)
  );

  // Note: veer_dma_* ports are driven by dma_axi_master_router (VeeR EL2 Dedicated DMA Slave Port)

  // Separate AHB response signals from each bridge
  logic [63:0] spi_hrdata, uart_hrdata, i2c_hrdata, dma_csr_hrdata;
  logic        spi_hready, uart_hready, i2c_hready, dma_csr_hready;
  logic        spi_hresp,  uart_hresp,  i2c_hresp,  dma_csr_hresp;

  // AHB response stage registration
  logic [4:0] active_slave_q;
  always_ff @(posedge clk_i or negedge rst_l) begin
    if (!rst_l) begin
      active_slave_q <= 5'b0;
    end else if (sys_hready) begin
      if (sys_htrans[1]) begin
        active_slave_q <= {hsel_dccm, hsel_dma_csr, hsel_i2c, hsel_uart, hsel_spi};
      end else begin
        active_slave_q <= 5'b0;
      end
    end
  end

  always_comb begin
    case (active_slave_q)
      5'b00001: begin
        sys_hrdata = spi_hrdata;
        sys_hready = spi_hready;
        sys_hresp  = spi_hresp;
      end
      5'b00010: begin
        sys_hrdata = uart_hrdata;
        sys_hready = uart_hready;
        sys_hresp  = uart_hresp;
      end
      5'b00100: begin
        sys_hrdata = i2c_hrdata;
        sys_hready = i2c_hready;
        sys_hresp  = i2c_hresp;
      end
      5'b01000: begin
        sys_hrdata = dma_csr_hrdata;
        sys_hready = dma_csr_hready;
        sys_hresp  = dma_csr_hresp;
      end
      5'b10000: begin
        sys_hrdata = dccm_hrdata;
        sys_hready = dccm_hready;
        sys_hresp  = dccm_hresp;
      end
      default: begin
        sys_hrdata = 64'b0;
        sys_hready = 1'b1;
        sys_hresp  = 1'b0;
      end
    endcase
  end

  // --------------------------------------------------------------------
  //  3) Bridges (AHB -> AXI-Lite and AHB -> Wishbone)
  // --------------------------------------------------------------------
  // SPI bridge
  logic spi_awvalid, spi_awready, spi_wvalid, spi_wready, spi_wlast;
  logic spi_bvalid, spi_bready, spi_arvalid, spi_arready, spi_rvalid, spi_rready;
  logic [31:0] spi_awaddr, spi_araddr;
  logic [2:0]  spi_awprot, spi_arprot;
  logic [63:0] spi_wdata, spi_rdata;
  logic [7:0]  spi_wstrb, spi_bid, spi_rid;
  logic [1:0]  spi_bresp, spi_rresp;

  ahb2axi_lite_bridge #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64)
  ) u_spi_bridge (
    .clk            (clk_i),
    .rst_l          (rst_l),
    .hsel           (hsel_spi),
    .haddr          (sys_haddr),
    .hburst         (sys_hburst),
    .hmastlock      (sys_hmastlock),
    .hprot          (sys_hprot),
    .hsize          (sys_hsize),
    .htrans         (sys_htrans),
    .hwrite         (sys_hwrite),
    .hwdata         (sys_hwdata),
    .hrdata         (spi_hrdata),
    .hready         (spi_hready),
    .hresp          (spi_hresp),

    .axi_awvalid    (spi_awvalid),
    .axi_awready    (spi_awready),
    .axi_awaddr     (spi_awaddr),
    .axi_awprot     (spi_awprot),
    .axi_wvalid     (spi_wvalid),
    .axi_wready     (spi_wready),
    .axi_wdata      (spi_wdata),
    .axi_wstrb      (spi_wstrb),
    .axi_wlast      (spi_wlast),
    .axi_bvalid     (spi_bvalid),
    .axi_bready     (spi_bready),
    .axi_bid        (spi_bid),
    .axi_bresp      (spi_bresp),
    .axi_arvalid    (spi_arvalid),
    .axi_arready    (spi_arready),
    .axi_araddr     (spi_araddr),
    .axi_arprot     (spi_arprot),
    .axi_rvalid     (spi_rvalid),
    .axi_rready     (spi_rready),
    .axi_rid        (spi_rid),
    .axi_rdata      (spi_rdata),
    .axi_rresp      (spi_rresp)
  );

  // UART bridge
  logic uart_awvalid, uart_awready, uart_wvalid, uart_wready, uart_wlast;
  logic uart_bvalid, uart_bready, uart_arvalid, uart_arready, uart_rvalid, uart_rready;
  logic [31:0] uart_awaddr, uart_araddr;
  logic [2:0]  uart_awprot, uart_arprot;
  logic [63:0] uart_wdata, uart_rdata;
  logic [7:0]  uart_wstrb, uart_bid, uart_rid;
  logic [1:0]  uart_bresp, uart_rresp;

  ahb2axi_lite_bridge #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64)
  ) u_uart_bridge (
    .clk            (clk_i),
    .rst_l          (rst_l),
    .hsel           (hsel_uart),
    .haddr          (sys_haddr),
    .hburst         (sys_hburst),
    .hmastlock      (sys_hmastlock),
    .hprot          (sys_hprot),
    .hsize          (sys_hsize),
    .htrans         (sys_htrans),
    .hwrite         (sys_hwrite),
    .hwdata         (sys_hwdata),
    .hrdata         (uart_hrdata),
    .hready         (uart_hready),
    .hresp          (uart_hresp),

    .axi_awvalid    (uart_awvalid),
    .axi_awready    (uart_awready),
    .axi_awaddr     (uart_awaddr),
    .axi_awprot     (uart_awprot),
    .axi_wvalid     (uart_wvalid),
    .axi_wready     (uart_wready),
    .axi_wdata      (uart_wdata),
    .axi_wstrb      (uart_wstrb),
    .axi_wlast      (uart_wlast),
    .axi_bvalid     (uart_bvalid),
    .axi_bready     (uart_bready),
    .axi_bid        (uart_bid),
    .axi_bresp      (uart_bresp),
    .axi_arvalid    (uart_arvalid),
    .axi_arready    (uart_arready),
    .axi_araddr     (uart_araddr),
    .axi_arprot     (uart_arprot),
    .axi_rvalid     (uart_rvalid),
    .axi_rready     (uart_rready),
    .axi_rid        (uart_rid),
    .axi_rdata      (uart_rdata),
    .axi_rresp      (uart_rresp)
  );

  // DMA CSR bridge
  logic dma_csr_awvalid, dma_csr_awready, dma_csr_wvalid, dma_csr_wready, dma_csr_wlast;
  logic dma_csr_bvalid, dma_csr_bready, dma_csr_arvalid, dma_csr_arready, dma_csr_rvalid, dma_csr_rready;
  logic [31:0] dma_csr_awaddr, dma_csr_araddr;
  logic [2:0]  dma_csr_awprot, dma_csr_arprot;
  logic [63:0] dma_csr_wdata, dma_csr_rdata;
  logic [7:0]  dma_csr_wstrb, dma_csr_bid, dma_csr_rid;
  logic [1:0]  dma_csr_bresp, dma_csr_rresp;

  ahb2axi_lite_bridge #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64)
  ) u_dma_csr_bridge (
    .clk            (clk_i),
    .rst_l          (rst_l),
    .hsel           (hsel_dma_csr),
    .haddr          (sys_haddr),
    .hburst         (sys_hburst),
    .hmastlock      (sys_hmastlock),
    .hprot          (sys_hprot),
    .hsize          (sys_hsize),
    .htrans         (sys_htrans),
    .hwrite         (sys_hwrite),
    .hwdata         (sys_hwdata),
    .hrdata         (dma_csr_hrdata),
    .hready         (dma_csr_hready),
    .hresp          (dma_csr_hresp),

    .axi_awvalid    (dma_csr_awvalid),
    .axi_awready    (dma_csr_awready),
    .axi_awaddr     (dma_csr_awaddr),
    .axi_awprot     (dma_csr_awprot),
    .axi_wvalid     (dma_csr_wvalid),
    .axi_wready     (dma_csr_wready),
    .axi_wdata      (dma_csr_wdata),
    .axi_wstrb      (dma_csr_wstrb),
    .axi_wlast      (dma_csr_wlast),
    .axi_bvalid     (dma_csr_bvalid),
    .axi_bready     (dma_csr_bready),
    .axi_bid        (dma_csr_bid),
    .axi_bresp      (dma_csr_bresp),
    .axi_arvalid    (dma_csr_arvalid),
    .axi_arready    (dma_csr_arready),
    .axi_araddr     (dma_csr_araddr),
    .axi_arprot     (dma_csr_arprot),
    .axi_rvalid     (dma_csr_rvalid),
    .axi_rready     (dma_csr_rready),
    .axi_rid        (dma_csr_rid),
    .axi_rdata      (dma_csr_rdata),
    .axi_rresp      (dma_csr_rresp)
  );

  // I2C bridge
  logic i2c_wb_clk_i, i2c_wb_rst_i;
  logic [2:0] i2c_wb_adr_i;
  logic [7:0] i2c_wb_dat_i, i2c_wb_dat_o;
  logic       i2c_wb_we_i, i2c_wb_stb_i, i2c_wb_cyc_i, i2c_wb_ack_o, i2c_wb_inta_o;

  ahb2wishbone_bridge #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(64)
  ) u_i2c_bridge (
    .clk            (clk_i),
    .rst_l          (rst_l),
    .hsel           (hsel_i2c),
    .haddr          (sys_haddr),
    .hburst         (sys_hburst),
    .hmastlock      (sys_hmastlock),
    .hprot          (sys_hprot),
    .hsize          (sys_hsize),
    .htrans         (sys_htrans),
    .hwrite         (sys_hwrite),
    .hwdata         (sys_hwdata),
    .hrdata         (i2c_hrdata),
    .hready         (i2c_hready),
    .hresp          (i2c_hresp),

    .wb_clk_i       (i2c_wb_clk_i),
    .wb_rst_i       (i2c_wb_rst_i),
    .wb_adr_i       (i2c_wb_adr_i),
    .wb_dat_i       (i2c_wb_dat_i),
    .wb_dat_o       (i2c_wb_dat_o),
    .wb_we_i        (i2c_wb_we_i),
    .wb_stb_i       (i2c_wb_stb_i),
    .wb_cyc_i       (i2c_wb_cyc_i),
    .wb_ack_o       (i2c_wb_ack_o),
    .wb_inta_o      (i2c_wb_inta_o)
  );

  // --------------------------------------------------------------------
  //  4) DMA Controller & AXI Interconnect
  // --------------------------------------------------------------------
  s_axil_mosi_t  dma_csr_mosi;
  s_axil_miso_t  dma_csr_miso;
  s_axi_mosi_t   dma_m_mosi;
  s_axi_miso_t   dma_m_miso;

  // Connect AXI-Lite CSR signals
  assign dma_csr_mosi.awvalid = dma_csr_awvalid;
  assign dma_csr_awready      = dma_csr_miso.awready;
  assign dma_csr_mosi.awid    = '0;
  assign dma_csr_mosi.awaddr  = dma_csr_awaddr;
  assign dma_csr_mosi.awprot  = axi_prot_t'(dma_csr_awprot);
  assign dma_csr_mosi.wvalid  = dma_csr_wvalid;
  assign dma_csr_wready       = dma_csr_miso.wready;
  assign dma_csr_mosi.wdata   = dma_csr_awaddr[2] ? dma_csr_wdata[63:32] : dma_csr_wdata[31:0];
  assign dma_csr_mosi.wstrb   = dma_csr_awaddr[2] ? dma_csr_wstrb[7:4]   : dma_csr_wstrb[3:0];
  assign dma_csr_mosi.bready  = dma_csr_bready;
  assign dma_csr_bvalid       = dma_csr_miso.bvalid;
  assign dma_csr_bid          = {{(8-`AXI_TXN_ID_WIDTH){1'b0}}, dma_csr_miso.bid};
  assign dma_csr_bresp        = dma_csr_miso.bresp;
  assign dma_csr_mosi.arvalid = dma_csr_arvalid;
  assign dma_csr_arready      = dma_csr_miso.arready;
  assign dma_csr_mosi.arid    = '0;
  assign dma_csr_mosi.araddr  = dma_csr_araddr;
  assign dma_csr_mosi.arprot  = axi_prot_t'(dma_csr_arprot);
  assign dma_csr_mosi.rready  = dma_csr_rready;
  assign dma_csr_rvalid       = dma_csr_miso.rvalid;
  assign dma_csr_rid          = {{(8-`AXI_TXN_ID_WIDTH){1'b0}}, dma_csr_miso.rid};
  assign dma_csr_rdata        = {32'h0, dma_csr_miso.rdata};
  assign dma_csr_rresp        = dma_csr_miso.rresp;

  // DMA wrapper instance
  dma_axi_wrapper #(.DMA_ID_VAL(0)) u_dma_wrapper (
    .clk               (clk_i),
    .rst               (~rst_l),
    .dma_csr_mosi_i    (dma_csr_mosi),
    .dma_csr_miso_o    (dma_csr_miso),
    .dma_m_mosi_o      (dma_m_mosi),
    .dma_m_miso_i      (dma_m_miso),
    .dma_done_o        (dma_done),
    .dma_error_o       (dma_error)
  );

  // AXI Interconnect 2x6 instance (connects CPU LSU master + DMA master to Slaves)
  axi_interconnect_wrap_2x6 #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32),
    .STRB_WIDTH(4),
    .ID_WIDTH(8)
  ) u_interconnect (
    .clk               (clk_i),
    .rst               (~rst_l),

    // S00: CPU Master
    .s00_axi_awid      (8'h0),
    .s00_axi_awaddr    (cpu_haddr),
    .s00_axi_awlen     (8'h0),
    .s00_axi_awsize    (3'd2),
    .s00_axi_awburst   (2'b01),
    .s00_axi_awlock    (1'b0),
    .s00_axi_awcache   (4'h0),
    .s00_axi_awprot    (3'h0),
    .s00_axi_awqos     (4'h0),
    .s00_axi_awuser    (1'b0),
    .s00_axi_awvalid   (1'b0),
    .s00_axi_awready   (),
    .s00_axi_wdata     (cpu_hwdata[31:0]),
    .s00_axi_wstrb     (4'hF),
    .s00_axi_wlast     (1'b1),
    .s00_axi_wuser     (1'b0),
    .s00_axi_wvalid    (1'b0),
    .s00_axi_wready    (),
    .s00_axi_bid       (),
    .s00_axi_bresp     (),
    .s00_axi_buser     (),
    .s00_axi_bvalid    (),
    .s00_axi_bready    (1'b1),
    .s00_axi_arid      (8'h0),
    .s00_axi_araddr    (cpu_haddr),
    .s00_axi_arlen     (8'h0),
    .s00_axi_arsize    (3'd2),
    .s00_axi_arburst   (2'b01),
    .s00_axi_arlock    (1'b0),
    .s00_axi_arcache   (4'h0),
    .s00_axi_arprot    (3'h0),
    .s00_axi_arqos     (4'h0),
    .s00_axi_aruser    (1'b0),
    .s00_axi_arvalid   (1'b0),
    .s00_axi_arready   (),
    .s00_axi_rid       (),
    .s00_axi_rdata     (),
    .s00_axi_rresp     (),
    .s00_axi_rlast     (),
    .s00_axi_ruser     (),
    .s00_axi_rvalid    (),
    .s00_axi_rready    (1'b1),

    // S01: Secondary Master Port
    .s01_axi_awid      (8'h0),
    .s01_axi_awaddr    (32'h0),
    .s01_axi_awlen     (8'h0),
    .s01_axi_awsize    (3'd2),
    .s01_axi_awburst   (2'b01),
    .s01_axi_awlock    (1'b0),
    .s01_axi_awcache   (4'h0),
    .s01_axi_awprot    (3'h0),
    .s01_axi_awqos     (4'h0),
    .s01_axi_awuser    (1'b0),
    .s01_axi_awvalid   (1'b0),
    .s01_axi_awready   (),
    .s01_axi_wdata     (32'h0),
    .s01_axi_wstrb     (4'h0),
    .s01_axi_wlast     (1'b1),
    .s01_axi_wuser     (1'b0),
    .s01_axi_wvalid    (1'b0),
    .s01_axi_wready    (),
    .s01_axi_bid       (),
    .s01_axi_bresp     (),
    .s01_axi_buser     (),
    .s01_axi_bvalid    (),
    .s01_axi_bready    (1'b1),
    .s01_axi_arid      (8'h0),
    .s01_axi_araddr    (32'h0),
    .s01_axi_arlen     (8'h0),
    .s01_axi_arsize    (3'd2),
    .s01_axi_arburst   (2'b01),
    .s01_axi_arlock    (1'b0),
    .s01_axi_arcache   (4'h0),
    .s01_axi_arprot    (3'h0),
    .s01_axi_arqos     (4'h0),
    .s01_axi_aruser    (1'b0),
    .s01_axi_arvalid   (1'b0),
    .s01_axi_arready   (),
    .s01_axi_rid       (),
    .s01_axi_rdata     (),
    .s01_axi_rresp     (),
    .s01_axi_rlast     (),
    .s01_axi_ruser     (),
    .s01_axi_rvalid    (),
    .s01_axi_rready    (1'b1),

    // M00 .. M05 slave outputs
    .m00_axi_awvalid   (), .m00_axi_awready(1'b1), .m00_axi_awaddr(), .m00_axi_awid(), .m00_axi_awlen(), .m00_axi_awsize(), .m00_axi_awburst(), .m00_axi_awlock(), .m00_axi_awcache(), .m00_axi_awprot(), .m00_axi_awqos(), .m00_axi_awregion(), .m00_axi_awuser(),
    .m00_axi_wvalid    (), .m00_axi_wready(1'b1),  .m00_axi_wdata(),  .m00_axi_wstrb(), .m00_axi_wlast(), .m00_axi_wuser(),
    .m00_axi_bvalid    (1'b0), .m00_axi_bready(),  .m00_axi_bid(8'h0),.m00_axi_bresp(2'b0), .m00_axi_buser(1'b0),
    .m00_axi_arvalid   (), .m00_axi_arready(1'b1), .m00_axi_araddr(), .m00_axi_arid(), .m00_axi_arlen(), .m00_axi_arsize(), .m00_axi_arburst(), .m00_axi_arlock(), .m00_axi_arcache(), .m00_axi_arprot(), .m00_axi_arqos(), .m00_axi_arregion(), .m00_axi_aruser(),
    .m00_axi_rvalid    (1'b0), .m00_axi_rready(),  .m00_axi_rid(8'h0),.m00_axi_rdata(32'h0),.m00_axi_rresp(2'b0), .m00_axi_rlast(1'b1), .m00_axi_ruser(1'b0),

    .m01_axi_awvalid   (), .m01_axi_awready(1'b1), .m01_axi_awaddr(), .m01_axi_awid(), .m01_axi_awlen(), .m01_axi_awsize(), .m01_axi_awburst(), .m01_axi_awlock(), .m01_axi_awcache(), .m01_axi_awprot(), .m01_axi_awqos(), .m01_axi_awregion(), .m01_axi_awuser(),
    .m01_axi_wvalid    (), .m01_axi_wready(1'b1),  .m01_axi_wdata(),  .m01_axi_wstrb(), .m01_axi_wlast(), .m01_axi_wuser(),
    .m01_axi_bvalid    (1'b0), .m01_axi_bready(),  .m01_axi_bid(8'h0),.m01_axi_bresp(2'b0), .m01_axi_buser(1'b0),
    .m01_axi_arvalid   (), .m01_axi_arready(1'b1), .m01_axi_araddr(), .m01_axi_arid(), .m01_axi_arlen(), .m01_axi_arsize(), .m01_axi_arburst(), .m01_axi_arlock(), .m01_axi_arcache(), .m01_axi_arprot(), .m01_axi_arqos(), .m01_axi_arregion(), .m01_axi_aruser(),
    .m01_axi_rvalid    (1'b0), .m01_axi_rready(),  .m01_axi_rid(8'h0),.m01_axi_rdata(32'h0),.m01_axi_rresp(2'b0), .m01_axi_rlast(1'b1), .m01_axi_ruser(1'b0),

    .m02_axi_awvalid   (), .m02_axi_awready(1'b1), .m02_axi_awaddr(), .m02_axi_awid(), .m02_axi_awlen(), .m02_axi_awsize(), .m02_axi_awburst(), .m02_axi_awlock(), .m02_axi_awcache(), .m02_axi_awprot(), .m02_axi_awqos(), .m02_axi_awregion(), .m02_axi_awuser(),
    .m02_axi_wvalid    (), .m02_axi_wready(1'b1),  .m02_axi_wdata(),  .m02_axi_wstrb(), .m02_axi_wlast(), .m02_axi_wuser(),
    .m02_axi_bvalid    (1'b0), .m02_axi_bready(),  .m02_axi_bid(8'h0),.m02_axi_bresp(2'b0), .m02_axi_buser(1'b0),
    .m02_axi_arvalid   (), .m02_axi_arready(1'b1), .m02_axi_araddr(), .m02_axi_arid(), .m02_axi_arlen(), .m02_axi_arsize(), .m02_axi_arburst(), .m02_axi_arlock(), .m02_axi_arcache(), .m02_axi_arprot(), .m02_axi_arqos(), .m02_axi_arregion(), .m02_axi_aruser(),
    .m02_axi_rvalid    (1'b0), .m02_axi_rready(),  .m02_axi_rid(8'h0),.m02_axi_rdata(32'h0),.m02_axi_rresp(2'b0), .m02_axi_rlast(1'b1), .m02_axi_ruser(1'b0),

    .m03_axi_awvalid   (), .m03_axi_awready(1'b1), .m03_axi_awaddr(), .m03_axi_awid(), .m03_axi_awlen(), .m03_axi_awsize(), .m03_axi_awburst(), .m03_axi_awlock(), .m03_axi_awcache(), .m03_axi_awprot(), .m03_axi_awqos(), .m03_axi_awregion(), .m03_axi_awuser(),
    .m03_axi_wvalid    (), .m03_axi_wready(1'b1),  .m03_axi_wdata(),  .m03_axi_wstrb(), .m03_axi_wlast(), .m03_axi_wuser(),
    .m03_axi_bvalid    (1'b0), .m03_axi_bready(),  .m03_axi_bid(8'h0),.m03_axi_bresp(2'b0), .m03_axi_buser(1'b0),
    .m03_axi_arvalid   (), .m03_axi_arready(1'b1), .m03_axi_araddr(), .m03_axi_arid(), .m03_axi_arlen(), .m03_axi_arsize(), .m03_axi_arburst(), .m03_axi_arlock(), .m03_axi_arcache(), .m03_axi_arprot(), .m03_axi_arqos(), .m03_axi_arregion(), .m03_axi_aruser(),
    .m03_axi_rvalid    (1'b0), .m03_axi_rready(),  .m03_axi_rid(8'h0),.m03_axi_rdata(32'h0),.m03_axi_rresp(2'b0), .m03_axi_rlast(1'b1), .m03_axi_ruser(1'b0),

    .m04_axi_awvalid   (), .m04_axi_awready(1'b1), .m04_axi_awaddr(), .m04_axi_awid(), .m04_axi_awlen(), .m04_axi_awsize(), .m04_axi_awburst(), .m04_axi_awlock(), .m04_axi_awcache(), .m04_axi_awprot(), .m04_axi_awqos(), .m04_axi_awregion(), .m04_axi_awuser(),
    .m04_axi_wvalid    (), .m04_axi_wready(1'b1),  .m04_axi_wdata(),  .m04_axi_wstrb(), .m04_axi_wlast(), .m04_axi_wuser(),
    .m04_axi_bvalid    (1'b0), .m04_axi_bready(),  .m04_axi_bid(8'h0),.m04_axi_bresp(2'b0), .m04_axi_buser(1'b0),
    .m04_axi_arvalid   (), .m04_axi_arready(1'b1), .m04_axi_araddr(), .m04_axi_arid(), .m04_axi_arlen(), .m04_axi_arsize(), .m04_axi_arburst(), .m04_axi_arlock(), .m04_axi_arcache(), .m04_axi_arprot(), .m04_axi_arqos(), .m04_axi_arregion(), .m04_axi_aruser(),
    .m04_axi_rvalid    (1'b0), .m04_axi_rready(),  .m04_axi_rid(8'h0),.m04_axi_rdata(32'h0),.m04_axi_rresp(2'b0), .m04_axi_rlast(1'b1), .m04_axi_ruser(1'b0),

    .m05_axi_awvalid   (), .m05_axi_awready(1'b1), .m05_axi_awaddr(), .m05_axi_awid(), .m05_axi_awlen(), .m05_axi_awsize(), .m05_axi_awburst(), .m05_axi_awlock(), .m05_axi_awcache(), .m05_axi_awprot(), .m05_axi_awqos(), .m05_axi_awregion(), .m05_axi_awuser(),
    .m05_axi_wvalid    (), .m05_axi_wready(1'b1),  .m05_axi_wdata(),  .m05_axi_wstrb(), .m05_axi_wlast(), .m05_axi_wuser(),
    .m05_axi_bvalid    (1'b0), .m05_axi_bready(),  .m05_axi_bid(8'h0),.m05_axi_bresp(2'b0), .m05_axi_buser(1'b0),
    .m05_axi_arvalid   (), .m05_axi_arready(1'b1), .m05_axi_araddr(), .m05_axi_arid(), .m05_axi_arlen(), .m05_axi_arsize(), .m05_axi_arburst(), .m05_axi_arlock(), .m05_axi_arcache(), .m05_axi_arprot(), .m05_axi_arqos(), .m05_axi_arregion(), .m05_axi_aruser(),
    .m05_axi_rvalid    (1'b0), .m05_axi_rready(),  .m05_axi_rid(8'h0),.m05_axi_rdata(32'h0),.m05_axi_rresp(2'b0), .m05_axi_rlast(1'b1), .m05_axi_ruser(1'b0)
  );

  // DMA AXI Master Router: routes DCCM accesses directly to dedicated VeeR EL2 DMA slave port,
  // and routes peripheral accesses to the AHB adapter.
  s_axi_mosi_t per_dma_mosi;
  s_axi_miso_t per_dma_miso;

  dma_axi_master_router #(
    .DMA_BUS_TAG(pt.DMA_BUS_TAG)
  ) u_dma_router (
    .clk              (clk_i),
    .rst_l            (rst_l),

    // Upstream DMA master
    .dma_m_mosi       (dma_m_mosi),
    .dma_m_miso       (dma_m_miso),

    // VeeR EL2 dedicated DMA slave port
    .veer_dma_awvalid (veer_dma_awvalid),
    .veer_dma_awready (veer_dma_awready),
    .veer_dma_awid    (veer_dma_awid),
    .veer_dma_awaddr  (veer_dma_awaddr),
    .veer_dma_awsize  (veer_dma_awsize),
    .veer_dma_awprot  (veer_dma_awprot),
    .veer_dma_awlen   (veer_dma_awlen),
    .veer_dma_awburst (veer_dma_awburst),

    .veer_dma_wvalid  (veer_dma_wvalid),
    .veer_dma_wready  (veer_dma_wready),
    .veer_dma_wdata   (veer_dma_wdata),
    .veer_dma_wstrb   (veer_dma_wstrb),
    .veer_dma_wlast   (veer_dma_wlast),

    .veer_dma_bvalid  (veer_dma_bvalid),
    .veer_dma_bready  (veer_dma_bready),
    .veer_dma_bresp   (veer_dma_bresp),
    .veer_dma_bid     (veer_dma_bid),

    .veer_dma_arvalid (veer_dma_arvalid),
    .veer_dma_arready (veer_dma_arready),
    .veer_dma_arid    (veer_dma_arid),
    .veer_dma_araddr  (veer_dma_araddr),
    .veer_dma_arsize  (veer_dma_arsize),
    .veer_dma_arprot  (veer_dma_arprot),
    .veer_dma_arlen   (veer_dma_arlen),
    .veer_dma_arburst (veer_dma_arburst),

    .veer_dma_rvalid  (veer_dma_rvalid),
    .veer_dma_rready  (veer_dma_rready),
    .veer_dma_rid     (veer_dma_rid),
    .veer_dma_rdata   (veer_dma_rdata),
    .veer_dma_rresp   (veer_dma_rresp),
    .veer_dma_rlast   (veer_dma_rlast),

    // Downstream to AHB adapter
    .per_dma_mosi     (per_dma_mosi),
    .per_dma_miso     (per_dma_miso)
  );

  // Adapter – converts DMA AXI4 master (peripheral path) to VeeR DMA AHB-Lite slave
  dma_axi4_to_ahb_adapter u_dma_adapter (
    .clk                (clk_i),
    .rst_l              (rst_l),
    .dma_axi_mosi      (per_dma_mosi),
    .dma_axi_miso      (per_dma_miso),

    .dma_haddr         (dma_haddr),
    .dma_hburst        (dma_hburst),
    .dma_hmastlock     (dma_hmastlock),
    .dma_hprot         (dma_hprot),
    .dma_hsize         (dma_hsize),
    .dma_htrans        (dma_htrans),
    .dma_hwrite        (dma_hwrite),
    .dma_hwdata        (dma_hwdata),
    .dma_hrdata        (dma_hrdata),
    .dma_hreadyin      (dma_hreadyin),
    .dma_hreadyout     (dma_hreadyout),
    .dma_hresp         (dma_hresp),
    .dma_busy          (dma_busy)
  );

  // Width packers
  dma_width_packer #(.NUM_BYTES(8)) u_spi_packer (
    .clk        (clk_i),
    .rst_l      (rst_l),
    .hwrite     (spi_wvalid && spi_wready),
    .haddr      (spi_awaddr),
    .hwdata     (spi_wdata),
    .hrdata     (),
    .hready     (spi_wready),
    .hresp      (1'b0),
    .per_write  (),
    .per_addr   (),
    .per_wdata  (),
    .per_rdata  (8'h0),
    .per_ack    (1'b1)
  );

  dma_width_packer #(.NUM_BYTES(8)) u_i2c_packer (
    .clk        (clk_i),
    .rst_l      (rst_l),
    .hwrite     (i2c_wb_we_i && i2c_wb_stb_i && i2c_wb_cyc_i),
    .haddr      ({29'b0, i2c_wb_adr_i}),
    .hwdata     ({56'b0, i2c_wb_dat_i}),
    .hrdata     (),
    .hready     (i2c_wb_ack_o),
    .hresp      (1'b0),
    .per_write  (),
    .per_addr   (),
    .per_wdata  (),
    .per_rdata  (8'h0),
    .per_ack    (1'b1)
  );

  // --------------------------------------------------------------------
  //  5) Peripheral IP instantiations
  // --------------------------------------------------------------------
  // SPI IP
  axi_spi_top u_spi (
    .fixed_clk_i   (clk_i),
    .axi_aclk_i    (clk_i),
    .axi_aresetn_i (rst_l),
    .axi_arid_i    (12'h0),
    .axi_araddr_i  (spi_araddr[6:0]),
    .axi_arvalid_i (spi_arvalid),
    .axi_arready_o (spi_arready),
    .axi_rid_o     (),
    .axi_rdata_o   (spi_rdata[31:0]),
    .axi_rresp_o   (spi_rresp),
    .axi_rvalid_o  (spi_rvalid),
    .axi_rready_i  (spi_rready),
    .axi_awid_i    (12'h0),
    .axi_awaddr_i  (spi_awaddr[6:0]),
    .axi_awvalid_i (spi_awvalid),
    .axi_awready_o (spi_awready),
    .axi_wdata_i   (spi_awaddr[2] ? spi_wdata[63:32] : spi_wdata[31:0]),
    .axi_wstrb_i   (spi_awaddr[2] ? spi_wstrb[7:4]   : spi_wstrb[3:0]),
    .axi_wvalid_i  (spi_wvalid),
    .axi_wready_o  (spi_wready),
    .axi_bid_o     (),
    .axi_bresp_o   (spi_bresp),
    .axi_bvalid_o  (spi_bvalid),
    .axi_bready_i  (spi_bready),
    .spi_clk_o     (spi_clk_o),
    .spi_cs_n_o    (spi_cs_n_o),
    .spi_mosi_o    (spi_mosi_o),
    .spi_miso_i    (spi_miso_i)
  );
  assign spi_rdata[63:32] = 32'h0;

  // UART IP
  axi_uart_top u_uart (
    .fixed_clk_i   (clk_i),
    .axi_aclk_i    (clk_i),
    .axi_aresetn_i (rst_l),
    .axi_arid_i    (12'h0),
    .axi_araddr_i  (uart_araddr[4:0]),
    .axi_arvalid_i (uart_arvalid),
    .axi_arready_o (uart_arready),
    .axi_rid_o     (),
    .axi_rdata_o   (uart_rdata[31:0]),
    .axi_rresp_o   (uart_rresp),
    .axi_rvalid_o  (uart_rvalid),
    .axi_rready_i  (uart_rready),
    .axi_awid_i    (12'h0),
    .axi_awaddr_i  (uart_awaddr[4:0]),
    .axi_awvalid_i (uart_awvalid),
    .axi_awready_o (uart_awready),
    .axi_wdata_i   (uart_awaddr[2] ? uart_wdata[63:32] : uart_wdata[31:0]),
    .axi_wstrb_i   (uart_awaddr[2] ? uart_wstrb[7:4]   : uart_wstrb[3:0]),
    .axi_wvalid_i  (uart_wvalid),
    .axi_wready_o  (uart_wready),
    .axi_bid_o     (),
    .axi_bresp_o   (uart_bresp),
    .axi_bvalid_o  (uart_bvalid),
    .axi_bready_i  (uart_bready),
    .uart_tx_o     (uart_tx_o),
    .uart_rx_i     (uart_rx_i),
    .read_interrupt_o (uart_irq)
  );
  assign uart_rts_o = 1'b0;
  assign uart_rdata[63:32] = 32'h0;

  // I2C IP
  logic i2c_scl_o, i2c_scl_oen;
  logic i2c_sda_o, i2c_sda_oen;

  assign i2c_scl = (!i2c_scl_oen) ? i2c_scl_o : 1'bz;
  assign i2c_sda = (!i2c_sda_oen) ? i2c_sda_o : 1'bz;

  // I2C IP
  i2c_master_top u_i2c (
    .wb_clk_i      (clk_i),
    .wb_rst_i      (~rst_l),
    .arst_i        (~rst_l),
    .wb_adr_i      (i2c_wb_adr_i),
    .wb_dat_i      (i2c_wb_dat_i),
    .wb_dat_o      (i2c_wb_dat_o),
    .wb_we_i       (i2c_wb_we_i),
    .wb_stb_i      (i2c_wb_stb_i),
    .wb_cyc_i      (i2c_wb_cyc_i),
    .wb_ack_o      (i2c_wb_ack_o),
    .wb_inta_o     (i2c_wb_inta_o),
    .scl_pad_i     (i2c_scl),
    .scl_pad_o     (i2c_scl_o),
    .scl_padoen_o  (i2c_scl_oen),
    .sda_pad_i     (i2c_sda),
    .sda_pad_o     (i2c_sda_o),
    .sda_padoen_o  (i2c_sda_oen)
  );

  // Real SPI interrupt logic
  assign spi_irq = u_spi.spi_interrupt_status_reg[0] || u_spi.spi_interrupt_status_reg[2] || (u_spi.fsm_axi_wr == 3'b011);

  // PIC interrupt glue
  pic_interrupt_glue u_pic_glue (
    .clk            (clk_i),
    .rst_l          (rst_l),
    .dma_done_i     (dma_done),
    .dma_error_i    (dma_error),
    .spi_irq_i      (spi_irq),
    .uart_irq_i     (uart_irq),
    .i2c_irq_i      (i2c_wb_inta_o),
    .extintsrc_req  (extintsrc_req)
  );

endmodule

// ==============================================================================
//  Helper Integration Modules
// ==============================================================================

module address_decoder (
  input  logic [31:0] haddr,
  output logic        hsel_dccm,
  output logic        hsel_spi,
  output logic        hsel_uart,
  output logic        hsel_i2c,
  output logic        hsel_dma_csr
);
  // DCCM: S09* Native VeeR Base (0xF0040000-0xF004FFFF) & S00 Unified Memory Alias (0x00000000-0x0000FFFF)
  assign hsel_dccm    = (haddr[31:28] == 4'h0) || (haddr[31:16] == 16'hF004);

  // SPI: S04 Target (0x40006000-0x40006FFF) + Legacy Alias (0x40001000-0x40001FFF)
  assign hsel_spi     = (haddr[31:12] == 20'h40006) || (haddr[31:12] == 20'h40001);

  // UART: S01 Target (0x40000000-0x40000BFF) + Legacy Alias (0x40002000-0x40002FFF)
  // Qualified with haddr[11:8] < 4'hC to preserve upper 1 KiB (0x40000C00-0x40000FFF) for DMA CSR
  assign hsel_uart    = ((haddr[31:12] == 20'h40000) && (haddr[11:8] < 4'hC)) || (haddr[31:12] == 20'h40002);

  // I2C: S05 Target (0x40008000-0x40008FFF) + Legacy Alias (0x40003000-0x40003FFF)
  assign hsel_i2c     = (haddr[31:12] == 20'h40008) || (haddr[31:12] == 20'h40003);

  // DMA CSR: Preserved existing RTL address (0x40000C00-0x40000FFF, 1 KiB)
  assign hsel_dma_csr = (haddr[31:12] == 20'h40000) && (haddr[11:8] >= 4'hC);
endmodule

module soc_dccm_ram #(
  parameter int ADDR_WIDTH = 16,
  parameter int DATA_WIDTH = 64
)(
  input  logic        clk,
  input  logic        rst_l,

  // AHB-Lite Slave Interface
  input  logic        hsel,
  input  logic [31:0] haddr,
  input  logic [1:0]  htrans,
  input  logic        hwrite,
  input  logic [2:0]  hsize,
  input  logic [63:0] hwdata,
  output logic [63:0] hrdata,
  output logic        hready,
  output logic        hresp,

  // Core DCCM SRAM Interface
  input  logic        core_wren,
  input  logic        core_rden,
  input  logic [15:0] core_wr_addr_lo,
  input  logic [15:0] core_wr_addr_hi,
  input  logic [15:0] core_rd_addr_lo,
  input  logic [38:0] core_wr_data_lo,
  input  logic [38:0] core_wr_data_hi,
  output logic [38:0] core_rd_data_lo,
  output logic [38:0] core_rd_data_hi
);
  // 64 KB byte-addressable memory array
  logic [7:0] mem [0:65535];

  initial begin
    for (int i = 0; i < 65536; i++) begin
      mem[i] = 8'h00;
    end
  end

  // AHB address & control stage registers
  logic        hsel_q;
  logic [15:0] haddr_q;
  logic        hwrite_q;
  logic [2:0]  hsize_q;
  logic [1:0]  htrans_q;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      hsel_q   <= 1'b0;
      haddr_q  <= '0;
      hwrite_q <= 1'b0;
      hsize_q  <= '0;
      htrans_q <= '0;
    end else begin
      hsel_q   <= hsel;
      haddr_q  <= haddr[15:0];
      hwrite_q <= hwrite;
      hsize_q  <= hsize;
      htrans_q <= htrans;
    end
  end

  // AHB and Core writes
  always @(posedge clk) begin
    if (hsel_q && htrans_q[1] && hwrite_q) begin
      case (hsize_q)
        3'd0: begin
          mem[haddr_q] <= (hwdata[haddr_q[2:0]*8 +: 8] != 8'h0) ?
                          hwdata[haddr_q[2:0]*8 +: 8] : hwdata[7:0];
        end
        3'd1: begin
          if (haddr_q[1] == 1'b0) begin
            mem[{haddr_q[15:1], 1'b0}] <= haddr_q[2] ? hwdata[39:32] : hwdata[7:0];
            mem[{haddr_q[15:1], 1'b1}] <= haddr_q[2] ? hwdata[47:40] : hwdata[15:8];
          end else begin
            mem[{haddr_q[15:1], 1'b0}] <= haddr_q[2] ? hwdata[55:48] : hwdata[23:16];
            mem[{haddr_q[15:1], 1'b1}] <= haddr_q[2] ? hwdata[63:56] : hwdata[31:24];
          end
        end
        3'd2: begin
          if (haddr_q[2] == 1'b0) begin
            mem[{haddr_q[15:2], 2'b00}] <= hwdata[7:0];
            mem[{haddr_q[15:2], 2'b01}] <= hwdata[15:8];
            mem[{haddr_q[15:2], 2'b10}] <= hwdata[23:16];
            mem[{haddr_q[15:2], 2'b11}] <= hwdata[31:24];
          end else begin
            logic [31:0] w32;
            w32 = (hwdata[63:32] != 32'h0) ? hwdata[63:32] : hwdata[31:0];
            mem[{haddr_q[15:2], 2'b00}] <= w32[7:0];
            mem[{haddr_q[15:2], 2'b01}] <= w32[15:8];
            mem[{haddr_q[15:2], 2'b10}] <= w32[23:16];
            mem[{haddr_q[15:2], 2'b11}] <= w32[31:24];
          end
        end
        default: begin
          logic [15:0] base_w;
          base_w = {haddr_q[15:3], 3'b000};
          for (int i = 0; i < 8; i++) begin
            mem[base_w + i] <= hwdata[i*8 +: 8];
          end
        end
      endcase
    end
    if (core_wren) begin
      mem[core_wr_addr_lo]     <= core_wr_data_lo[7:0];
      mem[core_wr_addr_lo + 1] <= core_wr_data_lo[15:8];
      mem[core_wr_addr_lo + 2] <= core_wr_data_lo[23:16];
      mem[core_wr_addr_lo + 3] <= core_wr_data_lo[31:24];
      if (core_wr_addr_hi != core_wr_addr_lo) begin
        mem[core_wr_addr_hi]     <= core_wr_data_hi[7:0];
        mem[core_wr_addr_hi + 1] <= core_wr_data_hi[15:8];
        mem[core_wr_addr_hi + 2] <= core_wr_data_hi[23:16];
        mem[core_wr_addr_hi + 3] <= core_wr_data_hi[31:24];
      end
    end
  end

  // AHB read
  logic [15:0] rd_addr;
  logic [15:0] rd_base;
  assign rd_addr = (hsel && htrans[1]) ? haddr[15:0] : haddr_q;
  assign rd_base = {rd_addr[15:3], 3'b000};

  assign hrdata = {
    mem[rd_base + 7], mem[rd_base + 6], mem[rd_base + 5], mem[rd_base + 4],
    mem[rd_base + 3], mem[rd_base + 2], mem[rd_base + 1], mem[rd_base + 0]
  };
  assign hready = 1'b1;
  assign hresp  = 1'b0;

  // Core read (synchronous 1-cycle latency matching VeeR EL2 DCCM SRAM spec)
  logic [38:0] core_rd_data_lo_q;
  logic [38:0] core_rd_data_hi_q;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      core_rd_data_lo_q <= '0;
      core_rd_data_hi_q <= '0;
    end else if (core_rden) begin
      core_rd_data_lo_q <= {7'h0, mem[core_rd_addr_lo + 3], mem[core_rd_addr_lo + 2], mem[core_rd_addr_lo + 1], mem[core_rd_addr_lo]};
      core_rd_data_hi_q <= {7'h0, mem[core_rd_addr_lo + 7], mem[core_rd_addr_lo + 6], mem[core_rd_addr_lo + 5], mem[core_rd_addr_lo + 4]};
    end
  end

  assign core_rd_data_lo = core_rd_data_lo_q;
  assign core_rd_data_hi = core_rd_data_hi_q;
endmodule

module soc_ifu_boot_rom #(
  parameter int TAG_WIDTH = 3
)(
  input  logic                 clk,
  input  logic                 rst_l,
  input  logic                 arvalid,
  output logic                 arready,
  input  logic [31:0]          araddr,
  input  logic [TAG_WIDTH-1:0] arid,
  output logic                 rvalid,
  input  logic                 rready,
  output logic [TAG_WIDTH-1:0] rid,
  output logic [63:0]          rdata,
  output logic [1:0]           rresp,
  output logic                 rlast
);
  logic [TAG_WIDTH-1:0] id_q;
  logic                 pending_q;
  logic [63:0]          rom_mem [0:1023];
  logic [9:0]           rom_addr_q;

  initial begin
    for (int i = 0; i < 1024; i++) begin
      rom_mem[i] = 64'h0000_0013_0000_0013; // default NOPs
    end
    $readmemh("firmware.hex", rom_mem);
  end

  assign arready = !pending_q;
  assign rresp   = 2'b00; // OKAY
  assign rlast   = 1'b1;
  assign rdata   = rom_mem[rom_addr_q];
  assign rid     = id_q;
  assign rvalid  = pending_q;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      pending_q  <= 1'b0;
      id_q       <= '0;
      rom_addr_q <= '0;
    end else begin
      if (arvalid && arready) begin
        pending_q  <= 1'b1;
        id_q       <= arid;
        rom_addr_q <= araddr[12:3];
      end else if (rvalid && rready) begin
        pending_q  <= 1'b0;
      end
    end
  end
endmodule

module ahb2axi_lite_bridge #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 64
)(
  input  logic        clk,
  input  logic        rst_l,
  input  logic        hsel,
  input  logic [31:0] haddr,
  input  logic [2:0]  hburst,
  input  logic        hmastlock,
  input  logic [3:0]  hprot,
  input  logic [2:0]  hsize,
  input  logic [1:0]  htrans,
  input  logic        hwrite,
  input  logic [63:0] hwdata,
  output logic [63:0] hrdata,
  output logic        hready,
  output logic        hresp,

  output logic                  axi_awvalid,
  input  logic                  axi_awready,
  output logic [ADDR_WIDTH-1:0] axi_awaddr,
  output logic [2:0]            axi_awprot,
  output logic                  axi_wvalid,
  input  logic                  axi_wready,
  output logic [DATA_WIDTH-1:0] axi_wdata,
  output logic [(DATA_WIDTH/8)-1:0] axi_wstrb,
  output logic                  axi_wlast,
  input  logic                  axi_bvalid,
  output logic                  axi_bready,
  input  logic [7:0]            axi_bid,
  input  logic [1:0]            axi_bresp,
  output logic                  axi_arvalid,
  input  logic                  axi_arready,
  output logic [ADDR_WIDTH-1:0] axi_araddr,
  output logic [2:0]            axi_arprot,
  input  logic                  axi_rvalid,
  output logic                  axi_rready,
  input  logic [7:0]            axi_rid,
  input  logic [DATA_WIDTH-1:0] axi_rdata,
  input  logic [1:0]            axi_rresp
);
  typedef enum logic [1:0] {IDLE, WRITE_DATA, READ_WAIT} state_t;
  state_t state;
  logic [31:0] addr_reg;
  logic        aw_done, w_done;

  assign axi_awaddr  = addr_reg;
  assign axi_awprot  = 3'b000;
  assign axi_wdata   = (DATA_WIDTH == 64) ? (addr_reg[2] ? {2{hwdata[63:32]}} : {2{hwdata[31:0]}}) : hwdata;
  assign axi_wstrb   = {((DATA_WIDTH/8)){1'b1}};
  assign axi_wlast   = 1'b1;
  assign axi_araddr  = addr_reg;
  assign axi_arprot  = 3'b000;
  assign axi_bready  = 1'b1;
  assign axi_rready  = 1'b1;
  assign hresp       = 1'b0;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      state       <= IDLE;
      addr_reg    <= '0;
      hrdata      <= '0;
      hready      <= 1'b1;
      axi_awvalid <= 1'b0;
      axi_wvalid  <= 1'b0;
      axi_arvalid <= 1'b0;
      aw_done     <= 1'b0;
      w_done      <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          hready  <= 1'b1;
          aw_done <= 1'b0;
          w_done  <= 1'b0;
          if (hsel && htrans[1]) begin
            addr_reg <= haddr;
            if (hwrite) begin
              axi_awvalid <= 1'b1;
              axi_wvalid  <= 1'b1;
              state       <= WRITE_DATA;
              hready      <= 1'b0;
            end else begin
              axi_arvalid <= 1'b1;
              state       <= READ_WAIT;
              hready      <= 1'b0;
            end
          end
        end

        WRITE_DATA: begin
          if (axi_awready) begin
            axi_awvalid <= 1'b0;
            aw_done     <= 1'b1;
          end
          if (axi_wready) begin
            axi_wvalid  <= 1'b0;
            w_done      <= 1'b1;
          end
          if (((axi_awvalid && axi_awready) || aw_done || !axi_awvalid) &&
              ((axi_wvalid && axi_wready)   || w_done  || !axi_wvalid) &&
              axi_bvalid) begin
            axi_awvalid <= 1'b0;
            axi_wvalid  <= 1'b0;
            hready      <= 1'b1;
            state       <= IDLE;
          end
        end

        READ_WAIT: begin
          if (axi_arready) axi_arvalid <= 1'b0;
          if (axi_rvalid) begin
            hrdata      <= (DATA_WIDTH == 64) ? {2{axi_rdata[31:0]}} : axi_rdata;
            axi_arvalid <= 1'b0;
            hready      <= 1'b1;
            state       <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end
endmodule

module ahb2wishbone_bridge #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 64
)(
  input  logic        clk,
  input  logic        rst_l,
  input  logic        hsel,
  input  logic [31:0] haddr,
  input  logic [2:0]  hburst,
  input  logic        hmastlock,
  input  logic [3:0]  hprot,
  input  logic [2:0]  hsize,
  input  logic [1:0]  htrans,
  input  logic        hwrite,
  input  logic [63:0] hwdata,
  output logic [63:0] hrdata,
  output logic        hready,
  output logic        hresp,

  output logic        wb_clk_i,
  output logic        wb_rst_i,
  output logic [2:0]  wb_adr_i,
  output logic [7:0]  wb_dat_i,
  input  logic [7:0]  wb_dat_o,
  output logic        wb_we_i,
  output logic        wb_stb_i,
  output logic        wb_cyc_i,
  input  logic        wb_ack_o,
  input  logic        wb_inta_o
);
  assign wb_clk_i = clk;
  assign wb_rst_i = ~rst_l;
  assign hresp    = 1'b0;

  typedef enum logic [1:0] { WB_IDLE, WB_REQ, WB_WAIT } wb_state_t;
  wb_state_t state;
  logic [2:0] addr_reg;
  logic       we_reg;
  logic       haddr2_reg;

  // Select byte from 64-bit AHB hwdata based on haddr2_reg
  assign wb_dat_i = (haddr2_reg && (hwdata[39:32] != 8'h0)) ? hwdata[39:32] : hwdata[7:0];
  assign wb_adr_i = addr_reg;
  assign wb_we_i  = we_reg;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      state      <= WB_IDLE;
      wb_cyc_i   <= 1'b0;
      wb_stb_i   <= 1'b0;
      addr_reg   <= '0;
      we_reg     <= 1'b0;
      haddr2_reg <= 1'b0;
      hrdata     <= '0;
      hready     <= 1'b1;
    end else begin
      case (state)
        WB_IDLE: begin
          hready <= 1'b1;
          if (hsel && htrans[1]) begin
            addr_reg   <= haddr[4:2];
            we_reg     <= hwrite;
            haddr2_reg <= haddr[2];
            hready     <= 1'b0;
            state      <= WB_REQ;
          end
        end

        WB_REQ: begin
          // In WB_REQ, hwdata is valid from AHB master for writes
          wb_cyc_i <= 1'b1;
          wb_stb_i <= 1'b1;
          state    <= WB_WAIT;
        end

        WB_WAIT: begin
          if (wb_ack_o) begin
            wb_cyc_i <= 1'b0;
            wb_stb_i <= 1'b0;
            hrdata   <= {2{24'b0, wb_dat_o}};
            hready   <= 1'b1;
            state    <= WB_IDLE;
          end
        end

        default: state <= WB_IDLE;
      endcase
    end
  end
endmodule

// ====================================================================
// DMA AXI Master Router
// Routes DCCM accesses (0x0000_xxxx, 0xF004_xxxx) to the dedicated
// VeeR EL2 DMA slave port (64-bit AXI4) with address normalization to
// {16'hF004, addr[15:0]} and 32/64-bit lane adaptation.
// Routes peripheral accesses (SPI, UART, I2C, etc.) to the AHB adapter.
// ====================================================================
module dma_axi_master_router import amba_axi_pkg::*; #(
  parameter int DMA_BUS_TAG = 1
)(
  input  logic                    clk,
  input  logic                    rst_l,

  // Upstream DMA Master Interface (32-bit AXI4)
  input  s_axi_mosi_t             dma_m_mosi,
  output s_axi_miso_t             dma_m_miso,

  // Downstream Dedicated VeeR EL2 DMA Slave Port (64-bit AXI4)
  output logic                    veer_dma_awvalid,
  input  logic                    veer_dma_awready,
  output logic [DMA_BUS_TAG-1:0]  veer_dma_awid,
  output logic [31:0]             veer_dma_awaddr,
  output logic [2:0]              veer_dma_awsize,
  output logic [2:0]              veer_dma_awprot,
  output logic [7:0]              veer_dma_awlen,
  output logic [1:0]              veer_dma_awburst,

  output logic                    veer_dma_wvalid,
  input  logic                    veer_dma_wready,
  output logic [63:0]             veer_dma_wdata,
  output logic [7:0]              veer_dma_wstrb,
  output logic                    veer_dma_wlast,

  input  logic                    veer_dma_bvalid,
  output logic                    veer_dma_bready,
  input  logic [1:0]              veer_dma_bresp,
  input  logic [DMA_BUS_TAG-1:0]  veer_dma_bid,

  output logic                    veer_dma_arvalid,
  input  logic                    veer_dma_arready,
  output logic [DMA_BUS_TAG-1:0]  veer_dma_arid,
  output logic [31:0]             veer_dma_araddr,
  output logic [2:0]              veer_dma_arsize,
  output logic [2:0]              veer_dma_arprot,
  output logic [7:0]              veer_dma_arlen,
  output logic [1:0]              veer_dma_arburst,

  input  logic                    veer_dma_rvalid,
  output logic                    veer_dma_rready,
  input  logic [DMA_BUS_TAG-1:0]  veer_dma_rid,
  input  logic [63:0]             veer_dma_rdata,
  input  logic [1:0]              veer_dma_rresp,
  input  logic                    veer_dma_rlast,

  // Downstream Peripheral Interface to AHB Adapter (32-bit AXI4)
  output s_axi_mosi_t             per_dma_mosi,
  input  s_axi_miso_t             per_dma_miso
);

  function automatic logic is_dccm_addr(input logic [31:0] addr);
    return (addr[31:28] == 4'h0) || (addr[31:16] == 16'hF004);
  endfunction

  wire aw_is_dccm = is_dccm_addr(dma_m_mosi.awaddr);
  wire ar_is_dccm = is_dccm_addr(dma_m_mosi.araddr);

  // ------------------------------------------------------------------
  // Write channel tracking
  // ------------------------------------------------------------------
  logic wr_busy_q;
  logic wr_route_dccm_q;
  logic wr_addr2_q;

  wire aw_fire = dma_m_mosi.awvalid && dma_m_miso.awready;
  wire w_fire  = dma_m_mosi.wvalid  && dma_m_miso.wready;
  wire b_fire  = dma_m_miso.bvalid  && dma_m_mosi.bready;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      wr_busy_q       <= 1'b0;
      wr_route_dccm_q <= 1'b0;
      wr_addr2_q      <= 1'b0;
    end else begin
      if (aw_fire) begin
        wr_route_dccm_q <= aw_is_dccm;
        wr_addr2_q      <= dma_m_mosi.awaddr[2];
        wr_busy_q       <= ~b_fire;
      end else if (w_fire && !dma_m_mosi.wlast) begin
        wr_addr2_q      <= ~wr_addr2_q;
      end else if (b_fire) begin
        wr_busy_q       <= 1'b0;
      end
    end
  end

  wire wr_is_dccm = wr_busy_q ? wr_route_dccm_q : aw_is_dccm;
  wire wr_addr2   = wr_busy_q ? wr_addr2_q      : dma_m_mosi.awaddr[2];

  // ------------------------------------------------------------------
  // Read channel tracking
  // ------------------------------------------------------------------
  logic rd_busy_q;
  logic rd_route_dccm_q;
  logic rd_addr2_q;

  wire ar_fire = dma_m_mosi.arvalid && dma_m_miso.arready;
  wire r_fire  = dma_m_miso.rvalid  && dma_m_mosi.rready;
  wire r_last_fire = r_fire && dma_m_miso.rlast;

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      rd_busy_q       <= 1'b0;
      rd_route_dccm_q <= 1'b0;
      rd_addr2_q      <= 1'b0;
    end else begin
      if (ar_fire) begin
        rd_route_dccm_q <= ar_is_dccm;
        rd_addr2_q      <= dma_m_mosi.araddr[2];
        rd_busy_q       <= ~r_last_fire;
      end else if (r_fire && !dma_m_miso.rlast) begin
        rd_addr2_q      <= ~rd_addr2_q;
      end else if (r_last_fire) begin
        rd_busy_q       <= 1'b0;
      end
    end
  end

  wire rd_is_dccm = rd_busy_q ? rd_route_dccm_q : ar_is_dccm;
  wire rd_addr2   = rd_busy_q ? rd_addr2_q      : dma_m_mosi.araddr[2];

  // ------------------------------------------------------------------
  // Demux to VeeR Dedicated DMA Slave Port (64-bit)
  // ------------------------------------------------------------------
  assign veer_dma_awvalid = aw_is_dccm && dma_m_mosi.awvalid;
  assign veer_dma_awaddr  = {16'hF004, dma_m_mosi.awaddr[15:0]};
  assign veer_dma_awsize  = 3'b010; // 32-bit word
  assign veer_dma_awprot  = dma_m_mosi.awprot;
  assign veer_dma_awlen   = dma_m_mosi.awlen;
  assign veer_dma_awburst = dma_m_mosi.awburst;
  assign veer_dma_awid    = dma_m_mosi.awid[DMA_BUS_TAG-1:0];

  assign veer_dma_wvalid  = wr_is_dccm && dma_m_mosi.wvalid;
  assign veer_dma_wdata   = {dma_m_mosi.wdata, dma_m_mosi.wdata};
  assign veer_dma_wstrb   = wr_addr2 ? 8'hF0 : 8'h0F;
  assign veer_dma_wlast   = dma_m_mosi.wlast;

  assign veer_dma_bready  = wr_is_dccm && dma_m_mosi.bready;

  assign veer_dma_arvalid = ar_is_dccm && dma_m_mosi.arvalid;
  assign veer_dma_araddr  = {16'hF004, dma_m_mosi.araddr[15:0]};
  assign veer_dma_arsize  = 3'b010; // 32-bit word
  assign veer_dma_arprot  = dma_m_mosi.arprot;
  assign veer_dma_arlen   = dma_m_mosi.arlen;
  assign veer_dma_arburst = dma_m_mosi.arburst;
  assign veer_dma_arid    = dma_m_mosi.arid[DMA_BUS_TAG-1:0];

  assign veer_dma_rready  = rd_is_dccm && dma_m_mosi.rready;

  // ------------------------------------------------------------------
  // Demux to Peripheral AHB Adapter (32-bit)
  // ------------------------------------------------------------------
  always_comb begin
    per_dma_mosi          = dma_m_mosi;
    per_dma_mosi.awvalid  = ~aw_is_dccm && dma_m_mosi.awvalid;
    per_dma_mosi.wvalid   = ~wr_is_dccm && dma_m_mosi.wvalid;
    per_dma_mosi.bready   = ~wr_is_dccm && dma_m_mosi.bready;
    per_dma_mosi.arvalid  = ~ar_is_dccm && dma_m_mosi.arvalid;
    per_dma_mosi.rready   = ~rd_is_dccm && dma_m_mosi.rready;
  end

  // ------------------------------------------------------------------
  // Mux back to DMA Controller Master Port
  // ------------------------------------------------------------------
  always_comb begin
    dma_m_miso = '0;

    // AW Ready
    dma_m_miso.awready = aw_is_dccm ? veer_dma_awready : per_dma_miso.awready;

    // W Ready
    dma_m_miso.wready  = wr_is_dccm ? veer_dma_wready  : per_dma_miso.wready;

    // B Channel
    if (wr_is_dccm) begin
      dma_m_miso.bvalid = veer_dma_bvalid;
      dma_m_miso.bresp  = axi_resp_t'(veer_dma_bresp);
      dma_m_miso.bid    = {{(8-DMA_BUS_TAG){1'b0}}, veer_dma_bid};
      dma_m_miso.buser  = '0;
    end else begin
      dma_m_miso.bvalid = per_dma_miso.bvalid;
      dma_m_miso.bresp  = per_dma_miso.bresp;
      dma_m_miso.bid    = per_dma_miso.bid;
      dma_m_miso.buser  = per_dma_miso.buser;
    end

    // AR Ready
    dma_m_miso.arready = ar_is_dccm ? veer_dma_arready : per_dma_miso.arready;

    // R Channel
    if (rd_is_dccm) begin
      dma_m_miso.rvalid = veer_dma_rvalid;
      dma_m_miso.rdata  = rd_addr2 ? veer_dma_rdata[63:32] : veer_dma_rdata[31:0];
      dma_m_miso.rresp  = axi_resp_t'(veer_dma_rresp);
      dma_m_miso.rlast  = veer_dma_rlast;
      dma_m_miso.rid    = {{(8-DMA_BUS_TAG){1'b0}}, veer_dma_rid};
      dma_m_miso.ruser  = '0;
    end else begin
      dma_m_miso.rvalid = per_dma_miso.rvalid;
      dma_m_miso.rdata  = per_dma_miso.rdata;
      dma_m_miso.rresp  = per_dma_miso.rresp;
      dma_m_miso.rlast  = per_dma_miso.rlast;
      dma_m_miso.rid    = per_dma_miso.rid;
      dma_m_miso.ruser  = per_dma_miso.ruser;
    end
  end

endmodule

module dma_axi4_to_ahb_adapter import amba_axi_pkg::*; (
  input  logic        clk,
  input  logic        rst_l,

  input  s_axi_mosi_t dma_axi_mosi,
  output s_axi_miso_t dma_axi_miso,

  output logic [31:0] dma_haddr,
  output logic [2:0]  dma_hburst,
  output logic        dma_hmastlock,
  output logic [3:0]  dma_hprot,
  output logic [2:0]  dma_hsize,
  output logic [1:0]  dma_htrans,
  output logic        dma_hwrite,
  output logic [63:0] dma_hwdata,
  input  logic [63:0] dma_hrdata,
  output logic        dma_hreadyin,
  input  logic        dma_hreadyout,
  input  logic        dma_hresp,
  output logic        dma_busy
);
  typedef enum logic [1:0] {
    ST_IDLE,
    ST_WRITE,
    ST_READ,
    ST_RESP
  } state_t;

  state_t state, state_d;
  logic [31:0] addr_q, addr_d;
  logic [31:0] wdata_q, wdata_d;
  logic [2:0]  size_q, size_d;
  logic [7:0]  id_q, id_d;
  logic [31:0] rdata_q, rdata_d;

  assign dma_hburst    = 3'b000;
  assign dma_hmastlock = 1'b0;
  assign dma_hprot     = 4'b0000;
  assign dma_hreadyin  = dma_hreadyout;
  assign dma_busy      = (state != ST_IDLE) ||
                         (dma_axi_mosi.awvalid && dma_axi_mosi.wvalid) ||
                         (dma_axi_mosi.arvalid);

  always_comb begin
    state_d = state;
    addr_d  = addr_q;
    wdata_d = wdata_q;
    size_d  = size_q;
    id_d    = id_q;
    rdata_d = rdata_q;

    dma_haddr  = addr_q;
    dma_hwdata = {wdata_q, wdata_q};
    dma_hsize  = size_q;
    dma_hwrite = 1'b0;
    dma_htrans = 2'b00;

    dma_axi_miso.awready = 1'b0;
    dma_axi_miso.wready  = 1'b0;
    dma_axi_miso.bvalid  = 1'b0;
    dma_axi_miso.bid     = id_q;
    dma_axi_miso.bresp   = AXI_OKAY;
    dma_axi_miso.buser   = '0;

    dma_axi_miso.arready = 1'b0;
    dma_axi_miso.rvalid  = 1'b0;
    dma_axi_miso.rid     = id_q;
    dma_axi_miso.rdata   = rdata_q;
    dma_axi_miso.rresp   = AXI_OKAY;
    dma_axi_miso.rlast   = 1'b1;
    dma_axi_miso.ruser   = '0;

    case (state)
      ST_IDLE: begin
        if (dma_axi_mosi.awvalid && dma_axi_mosi.wvalid) begin
          addr_d               = dma_axi_mosi.awaddr;
          wdata_d              = dma_axi_mosi.wdata;
          size_d               = 3'(dma_axi_mosi.awsize);
          id_d                 = dma_axi_mosi.awid;
          dma_axi_miso.awready = 1'b1;
          dma_axi_miso.wready  = 1'b1;
          dma_haddr            = dma_axi_mosi.awaddr;
          dma_hwdata           = {dma_axi_mosi.wdata, dma_axi_mosi.wdata};
          dma_hsize            = 3'(dma_axi_mosi.awsize);
          dma_hwrite           = 1'b1;
          dma_htrans           = 2'b10;
          state_d              = ST_WRITE;
        end else if (dma_axi_mosi.arvalid) begin
          addr_d               = dma_axi_mosi.araddr;
          size_d               = 3'(dma_axi_mosi.arsize);
          id_d                 = dma_axi_mosi.arid;
          dma_axi_miso.arready = 1'b1;
          dma_haddr            = dma_axi_mosi.araddr;
          dma_hsize            = 3'(dma_axi_mosi.arsize);
          dma_hwrite           = 1'b0;
          dma_htrans           = 2'b10;
          state_d              = ST_READ;
        end
      end

      ST_WRITE: begin
        dma_haddr  = addr_q;
        dma_hwdata = {wdata_q, wdata_q};
        dma_hsize  = size_q;
        dma_hwrite = 1'b1;
        dma_htrans = 2'b00;
        if (dma_hreadyout) begin
          dma_axi_miso.bvalid = 1'b1;
          state_d             = ST_IDLE;
        end
      end

      ST_READ: begin
        dma_haddr  = addr_q;
        dma_hsize  = size_q;
        dma_hwrite = 1'b0;
        dma_htrans = 2'b00;
        if (dma_hreadyout) begin
          rdata_d = addr_q[2] ? dma_hrdata[63:32] : dma_hrdata[31:0];
          state_d = ST_RESP;
        end
      end

      ST_RESP: begin
        dma_axi_miso.rvalid = 1'b1;
        dma_axi_miso.rdata  = rdata_q;
        if (dma_axi_mosi.rready) begin
          state_d = ST_IDLE;
        end
      end

      default: state_d = ST_IDLE;
    endcase
  end

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) begin
      state   <= ST_IDLE;
      addr_q  <= '0;
      wdata_q <= '0;
      size_q  <= '0;
      id_q    <= '0;
      rdata_q <= '0;
    end else begin
      state   <= state_d;
      addr_q  <= addr_d;
      wdata_q <= wdata_d;
      size_q  <= size_d;
      id_q    <= id_d;
      rdata_q <= rdata_d;
    end
  end
endmodule

module dma_width_packer #(
  parameter int NUM_BYTES = 8
)(
  input  logic        clk,
  input  logic        rst_l,
  input  logic        hwrite,
  input  logic [31:0] haddr,
  input  logic [63:0] hwdata,
  output logic [63:0] hrdata,
  input  logic        hready,
  input  logic        hresp,
  output logic        per_write,
  output logic [31:0] per_addr,
  output logic [7:0]  per_wdata,
  input  logic [7:0]  per_rdata,
  input  logic        per_ack
);
  assign per_write = hwrite;
  assign per_addr  = haddr;
  assign per_wdata = hwdata[7:0];
  assign hrdata    = {56'b0, per_rdata};
endmodule

module pic_interrupt_glue (
  input  logic        clk,
  input  logic        rst_l,
  input  logic        dma_done_i,
  input  logic        dma_error_i,
  input  logic        spi_irq_i,
  input  logic        uart_irq_i,
  input  logic        i2c_irq_i,
  output logic [31:0] extintsrc_req
);
  always_comb begin
    extintsrc_req = 32'b0;
    extintsrc_req[1] = dma_done_i;
    extintsrc_req[2] = dma_error_i;
    extintsrc_req[3] = spi_irq_i;
    extintsrc_req[4] = uart_irq_i;
    extintsrc_req[5] = i2c_irq_i;
  end
endmodule

`default_nettype wire

