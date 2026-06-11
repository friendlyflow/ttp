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
#include "syscall.h"

// Ring-3 syscall wrappers. The ABI: number in rax, arg0 in rdi, result in rax;
// SYSCALL clobbers rcx (saved RIP) and r11 (saved RFLAGS). These let ring-3
// code reach the kernel without touching hardware directly.

static inline void sys_print(const char *s) {
    __asm__ volatile("syscall" :: "a"((uint64_t)SYS_PRINT), "D"(s)
                     : "rcx", "r11", "memory");
}

static inline void sys_exit(void) {
    __asm__ volatile("syscall" :: "a"((uint64_t)SYS_EXIT)
                     : "rcx", "r11", "memory");
}

// Block until a key is pressed; returns the key code (see keyboard.h KEY_*).
static inline int sys_getkey(void) {
    uint64_t r;
    __asm__ volatile("syscall" : "=a"(r) : "a"((uint64_t)SYS_GETKEY)
                     : "rcx", "r11", "memory");
    return (int)r;
}

// Copy an 80x25 cell buffer (char | attr<<8 per cell) to the VGA text screen.
static inline void sys_blit(const uint16_t *cells) {
    __asm__ volatile("syscall" :: "a"((uint64_t)SYS_BLIT), "D"(cells)
                     : "rcx", "r11", "memory");
}

// Allocate `n` bytes on the shared heap; returns NULL on exhaustion.
static inline void *sys_alloc(uint64_t n) {
    uint64_t r;
    __asm__ volatile("syscall" : "=a"(r) : "a"((uint64_t)SYS_ALLOC), "D"(n)
                     : "rcx", "r11", "memory");
    return (void *)r;
}
