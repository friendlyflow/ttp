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
#include "keyboard.h"
#include "heap.h"
#include "string.h"

extern void syscall_entry(void);   // defined below in asm

#define VGA_MEM ((volatile uint16_t *)0xB8000)

void syscall_init(void) {
    // wrmsr takes EDX:EAX, so each 64-bit value must be split explicitly. The
    // "A" constraint does NOT reliably do this on x86-64 (it can leave the whole
    // value in RAX with EDX stale), which silently corrupted STAR's SYSCALL_CS
    // field — masked until an IRQ during a syscall made iretq reload a bad SS.
    #define WRMSR(msr, val) do {                                  \
        uint64_t _v = (uint64_t)(val);                            \
        __asm__ volatile("wrmsr" :: "c"(msr),                     \
                         "a"((uint32_t)_v), "d"((uint32_t)(_v >> 32))); \
    } while (0)

    // STAR MSR — syscall base 0x08 (kernel CS=0x08, SS=0x10);
    // sysret base 0x10 (user CS=0x10+16=0x20|3, SS=0x10+8=0x18|3)
    uint64_t star = ((uint64_t)0x08 << 32) | ((uint64_t)0x10 << 48);
    WRMSR(0xC0000081UL, star);

    // LSTAR MSR — syscall entry point
    WRMSR(0xC0000082UL, (uint64_t)syscall_entry);

    // SFMASK MSR — clear IF on syscall entry (disable interrupts)
    WRMSR(0xC0000084UL, (uint64_t)0x200);

    // Enable syscall via EFER SCE bit
    uint32_t efer_lo, efer_hi;
    __asm__ volatile("rdmsr" : "=a"(efer_lo), "=d"(efer_hi) : "c"(0xC0000080UL));
    efer_lo |= 1;
    __asm__ volatile("wrmsr" :: "c"(0xC0000080UL), "a"(efer_lo), "d"(efer_hi));
}

// ── Called from syscall_entry below; return value goes back in rax ────
uint64_t syscall_handler(uint64_t num, uint64_t arg0) {
    switch (num) {

        case SYS_PRINT:
            // arg0 = pointer to string in user memory
            vga_println((const char *)arg0, LIGHT_GREEN, BLACK);
            return 0;

        case SYS_EXIT:
            vga_println("User program exited.", YELLOW, BLACK);
            for (;;) __asm__ volatile("cli; hlt");

        case SYS_GETKEY:
            // Blocks in ring 0 (the keyboard port and hlt are privileged).
            return (uint64_t)keyboard_getkey();

        case SYS_BLIT:
            // arg0 = ring-3 cell buffer -> the VGA text framebuffer.
            memcpy((void *)VGA_MEM, (const void *)arg0,
                   VGA_CELLS * sizeof(uint16_t));
            return 0;

        case SYS_ALLOC:
            return (uint64_t)malloc(arg0);

        default:
            vga_println("Unknown syscall!", LIGHT_RED, BLACK);
            return (uint64_t)-1;
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