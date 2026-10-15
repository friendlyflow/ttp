// hello.s — progs/aarch64/hello.ff for GNU as, linked with ff.ld: the
// bytes after ttpc's 120-byte ELF header must be the same.
    .section .rodata
msg:    .ascii "hello, ff\n"
    .equ msg_len, . - msg

    .section .text
    .globl _start
_start:
    movz    x19, #3
1:  bl      print
    adrp    x9, count
    add     x9, x9, :lo12:count
    str     x19, [x9]
    sub     x19, x19, #1
    cbnz    x19, 1b
    movz    x0, #0
    movz    x8, #93
    svc     #0
print:
    movz    x0, #1
    adrp    x1, msg
    add     x1, x1, :lo12:msg
    movz    x2, #msg_len
    movz    x8, #64
    svc     #0
    ret

    .section .bss
    .balign 8
count:  .skip 8
