#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "=== Compiling Overall UVM Testbench (Integrating All VIPs) ==="
cd "$SCRIPT_DIR/overall_uvm"
./compile_vcs.sh
echo "=== Compilation Succeeded! Executable built at: $SCRIPT_DIR/overall_uvm/simv ==="
