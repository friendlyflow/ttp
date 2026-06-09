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

#include "userspace.h"

// Forward declaration — user_program is compiled separately
extern void user_program(void);

void jump_to_userspace(void) {
    uint64_t user_stack = 0x70000;          // must lie in the identity-mapped first 2MB
    uint64_t user_entry = (uint64_t)user_program;

    // Set user data segments
    __asm__ volatile(
        "mov $0x1B, %%ax    \n"     // 0x18 | 3 = user data selector
        "mov %%ax, %%ds     \n"
        "mov %%ax, %%es     \n"
        "mov %%ax, %%fs     \n"
        "mov %%ax, %%gs     \n"

        // iretq frame: SS, RSP, RFLAGS, CS, RIP
        "push $0x1B         \n"     // SS  — user data
        "push %0            \n"     // RSP — user stack
        "push $0x202        \n"     // RFLAGS — IF=1 (interrupts on)
        "push $0x23         \n"     // CS  — 0x20 | 3 = user code
        "push %1            \n"     // RIP — user entry point
        "iretq              \n"
        :
        : "r"(user_stack), "r"(user_entry)
        : "rax"
    );
}