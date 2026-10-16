# hello.s — progs/riscv64/hello.ff for GNU as, linked with ff64.ld:
# `make check` compares the bytes.
    .option norvc
    .section .rodata
msg:    .ascii "hello, ff\n"
    .equ msg_len, . - msg

    .section .text
    .globl _start
_start:
    li      s1, 3
1:  call    print
    la      t0, count
    sd      s1, 0(t0)
    addi    s1, s1, -1
    bnez    s1, 1b
    li      a0, 0
    li      a7, 93
    ecall
print:
    li      a0, 1
    la      a1, msg
    li      a2, msg_len
    li      a7, 64
    ecall
    ret

    .section .bss
    .balign 8
count:  .skip 8
