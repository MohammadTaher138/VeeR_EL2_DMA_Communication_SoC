class spi_base_seq extends uvm_sequence #(spi_item);
  `uvm_object_utils(spi_base_seq)

  function new(string name="spi_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing SPI base sequence", UVM_MEDIUM)
  endtask
endclass

class spi_random_seq extends spi_base_seq;
  `uvm_object_utils(spi_random_seq)

  rand int num_trans;
  constraint c_num_trans { num_trans inside {[5:15]}; }

  function new(string name="spi_random_seq");
    super.new(name);
    num_trans = 10;
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Executing SPI random sequence (%0d items)", num_trans), UVM_MEDIUM)
    repeat (num_trans) begin
      `uvm_do(req)
    end
  endtask
endclass

// ==========================================================================
// Dedicated Test Sequences Mapped to SPI Testplan Specifications
// ==========================================================================

// Testcase: TC_SPI_VIP_RST_01
// Scenario: Hardware Power-On Reset State
// Type:     External
class spi_TC_SPI_VIP_RST_01_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_RST_01_seq)

  function new(string name="spi_TC_SPI_VIP_RST_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_RST_01 - Hardware Power-On Reset State", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_RST_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_SPI_VIP_RST_02
// Scenario: Software Reset Register Verification (SPI_SRR)
// Type:     Internal
class spi_TC_SPI_VIP_RST_02_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_RST_02_seq)

  function new(string name="spi_TC_SPI_VIP_RST_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_RST_02 - Software Reset Register Verification (SPI_SRR)", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_RST_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_SPI_VIP_FUNC_01
// Scenario: Register Read/Write Access & Bit Masking
// Type:     Internal
class spi_TC_SPI_VIP_FUNC_01_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_FUNC_01_seq)

  function new(string name="spi_TC_SPI_VIP_FUNC_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_FUNC_01 - Register Read/Write Access & Bit Masking", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_FUNC_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_SPI_VIP_FUNC_02
// Scenario: Single-Byte Master Transmit in SPI Mode 0
// Type:     External
class spi_TC_SPI_VIP_FUNC_02_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_FUNC_02_seq)

  function new(string name="spi_TC_SPI_VIP_FUNC_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_FUNC_02 - Single-Byte Master Transmit in SPI Mode 0", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_FUNC_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_SPI_VIP_FUNC_03
// Scenario: Single-Byte Master Receive in SPI Mode 0
// Type:     External
class spi_TC_SPI_VIP_FUNC_03_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_FUNC_03_seq)

  function new(string name="spi_TC_SPI_VIP_FUNC_03_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_FUNC_03 - Single-Byte Master Receive in SPI Mode 0", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_FUNC_03", UVM_LOW)
  endtask
endclass

// Testcase: TC_SPI_VIP_FUNC_04
// Scenario: Master Transmit/Receive in SPI Mode 1 (CPOL=0, CPHA=1)
// Type:     External
class spi_TC_SPI_VIP_FUNC_04_seq extends spi_base_seq;
  `uvm_object_utils(spi_TC_SPI_VIP_FUNC_04_seq)

  function new(string name="spi_TC_SPI_VIP_FUNC_04_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_SPI_VIP_FUNC_04 - Master Transmit/Receive in SPI Mode 1 (CPOL=0, CPHA=1)", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_SPI_VIP_FUNC_04", UVM_LOW)
  endtask
endclass
