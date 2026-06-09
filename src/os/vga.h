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

#pragma once
#include <stdint.h>

typedef enum {
    BLACK = 0, BLUE, GREEN, CYAN, RED, MAGENTA,
    BROWN, LIGHT_GREY, DARK_GREY, LIGHT_BLUE,
    LIGHT_GREEN, LIGHT_CYAN, LIGHT_RED, PINK,
    YELLOW, WHITE
} vga_color;

void vga_clear(vga_color bg);
void vga_print(const char *str, vga_color fg, vga_color bg);
void vga_println(const char *str, vga_color fg, vga_color bg);
void vga_print_int(int n, vga_color fg, vga_color bg);