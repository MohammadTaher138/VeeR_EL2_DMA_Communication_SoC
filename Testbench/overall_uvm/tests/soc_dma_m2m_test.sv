//==========================================================================
//  soc_dma_m2m_test.sv – Functional Verification of DMA Memory-to-Memory
//==========================================================================
//  Targets: TC_DMA_01 (CSR Readback), TC_DMA_06 (Alignment), TC_DMA_07 (Arbitration)
//==========================================================================

`ifndef SOC_DMA_M2M_TEST_SV
`define SOC_DMA_M2M_TEST_SV

class soc_dma_m2m_test extends uvm_test;
  `uvm_component_utils(soc_dma_m2m_test)

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
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC DMA MEMORY-TO-MEMORY TEST          ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Verifying DMA CSR R/W, Alignment, Arbitration & M2M Flow  ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork : wait_dma_m2m_milestones
      begin
        // Wait until Milestone 0x16 (TC_DMA_07 done)
        wait (cfg.current_milestone >= 8'h16 || cfg.current_milestone == 8'hEE);
      end
      begin
        #350000; // 350 us timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: DMA M2M test timed out! Milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_dma_m2m_milestones;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("DMA M2M TEST FAILED: FailCode=0x%02h", cfg.fail_code))
    end else begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf(">>> DMA M2M TESTS PASSED (Milestone 0x%02h achieved) <<<", cfg.current_milestone), UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass

`endif
