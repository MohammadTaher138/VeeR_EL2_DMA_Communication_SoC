//==========================================================================
//  soc_uvm_pkg.sv – Top-Level Overall UVM Package for VeeR EL2 SoC
//==========================================================================

`ifndef SOC_UVM_PKG_SV
`define SOC_UVM_PKG_SV

package soc_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import individual external interface VIP packages
  import spi_pkg::*;
  import i2c_pkg::*;
  import uart_pkg::*;

  // Passive AHB-Lite bus monitoring components
  `include "ahb_item.sv"
  `include "ahb_monitor.sv"
  `include "ahb_agent.sv"

  // Top-Level SoC Environment Components
  `include "soc_config.sv"
  `include "soc_virtual_sequencer.sv"
  `include "soc_scoreboard.sv"
  `include "soc_coverage.sv"
  `include "soc_env.sv"

  // Virtual Sequences
  `include "soc_base_sequence.sv"
  `include "soc_virtual_sequence.sv"

  // Top-Level UVM Tests
  `include "soc_overall_test.sv"
  `include "soc_construction_test.sv"
  `include "soc_boot_test.sv"
  `include "soc_spi_test.sv"
  `include "soc_i2c_test.sv"
  `include "soc_dma_m2m_test.sv"
  `include "soc_dma_spi_test.sv"
  `include "soc_dma_i2c_test.sv"
  `include "soc_uart_test.sv"
  `include "soc_sys_test.sv"
endpackage

`endif
