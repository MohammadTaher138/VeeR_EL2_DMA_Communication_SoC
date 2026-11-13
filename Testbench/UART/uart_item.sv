class uart_item extends uvm_sequence_item;

  bit uart_tx_o;
  rand bit uart_rx_i;
  bit uart_rts_o;
  rand bit uart_cts_i;

  `uvm_object_utils(uart_item)

  function new(string name="uart_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("[UART_ITEM] uart_tx_o=0x%0h, uart_rx_i=0x%0h, uart_rts_o=0x%0h, uart_cts_i=0x%0h", uart_tx_o, uart_rx_i, uart_rts_o, uart_cts_i);
  endfunction
endclass
