class i2c_scoreboard extends uvm_scoreboard;
  uvm_analysis_imp #(i2c_item, i2c_scoreboard) item_export;
  int item_count = 0;
  `uvm_component_utils(i2c_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction

  function void write(i2c_item item);
    item_count++;
    `uvm_info(get_type_name(), $sformatf("Scoreboard captured item #%0d: %s", item_count, item.convert2string()), UVM_MEDIUM)
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Scoreboard verification summary: %0d items checked", item_count), UVM_LOW)
  endfunction
endclass
