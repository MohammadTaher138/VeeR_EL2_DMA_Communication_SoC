//==========================================================================
//  soc_i2c_test.sv – Functional Verification of I2C Subsystem
//==========================================================================
//  Targets: TC_I2C_01, TC_I2C_02, TC_I2C_03, TC_I2C_04, TC_I2C_05
//==========================================================================

`ifndef SOC_I2C_TEST_SV
`define SOC_I2C_TEST_SV

class soc_i2c_test extends uvm_test;
  `uvm_component_utils(soc_i2c_test)

  soc_env    env;
  soc_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
      cfg = soc_config::type_id::create("cfg");
      uvm_config_db#(soc_config)::set(this, "env", "cfg", cfg);
    end
    env = soc_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC I2C PERIPHERAL TEST                 ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Verifying I2C START/STOP, Slave Write, Read (0x5A) & NACK ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork : wait_i2c_milestones
      begin
        // Wait until Milestone 0x0F (TC_I2C_05 done)
        wait (cfg.current_milestone >= 8'h0F || cfg.current_milestone == 8'hEE);
      end
      begin
        #200000; // 200 us timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: I2C test timed out! Milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_i2c_milestones;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("I2C TEST FAILED: FailCode=0x%02h", cfg.fail_code))
    end else begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf(">>> I2C TESTS PASSED (Milestone 0x%02h achieved) <<<", cfg.current_milestone), UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass

`endif
