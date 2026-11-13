.section .text.init
.global _start
_start:
    /* Disable interrupts initially */
    csrw mstatus, zero
    csrw mie, zero

    /* Set up stack pointer in DCCM */
    li sp, 0x00000FF0
    li gp, 0

    /* Set up external interrupt vector table at 0xF0040400 in DCCM */
    li t0, 0xF0040400
    csrw 0xBC8, t0  /* CSR meivt = 0xF0040400 */

    /* Populate table entries for all 32 external interrupt sources */
    la t1, isr_wrapper
    li t2, 32
1:
    sw t1, 0(t0)
    addi t0, t0, 4
    addi t2, t2, -1
    bnez t2, 1b

    /* Set up mtvec to point to isr_wrapper (Direct mode) */
    la t0, isr_wrapper
    csrw mtvec, t0

    /* Configure MRAC (Memory Region Attributes CSR = 0x7c0) */
    /* Set side-effect bit for external MMIO regions */
    li t0, 0xAAAAAAAA
    csrw 0x7c0, t0

    /* Disable DCCM ECC check in MFDC (CSR 0x7F9, bit 8) */
    li t0, 0x100
    csrs 0x7F9, t0

    /* Set priority threshold meipt = 0 */
    csrw 0xBC9, zero
    /* Set current priority meicurpl = 0 */
    csrw 0xBCC, zero

    /* Jump to C main */
    call main

    /* Loop forever if main returns */
_halt:
    wfi
    j _halt

.balign 64
.global isr_wrapper
isr_wrapper:
    addi sp, sp, -64
    sw ra, 0(sp)
    sw t0, 4(sp)
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw a0, 16(sp)
    sw a1, 20(sp)
    sw a2, 24(sp)
    sw a3, 28(sp)
    sw a4, 32(sp)
    sw a5, 36(sp)
    sw a6, 40(sp)
    sw a7, 44(sp)
    sw t3, 48(sp)
    sw t4, 52(sp)
    sw t5, 56(sp)
    sw t6, 60(sp)

    call c_isr_handler

    lw ra, 0(sp)
    lw t0, 4(sp)
    lw t1, 8(sp)
    lw t2, 12(sp)
    lw a0, 16(sp)
    lw a1, 20(sp)
    lw a2, 24(sp)
    lw a3, 28(sp)
    lw a4, 32(sp)
    lw a5, 36(sp)
    lw a6, 40(sp)
    lw a7, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    addi sp, sp, 64
    mret

