//==========================================================================
//  soc_sys_test.sv – Functional Verification of System Integration & PIC
//==========================================================================
//  Targets: TC_DMA_08 (Completion & IRQ), TC_PIC_01 (PIC IRQ Routing),
//           TC_SYS_01 (Concurrent CPU/DMA), TC_SYS_04 (Full System Regression)
//==========================================================================

`ifndef SOC_SYS_TEST_SV
`define SOC_SYS_TEST_SV

class soc_sys_test extends uvm_test;
  `uvm_component_utils(soc_sys_test)

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
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC SYSTEM INTEGRATION & PIC TEST       ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Verifying PIC Interrupt Routing, ISR & Concurrent CPU/DMA ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork : wait_sys_milestones
      begin
        // Wait until Milestone 0xAA (All tests complete)
        wait (cfg.current_milestone == 8'hAA || cfg.current_milestone == 8'hEE);
      end
      begin
        #600000; // 600 us timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: System test timed out! Milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_sys_milestones;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("SYSTEM TEST FAILED: FailCode=0x%02h", cfg.fail_code))
    end else if (cfg.current_milestone == 8'hAA) begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf(">>> SYSTEM INTEGRATION & PIC TESTS PASSED (ISR Count=%0d) <<<", cfg.isr_count), UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass

`endif
