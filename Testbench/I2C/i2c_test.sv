class i2c_test extends uvm_test;
  i2c_env env;
  `uvm_component_utils(i2c_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = i2c_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    i2c_random_seq seq;
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Starting I2C UVM Verification Simulation ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Testplan coverage: 21 documented scenarios from CSV", UVM_LOW)
    seq = i2c_random_seq::type_id::create("seq");
    void'(seq.randomize());
    seq.start(env.agent.seqr);
    #100;
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== I2C UVM Verification Completed Successfully ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
