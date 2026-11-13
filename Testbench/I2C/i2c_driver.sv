//==========================================================================
//  i2c_driver.sv – Functional Reactive Slave Driver for I2C Verification IP
//==========================================================================

`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_item);
  virtual i2c_if vif;
  `uvm_component_utils(i2c_driver)

  bit [7:0] slave_read_pattern = 8'h5A;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set; running in unbonded mode", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    if (vif == null) return;

    vif.sda_drv_low = 1'b0;

    fork
      // Process incoming sequence items from sequencer
      process_sequence_items();
      // Pure protocol-level reactive slave responder
      protocol_slave_loop();
    join
  endtask

  task process_sequence_items();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("I2C Driver processing item: %s", req.convert2string()), UVM_HIGH)
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask

  // Pure protocol-level I2C Slave Responder
  task protocol_slave_loop();
    logic [7:0] rx_byte;
    vif.sda_drv_low = 1'b0;

    forever begin
      wait (vif.rst_n);

      // Wait for either a START condition (SDA falls while SCL is high)
      // or SCL falling when an un-started transfer begins
      fork : wait_start
        begin
          @(negedge vif.i2c_sda iff (vif.i2c_scl === 1'b1));
          `uvm_info(get_type_name(), "I2C Slave Responder: START condition detected on bus", UVM_HIGH)
          // Wait for SCL to fall after START
          @(negedge vif.i2c_scl);
          disable wait_start;
        end
        begin
          @(negedge vif.i2c_scl iff (vif.i2c_sda === 1'b1));
          disable wait_start;
        end
      join

      // Active transaction byte loop
      forever begin
        // Allow FSM signals and lines to stabilize
        #10ns;

        // Check if master requested Read or Write
        if (vif.is_read) begin
          // Master Read transfer: slave drives pattern 0x5A bit by bit
          `uvm_info(get_type_name(), $sformatf("I2C Slave Responder: Master Read transfer, driving pattern 0x%02h", slave_read_pattern), UVM_HIGH)
          for (int b = 7; b >= 0; b--) begin
            vif.sda_drv_low = (slave_read_pattern[b] == 1'b0) ? 1'b1 : 1'b0;
            @(posedge vif.i2c_scl);
            @(negedge vif.i2c_scl);
          end
          // 9th clock: release SDA so master can send ACK/NACK
          vif.sda_drv_low = 1'b0;
          @(posedge vif.i2c_scl);
          @(negedge vif.i2c_scl);
          break;
        end else begin
          // Master Write transfer: master transmits byte, slave receives and ACKs
          rx_byte = 8'h00;
          for (int b = 7; b >= 0; b--) begin
            @(posedge vif.i2c_scl);
            rx_byte[b] = vif.i2c_sda;
            @(negedge vif.i2c_scl);
          end

          `uvm_info(get_type_name(), $sformatf("I2C Slave Responder: Received write byte 0x%02h", rx_byte), UVM_HIGH)

          // 9th clock: ACK or NACK
          if (rx_byte == 8'hFE) begin
            // Withhold ACK for 0xFE (TC_I2C_04 NACK test)
            `uvm_info(get_type_name(), "I2C Slave Responder: Withholding ACK for 0xFE (NACK test)", UVM_MEDIUM)
            vif.sda_drv_low = 1'b0;
            @(posedge vif.i2c_scl);
            @(negedge vif.i2c_scl);
          end else begin
            // Drive ACK
            `uvm_info(get_type_name(), $sformatf("I2C Slave Responder: Driving ACK for byte 0x%02h", rx_byte), UVM_HIGH)
            vif.sda_drv_low = 1'b1;
            @(posedge vif.i2c_scl);
            @(negedge vif.i2c_scl);
            vif.sda_drv_low = 1'b0;
          end
        end

        // Wait to see if master generates STOP, repeated START, or next byte
        fork : check_next
          begin
            @(posedge vif.i2c_sda iff (vif.i2c_scl === 1'b1));
            disable check_next;
          end
          begin
            @(negedge vif.i2c_sda iff (vif.i2c_scl === 1'b1));
            disable check_next;
          end
          begin
            @(negedge vif.i2c_scl);
            disable check_next;
          end
        join_any
        disable check_next;

        // If STOP condition or repeated START detected, exit byte loop
        if (vif.i2c_scl === 1'b1) begin
          break;
        end
      end
      vif.sda_drv_low = 1'b0;
    end
  endtask
endclass

`endif
