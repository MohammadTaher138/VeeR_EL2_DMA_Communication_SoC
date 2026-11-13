//==========================================================================
//  ahb_lite_mon_if.sv – Passive AHB-Lite Bus Monitoring Interface
//==========================================================================
//  Observes internal AHB-Lite bus transactions between CPU/DMA and peripherals
//  without driving any signals on the bus (strictly passive).
//==========================================================================

`ifndef AHB_LITE_MON_IF_SV
`define AHB_LITE_MON_IF_SV

interface ahb_lite_mon_if (input logic clk, input logic rst_n);
  logic [31:0] haddr;
  logic [1:0]  htrans;
  logic        hwrite;
  logic [2:0]  hsize;
  logic [2:0]  hburst;
  logic [3:0]  hprot;
  logic        hmastlock;
  logic        hready;
  logic        hresp;
  logic [63:0] hwdata;
  logic [63:0] hrdata;

  // System interrupt monitoring signals
  logic [31:0] extintsrc_req;
  logic        dma_done;
  logic        dma_error;

  // Dedicated VeeR EL2 DMA Slave Port monitoring
  logic        veer_dma_awvalid;
  logic        veer_dma_awready;
  logic [31:0] veer_dma_awaddr;
  logic [2:0]  veer_dma_awsize;
  logic        veer_dma_wvalid;
  logic        veer_dma_wready;
  logic [63:0] veer_dma_wdata;
  logic [7:0]  veer_dma_wstrb;
  logic        veer_dma_bvalid;
  logic        veer_dma_bready;
  logic [1:0]  veer_dma_bresp;

  logic        veer_dma_arvalid;
  logic        veer_dma_arready;
  logic [31:0] veer_dma_araddr;
  logic [2:0]  veer_dma_arsize;
  logic        veer_dma_rvalid;
  logic        veer_dma_rready;
  logic [63:0] veer_dma_rdata;
  logic [1:0]  veer_dma_rresp;
  logic        veer_dma_rlast;
endinterface

`endif
