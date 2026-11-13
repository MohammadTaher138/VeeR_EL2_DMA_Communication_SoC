#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORK_DIR"

export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export PATH=$VCS_HOME/bin:$PATH

echo "=== Running VeeR EL2 Overall SoC UVM Simulation ==="
if [ ! -f "$WORK_DIR/simv" ]; then
    echo "ERROR: simv binary not found. Please run compile.sh first."
    exit 1
fi

./simv +UVM_VERBOSITY=UVM_MEDIUM -l sim.log "$@"

echo "=== Overall SoC UVM Simulation Finished! Log saved at: $WORK_DIR/sim.log ==="
