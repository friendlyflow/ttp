; ttp — the trust project: a self-hosting OS and compiler.
; Copyright (C) 2026  Nico Verrijdt
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

[bits 16]
[org 0x0000]

; boot.asm loads this stage at physical 0x10000 (segment 0x1000). Labels are
; org-0 offsets, so any value used as a linear address (GDT bases, the targets
; of the protected/long-mode far jumps) must be biased by LOAD.
LOAD equ 0x10000

    cli
    push cs
    pop ds                      ; DS = 0x1000 so [gdt32_descriptor] -> physical
    lgdt [gdt32_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword 0x08:(LOAD + pmode32)

[bits 32]
pmode32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000

    ; Identity map first 2MB via paging
    mov edi, 0x1000
    mov ecx, 0x3000
    xor eax, eax
    rep stosd

    mov dword [0x1000], 0x2007  ; present|write|user
    mov dword [0x2000], 0x3007  ; present|write|user
    mov dword [0x3000], 0x0087  ; present|write|user|2MB page

    mov eax, 0x1000
    mov cr3, eax

    mov eax, cr4
    or eax, (1 << 5)
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    mov eax, cr0
    or eax, (1 << 31) | 1
    mov cr0, eax

    lgdt [LOAD + gdt64_descriptor]
    jmp 0x08:(LOAD + long_mode)

; ── GDT for 32-bit protected mode ──────────────────
gdt32_start:
    dq 0
gdt32_code:
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
gdt32_data:
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt32_end:
gdt32_descriptor:
    dw gdt32_end - gdt32_start - 1
    dd LOAD + gdt32_start

; ── GDT for 64-bit long mode (ring 0 + ring 3 + TSS) ──
gdt64_start:
    dq 0                    ; 0x00 null
gdt64_kernel_code:          ; 0x08 kernel code  ring 0
    dw 0x0000, 0x0000
    db 0x00, 10011010b, 10100000b, 0x00
gdt64_kernel_data:          ; 0x10 kernel data  ring 0
    dw 0x0000, 0x0000
    db 0x00, 10010010b, 00000000b, 0x00
gdt64_user_data:            ; 0x18 user data    ring 3
    dw 0x0000, 0x0000
    db 0x00, 11110010b, 00000000b, 0x00
gdt64_user_code:            ; 0x20 user code    ring 3
    dw 0x0000, 0x0000
    db 0x00, 11111010b, 10100000b, 0x00
gdt64_tss_entry:            ; 0x28 TSS (16 bytes)
    dw 0x0068, 0x0000
    db 0x00, 10001001b, 00000000b, 0x00
    dq 0
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd LOAD + gdt64_start
    dd 0

; kernel.bin is loaded at disk sector 9; boot.asm reads from sector 1 to
; physical 0x10000, so kernel_entry sits at 0x10000 + (9-1)*512 = 0x11000
; (4K-aligned to match the page size).
KERNEL_PADDR equ 0x11000

[bits 64]
long_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov rsp, 0x90000
    mov rax, KERNEL_PADDR
    jmp rax