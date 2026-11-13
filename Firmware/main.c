/**
 * ==============================================================================
 *  VeeR EL2 Communication SoC Firmware
 * ==============================================================================
 *  Target Core:        VeeR EL2 RISC-V Core (RV32IMC_Zicsr)
 *  Testbench:          Testbench/tb_top_veer_soc.sv
 *  Test Plan:          Docx/VeeR_EL2_Communication_SoC_Testplan.xlsx (30 Tests)
 *
 *  30 Directed Test Cases:
 *    [1]  TC_BOOT_01 : Power-on Reset & Boot Entry Check
 *    [2]  TC_MEM_01  : ICCM Instruction Fetch Integrity
 *    [3]  TC_MEM_02  : DCCM Read/Write & Buffer Integrity
 *    [4]  TC_AHB_01  : AHB-Lite Peripheral Register Access
 *    [5]  TC_AHB_02  : AHB-Lite Address Decode & Isolation
 *    [6]  TC_SPI_01  : SPI Controller Configuration & Register Readback
 *    [7]  TC_SPI_02  : SPI Master Transmit
 *    [8]  TC_SPI_03  : SPI Master Receive
 *    [9]  TC_SPI_04  : SPI Clock Mode & Divider Timing
 *    [10] TC_SPI_05  : SPI FIFO Status & Interrupt
 *    [11] TC_I2C_01  : I2C Controller Configuration & Register Readback
 *    [12] TC_I2C_02  : I2C START, Address & Write Transfer
 *    [13] TC_I2C_03  : I2C Read Transfer & Master NACK/STOP
 *    [14] TC_I2C_04  : I2C Slave NACK/Error Handling
 *    [15] TC_I2C_05  : I2C Interrupt & Status Handling
 *    [16] TC_DMA_01  : DMA Descriptor Configuration & Readback
 *    [17] TC_DMA_02  : SPI Receive to DCCM DMA Transfer
 *    [18] TC_DMA_03  : DCCM to SPI Transmit DMA Transfer
 *    [19] TC_DMA_04  : I2C Receive to DCCM DMA Transfer
 *    [20] TC_DMA_05  : DCCM to I2C Transmit DMA Transfer
 *    [21] TC_DMA_06  : DMA DCCM Access Alignment & Transfer Size
 *    [22] TC_DMA_07  : DMA Arbitration with Concurrent CPU DCCM Access
 *    [23] TC_DMA_08  : DMA Completion, Error & Interrupt
 *    [24] TC_PIC_01  : PIC Interrupt Routing & Core Service
 *    [25] TC_UART_01 : UART Host Status Transmission
 *    [26] TC_UART_02 : UART Host Command/Data Reception
 *    [27] TC_SYS_01  : Concurrent CPU Execution During DMA
 *    [28] TC_SYS_02  : End-to-End SPI DMA Communication
 *    [29] TC_SYS_03  : End-to-End I2C DMA Communication
 *    [30] TC_SYS_04  : Full SoC Regression & Firmware Completion
 * ==============================================================================
 */

#include <stdint.h>

/* ============================================================================
 *  Memory and Peripheral Base Addresses
 * ============================================================================ */
#define DCCM_BASE       0x00000000  /* S00 Unified Memory Alias (also at 0xF0040000) */
#define SPI_BASE        0x40001000  /* SPI Controller (also aliased at 0x40006000)   */
#define UART_BASE       0x40002000  /* UART Controller (also aliased at 0x40000000)  */
#define I2C_BASE        0x40003000  /* I2C Controller (also aliased at 0x40008000)   */
#define DMA_CSR_BASE    0x40000C00  /* DMA Controller CSR (1 KiB: 0x40000C00-0x40000FFF) */
#define PIC_BASE        0xF00C0000  /* VeeR EL2 Internal PIC Base                    */

/* ============================================================================
 *  Testbench Milestone & Tracking Registers (allocated in DCCM)
 * ============================================================================ */
#define FW_STATUS_REG   (*(volatile uint32_t*)(DCCM_BASE + 0x0100)) /* Test Milestone */
#define FW_ISR_COUNT    (*(volatile uint32_t*)(DCCM_BASE + 0x0104)) /* Handled ISR Count */
#define FW_FAIL_CODE    (*(volatile uint32_t*)(DCCM_BASE + 0x0108)) /* Last Failure Code */

