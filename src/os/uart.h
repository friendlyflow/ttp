/* uart.h — NS16550A serial console on QEMU's `virt` machine (0x10000000). */
#ifndef OS_UART_H
#define OS_UART_H

#include <stdint.h>

void uart_putc(char c);
int  uart_getc(void);          /* next byte, or -1 if none is waiting */
void uart_puts(const char *s);
void uart_puthex(uint64_t v);  /* "0x" + 16 hex digits */

#endif
