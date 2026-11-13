//==========================================================================
//  ahb_agent.sv – Passive AHB-Lite Monitoring Agent (No Master/Driver)
//==========================================================================

`ifndef AHB_AGENT_SV
`define AHB_AGENT_SV

class ahb_agent extends uvm_agent;
  ahb_monitor mon;

  `uvm_component_utils(ahb_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Always passive: only monitor is instantiated
    mon = ahb_monitor::type_id::create("mon", this);
  endfunction
endclass

`endif
