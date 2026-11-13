#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORK_DIR"

export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export PATH=$VCS_HOME/bin:$PATH

echo "=== Compiling VeeR EL2 Overall SoC UVM Testbench with Synopsys VCS ==="
vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \
    -top tb_top_veer_soc \
    -f run_uvm.f \
    +define+RV_BUILD=1 \
    -l vcs_compile.log

echo "=== Overall SoC UVM Compilation Succeeded! Executable built at: $WORK_DIR/simv ==="
