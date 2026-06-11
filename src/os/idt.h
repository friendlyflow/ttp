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

// Install the IDT: CPU-exception handlers (0..31) that render a PANIC screen,
// a benign default for vectors 32..255, and remap the 8259 PIC to 0x20..0x2F
// with all hardware IRQs masked. Call once, early in kernel_main.
void idt_init(void);

// Point a single IDT vector at a handler (used by later milestones, e.g. the
// keyboard wiring IRQ1 -> vector 0x21). type_attr 0x8E = present ring-0 gate.
void idt_set_gate(int vec, uint64_t handler, uint8_t type_attr);
