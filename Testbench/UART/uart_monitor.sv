class uart_monitor extends uvm_monitor;
  virtual uart_if vif;
  uvm_analysis_port #(uart_item) ap;
  `uvm_component_utils(uart_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set for monitor", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    uart_item item;
    forever begin
      if (vif != null) begin
        @(posedge vif.clk);
        item = uart_item::type_id::create("item");
        item.uart_tx_o = vif.uart_tx_o;
        item.uart_rx_i = vif.uart_rx_i;
        item.uart_rts_o = vif.uart_rts_o;
        item.uart_cts_i = vif.uart_cts_i;
        `uvm_info(get_type_name(), $sformatf("Monitor sampled transaction: %s", item.convert2string()), UVM_HIGH)
        ap.write(item);
      end else begin
        #10;
      end
    end
  endtask
endclass
