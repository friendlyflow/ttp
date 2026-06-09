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

#include <stdint.h>
#include <stddef.h>

// VGA text buffer
#define VGA_ADDRESS  0xB8000
#define VGA_WIDTH    80
#define VGA_HEIGHT   25

typedef enum {
    BLACK       = 0,
    BLUE        = 1,
    GREEN       = 2,
    CYAN        = 3,
    RED         = 4,
    MAGENTA     = 5,
    BROWN       = 6,
    LIGHT_GREY  = 7,
    DARK_GREY   = 8,
    LIGHT_BLUE  = 9,
    LIGHT_GREEN = 10,
    LIGHT_CYAN  = 11,
    LIGHT_RED   = 12,
    PINK        = 13,
    YELLOW      = 14,
    WHITE       = 15,
} vga_color;

static volatile uint16_t* vga = (uint16_t*)VGA_ADDRESS;
static int cur_x = 0;
static int cur_y = 0;

static uint16_t vga_entry(char c, vga_color fg, vga_color bg) {
    return (uint16_t)c | (uint16_t)((bg << 4) | fg) << 8;
}

void clear_screen(vga_color bg) {
    for (int y = 0; y < VGA_HEIGHT; y++)
        for (int x = 0; x < VGA_WIDTH; x++)
            vga[y * VGA_WIDTH + x] = vga_entry(' ', WHITE, bg);
    cur_x = cur_y = 0;
}

void putchar(char c, vga_color fg, vga_color bg) {
    if (c == '\n') {
        cur_x = 0;
        cur_y++;
        return;
    }
    vga[cur_y * VGA_WIDTH + cur_x] = vga_entry(c, fg, bg);
    if (++cur_x >= VGA_WIDTH) {
        cur_x = 0;
        cur_y++;
    }
}

void print(const char *str, vga_color fg, vga_color bg) {
    for (int i = 0; str[i]; i++)
        putchar(str[i], fg, bg);
}

// Minimal itoa — no stdlib available
void print_int(int n, vga_color fg, vga_color bg) {
    if (n < 0) { putchar('-', fg, bg); n = -n; }
    char buf[20];
    int i = 0;
    if (n == 0) { putchar('0', fg, bg); return; }
    while (n > 0) { buf[i++] = '0' + (n % 10); n /= 10; }
    while (i--) putchar(buf[i], fg, bg);
}

// -----------------------------------------------
// Your kernel starts here
// -----------------------------------------------
void kernel_main(void) {
    clear_screen(BLACK);

    print("=== My 64-bit OS ===\n", YELLOW, BLACK);
    print("Running in 64-bit long mode.\n", WHITE, BLACK);
    print("VGA text output working.\n", LIGHT_GREEN, BLACK);
    print("\nCount: ", CYAN, BLACK);

    for (int i = 1; i <= 5; i++) {
        print_int(i, LIGHT_CYAN, BLACK);
        print(" ", WHITE, BLACK);
    }

    print("\n\nKernel halted.", LIGHT_GREY, BLACK);

    while (1) {}
}