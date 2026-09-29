/* uart.c — polled NS16550A driver. QEMU needs no baud/FIFO setup. */
#include "uart.h"

#define UART_BASE 0x10000000UL
#define UART_THR  0   /* transmit holding register (write) */
#define UART_RBR  0   /* receive buffer register (read)    */
#define UART_LSR  5   /* line status register              */
#define LSR_DR    0x01 /* data ready          */
#define LSR_THRE  0x20 /* transmitter empty   */

static volatile uint8_t *const uart = (volatile uint8_t *)UART_BASE;

void uart_putc(char c)
{
    while (!(uart[UART_LSR] & LSR_THRE))
        ;
    uart[UART_THR] = (uint8_t)c;
}

int uart_getc(void)
{
    if (!(uart[UART_LSR] & LSR_DR))
        return -1;
    return uart[UART_RBR];
}

void uart_puts(const char *s)
{
    while (*s) {
        if (*s == '\n')
            uart_putc('\r');
        uart_putc(*s++);
    }
}

void uart_puthex(uint64_t v)
{
    uart_puts("0x");
    for (int shift = 60; shift >= 0; shift -= 4)
        uart_putc("0123456789abcdef"[(v >> shift) & 0xf]);
}
