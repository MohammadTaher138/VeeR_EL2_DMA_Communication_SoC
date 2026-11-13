class i2c_base_seq extends uvm_sequence #(i2c_item);
  `uvm_object_utils(i2c_base_seq)

  function new(string name="i2c_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing I2C base sequence", UVM_MEDIUM)
  endtask
endclass

class i2c_random_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_random_seq)

  rand int num_trans;
  constraint c_num_trans { num_trans inside {[5:15]}; }

  function new(string name="i2c_random_seq");
    super.new(name);
    num_trans = 10;
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Executing I2C random sequence (%0d items)", num_trans), UVM_MEDIUM)
    repeat (num_trans) begin
      `uvm_do(req)
    end
  endtask
endclass

// ==========================================================================
// Dedicated Test Sequences Mapped to I2C Testplan Specifications
// ==========================================================================

// Testcase: TC_I2C_VIP_RST_01
// Scenario: Power-On Reset & Default Register States
// Type:     External
class i2c_TC_I2C_VIP_RST_01_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_RST_01_seq)

  function new(string name="i2c_TC_I2C_VIP_RST_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_RST_01 - Power-On Reset & Default Register States", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_RST_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_I2C_VIP_RST_02
// Scenario: Core Enable/Disable Control via CTR
// Type:     Internal
class i2c_TC_I2C_VIP_RST_02_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_RST_02_seq)

  function new(string name="i2c_TC_I2C_VIP_RST_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_RST_02 - Core Enable/Disable Control via CTR", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_RST_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_I2C_VIP_FUNC_01
// Scenario: Clock Prescaler Configuration & SCL Timing
// Type:     External
class i2c_TC_I2C_VIP_FUNC_01_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_FUNC_01_seq)

  function new(string name="i2c_TC_I2C_VIP_FUNC_01_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_FUNC_01 - Clock Prescaler Configuration & SCL Timing", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_FUNC_01", UVM_LOW)
  endtask
endclass

// Testcase: TC_I2C_VIP_FUNC_02
// Scenario: Bus START Condition Generation
// Type:     External
class i2c_TC_I2C_VIP_FUNC_02_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_FUNC_02_seq)

  function new(string name="i2c_TC_I2C_VIP_FUNC_02_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_FUNC_02 - Bus START Condition Generation", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_FUNC_02", UVM_LOW)
  endtask
endclass

// Testcase: TC_I2C_VIP_FUNC_03
// Scenario: 7-Bit Slave Addressing & Write Transfer
// Type:     External
class i2c_TC_I2C_VIP_FUNC_03_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_FUNC_03_seq)

  function new(string name="i2c_TC_I2C_VIP_FUNC_03_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_FUNC_03 - 7-Bit Slave Addressing & Write Transfer", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_FUNC_03", UVM_LOW)
  endtask
endclass

// Testcase: TC_I2C_VIP_FUNC_04
// Scenario: Master Single-Byte Data Write Transfer
// Type:     External
class i2c_TC_I2C_VIP_FUNC_04_seq extends i2c_base_seq;
  `uvm_object_utils(i2c_TC_I2C_VIP_FUNC_04_seq)

  function new(string name="i2c_TC_I2C_VIP_FUNC_04_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Starting Test: TC_I2C_VIP_FUNC_04 - Master Single-Byte Data Write Transfer", UVM_LOW)
    `uvm_do(req)
    `uvm_info(get_type_name(), "Completed Test: TC_I2C_VIP_FUNC_04", UVM_LOW)
  endtask
endclass
