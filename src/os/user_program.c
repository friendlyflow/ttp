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
// ║  - cannot call kernel functions directly     ║
// ║  - talk to kernel only via syscall           ║
// ║  Add user programs here:                     ║
// ║    - shell                                   ║
// ║    - applications                            ║
// ║    - user libraries                          ║
// ╚══════════════════════════════════════════════╝

// Inline syscall — no libc available
static void sys_print(const char *str) {
    __asm__ volatile(
        "mov $0, %%rax  \n"     // SYS_PRINT = 0
        "mov %0, %%rdi  \n"     // arg0 = string pointer
        "syscall        \n"
        :: "r"(str) : "rax", "rdi", "rcx", "r11"
    );
}

static void sys_exit(void) {
    __asm__ volatile(
        "mov $1, %%rax  \n"     // SYS_EXIT = 1
        "syscall        \n"
        ::: "rax", "rcx", "r11"
    );
}

void user_program(void) {
    sys_print("Hello from ring 3 userspace!");
    sys_print("I cannot touch hardware directly.");
    sys_print("I talk to the kernel via syscall.");
    sys_exit();
}