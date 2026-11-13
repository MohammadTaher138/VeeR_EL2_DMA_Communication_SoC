class i2c_monitor extends uvm_monitor;
  virtual i2c_if vif;
  uvm_analysis_port #(i2c_item) ap;
  `uvm_component_utils(i2c_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set for monitor", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    i2c_item item;
    forever begin
      if (vif != null) begin
        @(posedge vif.clk);
        item = i2c_item::type_id::create("item");
        item.i2c_scl = vif.i2c_scl;
        item.i2c_sda = vif.i2c_sda;
        `uvm_info(get_type_name(), $sformatf("Monitor sampled transaction: %s", item.convert2string()), UVM_HIGH)
        ap.write(item);
      end else begin
        #10;
      end
    end
  endtask
endclass
