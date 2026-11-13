# ==============================================================================
# Makefile for VeeR EL2 Communication SoC Testbench Suite
# ==============================================================================

IPS = I2C SPI UART

.PHONY: all overall ips clean $(IPS)

all: overall

overall:
	@echo "=== Compiling & Running Overall SoC UVM Testbench ==="
	cd overall_uvm && ./compile_vcs.sh && ./run_sim.sh

ips: $(IPS)

I2C:
	@echo "=== Compiling & Running I2C UVM VIP Testbench ==="
	cd I2C && ./compile_vcs.sh && ./run_sim.sh

SPI:
	@echo "=== Compiling & Running SPI UVM VIP Testbench ==="
	cd SPI && ./compile_vcs.sh && ./run_sim.sh

UART:
	@echo "=== Compiling & Running UART UVM VIP Testbench ==="
	cd UART && ./compile_vcs.sh && ./run_sim.sh

clean:
	@echo "=== Cleaning simulation outputs ==="
	cd overall_uvm && rm -rf simv* csrc *.log ucli.key
	@for d in $(IPS); do \
		echo "Cleaning $$d..."; \
		rm -rf $$d/simv* $$d/csrc $$d/*.log $$d/ucli.key; \
	done
