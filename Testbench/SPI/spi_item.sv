class spi_item extends uvm_sequence_item;

  bit spi_clk_o;
  bit spi_cs_n_o;
  bit spi_mosi_o;
  rand bit spi_miso_i;

  `uvm_object_utils(spi_item)

  function new(string name="spi_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("[SPI_ITEM] spi_clk_o=0x%0h, spi_cs_n_o=0x%0h, spi_mosi_o=0x%0h, spi_miso_i=0x%0h", spi_clk_o, spi_cs_n_o, spi_mosi_o, spi_miso_i);
  endfunction
endclass
