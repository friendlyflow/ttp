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

// PS/2 keyboard via IRQ1. keyboard_init installs the handler at vector 0x21 and
// unmasks IRQ1 at the PIC. Key presses are decoded (scancode set 1) and queued;
// the navigator pops them with keyboard_getkey.

// Key codes. Printable keys come through as their ASCII value (< 0x100); the
// special keys below sit above the ASCII range so they never collide.
#define KEY_ENTER     '\n'
#define KEY_ESC       0x1B
#define KEY_BACKSPACE 0x08
#define KEY_UP        0x100
#define KEY_DOWN      0x101
#define KEY_LEFT      0x102
#define KEY_RIGHT     0x103

void keyboard_init(void);

// Block until a key is available (enabling interrupts while idle), return it.
int  keyboard_getkey(void);

// Non-blocking: return a queued key, or -1 if none.
int  keyboard_poll(void);
