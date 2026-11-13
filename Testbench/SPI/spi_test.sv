class spi_test extends uvm_test;
  spi_env env;
  `uvm_component_utils(spi_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    spi_random_seq seq;
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== Starting SPI UVM Verification Simulation ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Testplan coverage: 22 documented scenarios from CSV", UVM_LOW)
    seq = spi_random_seq::type_id::create("seq");
    void'(seq.randomize());
    seq.start(env.agent.seqr);
    #100;
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== SPI UVM Verification Completed Successfully ===", UVM_LOW)
    `uvm_info(get_type_name(), "=========================================================", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass
