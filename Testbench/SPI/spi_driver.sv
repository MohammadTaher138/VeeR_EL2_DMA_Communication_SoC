//==========================================================================
//  spi_driver.sv – Functional Active Slave Driver for SPI Verification IP
//==========================================================================

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_item);
  virtual spi_if vif;
  `uvm_component_utils(spi_driver)

  bit loopback_mode = 1'b1;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set; running in unbonded mode", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    if (vif == null) return;

    vif.spi_miso_i = 1'b1;

    fork
      // Process incoming sequence items
      process_sequence_items();
      // Active slave loopback / responder
      active_slave_loop();
    join
  endtask

  task process_sequence_items();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("SPI Driver processing item: %s", req.convert2string()), UVM_HIGH)
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask

  // Functional slave responder with loopback mode
  task active_slave_loop();
    forever begin
      @(vif.spi_mosi_o or vif.spi_clk_o or vif.spi_cs_n_o);
      if (loopback_mode) begin
        vif.spi_miso_i = vif.spi_mosi_o;
      end else begin
        vif.spi_miso_i = 1'b1;
      end
    end
  endtask
endclass

`endif
