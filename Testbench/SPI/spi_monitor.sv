class spi_monitor extends uvm_monitor;
  virtual spi_if vif;
  uvm_analysis_port #(spi_item) ap;
  `uvm_component_utils(spi_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set for monitor", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    spi_item item;
    forever begin
      if (vif != null) begin
        @(posedge vif.clk);
        item = spi_item::type_id::create("item");
        item.spi_clk_o = vif.spi_clk_o;
        item.spi_cs_n_o = vif.spi_cs_n_o;
        item.spi_mosi_o = vif.spi_mosi_o;
        item.spi_miso_i = vif.spi_miso_i;
        `uvm_info(get_type_name(), $sformatf("Monitor sampled transaction: %s", item.convert2string()), UVM_HIGH)
        ap.write(item);
      end else begin
        #10;
      end
    end
  endtask
endclass
