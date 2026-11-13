#!/bin/bash
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export PATH=$VCS_HOME/bin:$PATH

vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \
    i2c_if.sv i2c_pkg.sv tb_top.sv \
    -l vcs_compile.log
