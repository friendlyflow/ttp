@ hello.s — progs/arm/hello.ff for GNU as, linked with ff32.ld: its bytes
@ must equal what ttpc writes after the 84-byte ELF header.
    .syntax unified
    .arch armv7-a
    .section .rodata
msg:    .ascii "hello, ff\n"
    .equ msg_len, . - msg

    .text
    .globl _start
    .arm
_start:
    mov     r4, #3
1:  bl      print
    movw    r0, #:lower16:count
    movt    r0, #:upper16:count
    str     r4, [r0]
    subs    r4, r4, #1
    bne     1b
    mov     r0, #0
    mov     r7, #1
    svc     #0
print:
    mov     r0, #1
    movw    r1, #:lower16:msg
    movt    r1, #:upper16:msg
    movw    r2, #:lower16:msg_len
    movt    r2, #:upper16:msg_len
    mov     r7, #4
    svc     #0
    bx      lr

    .bss
    .balign 8
count:  .skip 4
