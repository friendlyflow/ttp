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
#include "idt.h"
#include "heap.h"
#include "keyboard.h"
#include "navigator.h"
#include "tss.h"
#include "syscall.h"
#include "userspace.h"
#include <node.h>

// The embedded ff (serialized node program), from ff_blob.asm.
extern const unsigned char ff_blob_start[];
extern const unsigned char ff_blob_end[];

// Total node count in a subtree (the ff's true size, including operand leaves).
static int ff_count(struct node *n) {
    int c = 1;
    for (int i = 0; i < n->n_children; i++)
        c += ff_count(n->children[i]);
    return c;
}

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
    // Install the IDT first: until it exists, any CPU exception triple-faults
    // and silently reboots. With it, a fault renders a PANIC screen instead.
    idt_init();
    vga_println("[OK] IDT installed (PIC remapped, IRQs masked).", LIGHT_GREY, BLACK);

    // Bring up the heap (bump allocator in the 0x100000..0x1F0000 hole).
    heap_init();
    {
        // Self-test: allocate a few blocks, prove realloc preserves data.
        char *a = malloc(64);
        for (int i = 0; i < 64; i++) a[i] = (char)i;
        a = realloc(a, 256);
        int ok = 1;
        for (int i = 0; i < 64; i++) if (a[i] != (char)i) ok = 0;
        int *b = malloc(100 * sizeof(int));
        for (int i = 0; i < 100; i++) b[i] = i * 3;
        if (b[99] != 297) ok = 0;

        vga_print("[OK] Heap up @0x100000: ", LIGHT_GREY, BLACK);
        vga_print_int((int)heap_used(), WHITE, BLACK);
        vga_print(" bytes used, ", LIGHT_GREY, BLACK);
        vga_print_int((int)(heap_free() / 1024), WHITE, BLACK);
        vga_print(" KB free", LIGHT_GREY, BLACK);
        vga_println(ok ? " (realloc OK)." : " (SELFTEST FAIL).",
                    ok ? LIGHT_GREY : LIGHT_RED, BLACK);
    }

    // ── Load the ff (the node tree) from the embedded blob ────────
    struct node *ff = node_read_mem(ff_blob_start,
                                    (size_t)(ff_blob_end - ff_blob_start));
    if (ff) {
        vga_print("[OK] ff loaded: root '", LIGHT_GREY, BLACK);
        vga_print(ff->content, YELLOW, BLACK);
        vga_print("', ", LIGHT_GREY, BLACK);
        vga_print_int(ff_count(ff), WHITE, BLACK);
        vga_print(" nodes, ", LIGHT_GREY, BLACK);
        vga_print_int(ff->n_children, WHITE, BLACK);
        vga_println(" top-level children.", LIGHT_GREY, BLACK);
    } else {
        vga_println("[!!] ff failed to load.", LIGHT_RED, BLACK);
    }

    // Bring up the keyboard (IRQ1) and hand control to the ff navigator. The
    // navigator owns the screen from here and does not return.
    keyboard_init();
    if (ff)
        navigator_run(ff);

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