/* kernel.c — where entry.S lands: the C side of the OS. */
#include <stdint.h>
#include "uart.h"

/* SiFive test finisher on `virt`: writing FINISHER_PASS powers QEMU off. */
#define TEST_FINISHER  0x100000UL
#define FINISHER_PASS  0x5555

#define CTRL_D 0x04

static void poweroff(void)
{
    uart_puts("\nos: poweroff\n");
    *(volatile uint32_t *)TEST_FINISHER = FINISHER_PASS;
    for (;;)
        __asm__ volatile("wfi");
}

/* Called from trap.S. No interrupts are enabled, so every trap is an
 * exception: report it and halt. */
void trap_handler(uint64_t mcause, uint64_t mepc, uint64_t mtval)
{
    uart_puts("\nos: trap mcause=");
    uart_puthex(mcause);
    uart_puts(" mepc=");
    uart_puthex(mepc);
    uart_puts(" mtval=");
    uart_puthex(mtval);
    uart_puts("\n");
    for (;;)
        __asm__ volatile("wfi");
}

void kmain(void)
{
    uint64_t hart;
    __asm__ volatile("csrr %0, mhartid" : "=r"(hart));

    uart_puts("os: hello from C on hart ");
    uart_puthex(hart);
    uart_puts("\nos: type to echo, Ctrl-D to power off\n");

    for (;;) {
        int c = uart_getc();
        if (c < 0)
            continue;
        if (c == CTRL_D)
            poweroff();
        if (c == '\r' || c == '\n')
            uart_puts("\n");
        else if (c == 0x7f || c == '\b')
            uart_puts("\b \b");
        else
            uart_putc((char)c);
    }
}
