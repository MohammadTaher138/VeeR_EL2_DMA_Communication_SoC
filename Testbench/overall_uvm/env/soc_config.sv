//==========================================================================
//  soc_config.sv – Top-Level Verification Configuration Object
//==========================================================================

`ifndef SOC_CONFIG_SV
`define SOC_CONFIG_SV

class soc_config extends uvm_object;
  `uvm_object_utils(soc_config)

  uvm_active_passive_enum spi_is_active  = UVM_ACTIVE;
  uvm_active_passive_enum i2c_is_active  = UVM_ACTIVE;
  uvm_active_passive_enum uart_is_active = UVM_ACTIVE;
  uvm_active_passive_enum ahb_is_active  = UVM_PASSIVE;

  bit enable_scoreboard_checks = 1'b1;
  bit enable_coverage          = 1'b1;
  real clk_period_ns           = 10.0;
  real reset_duration_ns       = 40.0;

  virtual spi_if          spi_vif;
  virtual i2c_if          i2c_vif;
  virtual uart_if         uart_vif;
  virtual ahb_lite_mon_if ahb_vif;

  // Real-time SoC Firmware Milestone & Interrupt Tracking
  bit [7:0] current_milestone = 8'h00;
  bit [7:0] fail_code         = 8'h00;
  int       isr_count         = 0;
  bit       all_tests_passed  = 1'b0;
  event     milestone_ev;

  function new(string name = "soc_config");
    super.new(name);
  endfunction
endclass

`endif
