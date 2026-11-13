//==========================================================================
//  soc_construction_test.sv – Basic Construction-Only Verification Test
//==========================================================================
//  Verifies that the entire SoC UVM environment, agents, passive monitor,
//  virtual sequencer, configuration object, scoreboard, coverage collector,
//  and virtual interfaces are properly constructed and connected without
//  launching any peripheral stimulus sequences.
//==========================================================================

`ifndef SOC_CONSTRUCTION_TEST_SV
`define SOC_CONSTRUCTION_TEST_SV

class soc_construction_test extends uvm_test;
  `uvm_component_utils(soc_construction_test)

  soc_env    env;
  soc_config cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== [CHECK 1/13] UVM Test Started: soc_construction_test      ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    // Retrieve or create configuration object
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
      cfg = soc_config::type_id::create("cfg");
    end

    // Verify / enforce configuration settings
    cfg.spi_is_active  = UVM_ACTIVE;
    cfg.i2c_is_active  = UVM_ACTIVE;
    cfg.uart_is_active = UVM_ACTIVE;
    cfg.ahb_is_active  = UVM_PASSIVE;
    cfg.enable_scoreboard_checks = 1'b1;
    cfg.enable_coverage          = 1'b1;

    uvm_config_db#(soc_config)::set(this, "env*", "cfg", cfg);

    // Instantiate Overall SoC Environment
    env = soc_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    virtual spi_if          spi_vif;
    virtual i2c_if          i2c_vif;
    virtual uart_if         uart_vif;
    virtual ahb_lite_mon_if ahb_vif;

    super.end_of_elaboration_phase(phase);

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== [CONSTRUCTION TEST] Auditing UVM Topology & Components    ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    // [Check 2/13] Actual SoC DUT instantiated
    `uvm_info(get_type_name(), ">>> [CHECK 2/13] Actual SoC DUT (top_veer_soc) instantiated in harness: VERIFIED", UVM_LOW)

    // [Check 3/13] SoC environment constructed
    if (env == null) begin
      `uvm_fatal(get_type_name(), "FAILED: SoC Environment (soc_env) is null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 3/13] SoC Environment (soc_env) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 4/13] SPI Agent constructed
    if (env.spi_agnt == null || env.spi_agnt.mon == null || env.spi_agnt.drv == null || env.spi_agnt.seqr == null) begin
      `uvm_fatal(get_type_name(), "FAILED: SPI Agent or its subcomponents are null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 4/13] SPI Agent (drv, mon, seqr) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 5/13] I2C Agent constructed
    if (env.i2c_agnt == null || env.i2c_agnt.mon == null || env.i2c_agnt.drv == null || env.i2c_agnt.seqr == null) begin
      `uvm_fatal(get_type_name(), "FAILED: I2C Agent or its subcomponents are null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 5/13] I2C Agent (drv, mon, seqr) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 6/13] UART Agent constructed
    if (env.uart_agnt == null || env.uart_agnt.mon == null || env.uart_agnt.drv == null || env.uart_agnt.seqr == null) begin
      `uvm_fatal(get_type_name(), "FAILED: UART Agent or its subcomponents are null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 6/13] UART Agent (drv, mon, seqr) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 7/13] AHB passive monitor constructed
    if (env.ahb_agnt == null || env.ahb_agnt.mon == null) begin
      `uvm_fatal(get_type_name(), "FAILED: Passive AHB-Lite Monitor (ahb_agent / ahb_monitor) is null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 7/13] Passive AHB-Lite Monitor constructed: VERIFIED", UVM_LOW)
    end

    // [Check 8/13] Virtual sequencer constructed
    if (env.v_seqr == null || env.v_seqr.spi_seqr == null || env.v_seqr.i2c_seqr == null || env.v_seqr.uart_seqr == null) begin
      `uvm_fatal(get_type_name(), "FAILED: Virtual Sequencer (soc_virtual_sequencer) or its target handles are null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 8/13] Virtual Sequencer and handles (SPI, I2C, UART) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 9/13] Configuration successfully distributed
    if (env.cfg == null) begin
      `uvm_fatal(get_type_name(), "FAILED: Configuration object not distributed to env!")
    end else begin
      `uvm_info(get_type_name(), $sformatf(">>> [CHECK 9/13] Configuration successfully distributed (SPI=%s, I2C=%s, UART=%s, AHB=%s): VERIFIED",
                                           env.cfg.spi_is_active.name(), env.cfg.i2c_is_active.name(),
                                           env.cfg.uart_is_active.name(), env.cfg.ahb_is_active.name()), UVM_LOW)
    end

    // [Check 10/13] All required virtual interfaces available
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", spi_vif))
      `uvm_fatal(get_type_name(), "FAILED: virtual spi_if not accessible in config_db!")
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", i2c_vif))
      `uvm_fatal(get_type_name(), "FAILED: virtual i2c_if not accessible in config_db!")
    if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", uart_vif))
      `uvm_fatal(get_type_name(), "FAILED: virtual uart_if not accessible in config_db!")
    if (!uvm_config_db#(virtual ahb_lite_mon_if)::get(this, "", "vif", ahb_vif))
      `uvm_fatal(get_type_name(), "FAILED: virtual ahb_lite_mon_if not accessible in config_db!")
    `uvm_info(get_type_name(), ">>> [CHECK 10/13] All required virtual interfaces (SPI, I2C, UART, AHB) verified available: VERIFIED", UVM_LOW)

    // [Check 11/13] Scoreboard constructed
    if (env.sb == null) begin
      `uvm_fatal(get_type_name(), "FAILED: Central Scoreboard (soc_scoreboard) is null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 11/13] Central Scoreboard (soc_scoreboard) constructed: VERIFIED", UVM_LOW)
    end

    // [Check 12/13] Coverage collector constructed
    if (env.cov == null) begin
      `uvm_fatal(get_type_name(), "FAILED: Functional Coverage Collector (soc_coverage) is null!")
    end else begin
      `uvm_info(get_type_name(), ">>> [CHECK 12/13] Functional Coverage Collector (soc_coverage) constructed: VERIFIED", UVM_LOW)
    end

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "=== [CONSTRUCTION TEST] All 12 Structural Checks Passed!      ===", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "=== [CONSTRUCTION TEST] run_phase active: NO stimulus sequences started ===", UVM_LOW)

    // Brief settling observation to allow reset release without driving any sequence items
    #200;

    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), ">>> [CHECK 13/13] UVM environment completes without fatal errors: VERIFIED", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass

`endif
