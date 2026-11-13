class i2c_item extends uvm_sequence_item;

  rand bit i2c_scl;
  rand bit i2c_sda;

  `uvm_object_utils(i2c_item)

  function new(string name="i2c_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("[I2C_ITEM] i2c_scl=0x%0h, i2c_sda=0x%0h", i2c_scl, i2c_sda);
  endfunction
endclass
