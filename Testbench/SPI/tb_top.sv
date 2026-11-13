`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import spi_pkg::*;

  // Clock & Reset Generation
  logic clk;
  logic rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    #30 rst_n = 1'b1;
  end

  // Interface Instance
  spi_if vif();
  assign vif.clk = clk;
  assign vif.rst_n = rst_n;


  initial begin
    uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
    run_test("spi_test");
  end
endmodule
