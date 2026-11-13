//==========================================================================
//  soc_env.sv – Integrated Overall UVM Environment for VeeR EL2 SoC
//==========================================================================

`ifndef SOC_ENV_SV
`define SOC_ENV_SV

class soc_env extends uvm_env;
  `uvm_component_utils(soc_env)

  // Configuration
  soc_config             cfg;

  // Peripheral VIP Agents
  spi_agent              spi_agnt;
  i2c_agent              i2c_agnt;
  uart_agent             uart_agnt;

  // Passive AHB-Lite Bus Monitoring Agent
  ahb_agent              ahb_agnt;

  // Virtual Sequencer, Scoreboard & Coverage Collector
  soc_virtual_sequencer  v_seqr;
  soc_scoreboard         sb;
  soc_coverage           cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Retrieve or instantiate configuration
    if (!uvm_config_db#(soc_config)::get(this, "", "cfg", cfg)) begin
      `uvm_info(get_type_name(), "soc_config not found in config_db; creating default instance", UVM_MEDIUM)
      cfg = soc_config::type_id::create("cfg", this);
    end

    // Distribute active/passive configuration settings to agents
    uvm_config_db#(uvm_active_passive_enum)::set(this, "spi_agnt", "is_active", cfg.spi_is_active);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "i2c_agnt", "is_active", cfg.i2c_is_active);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "uart_agnt", "is_active", cfg.uart_is_active);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "ahb_agnt", "is_active", cfg.ahb_is_active);

    // Distribute configuration object to scoreboard and coverage collector
    uvm_config_db#(soc_config)::set(this, "sb", "cfg", cfg);
    uvm_config_db#(soc_config)::set(this, "cov", "cfg", cfg);

    // Instantiate Agents
    spi_agnt  = spi_agent::type_id::create("spi_agnt", this);
    spi_agnt.is_active = cfg.spi_is_active;

    i2c_agnt  = i2c_agent::type_id::create("i2c_agnt", this);
    i2c_agnt.is_active = cfg.i2c_is_active;

    uart_agnt = uart_agent::type_id::create("uart_agnt", this);
    uart_agnt.is_active = cfg.uart_is_active;

    ahb_agnt  = ahb_agent::type_id::create("ahb_agnt", this);
    ahb_agnt.is_active = cfg.ahb_is_active;

    // Instantiate Virtual Sequencer, Scoreboard, and Coverage
    v_seqr    = soc_virtual_sequencer::type_id::create("v_seqr", this);
    sb        = soc_scoreboard::type_id::create("sb", this);
    cov       = soc_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // 1. Connect Virtual Sequencer to Active VIP Sequencers
    if (cfg.spi_is_active == UVM_ACTIVE && spi_agnt.seqr != null) begin
      v_seqr.spi_seqr  = spi_agnt.seqr;
    end
    if (cfg.i2c_is_active == UVM_ACTIVE && i2c_agnt.seqr != null) begin
      v_seqr.i2c_seqr  = i2c_agnt.seqr;
    end
    if (cfg.uart_is_active == UVM_ACTIVE && uart_agnt.seqr != null) begin
      v_seqr.uart_seqr = uart_agnt.seqr;
    end

    // 2. Connect Analysis Ports to Central Scoreboard
    spi_agnt.mon.ap.connect(sb.spi_export);
    i2c_agnt.mon.ap.connect(sb.i2c_export);
    uart_agnt.mon.ap.connect(sb.uart_export);
    ahb_agnt.mon.ap.connect(sb.ahb_export);

    // 3. Connect Analysis Ports to Functional Coverage Collector
    spi_agnt.mon.ap.connect(cov.spi_cov_export);
    i2c_agnt.mon.ap.connect(cov.i2c_cov_export);
    uart_agnt.mon.ap.connect(cov.uart_cov_export);
    ahb_agnt.mon.ap.connect(cov.ahb_cov_export);

    // 4. Pass configuration handle to scoreboard & coverage
    sb.cfg  = cfg;
    cov.cfg = cfg;
  endfunction
endclass

`endif
