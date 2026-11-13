OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x00000800, LENGTH = 32K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > ROM

  .data : {
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > RAM AT > ROM

  .bss : {
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
  } > RAM

  _end = .;
}
