//==========================================================================
//  soc_overall_test.sv – Top UVM Test for VeeR EL2 SoC Overall Verification
//==========================================================================

`ifndef SOC_OVERALL_TEST_SV
`define SOC_OVERALL_TEST_SV

class soc_overall_test extends uvm_test;
  `uvm_component_utils(soc_overall_test)

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
    soc_full_integration_seq v_seq;
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC OVERALL UVM VERIFICATION RUN ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Integrating SPI, I2C, and UART Verification IPs (VIPs)  ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    v_seq = soc_full_integration_seq::type_id::create("v_seq");
    v_seq.start(env.v_seqr);

    // Allow CPU firmware to execute through all test plan milestones (0x01 through 0xAA)
    fork : wait_firmware_completion
      begin
        wait (cfg.current_milestone == 8'hAA || cfg.current_milestone == 8'hEE);
      end
      begin
        #600000; // 600 us maximum watchdog timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: Simulation exceeded cycle limit! Current milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_firmware_completion;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("FIRMWARE HALTED WITH ERROR: FailCode=0x%02h", cfg.fail_code))
    end else if (cfg.current_milestone == 8'hAA) begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), ">>> ALL 30 SOC DIRECTED TESTS EXECUTED AND PASSED IN FIRMWARE <<<", UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== VEER EL2 SOC OVERALL UVM VERIFICATION COMPLETED CLEANLY ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass

`endif
