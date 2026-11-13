CC = /opt/riscv/bin/riscv64-unknown-elf-gcc
OBJCOPY = /opt/riscv/bin/riscv64-unknown-elf-objcopy
OBJDUMP = /opt/riscv/bin/riscv64-unknown-elf-objdump

CFLAGS = -march=rv32imc_zicsr -mabi=ilp32 -O2 -nostartfiles -T link.ld -Wall -Wno-array-bounds

all: firmware.hex

firmware.elf: crt0.s main.c link.ld
	$(CC) $(CFLAGS) -o firmware.elf crt0.s main.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin
	$(OBJDUMP) -d firmware.elf > firmware.dis

firmware.hex: firmware.bin make_hex.py
	python3 make_hex.py firmware.bin firmware.hex
	cp firmware.hex ../Run/firmware.hex
	cp firmware.hex ../firmware.hex

clean:
	rm -f firmware.elf firmware.bin firmware.hex firmware.dis