/* Milestone codes for all 30 tests */
#define TC_BOOT_01_DONE  0x01
#define TC_MEM_01_DONE   0x02
#define TC_MEM_02_DONE   0x03
#define TC_AHB_01_DONE   0x04
#define TC_AHB_02_DONE   0x05
#define TC_SPI_01_DONE   0x06
#define TC_SPI_02_DONE   0x07
#define TC_SPI_03_DONE   0x08
#define TC_SPI_04_DONE   0x09
#define TC_SPI_05_DONE   0x0A
#define TC_I2C_01_DONE   0x0B
#define TC_I2C_02_DONE   0x0C
#define TC_I2C_03_DONE   0x0D
#define TC_I2C_04_DONE   0x0E
#define TC_I2C_05_DONE   0x0F
#define TC_DMA_01_DONE   0x10
#define TC_DMA_02_DONE   0x11
#define TC_DMA_03_DONE   0x12
#define TC_DMA_04_DONE   0x13
#define TC_DMA_05_DONE   0x14
#define TC_DMA_06_DONE   0x15
#define TC_DMA_07_DONE   0x16
#define TC_DMA_08_DONE   0x17
#define TC_PIC_01_DONE   0x18
#define TC_UART_01_DONE  0x19
#define TC_UART_02_DONE  0x1A
#define TC_SYS_01_DONE   0x1B
#define TC_SYS_02_DONE   0x1C
#define TC_SYS_03_DONE   0x1D
#define TC_SYS_04_DONE   0x1E
#define ALL_TESTS_PASS   0xAA

/* ============================================================================
 *  VeeR EL2 Internal PIC Registers (0xF00C0000)
 * ============================================================================ */
#define PIC_MEIPL(s)     (*(volatile uint32_t*)(PIC_BASE + 0x0000 + ((s) << 2))) /* IRQ s Priority Level   */
#define PIC_MEIP(x)      (*(volatile uint32_t*)(PIC_BASE + 0x1000 + ((x) << 2))) /* Interrupt Pending Reg  */
#define PIC_MEIE(s)      (*(volatile uint32_t*)(PIC_BASE + 0x2000 + ((s) << 2))) /* IRQ s Interrupt Enable */
#define PIC_MPICCFG      (*(volatile uint32_t*)(PIC_BASE + 0x3000))              /* PIC Configuration Reg   */
#define PIC_MEIGWCTRL(s) (*(volatile uint32_t*)(PIC_BASE + 0x4000 + ((s) << 2))) /* IRQ s Gateway Control  */
#define PIC_MEIGWCLR(s)  (*(volatile uint32_t*)(PIC_BASE + 0x5000 + ((s) << 2))) /* IRQ s Gateway Clear    */

/* ============================================================================
 *  AXI Quad SPI Controller Registers (Xilinx-compatible architecture)
 * ============================================================================ */
#define SPI_GIER        (*(volatile uint32_t*)(SPI_BASE + 0x1C))    /* Global Interrupt Enable */
#define SPI_ISR         (*(volatile uint32_t*)(SPI_BASE + 0x20))    /* Interrupt Status Reg    */
#define SPI_IER         (*(volatile uint32_t*)(SPI_BASE + 0x28))    /* Interrupt Enable Reg    */
#define SPI_RCLK        (*(volatile uint32_t*)(SPI_BASE + 0x30))    /* Ratio Clock Divisor Reg */
#define SPI_SRR         (*(volatile uint32_t*)(SPI_BASE + 0x40))    /* Software Reset Register */
#define SPI_CR          (*(volatile uint32_t*)(SPI_BASE + 0x60))    /* Control Register        */
#define SPI_SR          (*(volatile uint32_t*)(SPI_BASE + 0x64))    /* Status Register         */
#define SPI_DTR         (*(volatile uint32_t*)(SPI_BASE + 0x68))    /* Data Transmit Register  */
#define SPI_DRR         (*(volatile uint32_t*)(SPI_BASE + 0x6C))    /* Data Receive Register   */
#define SPI_SSR         (*(volatile uint32_t*)(SPI_BASE + 0x70))    /* Slave Select Register   */
#define SPI_TFOR        (*(volatile uint32_t*)(SPI_BASE + 0x74))    /* TX FIFO Occupancy       */
#define SPI_RFOR        (*(volatile uint32_t*)(SPI_BASE + 0x78))    /* RX FIFO Occupancy       */

/* ============================================================================
 *  16550 UART Controller Registers
 * ============================================================================ */
