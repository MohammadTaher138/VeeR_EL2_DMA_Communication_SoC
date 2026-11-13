#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$WORK_DIR"

export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export PATH=$VCS_HOME/bin:$PATH

TESTS=(
    "soc_construction_test"
    "soc_boot_test"
    "soc_spi_test"
    "soc_i2c_test"
    "soc_dma_m2m_test"
    "soc_dma_spi_test"
    "soc_dma_i2c_test"
    "soc_uart_test"
    "soc_sys_test"
    "soc_overall_test"
)

echo "=========================================================================="
echo "          VEER EL2 COMMUNICATION SOC UVM REGRESSION SUITE RUN             "
echo "=========================================================================="

PASSED_COUNT=0
FAILED_COUNT=0

mkdir -p logs

for test in "${TESTS[@]}"; do
    echo ">>> Running UVM Test: $test ..."
    if ./simv +UVM_TESTNAME=$test +UVM_VERBOSITY=UVM_LOW -l "logs/${test}.log" > /dev/null 2>&1; then
        # Check if log reported 0 UVM_ERROR and 0 UVM_FATAL
        ERRORS=$(grep "UVM_ERROR :" "logs/${test}.log" | tail -n 1 | awk '{print $3}')
        FATALS=$(grep "UVM_FATAL :" "logs/${test}.log" | tail -n 1 | awk '{print $3}')
        if [ "$ERRORS" == "0" ] && [ "$FATALS" == "0" ]; then
            echo "    STATUS: [PASSED] (0 Errors, 0 Fatals)"
            PASSED_COUNT=$((PASSED_COUNT + 1))
        else
            echo "    STATUS: [FAILED] (Errors: $ERRORS, Fatals: $FATALS)"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        echo "    STATUS: [CRASHED/FAILED]"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

echo "=========================================================================="
echo "                      REGRESSION EXECUTION SUMMARY                        "
echo "=========================================================================="
echo "  Total Tests Executed: ${#TESTS[@]}"
echo "  Passed:               $PASSED_COUNT"
echo "  Failed:               $FAILED_COUNT"
echo "=========================================================================="

if [ $FAILED_COUNT -eq 0 ]; then
    echo ">>> ALL UVM REGRESSION TESTS COMPLETED AND PASSED SUCCESSFULLY! <<<"
    exit 0
else
    echo ">>> REGRESSION SUITE FAILED WITH $FAILED_COUNT ERRORS! <<<"
    exit 1
fi
