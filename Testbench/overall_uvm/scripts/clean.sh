#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORK_DIR"

echo "=== Cleaning Overall UVM Build & Simulation Artifacts ==="
rm -rf simv simv.daidir csrc *.log ucli.key vc_hdrs.h DVEfiles urgReport *.vpd *.vcd
echo "=== Clean Complete ==="
