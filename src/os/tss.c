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

#include "tss.h"
#include <stdint.h>

// GDT TSS descriptor is at selector offset 0x28 in the GDT set up by stage2.asm

__attribute__((aligned(16)))
TSS tss = {0};

void tss_init(uint64_t kernel_stack) {
    tss.rsp0       = kernel_stack;
    tss.iomap_base = sizeof(TSS);

    uint64_t base = (uint64_t)&tss;

    // Read the live GDT base instead of hardcoding it, so this stays correct
    // regardless of where stage2.asm placed the GDT.
    struct __attribute__((packed)) {
        uint16_t limit;
        uint64_t base;
    } gdtr;
    __asm__ volatile("sgdt %0" : "=m"(gdtr));

    // Patch TSS base address into GDT entry at 0x28
    uint8_t *entry = (uint8_t *)(gdtr.base + 0x28);
    entry[2]  = (base >>  0) & 0xFF;
    entry[3]  = (base >>  8) & 0xFF;
    entry[4]  = (base >> 16) & 0xFF;
    entry[7]  = (base >> 24) & 0xFF;
    *(uint32_t *)(entry + 8) = (uint32_t)(base >> 32);

    // Load TSS selector into TR register
    __asm__ volatile("ltr %0" :: "r"((uint16_t)0x28));
}