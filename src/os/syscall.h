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

void syscall_init(void);

// Syscall numbers. The ABI: rax = number, rdi = arg0, return value in rax.
#define SYS_PRINT  0   // arg0 = const char* (NUL-terminated), prints a line
#define SYS_EXIT   1   // halt the machine
#define SYS_GETKEY 2   // block for a key; returns the key code
#define SYS_BLIT   3   // arg0 = uint16_t[80*25] cell buffer -> copied to VGA
#define SYS_ALLOC  4   // arg0 = size; returns a heap pointer (or 0)

// VGA text dimensions, shared so ring 3 can size its blit buffer.
#define VGA_CELLS (80 * 25)