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
#include "tss.h"
#include "syscall.h"
#include "userspace.h"

// ╔══════════════════════════════════════════════╗
// ║  KERNEL MAIN — ring 0, full hardware access  ║
// ║  Add kernel features here:                   ║
// ║    - memory management                       ║
// ║    - interrupt handlers (IDT)                ║
// ║    - device drivers                          ║
// ║    - filesystem                              ║
// ║    - process scheduler                       ║
// ╚══════════════════════════════════════════════╝

void kernel_main(void) {

    // ── Boot message ─────────────────────────────
    vga_clear(BLACK);
    vga_println("Kernel booted in 64-bit long mode.", YELLOW,      BLACK);
    vga_println("Ring 0 — kernel space active.",      LIGHT_GREEN, BLACK);
    vga_println("",                                   WHITE,       BLACK);

    // ── Kernel initialization ─────────────────────
    // Set up TSS so CPU knows the kernel stack for ring 3 → ring 0 switches
    tss_init(0x90000);
    vga_println("[OK] TSS initialized.",              LIGHT_GREY,  BLACK);

    // Set up syscall instruction handler
    syscall_init();
    vga_println("[OK] Syscall handler ready.",        LIGHT_GREY,  BLACK);

    vga_println("",                                   WHITE,       BLACK);
    vga_println("Jumping to userspace...",            CYAN,        BLACK);
    vga_println("",                                   WHITE,       BLACK);

    // ── Hand off to ring 3 ────────────────────────
    jump_to_userspace();

    // Never reached — jump_to_userspace does not return
    while (1) {}
}