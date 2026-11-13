//==========================================================================
//  soc_base_sequence.sv – Base Virtual Sequence for VeeR EL2 SoC
//==========================================================================

`ifndef SOC_BASE_SEQUENCE_SV
`define SOC_BASE_SEQUENCE_SV

class soc_base_sequence extends uvm_sequence;
  `uvm_object_utils(soc_base_sequence)
  `uvm_declare_p_sequencer(soc_virtual_sequencer)

  function new(string name = "soc_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), "Executing SoC base virtual sequence", UVM_MEDIUM)
  endtask
endclass

`endif
