//==========================================================================
//  soc_boot_test.sv – Verification of VeeR EL2 Boot & CPU Subsystem
//==========================================================================
//  Targets: TC_BOOT_01, TC_MEM_01, TC_MEM_02, TC_AHB_01, TC_AHB_02
//==========================================================================

`ifndef SOC_BOOT_TEST_SV
`define SOC_BOOT_TEST_SV

class soc_boot_test extends uvm_test;
  `uvm_component_utils(soc_boot_test)

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
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC BOOT & CPU SUBSYSTEM TEST          ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Verifying Reset, Boot Vector, ICCM/DCCM & AHB Isolation   ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork : wait_boot_milestones
      begin
        // Wait until Milestone 0x05 (TC_AHB_02 done)
        wait (cfg.current_milestone >= 8'h05 || cfg.current_milestone == 8'hEE);
      end
      begin
        #100000; // 100 us timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: Boot test timed out! Milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_boot_milestones;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("BOOT TEST FAILED: FailCode=0x%02h", cfg.fail_code))
    end else begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf(">>> BOOT & CPU TESTS PASSED (Milestone 0x%02h achieved) <<<", cfg.current_milestone), UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass

`endif
