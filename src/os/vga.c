/*
 * ttp — the trust project: a self-hosting OS and compiler.
 * Copyright (C) 2026  Nico Verrijdt
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "vga.h"
#include <stdint.h>

#define VGA_ADDRESS 0xB8000
#define VGA_WIDTH   80
#define VGA_HEIGHT  25

static volatile uint16_t *vga = (uint16_t *)VGA_ADDRESS;
static int cur_x = 0;
static int cur_y = 0;

static uint16_t entry(char c, vga_color fg, vga_color bg) {
    return (uint16_t)c | (uint16_t)((bg << 4) | fg) << 8;
}

void vga_clear(vga_color bg) {
    for (int y = 0; y < VGA_HEIGHT; y++)
        for (int x = 0; x < VGA_WIDTH; x++)
            vga[y * VGA_WIDTH + x] = entry(' ', WHITE, bg);
    cur_x = cur_y = 0;
}

static void putchar(char c, vga_color fg, vga_color bg) {
    if (c == '\n') { cur_x = 0; cur_y++; return; }
    vga[cur_y * VGA_WIDTH + cur_x] = entry(c, fg, bg);
    if (++cur_x >= VGA_WIDTH) { cur_x = 0; cur_y++; }
}

void vga_print(const char *str, vga_color fg, vga_color bg) {
    for (int i = 0; str[i]; i++) putchar(str[i], fg, bg);
}

void vga_println(const char *str, vga_color fg, vga_color bg) {
    vga_print(str, fg, bg);
    putchar('\n', fg, bg);
}

void vga_print_int(int n, vga_color fg, vga_color bg) {
    if (n < 0) { putchar('-', fg, bg); n = -n; }
    if (n == 0) { putchar('0', fg, bg); return; }
    char buf[20]; int i = 0;
    while (n > 0) { buf[i++] = '0' + (n % 10); n /= 10; }
    while (i--) putchar(buf[i], fg, bg);
}

void vga_print_hex(uint64_t n, vga_color fg, vga_color bg) {
    static const char digits[] = "0123456789abcdef";
    if (n == 0) { putchar('0', fg, bg); return; }
    char buf[16]; int i = 0;
    while (n > 0) { buf[i++] = digits[n & 0xF]; n >>= 4; }
    while (i--) putchar(buf[i], fg, bg);
}

void vga_putc_at(int x, int y, char c, vga_color fg, vga_color bg) {
    if (x < 0 || x >= VGA_WIDTH || y < 0 || y >= VGA_HEIGHT) return;
    vga[y * VGA_WIDTH + x] = entry(c, fg, bg);
}

void vga_puts_at(int x, int y, const char *s, vga_color fg, vga_color bg) {
    for (int i = 0; s[i] && x + i < VGA_WIDTH; i++)
        vga_putc_at(x + i, y, s[i], fg, bg);
}