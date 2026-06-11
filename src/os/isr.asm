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

; CPU exception entry stubs (vectors 0..31). Each pushes a uniform frame —
; (vector, error code) on top of the CPU's interrupt frame — and jumps to the
; common handler, which calls panic_from_isr(vector, errcode, rip) and halts.
; Some exceptions push an error code; for the rest we push a dummy 0 so the
; stack layout the common handler reads is identical for every vector.

[bits 64]

extern panic_from_isr

%macro ISR_NOERR 1
global isr_stub_%1
isr_stub_%1:
    push qword 0            ; dummy error code
    push qword %1           ; vector number
    jmp isr_common
%endmacro

%macro ISR_ERR 1
global isr_stub_%1
isr_stub_%1:
    ; CPU already pushed the error code
    push qword %1           ; vector number
    jmp isr_common
%endmacro

ISR_NOERR 0      ; #DE divide error
ISR_NOERR 1      ; #DB debug
ISR_NOERR 2      ; NMI
ISR_NOERR 3      ; #BP breakpoint
ISR_NOERR 4      ; #OF overflow
ISR_NOERR 5      ; #BR bound range
ISR_NOERR 6      ; #UD invalid opcode
ISR_NOERR 7      ; #NM device not available
ISR_ERR   8      ; #DF double fault
ISR_NOERR 9      ; (reserved)
ISR_ERR   10     ; #TS invalid TSS
ISR_ERR   11     ; #NP segment not present
ISR_ERR   12     ; #SS stack-segment fault
ISR_ERR   13     ; #GP general protection
ISR_ERR   14     ; #PF page fault
ISR_NOERR 15     ; (reserved)
ISR_NOERR 16     ; #MF x87 FP
ISR_ERR   17     ; #AC alignment check
ISR_NOERR 18     ; #MC machine check
ISR_NOERR 19     ; #XM SIMD FP
ISR_NOERR 20     ; #VE virtualization
ISR_ERR   21     ; #CP control protection
ISR_NOERR 22
ISR_NOERR 23
ISR_NOERR 24
ISR_NOERR 25
ISR_NOERR 26
ISR_NOERR 27
ISR_NOERR 28
ISR_NOERR 29
ISR_NOERR 30
ISR_NOERR 31

isr_common:
    mov rdi, [rsp]          ; vector
    mov rsi, [rsp + 8]      ; error code
    mov rdx, [rsp + 16]     ; faulting RIP (start of CPU interrupt frame)
    cld
    and rsp, -16            ; 16-byte align for the C ABI (we never return)
    call panic_from_isr
.hang:
    cli
    hlt
    jmp .hang

; Default handler for vectors 32..255. Most hardware IRQs are masked at the PIC;
; a stray/spurious interrupt just returns.
global isr_irq_default
isr_irq_default:
    iretq

; IRQ1 (keyboard) entry, installed at vector 0x21. Saves the caller-saved
; registers, calls the C handler (which reads the scancode and sends the PIC
; EOI), restores, and returns. No SSE is used anywhere (-mgeneral-regs-only),
; so stack alignment for the call is not a concern here.
extern keyboard_irq_handler
global irq1_stub
irq1_stub:
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    cld
    call keyboard_irq_handler
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    iretq

; Table of the 32 exception stub addresses, indexed by vector, for idt_init.
section .rodata
global isr_stub_table
isr_stub_table:
%assign i 0
%rep 32
    dq isr_stub_ %+ i
%assign i i + 1
%endrep
