//==========================================================================
//  soc_spi_test.sv – Functional Verification of SPI Subsystem
//==========================================================================
//  Targets: TC_SPI_01, TC_SPI_02, TC_SPI_03, TC_SPI_04, TC_SPI_05
//==========================================================================

`ifndef SOC_SPI_TEST_SV
`define SOC_SPI_TEST_SV

class soc_spi_test extends uvm_test;
  `uvm_component_utils(soc_spi_test)

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
    `uvm_info(get_type_name(), "=== STARTING VEER EL2 SOC SPI PERIPHERAL TEST                 ===", UVM_LOW)
    `uvm_info(get_type_name(), "=== Verifying SPI Master TX/RX, CPOL/CPHA Modes & FIFO Flags  ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    fork : wait_spi_milestones
      begin
        // Wait until Milestone 0x0A (TC_SPI_05 done)
        wait (cfg.current_milestone >= 8'h0A || cfg.current_milestone == 8'hEE);
      end
      begin
        #150000; // 150 us timeout
        `uvm_error(get_type_name(), $sformatf("TIMEOUT: SPI test timed out! Milestone=0x%02h, fail_code=0x%02h",
                                              cfg.current_milestone, cfg.fail_code))
      end
    join_any
    disable wait_spi_milestones;

    if (cfg.current_milestone == 8'hEE) begin
      `uvm_error(get_type_name(), $sformatf("SPI TEST FAILED: FailCode=0x%02h", cfg.fail_code))
    end else begin
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
      `uvm_info(get_type_name(), $sformatf(">>> SPI TESTS PASSED (Milestone 0x%02h achieved) <<<", cfg.current_milestone), UVM_LOW)
      `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass

`endif
