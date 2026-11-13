interface i2c_if;
  logic clk;
  logic rst_n;
  wire i2c_scl;
  wire i2c_sda;

  // Active slave open-drain drive control from i2c_driver
  logic sda_drv_low = 1'b0;
  assign i2c_sda = sda_drv_low ? 1'b0 : 1'bz;

  // Transfer direction indication (from master command register bit 5)
  logic is_read;
endinterface
