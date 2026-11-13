`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import i2c_pkg::*;

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
  i2c_if vif();
  assign vif.clk = clk;
  assign vif.rst_n = rst_n;

  // Pull-up resistors for I2C open-drain lines
  pullup p_scl (vif.i2c_scl);
  pullup p_sda (vif.i2c_sda);

  initial begin
    uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", vif);
    run_test("i2c_test");
  end
endmodule
