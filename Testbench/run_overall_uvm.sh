#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "=== Running Overall UVM Testbench (Integrating All VIPs) ==="
cd "$SCRIPT_DIR/overall_uvm"
./run_sim.sh
