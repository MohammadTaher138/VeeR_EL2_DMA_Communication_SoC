//==========================================================================
//  ahb_item.sv – Passive AHB-Lite Transaction Sequence Item
//==========================================================================

`ifndef AHB_ITEM_SV
`define AHB_ITEM_SV

typedef enum bit [3:0] {
  AHB_TARGET_UNKNOWN    = 4'd0,
  AHB_TARGET_SPI        = 4'd1,
  AHB_TARGET_SPI_ALIAS  = 4'd2,
  AHB_TARGET_UART       = 4'd3,
  AHB_TARGET_UART_ALIAS = 4'd4,
  AHB_TARGET_I2C        = 4'd5,
  AHB_TARGET_I2C_ALIAS  = 4'd6,
  AHB_TARGET_DMA_CSR    = 4'd7,
  AHB_TARGET_DCCM       = 4'd8,
  AHB_TARGET_DCCM_ALIAS = 4'd9
} ahb_target_e;

class ahb_item extends uvm_sequence_item;
  bit [31:0] haddr;
  bit        hwrite;
  bit [2:0]  hsize;
  bit [1:0]  htrans;
  bit [63:0] hwdata;
  bit [63:0] hrdata;
  bit        hresp;
  bit [31:0] extintsrc_req;
  bit        dma_done;
  bit        dma_error;

  `uvm_object_utils_begin(ahb_item)
    `uvm_field_int(haddr,         UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hwrite,        UVM_ALL_ON)
    `uvm_field_int(hsize,         UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(htrans,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hwdata,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hrdata,        UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(hresp,         UVM_ALL_ON)
    `uvm_field_int(extintsrc_req, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(dma_done,      UVM_ALL_ON)
    `uvm_field_int(dma_error,     UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ahb_item");
    super.new(name);
  endfunction

  function ahb_target_e get_target_id();
    if (haddr >= 32'h40000C00 && haddr <= 32'h40000FFF) return AHB_TARGET_DMA_CSR;
    if (haddr >= 32'h40001000 && haddr <= 32'h40001FFF) return AHB_TARGET_SPI;
    if (haddr >= 32'h40006000 && haddr <= 32'h40006FFF) return AHB_TARGET_SPI_ALIAS;
    if (haddr >= 32'h40002000 && haddr <= 32'h40002FFF) return AHB_TARGET_UART;
    if (haddr >= 32'h40000000 && haddr <= 32'h40000BFF) return AHB_TARGET_UART_ALIAS;
    if (haddr >= 32'h40003000 && haddr <= 32'h40003FFF) return AHB_TARGET_I2C;
    if (haddr >= 32'h40008000 && haddr <= 32'h40008FFF) return AHB_TARGET_I2C_ALIAS;
    if (haddr >= 32'h00000000 && haddr <= 32'h0000FFFF) return AHB_TARGET_DCCM_ALIAS;
    if (haddr >= 32'hF0040000 && haddr <= 32'hF004FFFF) return AHB_TARGET_DCCM;
    return AHB_TARGET_UNKNOWN;
  endfunction

  function string get_target_name();
    if (haddr >= 32'h40000C00 && haddr <= 32'h40000FFF) return "DMA_CSR";
    if (haddr >= 32'h40001000 && haddr <= 32'h40001FFF) return "SPI";
    if (haddr >= 32'h40006000 && haddr <= 32'h40006FFF) return "SPI_ALIAS";
    if (haddr >= 32'h40002000 && haddr <= 32'h40002FFF) return "UART";
    if (haddr >= 32'h40000000 && haddr <= 32'h40000BFF) return "UART_ALIAS";
    if (haddr >= 32'h40003000 && haddr <= 32'h40003FFF) return "I2C";
    if (haddr >= 32'h40008000 && haddr <= 32'h40008FFF) return "I2C_ALIAS";
    if (haddr >= 32'h00000000 && haddr <= 32'h0000FFFF) return "DCCM_ALIAS";
    if (haddr >= 32'hF0040000 && haddr <= 32'hF004FFFF) return "DCCM";
    return "UNKNOWN";
  endfunction

  virtual function string convert2string();
    return $sformatf("[AHB_ITEM] target=%s addr=0x%08x wr=%0b size=%0d trans=2'b%02b wdata=0x%016x rdata=0x%016x resp=%0b",
                     get_target_name(), haddr, hwrite, hsize, htrans, hwdata, hrdata, hresp);
  endfunction
endclass

`endif
