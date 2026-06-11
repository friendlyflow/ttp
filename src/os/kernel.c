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
#include "ata.h"
#include "gen.h"
#include "tss.h"
#include "syscall.h"
#include "userspace.h"
#include <node.h>

// The embedded ff (serialized node program), from ff_blob.asm.
extern const unsigned char ff_blob_start[];
extern const unsigned char ff_blob_end[];

// Handed to the ring-3 navigator entry (user_program.c).
extern struct node *g_ff;

// Total node count in a subtree (the ff's true size, including operand leaves).
static int ff_count(struct node *n) {
    int c = 1;
    for (int i = 0; i < n->n_children; i++)
        c += ff_count(n->children[i]);
    return c;
}

// Print the first 4 bytes of a 32-byte id as 8 hex chars.
static void print_hash8(const uint8_t *h, vga_color fg) {
    static const char hx[] = "0123456789abcdef";
    char b[9];
    for (int i = 0; i < 4; i++) { b[i*2] = hx[h[i] >> 4]; b[i*2+1] = hx[h[i] & 0xF]; }
    b[8] = '\0';
    vga_print(b, fg, BLACK);
}

// NixOS-style boot menu: pick a saved generation to boot. Returns the chosen
// generation index, or -1 when none are saved (boot the embedded ff). Defaults
// the selection to the newest generation.
static int boot_menu(void) {
    int n = gen_count();
    if (n == 0) return -1;
    int sel = n - 1;
    for (;;) {
        vga_clear(BLACK);
        vga_println("ttp - boot a generation:", YELLOW, BLACK);
        vga_println("", WHITE, BLACK);
        for (int i = 0; i < n; i++) {
            int on = (i == sel);
            vga_print(on ? "  > generation " : "    generation ",
                      on ? LIGHT_CYAN : LIGHT_GREY, BLACK);
            vga_print_int(i, on ? WHITE : LIGHT_GREY, BLACK);
            vga_print("   root ", LIGHT_GREY, BLACK);
            print_hash8(gen_root_id(i), on ? LIGHT_GREEN : DARK_GREY);
            if (i == gen_current()) vga_print("   (last booted)", DARK_GREY, BLACK);
            vga_println("", WHITE, BLACK);
        }
        vga_println("", WHITE, BLACK);
        vga_println("Up/Down: select    Enter: boot", DARK_GREY, BLACK);

        int k = keyboard_getkey();
        if (k == KEY_UP && sel > 0) sel--;
        else if (k == KEY_DOWN && sel < n - 1) sel++;
        else if (k == KEY_ENTER) return sel;
    }
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

    // ── Disk (ATA PIO) self-test ──────────────────────────────────
    {
        static uint8_t sec[ATA_SECTOR];
        int rok = (ata_read(0, 1, sec) == 0 &&
                   sec[510] == 0x55 && sec[511] == 0xAA);   // boot signature
        static uint8_t pat[ATA_SECTOR], back[ATA_SECTOR];
        for (int i = 0; i < ATA_SECTOR; i++) pat[i] = (uint8_t)(i * 7 + 1);
        int wok = (ata_write(1900, 1, pat) == 0 &&
                   ata_read(1900, 1, back) == 0);
        for (int i = 0; i < ATA_SECTOR && wok; i++) if (back[i] != pat[i]) wok = 0;
        vga_print("[OK] ATA disk: read ", LIGHT_GREY, BLACK);
        vga_print(rok ? "OK" : "FAIL", rok ? LIGHT_GREY : LIGHT_RED, BLACK);
        vga_print(", write ", LIGHT_GREY, BLACK);
        vga_println(wok ? "OK." : "FAIL.", wok ? LIGHT_GREY : LIGHT_RED, BLACK);
    }

    // Keyboard up early — the boot menu needs it (it runs in ring 0).
    keyboard_init();
    vga_println("[OK] Keyboard (IRQ1) enabled.",      LIGHT_GREY,  BLACK);

    // ── Choose the ff to boot: a saved generation, or the embedded seed ──
    gen_init();
    int choice = boot_menu();          // -1 when no generations exist yet
    struct node *ff = 0;
    if (choice >= 0) {
        ff = gen_load(choice);
        if (ff) gen_set_current(choice);
    }
    if (!ff)                            // first boot, or a load failure
        ff = node_read_mem(ff_blob_start,
                           (size_t)(ff_blob_end - ff_blob_start));

    vga_clear(BLACK);
    if (ff) {
        vga_print("[OK] ff: root '", LIGHT_GREY, BLACK);
        vga_print(ff->content, YELLOW, BLACK);
        vga_print("', ", LIGHT_GREY, BLACK);
        vga_print_int(ff_count(ff), WHITE, BLACK);
        vga_print(" nodes", LIGHT_GREY, BLACK);
        if (choice >= 0) { vga_print(" (generation ", LIGHT_GREY, BLACK);
                           vga_print_int(choice, WHITE, BLACK);
                           vga_print(")", LIGHT_GREY, BLACK); }
        else vga_print(" (embedded seed)", LIGHT_GREY, BLACK);
        vga_println(".", LIGHT_GREY, BLACK);
    } else {
        vga_println("[!!] ff failed to load.", LIGHT_RED, BLACK);
    }

    // Publish the ff to the ring-3 navigator, then bring up the rest of the
    // surface it needs: the TSS (kernel stack for ring 3 -> ring 0) and SYSCALL.
    g_ff = ff;
    tss_init(0x90000);
    syscall_init();

    vga_println("Entering the ff navigator in ring 3...", CYAN,    BLACK);

    // Hand off to ring 3; user_program() runs the navigator and never returns.
    jump_to_userspace();

    while (1) {}
}