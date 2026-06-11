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

#include "idt.h"
#include "io.h"
#include "vga.h"

// ── x86-64 IDT gate descriptor (16 bytes) ───────────────────────────
struct __attribute__((packed)) idt_entry {
    uint16_t offset_low;    // handler bits 0..15
    uint16_t selector;      // code segment selector (kernel code = 0x08)
    uint8_t  ist;           // bits 0..2 = IST index, rest 0
    uint8_t  type_attr;     // 0x8E = present, DPL 0, 64-bit interrupt gate
    uint16_t offset_mid;    // handler bits 16..31
    uint32_t offset_high;   // handler bits 32..63
    uint32_t zero;          // reserved
};

struct __attribute__((packed)) idtr {
    uint16_t limit;
    uint64_t base;
};

static struct idt_entry idt[256];

// The 64-bit kernel code selector set up in stage2.asm's GDT.
#define KERNEL_CS 0x08

// Exception stub addresses (vectors 0..31) and the catch-all, from isr.asm.
extern void *isr_stub_table[];
extern void isr_irq_default(void);

void idt_set_gate(int vec, uint64_t handler, uint8_t type_attr) {
    idt[vec].offset_low  = handler & 0xFFFF;
    idt[vec].selector    = KERNEL_CS;
    idt[vec].ist         = 0;
    idt[vec].type_attr   = type_attr;
    idt[vec].offset_mid  = (handler >> 16) & 0xFFFF;
    idt[vec].offset_high = (handler >> 32) & 0xFFFFFFFF;
    idt[vec].zero        = 0;
}

// Remap the 8259 PIC pair so hardware IRQs land at vectors 0x20..0x2F instead
// of colliding with the CPU exception vectors (0x08..0x0F). All IRQs masked —
// M5 unmasks IRQ1 (keyboard) once there is a handler for it.
static void pic_remap(void) {
    outb(0x20, 0x11); io_wait();   // ICW1: begin init, expect ICW4
    outb(0xA0, 0x11); io_wait();
    outb(0x21, 0x20); io_wait();   // ICW2: master vector offset 0x20
    outb(0xA1, 0x28); io_wait();   // ICW2: slave  vector offset 0x28
    outb(0x21, 0x04); io_wait();   // ICW3: slave is on master IRQ2
    outb(0xA1, 0x02); io_wait();   // ICW3: slave cascade identity 2
    outb(0x21, 0x01); io_wait();   // ICW4: 8086 mode
    outb(0xA1, 0x01); io_wait();
    outb(0x21, 0xFF);              // mask all master IRQs
    outb(0xA1, 0xFF);              // mask all slave IRQs
}

void idt_init(void) {
    pic_remap();

    for (int v = 0; v < 32; v++)
        idt_set_gate(v, (uint64_t)isr_stub_table[v], 0x8E);
    for (int v = 32; v < 256; v++)
        idt_set_gate(v, (uint64_t)isr_irq_default, 0x8E);

    struct idtr idtr = { .limit = sizeof(idt) - 1, .base = (uint64_t)idt };
    __asm__ volatile("lidt %0" :: "m"(idtr));
}

// ── PANIC: called from the common ISR stub for any CPU exception ─────
__attribute__((noreturn))
void panic_from_isr(uint64_t vector, uint64_t error, uint64_t rip) {
    vga_clear(RED);
    vga_println("", WHITE, RED);
    vga_print("  *** KERNEL PANIC - CPU exception #", WHITE, RED);
    vga_print_int((int)vector, YELLOW, RED);
    vga_println("", WHITE, RED);
    vga_print("  error code = 0x", WHITE, RED);
    vga_print_hex(error, YELLOW, RED);
    vga_println("", WHITE, RED);
    vga_print("  faulting RIP = 0x", WHITE, RED);
    vga_print_hex(rip, YELLOW, RED);
    vga_println("", WHITE, RED);
    vga_println("", WHITE, RED);
    vga_println("  System halted.", LIGHT_GREY, RED);

    for (;;)
        __asm__ volatile("cli; hlt");
}
