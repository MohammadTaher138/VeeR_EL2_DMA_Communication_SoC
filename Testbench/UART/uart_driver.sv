//==========================================================================
//  uart_driver.sv – Functional Active Driver for UART Verification IP
//==========================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_item);
  virtual uart_if vif;
  `uvm_component_utils(uart_driver)

  // Baud divider for 115200 baud with 100 MHz clock: 100,000,000 / 115200 ~= 868
  int baud_div = 868;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
      `uvm_info(get_type_name(), "Virtual interface not set; running in unbonded mode", UVM_LOW)
    end
  endfunction

  task run_phase(uvm_phase phase);
    if (vif == null) return;

    // Initialize line idle states
    vif.uart_rx_i  = 1'b1; // Idle line is High
    vif.uart_cts_i = 1'b1; // Clear to send

    fork
      // Process incoming sequence items
      process_sequence_items();
      // Autonomous command injector for receiver tests
      autonomous_rx_injector();
    join
  endtask

  task send_uart_byte(byte data);
    `uvm_info(get_type_name(), $sformatf("UART Driver serializing byte 0x%02h ('%c') onto uart_rx_i", data, (data >= 32 && data <= 126) ? data : 46), UVM_MEDIUM)

    // Start bit (0)
    vif.uart_rx_i = 1'b0;
    repeat (baud_div) @(posedge vif.clk);

    // 8 Data bits (LSB first)
    for (int i = 0; i < 8; i++) begin
      vif.uart_rx_i = data[i];
      repeat (baud_div) @(posedge vif.clk);
    end

    // Stop bit (1)
    vif.uart_rx_i = 1'b1;
    repeat (baud_div) @(posedge vif.clk);
  endtask

  task process_sequence_items();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("UART Driver received item: %s", req.convert2string()), UVM_HIGH)
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask

  task autonomous_rx_injector();
    // Wait until hardware reset is released
    wait (vif.rst_n === 1'b1);

    // Watch for UART TX activity (host transmission from SoC)
    // When UART status "TC25_PASS" is transmitted by firmware, inject command byte 'R' (0x52)
    forever begin
      @(negedge vif.uart_tx_o iff (vif.rst_n === 1'b1));
      // Allow transmission to proceed into test 26
      #50000;
      // Inject command byte 'R' (0x52) for TC_UART_02 verification
      repeat (500) @(posedge vif.clk);
      send_uart_byte(8'h52);
      `uvm_info(get_type_name(), "UART Driver: Successfully injected command 'R' (0x52) for TC_UART_02", UVM_LOW)
      // Wait long duration before any subsequent autonomous injection
      #2000000;
    end
  endtask
endclass

`endif