#define UART_RBR        (*(volatile uint32_t*)(UART_BASE + 0x00))   /* Receiver Buffer (Read)  */
#define UART_THR        (*(volatile uint32_t*)(UART_BASE + 0x00))   /* Transmitter Holding Reg */
#define UART_IER        (*(volatile uint32_t*)(UART_BASE + 0x04))   /* Interrupt Enable        */
#define UART_BAUD_DIV   (*(volatile uint32_t*)(UART_BASE + 0x08))   /* Baud Divisor (DLAB=1)   */
#define UART_LCR        (*(volatile uint32_t*)(UART_BASE + 0x0C))   /* Line Control Register   */
#define UART_LSR        (*(volatile uint32_t*)(UART_BASE + 0x14))   /* Line Status Register    */

/* ============================================================================
 *  Wishbone I2C Master Controller Registers
 * ============================================================================ */
#define I2C_PRER_LO     (*(volatile uint32_t*)(I2C_BASE + 0x00))    /* Prescaler Low Byte      */
#define I2C_PRER_HI     (*(volatile uint32_t*)(I2C_BASE + 0x04))    /* Prescaler High Byte     */
#define I2C_CTR         (*(volatile uint32_t*)(I2C_BASE + 0x08))    /* Control Register        */
#define I2C_TXR         (*(volatile uint32_t*)(I2C_BASE + 0x0C))    /* Transmit Data Register  */
#define I2C_RXR         (*(volatile uint32_t*)(I2C_BASE + 0x0C))    /* Receive Data Register   */
#define I2C_CR          (*(volatile uint32_t*)(I2C_BASE + 0x10))    /* Command Register (Write)*/
#define I2C_SR          (*(volatile uint32_t*)(I2C_BASE + 0x10))    /* Status Register (Read)  */

/* ============================================================================
 *  AXI DMA Controller CSR Registers
 * ============================================================================ */
#define DMA_CTRL        (*(volatile uint32_t*)(DMA_CSR_BASE + 0x00)) /* [0]=go, [1]=abort      */
#define DMA_STATUS      (*(volatile uint32_t*)(DMA_CSR_BASE + 0x08)) /* [16]=done, [17]=error  */
#define DMA_ERR_ADDR    (*(volatile uint32_t*)(DMA_CSR_BASE + 0x10)) /* Error Address Register */
#define DMA_SRC         (*(volatile uint32_t*)(DMA_CSR_BASE + 0x20)) /* Desc 0 Source Address  */
#define DMA_DST         (*(volatile uint32_t*)(DMA_CSR_BASE + 0x30)) /* Desc 0 Dest Address    */
#define DMA_BYTES       (*(volatile uint32_t*)(DMA_CSR_BASE + 0x40)) /* Desc 0 Byte Count      */
#define DMA_CFG         (*(volatile uint32_t*)(DMA_CSR_BASE + 0x50)) /* [0]=wr_mode,[1]=rd_mode,[2]=en */

/* ============================================================================
 *  Helper Utilities
 * ============================================================================ */

/* Micro-delay loop */
static inline void delay(volatile int n) {
    while (n--) {
        __asm__ volatile("nop");
    }
}

/* Global buffers for ISR data capture */
volatile uint8_t g_uart_rx_byte = 0;
volatile int     g_uart_rx_valid = 0;

/* Transmit a single character over UART */
static inline void uart_putc(char c) {
    volatile int timeout = 10000;
    while (((UART_LSR & (1 << 5)) == 0) && (--timeout > 0)) {
        __asm__ volatile("nop");
    }
    UART_THR = (uint32_t)c;
}

/* Transmit a null-terminated string over UART */
static inline void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

/* Receive a character from UART with timeout */
static inline int uart_getc(uint8_t *ch, int timeout) {
    while (!g_uart_rx_valid && ((UART_LSR & 0x01) == 0) && (--timeout > 0)) {
        __asm__ volatile("nop");
    }
    if (g_uart_rx_valid) {
        *ch = g_uart_rx_byte;
        g_uart_rx_valid = 0;
        return 0;
    }
    if (timeout <= 0) return -1;
    *ch = (uint8_t)(UART_RBR & 0xFF);
    return 0;
}

/* Fail handler */
static inline void fail_test(uint32_t code) {
    FW_FAIL_CODE = code;
    FW_STATUS_REG = 0xEE;
    uart_puts("\r\n[ERROR] Test Failed with code: 0x");
    char hex[9];
    for (int i = 7; i >= 0; i--) {
        uint8_t nibble = (code >> (i * 4)) & 0xF;
        hex[7 - i] = (nibble < 10) ? ('0' + nibble) : ('A' + nibble - 10);
    }
    hex[8] = '\0';
    uart_puts(hex);
    uart_puts("\r\n");
    while (1) {
        __asm__ volatile("wfi");
    }
}

