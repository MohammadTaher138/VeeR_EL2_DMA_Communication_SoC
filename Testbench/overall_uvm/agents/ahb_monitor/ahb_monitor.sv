//==========================================================================
//  ahb_monitor.sv – Passive AHB-Lite Protocol Monitor Component
//==========================================================================

`ifndef AHB_MONITOR_SV
`define AHB_MONITOR_SV

class ahb_monitor extends uvm_monitor;
  virtual ahb_lite_mon_if vif;
  uvm_analysis_port #(ahb_item) ap;

  `uvm_component_utils(ahb_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ahb_lite_mon_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface ahb_lite_mon_if not set for passive AHB monitor", UVM_LOW)
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit in_transfer = 0;
    bit [31:0] sampled_addr;
    bit        sampled_write;
    bit [2:0]  sampled_size;
    bit [1:0]  sampled_trans;

    if (vif == null) return;

    forever begin
      @(posedge vif.clk);
      if (!vif.rst_n) begin
        in_transfer = 0;
        continue;
      end

      // If we had an address phase previously, capture the data phase when hready is asserted
      if (in_transfer && vif.hready) begin
        ahb_item item = ahb_item::type_id::create("item");
        item.haddr  = sampled_addr;
        item.hwrite = sampled_write;
        item.hsize  = sampled_size;
        item.htrans = sampled_trans;
        item.hwdata       = vif.hwdata;
        item.hrdata       = vif.hrdata;
        item.hresp        = vif.hresp;
        item.extintsrc_req = vif.extintsrc_req;
        item.dma_done     = vif.dma_done;
        item.dma_error    = vif.dma_error;

        `uvm_info(get_type_name(), $sformatf("Captured AHB Transaction: %s", item.convert2string()), UVM_HIGH)
        ap.write(item);
        in_transfer = 0;
      end

      // Sample new address phase
      if (vif.hready && (vif.htrans[1] == 1'b1)) begin // NONSEQ (2'b10) or SEQ (2'b11)
        sampled_addr  = vif.haddr;
        sampled_write = vif.hwrite;
        sampled_size  = vif.hsize;
        sampled_trans = vif.htrans;
        in_transfer   = 1;
      end
    end
  endtask
endclass

`endif
