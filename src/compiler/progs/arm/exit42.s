@ exit42.s — progs/arm/exit42.ff for GNU as, linked with ff32.ld: its bytes
@ must equal what ttpc writes after the 84-byte ELF header. exit(42) comes
@ first; the rest only checks encodings.
    .syntax unified
    .arch armv7-a
    .fpu vfpv3
    .text
    .globl _start
    .arm
_start:
    mov     r0, #42
    mov     r7, #1
    svc     #0
    str     r0, [sp, #-8]!
    ldr     r4, [sp, #16]
    movw    r5, #0x1234
    movt    r5, #0x5678
    beq     .+16
    bl      .-12
    lsl     r0, r0, #3
    sub     r0, r0, r1
    vadd.f64 d0, d1, d2
    .thumb
    movs    r0, #1
    add     r8, r9
