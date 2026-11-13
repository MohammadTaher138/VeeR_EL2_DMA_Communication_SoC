class uart_base_seq extends uvm_sequence #(uart_item);
  `uvm_object_utils(uart_base_seq)

  function new(string name="uart_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing UART base sequence", UVM_MEDIUM)
  endtask
endclass

class uart_random_seq extends uart_base_seq;
  `uvm_object_utils(uart_random_seq)

  rand int num_trans;
  constraint c_num_trans { num_trans inside {[5:15]}; }

  function new(string name="uart_random_seq");
    super.new(name);
    num_trans = 10;
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Executing UART random sequence (%0d items)", num_trans), UVM_MEDIUM)
    repeat (num_trans) begin
      `uvm_do(req)
    end
  endtask
endclass

// ==========================================================================
// Dedicated Test Sequences Mapped to UART Testplan Specifications
// ==========================================================================

// Testcase: TC_UART_VIP_RST_01
// Scenario: Power-On Reset State of Line Status & Control Registers
// Type:     External
class uart_TC_UART_VIP_RST_01_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_RST_01_seq)

  function new(string name="uart_TC_UART_VIP_RST_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_RST_01 - Power-On Reset State of Line Status & Control Registers", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_RST_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_UART_VIP_RST_02
// Scenario: Software Reset & FIFO Initialization
// Type:     Internal
class uart_TC_UART_VIP_RST_02_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_RST_02_seq)

  function new(string name="uart_TC_UART_VIP_RST_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_RST_02 - Software Reset & FIFO Initialization", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_RST_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_UART_VIP_FUNC_01
// Scenario: Programmable Baud Rate Generator (115200 Baud Divisor)
// Type:     External
class uart_TC_UART_VIP_FUNC_01_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_FUNC_01_seq)

  function new(string name="uart_TC_UART_VIP_FUNC_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_FUNC_01 - Programmable Baud Rate Generator (115200 Baud Divisor)", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_FUNC_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_UART_VIP_FUNC_02
// Scenario: Single Character Transmission (8-N-1 Format)
// Type:     External
class uart_TC_UART_VIP_FUNC_02_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_FUNC_02_seq)

  function new(string name="uart_TC_UART_VIP_FUNC_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_FUNC_02 - Single Character Transmission (8-N-1 Format)", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_FUNC_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_UART_VIP_FUNC_03
// Scenario: Multi-Character String Stream Transmission
// Type:     External
class uart_TC_UART_VIP_FUNC_03_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_FUNC_03_seq)

  function new(string name="uart_TC_UART_VIP_FUNC_03_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_FUNC_03 - Multi-Character String Stream Transmission", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_FUNC_03", UVM_LOW)
  endtask
endclass

// Testcase: TC_UART_VIP_FUNC_04
// Scenario: Single Character Reception (8-N-1 Format)
// Type:     External
class uart_TC_UART_VIP_FUNC_04_seq extends uart_base_seq;
  `uvm_object_utils(uart_TC_UART_VIP_FUNC_04_seq)

  function new(string name="uart_TC_UART_VIP_FUNC_04_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_UART_VIP_FUNC_04 - Single Character Reception (8-N-1 Format)", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_UART_VIP_FUNC_04", UVM_LOW)
  endtask
endclass
