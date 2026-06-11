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

#include "keyboard.h"
#include "idt.h"
#include "io.h"

extern void irq1_stub(void);   // asm entry in isr.asm

// ── key event ring buffer (producer: IRQ1, consumer: getkey) ─────────
#define KB_BUF 64
static volatile int kb_buf[KB_BUF];
static volatile int kb_head = 0, kb_tail = 0;

static void kb_push(int key) {
    int next = (kb_head + 1) % KB_BUF;
    if (next != kb_tail) {          // drop on overflow rather than clobber
        kb_buf[kb_head] = key;
        kb_head = next;
    }
}

// ── scancode set 1 → key code ────────────────────────────────────────
// Unshifted US layout for the printable keys we care about; 0 = ignore.
static const unsigned char sc_ascii[128] = {
    0,    KEY_ESC, '1','2','3','4','5','6','7','8','9','0','-','=', KEY_BACKSPACE,
    '\t', 'q','w','e','r','t','y','u','i','o','p','[',']', KEY_ENTER,
    0,    'a','s','d','f','g','h','j','k','l',';','\'','`',
    0,    '\\','z','x','c','v','b','n','m',',','.','/',
    0,    '*', 0,  ' ',
};

static int extended = 0;   // set after an 0xE0 prefix byte

// Translate one make (press) scancode to a key code, honoring the 0xE0 prefix
// for the arrow keys. Returns 0 for keys we don't surface.
static int translate(unsigned char sc) {
    if (extended) {
        switch (sc) {
            case 0x48: return KEY_UP;
            case 0x50: return KEY_DOWN;
            case 0x4B: return KEY_LEFT;
            case 0x4D: return KEY_RIGHT;
            default:   return 0;
        }
    }
    switch (sc) {            // keypad arrows (NumLock off) send these unprefixed
        case 0x48: return KEY_UP;
        case 0x50: return KEY_DOWN;
        case 0x4B: return KEY_LEFT;
        case 0x4D: return KEY_RIGHT;
    }
    if (sc < 128)
        return sc_ascii[sc];
    return 0;
}

// Called from irq1_stub for every IRQ1.
void keyboard_irq_handler(void) {
    unsigned char sc = inb(0x60);

    if (sc == 0xE0) {                 // extended prefix; the real code follows
        extended = 1;
    } else if (sc & 0x80) {           // break (release) code — ignore presses up
        extended = 0;
    } else {                          // make (press) code
        int key = translate(sc);
        extended = 0;
        if (key)
            kb_push(key);
    }

    outb(0x20, 0x20);                 // EOI to the master PIC
}

void keyboard_init(void) {
    idt_set_gate(0x21, (unsigned long)irq1_stub, 0x8E);

    // Unmask IRQ1 (keyboard) on the master PIC, leaving the rest masked.
    unsigned char mask = inb(0x21);
    mask &= ~(1 << 1);
    outb(0x21, mask);
}

int keyboard_poll(void) {
    if (kb_head == kb_tail)
        return -1;
    int key = kb_buf[kb_tail];
    kb_tail = (kb_tail + 1) % KB_BUF;
    return key;
}

int keyboard_getkey(void) {
    for (;;) {
        __asm__ volatile("cli");
        if (kb_head != kb_tail) {
            int key = kb_buf[kb_tail];
            kb_tail = (kb_tail + 1) % KB_BUF;
            __asm__ volatile("sti");
            return key;
        }
        // sti then hlt: the instruction after sti is shielded from interrupts,
        // so a key queued just now fires right after hlt — no lost-wakeup race.
        __asm__ volatile("sti; hlt");
    }
}
