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

// ╔══════════════════════════════════════════════╗
// ║  USER PROGRAM — ring 3, restricted access    ║
// ║  - cannot touch hardware directly            ║
// ║  - talks to the kernel only via syscall      ║
// ║  This is the ring-3 entry: it runs the ff    ║
// ║  navigator (and, through it, the compiler).  ║
// ╚══════════════════════════════════════════════╝

#include "uapi.h"
#include "navigator.h"

// The ff root, published by the kernel (ring 0) before jump_to_userspace and
// read here in ring 3. The tree lives on the shared heap, so the pointer is all
// that crosses the boundary.
struct node *g_ff;

void user_program(void) {
    if (g_ff)
        navigator_run(g_ff);   // owns the screen; does not return

    sys_print("ff failed to load.");
    sys_exit();
}