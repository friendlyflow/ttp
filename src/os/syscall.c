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

#include "syscall.h"
#include "vga.h"

extern void syscall_entry(void);   // defined below in asm

void syscall_init(void) {
    // STAR MSR — syscall base 0x08 (kernel CS=0x08, SS=0x10);
    // sysret base 0x10 (user CS=0x10+16=0x20|3, SS=0x10+8=0x18|3)
    uint64_t star = ((uint64_t)0x08 << 32) | ((uint64_t)0x10 << 48);
    __asm__ volatile("wrmsr" :: "c"(0xC0000081UL), "A"(star));

    // LSTAR MSR — syscall entry point
    uint64_t lstar = (uint64_t)syscall_entry;
    __asm__ volatile("wrmsr" :: "c"(0xC0000082UL), "A"(lstar));

    // SFMASK MSR — clear IF on syscall entry (disable interrupts)
    __asm__ volatile("wrmsr" :: "c"(0xC0000084UL), "A"((uint64_t)0x200));

    // Enable syscall via EFER SCE bit
    uint32_t efer_lo, efer_hi;
    __asm__ volatile("rdmsr" : "=a"(efer_lo), "=d"(efer_hi) : "c"(0xC0000080UL));
    efer_lo |= 1;
    __asm__ volatile("wrmsr" :: "c"(0xC0000080UL), "a"(efer_lo), "d"(efer_hi));
}

// ── Called from syscall_entry below ──────────────────
void syscall_handler(uint64_t num, uint64_t arg0) {
    switch (num) {

        case SYS_PRINT:
            // arg0 = pointer to string in user memory
            vga_println((const char *)arg0, LIGHT_GREEN, BLACK);
            break;

        case SYS_EXIT:
            vga_println("User program exited.", YELLOW, BLACK);
            __asm__ volatile("hlt");
            break;

        default:
            vga_println("Unknown syscall!", LIGHT_RED, BLACK);
            break;
    }
}

// ── Raw syscall entry — must be naked asm ────────────
__attribute__((naked))
void syscall_entry(void) {
    __asm__ volatile(
        "swapgs             \n"     // swap to kernel GS base
        "push %%rcx         \n"     // save user RIP  (syscall puts it here)
        "push %%r11         \n"     // save user RFLAGS
        "mov %%rdi, %%rsi   \n"     // arg1 → arg0 of handler
        "mov %%rax, %%rdi   \n"     // syscall number → first arg
        "call syscall_handler\n"
        "pop %%r11          \n"
        "pop %%rcx          \n"
        "swapgs             \n"
        "sysretq            \n"     // return to ring 3
        :::
    );
}