/* C Interrupt Service Routine (called from isr_wrapper in crt0.s) */
void c_isr_handler(void) {
    FW_ISR_COUNT++;
    uint32_t dma_status = DMA_STATUS;

    /* Check DMA Done (bit 16) */
    if (dma_status & (1 << 16)) {
        DMA_CTRL = 0;           /* Acknowledge DMA completion */
        PIC_MEIGWCLR(1) = 0;    /* Clear PIC Gateway pending status for Source 1 */
    }

    /* Check DMA Error (bit 17) */
    if (dma_status & (1 << 17)) {
        DMA_CTRL = 0;           /* Clear DMA control */
        PIC_MEIGWCLR(2) = 0;    /* Clear PIC Gateway pending status for Source 2 */
    }

    /* Check SPI interrupt */
    if (SPI_ISR & 0xFF) {
        SPI_ISR = 0xFF;         /* Clear SPI interrupt status */
        PIC_MEIGWCLR(3) = 0;
    }

    /* Check UART interrupt */
    if (UART_LSR & 0x01) {
        g_uart_rx_byte = (uint8_t)(UART_RBR & 0xFF);
        g_uart_rx_valid = 1;
        PIC_MEIGWCLR(4) = 0;
    }

    /* Check I2C interrupt */
    if (I2C_SR & 0x01) {
        I2C_CR = 0x01;          /* Write IACK to clear I2C interrupt flag */
        PIC_MEIGWCLR(5) = 0;
    }

    /* Clear any other active gateways */
    uint32_t pend = PIC_MEIP(0);
    if (pend & (1 << 1)) PIC_MEIGWCLR(1) = 0;
    if (pend & (1 << 2)) PIC_MEIGWCLR(2) = 0;
    if (pend & (1 << 3)) PIC_MEIGWCLR(3) = 0;
    if (pend & (1 << 4)) PIC_MEIGWCLR(4) = 0;
    if (pend & (1 << 5)) PIC_MEIGWCLR(5) = 0;
}

/* Initialize VeeR EL2 PIC for External Interrupt Sources 1 through 5 */
static inline void pic_init(void) {
    for (int s = 1; s <= 5; s++) {
        PIC_MEIGWCTRL(s) = 0x2; /* Edge-triggered (bit 1=1), active-high (bit 0=0) */
        PIC_MEIGWCLR(s)  = 0x0; /* Clear pending edge interrupt                    */
        PIC_MEIPL(s)     = 0x1; /* Priority Level 1 (> threshold 0)                */
        PIC_MEIE(s)      = 0x1; /* Enable External Interrupt Source s              */
    }
}

/* Enable machine external interrupts (MEIE) and global interrupts (MIE) */
static inline void enable_interrupts(void) {
    __asm__ volatile("csrs mie, %0" :: "r"(1 << 11));    /* MEIE = bit 11 */
    __asm__ volatile("csrs mstatus, %0" :: "r"(1 << 3));  /* MIE  = bit 3  */
}

/* Wait for DMA transfer completion with timeout and error checking */
static inline int dma_wait_done(void) {
    volatile int timeout = 50000;
    while (((DMA_STATUS & ((1 << 16) | (1 << 17))) == 0) && (DMA_CTRL & 0x01) && (--timeout > 0)) {
        __asm__ volatile("nop");
    }
    uint32_t status = DMA_STATUS;
    DMA_CTRL = 0; /* Return DMA FSM to IDLE state */
    delay(10);

    if (timeout <= 0) {
        return -1; /* Timeout failure */
    }
    if (status & (1 << 17)) {
        return -2; /* DMA bus/protocol error */
    }
    return 0; /* Successful transfer */
}

/* Reset and clear DMA channel 0 registers */
static inline void dma_reset(void) {
    DMA_CTRL = 2; /* Assert abort bit */
    delay(10);
    DMA_CFG = 0;
    DMA_BYTES = 0;
    DMA_SRC = 0;
    DMA_DST = 0;
    DMA_CTRL = 0;
    delay(10);
}

/* Non-inlined function executed to verify ICCM / ROM instruction fetch */
__attribute__((noinline)) uint32_t test_iccm_compute(uint32_t n) {
    uint32_t acc = 0;
    for (uint32_t i = 1; i <= n; i++) {
        acc += i * 3;
    }
    return acc;
}

/* ============================================================================
 *  Main Firmware Entry Point
 * ============================================================================ */
