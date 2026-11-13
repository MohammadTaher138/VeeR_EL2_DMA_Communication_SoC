//==========================================================================
//  soc_virtual_sequencer.sv – Virtual Sequencer for VeeR EL2 SoC VIPs
//==========================================================================

`ifndef SOC_VIRTUAL_SEQUENCER_SV
`define SOC_VIRTUAL_SEQUENCER_SV

class soc_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(soc_virtual_sequencer)

  spi_sequencer  spi_seqr;
  i2c_sequencer  i2c_seqr;
  uart_sequencer uart_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

`endif