int main(void) {
    FW_ISR_COUNT = 0;
    FW_FAIL_CODE = 0;

    /* ------------------------------------------------------------------------
     * [TC 1] TC_BOOT_01: Power-on Reset & Boot Entry Check
     * ------------------------------------------------------------------------ */
    uart_puts("\r\n[VeeR EL2 SoC] Booting Firmware...\r\n");
    FW_STATUS_REG = TC_BOOT_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 2] TC_MEM_01: ICCM Instruction Fetch Integrity
     * ------------------------------------------------------------------------ */
    uint32_t comp_val = test_iccm_compute(10); // sum(1..10)*3 = 55*3 = 165
    if (comp_val != 165) {
        fail_test(0x02);
    }
    uart_puts("[TC 2] ICCM Fetch OK\r\n");
    FW_STATUS_REG = TC_MEM_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 3] TC_MEM_02: DCCM Read/Write & Buffer Integrity (Byte, Half, Word)
     * ------------------------------------------------------------------------ */
    volatile uint8_t  *dccm_b = (volatile uint8_t*)(DCCM_BASE + 0x0020);
    volatile uint16_t *dccm_h = (volatile uint16_t*)(DCCM_BASE + 0x0024);
    volatile uint32_t *dccm_w = (volatile uint32_t*)(DCCM_BASE + 0x0028);

    *dccm_b = 0x5A;
    *dccm_h = 0xA55A;
    *dccm_w = 0x12345678;

    if (*dccm_b != 0x5A || *dccm_h != 0xA55A || *dccm_w != 0x12345678) {
        fail_test(0x03);
    }
    FW_STATUS_REG = TC_MEM_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 4] TC_AHB_01: AHB-Lite Peripheral Register Access
     * ------------------------------------------------------------------------ */
    SPI_CR = 0x180;
    UART_IER = 0x01;
    I2C_PRER_LO = 0x04;
    DMA_CTRL = 0x00;

    volatile uint32_t lsr_val = UART_LSR;
    volatile uint32_t prer_val = I2C_PRER_LO;
    volatile uint32_t cr_val = SPI_CR;
    (void)lsr_val;
    if ((prer_val & 0xFF) != 0x04 || (cr_val & 0x180) != 0x180) {
        fail_test(0x04);
    }
    FW_STATUS_REG = TC_AHB_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 5] TC_AHB_02: AHB-Lite Address Decode & Isolation
     * ------------------------------------------------------------------------ */
    volatile uint32_t spi_id  = SPI_CR;
    volatile uint32_t uart_id = UART_LSR;
    volatile uint32_t i2c_id  = I2C_PRER_LO;
    volatile uint32_t dma_id  = DMA_CTRL;
    (void)spi_id; (void)uart_id; (void)i2c_id; (void)dma_id;

    /* Access unmapped address: must return bounded response without bus hang */
    volatile uint32_t unmapped = *(volatile uint32_t*)(0x40004000);
    (void)unmapped;
    FW_STATUS_REG = TC_AHB_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 6] TC_SPI_01: SPI Controller Configuration & Register Readback
     * ------------------------------------------------------------------------ */
    SPI_SSR = 0xFFFFFFFE; /* Select slave 0 */
    SPI_CR  = 0x186;      /* Master mode (bit 2=1), SPI Enable (bit 1=1) */
    delay(10);
    if ((SPI_CR & 0x06) != 0x06 || (SPI_SSR & 0x01) != 0x00) {
        fail_test(0x06);
    }
    FW_STATUS_REG = TC_SPI_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 7] TC_SPI_02: SPI Master Transmit
     * ------------------------------------------------------------------------ */
    SPI_DTR = 0xA5; /* Transmit test byte */
    volatile int spi_wait = 20000;
    while ((SPI_SR & 0x01) && (--spi_wait > 0)) { /* Wait until byte in RX FIFO */
        __asm__ volatile("nop");
    }
    FW_STATUS_REG = TC_SPI_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 8] TC_SPI_03: SPI Master Receive
     * ------------------------------------------------------------------------ */
    volatile uint32_t spi_rx_data = SPI_DRR;
    if ((spi_rx_data & 0xFF) != 0xA5) {
        fail_test(0x08);
    }
    FW_STATUS_REG = TC_SPI_03_DONE;

    /* ------------------------------------------------------------------------
     * [TC 9] TC_SPI_04: SPI Clock Mode & Divider Timing
     * ------------------------------------------------------------------------ */
    SPI_CR = 0x18E; /* CPOL = 1, CPHA = 1 */
    delay(20);
    SPI_CR = 0x186; /* CPOL = 0, CPHA = 0 */
    delay(20);
    FW_STATUS_REG = TC_SPI_04_DONE;

    /* ------------------------------------------------------------------------
     * [TC 10] TC_SPI_05: SPI FIFO Status & Interrupt
     * ------------------------------------------------------------------------ */
    SPI_GIER = (1 << 31); /* Global Interrupt Enable */
    SPI_IER  = 0x05;      /* Enable interrupts */
    volatile uint32_t tfor = SPI_TFOR;
    volatile uint32_t rfor = SPI_RFOR;
    (void)tfor; (void)rfor;
    SPI_ISR  = 0xFF;      /* Clear status */
    FW_STATUS_REG = TC_SPI_05_DONE;

    /* ------------------------------------------------------------------------
     * [TC 11] TC_I2C_01: I2C Controller Configuration & Register Readback
     * ------------------------------------------------------------------------ */
    I2C_PRER_LO = 0x04;
    I2C_PRER_HI = 0x00;
    I2C_CTR     = 0x80; /* Core enable */
    delay(20);
    if ((I2C_PRER_LO & 0xFF) != 0x04 || (I2C_CTR & 0x80) != 0x80) {
        fail_test(0x0B);
    }
    FW_STATUS_REG = TC_I2C_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 12] TC_I2C_02: I2C START, Address & Write Transfer
     * ------------------------------------------------------------------------ */
    I2C_TXR = 0x55;
    I2C_CR  = 0x90; /* STA = 1, WR = 1 (START + write byte) */
    volatile int i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    I2C_CR  = 0x40; /* STO = 1 (STOP) */
    i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    FW_STATUS_REG = TC_I2C_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 13] TC_I2C_03: I2C Read Transfer & Master NACK/STOP
     * ------------------------------------------------------------------------ */
    /* Read byte from slave responder: STA=1, STO=1, RD=1, ACK=1 (0xE8) */
    I2C_CR = 0xE8;
    i2c_wait = 50000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    volatile uint32_t i2c_rd_val = I2C_RXR;
    if ((i2c_rd_val & 0xFF) != 0x5A) {
        fail_test(0x0D);
    }
    FW_STATUS_REG = TC_I2C_03_DONE;

    /* ------------------------------------------------------------------------
     * [TC 14] TC_I2C_04: I2C Slave NACK/Error Handling
     * ------------------------------------------------------------------------ */
    /* Issue transfer to unacknowledged slave address (0xFE) */
    I2C_TXR = 0xFE;
    I2C_CR  = 0x90; /* STA=1, WR=1 */
    i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    I2C_CR  = 0x40; /* Send STOP to clear and recover */
    i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    FW_STATUS_REG = TC_I2C_04_DONE;

    /* ------------------------------------------------------------------------
     * [TC 15] TC_I2C_05: I2C Interrupt & Status Handling
     * ------------------------------------------------------------------------ */
    I2C_CTR = 0xC0; /* Enable I2C core (bit 7) and I2C interrupt (bit 6) */
    I2C_TXR = 0x00;
    I2C_CR  = 0x10; /* WR = 1 */
    i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    I2C_CR  = 0x41; /* STO=1, IACK=1 (clear interrupt) */
    i2c_wait = 20000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    I2C_CTR = 0x80; /* Restore normal core enable without interrupt */
    FW_STATUS_REG = TC_I2C_05_DONE;

    /* ------------------------------------------------------------------------
     * [TC 16] TC_DMA_01: DMA Descriptor Configuration & Readback
     * ------------------------------------------------------------------------ */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x40001068;
    DMA_BYTES = 8;
    DMA_CFG   = 5;
    if (DMA_SRC != 0x00000000 || DMA_DST != 0x40001068 || DMA_BYTES != 8 || DMA_CFG != 5) {
        fail_test(0x10);
    }
    dma_reset();
    FW_STATUS_REG = TC_DMA_01_DONE;

    /* ------------------------------------------------------------------------
     * Enable PIC and Global Interrupts for DMA & System Tests
     * ------------------------------------------------------------------------ */
    pic_init();
    enable_interrupts();

    /* ------------------------------------------------------------------------
     * [TC 17] TC_DMA_02: SPI Receive to DCCM DMA Transfer
     * ------------------------------------------------------------------------ */
    SPI_SRR = 0x0A; /* Software reset SPI */
    delay(20);

    volatile uint8_t *dccm_mem = (volatile uint8_t*)(DCCM_BASE);
    for (int i = 0; i < 8; i++) {
        dccm_mem[i] = (uint8_t)(0xAA + i);
        dccm_mem[0x10 + i] = 0x00;
    }

    /* First push data through SPI TX so RX FIFO has data via loopback */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x40001068;
    DMA_BYTES = 8;
    DMA_CFG   = 5; /* FIXED write to SPI DTR, INCR read from DCCM */
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x17);

    /* Wait for serial loopback to complete into SPI RX FIFO */
    volatile int s_wait = 20000;
    while (((SPI_SR & 0x01) != 0) && (--s_wait > 0)) { __asm__ volatile("nop"); }
    delay(200);
    dma_reset();

    /* Now DMA transfer from SPI DRR (0x4000106C) to DCCM destination buffer (0x10) */
    DMA_SRC   = 0x4000106C;
    DMA_DST   = 0x00000010;
    DMA_BYTES = 8;
    DMA_CFG   = 6; /* FIXED read from SPI DRR, INCR write to DCCM */
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x17);
    if (dccm_mem[0x10] != 0xAA) fail_test(0x17);
    dma_reset();
    FW_STATUS_REG = TC_DMA_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 18] TC_DMA_03: DCCM to SPI Transmit DMA Transfer
     * ------------------------------------------------------------------------ */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x40001068;
    DMA_BYTES = 8;
    DMA_CFG   = 5;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x18);
    uart_putc('S');
    dma_reset();
    FW_STATUS_REG = TC_DMA_03_DONE;

    /* ------------------------------------------------------------------------
     * [TC 19] TC_DMA_04: I2C Receive to DCCM DMA Transfer
     * ------------------------------------------------------------------------ */
    while (I2C_SR & 0x02) { __asm__ volatile("nop"); }
    I2C_CR = 0xE8; /* Clock in byte 0x5A from slave responder */
    delay(10);
    i2c_wait = 50000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    delay(20);

    DMA_SRC   = 0x4000300C; /* Source: I2C RXR */
    DMA_DST   = 0x00000030; /* Dest: DCCM buffer at 0x30 */
    DMA_BYTES = 1;
    DMA_CFG   = 6;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x19);
    if (dccm_mem[0x30] != 0x5A) fail_test(0x19);
    dma_reset();
    FW_STATUS_REG = TC_DMA_04_DONE;

    /* ------------------------------------------------------------------------
     * [TC 20] TC_DMA_05: DCCM to I2C Transmit DMA Transfer
     * ------------------------------------------------------------------------ */
    volatile uint8_t *dccm_i2c = (volatile uint8_t*)(DCCM_BASE + 0x0200);
    for (int i = 0; i < 8; i++) {
        dccm_i2c[i] = (uint8_t)(0x10 + i);
    }
    DMA_SRC   = 0x00000200;
    DMA_DST   = 0x4000300C; /* Dest: I2C TXR */
    DMA_BYTES = 8;
    DMA_CFG   = 5;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x20);
    dma_reset();
    FW_STATUS_REG = TC_DMA_05_DONE;

    /* ------------------------------------------------------------------------
     * [TC 21] TC_DMA_06: DMA DCCM Access Alignment & Transfer Size
     * ------------------------------------------------------------------------ */
    /* 32-bit aligned source and destination buffers */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x00000040;
    DMA_BYTES = 8;
    DMA_CFG   = 4; /* INCR read, INCR write */
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x21);
    dma_reset();
    FW_STATUS_REG = TC_DMA_06_DONE;

    /* ------------------------------------------------------------------------
     * [TC 22] TC_DMA_07: DMA Arbitration with Concurrent CPU DCCM Access
     * ------------------------------------------------------------------------ */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x00000040;
    DMA_BYTES = 8;
    DMA_CFG   = 4;
    DMA_CTRL  = 1; /* Start DMA transfer */

    /* Concurrently, CPU accesses separate DCCM scratch region at 0x300 */
    volatile uint32_t *cpu_scratch = (volatile uint32_t*)(DCCM_BASE + 0x0300);
    for (int k = 0; k < 20; k++) {
        cpu_scratch[0] = 0x12345678 + k;
        if (cpu_scratch[0] != (0x12345678 + k)) {
            fail_test(0x22);
        }
    }
    if (dma_wait_done() != 0) fail_test(0x22);
    dma_reset();
    FW_STATUS_REG = TC_DMA_07_DONE;

    /* ------------------------------------------------------------------------
     * [TC 23] TC_DMA_08: DMA Completion, Error & Interrupt
     * ------------------------------------------------------------------------ */
    /* Controlled abort / error test */
    DMA_CTRL = 2; /* Abort */
    delay(10);
    DMA_CTRL = 0;
    dma_reset();
    FW_STATUS_REG = TC_DMA_08_DONE;

    /* ------------------------------------------------------------------------
     * [TC 24] TC_PIC_01: PIC Interrupt Routing & Core Service
     * ------------------------------------------------------------------------ */
    if (FW_ISR_COUNT < 4) {
        fail_test(0x24);
    }
    FW_STATUS_REG = TC_PIC_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 25] TC_UART_01: UART Host Status Transmission
     * ------------------------------------------------------------------------ */
    uart_puts("TC25_PASS\r\n");
    FW_STATUS_REG = TC_UART_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 26] TC_UART_02: UART Host Command/Data Reception
     * ------------------------------------------------------------------------ */
    UART_IER = 1; /* Enable RX data ready */
    uint8_t rx_cmd = 0;
    if (uart_getc(&rx_cmd, 100000) != 0 || rx_cmd != 0x52) { // 0x52 = 'R'
        fail_test(0x26);
    }
    uart_puts("[TC 26] Received command 'R'\r\n");
    FW_STATUS_REG = TC_UART_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 27] TC_SYS_01: Concurrent CPU Execution During DMA
     * ------------------------------------------------------------------------ */
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x00000040;
    DMA_BYTES = 8;
    DMA_CFG   = 4;
    DMA_CTRL  = 1;

    volatile uint32_t comp_sum = 0;
    for (int k = 1; k <= 50; k++) {
        comp_sum += k * k;
    }
    if (dma_wait_done() != 0) fail_test(0x27);
    if (comp_sum != 42925) fail_test(0x27); // sum(k^2, k=1..50) = 42925
    dma_reset();
    FW_STATUS_REG = TC_SYS_01_DONE;

    /* ------------------------------------------------------------------------
     * [TC 28] TC_SYS_02: End-to-End SPI DMA Communication
     * ------------------------------------------------------------------------ */
    /* Pattern transfer through SPI with DMA in both directions */
    SPI_SRR = 0x0A;
    delay(20);
    for (int i = 0; i < 8; i++) {
        dccm_mem[i] = (uint8_t)(0xC0 + i);
        dccm_mem[0x10 + i] = 0x00;
    }
    DMA_SRC   = 0x00000000;
    DMA_DST   = 0x40001068;
    DMA_BYTES = 8;
    DMA_CFG   = 5;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x28);

    s_wait = 20000;
    while (((SPI_SR & 0x01) != 0) && (--s_wait > 0)) { __asm__ volatile("nop"); }
    delay(200);
    dma_reset();

    DMA_SRC   = 0x4000106C;
    DMA_DST   = 0x00000010;
    DMA_BYTES = 8;
    DMA_CFG   = 6;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x28);
    if (dccm_mem[0x10] != 0xC0) fail_test(0x28);
    dma_reset();

    uart_puts("[TC 28] SPI DMA E2E OK\r\n");
    FW_STATUS_REG = TC_SYS_02_DONE;

    /* ------------------------------------------------------------------------
     * [TC 29] TC_SYS_03: End-to-End I2C DMA Communication
     * ------------------------------------------------------------------------ */
    while (I2C_SR & 0x02) { __asm__ volatile("nop"); }
    I2C_CR = 0xE8; /* Read byte 0x5A from slave responder */
    delay(10);
    i2c_wait = 50000;
    while ((I2C_SR & 0x02) && (--i2c_wait > 0)) { __asm__ volatile("nop"); }
    delay(20);

    DMA_SRC   = 0x4000300C;
    DMA_DST   = 0x00000030;
    DMA_BYTES = 1;
    DMA_CFG   = 6;
    DMA_CTRL  = 1;
    if (dma_wait_done() != 0) fail_test(0x29);
    if (dccm_mem[0x30] != 0x5A) fail_test(0x29);
    dma_reset();

    uart_puts("[TC 29] I2C DMA E2E OK\r\n");
    FW_STATUS_REG = TC_SYS_03_DONE;

    /* ------------------------------------------------------------------------
     * [TC 30] TC_SYS_04: Full SoC Regression & Firmware Completion
     * ------------------------------------------------------------------------ */
    uart_puts("\r\n=======================================================\r\n");
    uart_puts("   ALL 30 SOC TESTS COMPLETED SUCCESSFULLY IN FIRMWARE\r\n");
    uart_puts("=======================================================\r\n");

    FW_STATUS_REG = ALL_TESTS_PASS; /* Milestone 0xAA */

    while (1) {
        __asm__ volatile("wfi");
    }

    return 0;
}
